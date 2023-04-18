package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
)

type RootObj struct {
	Files []FileObj `json:"files"`
}

type FileObj struct {
	Name      string        `json:"file"`
	Lines     []LineObj     `json:"lines"`
	Functions []FunctionObj `json:"functions"`
}

type LineObj struct {
	Number   int         `json:"line_number"`
	Count    int         `json:"count"`
	Branches []BranchObj `json:"branches"`
}

type BranchObj struct {
	Count int `json:"count"`
}

type FunctionObj struct {
	Name  string `json:"name"`
	Count int    `json:"execution_count"`
}

type FileStats struct {
	Lines struct {
		Covered map[int]struct{}
		Total   map[int]struct{}
	}
	Branches  map[int][]bool
	Functions struct {
		Covered map[string]struct{}
		Total   map[string]struct{}
	}
	Mutex sync.Mutex
}

func NewFileStats() *FileStats {
	stat := &FileStats{}
	stat.Lines.Covered = make(map[int]struct{})
	stat.Lines.Total = make(map[int]struct{})
	stat.Branches = make(map[int][]bool)
	stat.Functions.Covered = make(map[string]struct{})
	stat.Functions.Total = make(map[string]struct{})
	return stat
}

func main() {
	workDir, _ := filepath.Abs(".")
	for _, arg := range os.Args[1:] {
		if arg == "-h" || arg == "--help" {

			fmt.Printf("usage: %s [-h|--help] [-r|--reset] [-ph|--print-header]\n", filepath.Base(os.Args[0]))
			fmt.Print(`
This program collects Gcov coverage information and prints the aggregated
results as comma-separated values. It scans recursively the current working
directory for *.gcno files and uses these as arguments when executing 'gcov'.
By using the '--json-format' flag, the 'gcov' output is parsed and aggregated.

Order of CSV values:
  lines_covered, lines_total,
  branches_covered, branches_total,
  functions_covered, functions_total,
  files_covered, files_total

Example output (no coverage):    0,33947,0,20552,0,2148,0,212
Example output (with coverage):  1799,33947,609,20552,228,2148,42,212

Optional arguments:
  -h, --help             print this help message and exit
  -r, --reset            reset Gcov counters (coverage information)
                         with 'gcov-tool' and exit
  -ph, --print-header    print a CSV header in addition to the comma-separated
                         coverage results
`)
			return
		}
		if arg == "-r" || arg == "--reset" {
			dirs := make([]string, 0, 1)
			err := filepath.WalkDir(workDir, func(path string, d fs.DirEntry, err error) error {
				if err != nil {
					return err
				}
				if d.IsDir() {
					dirs = append(dirs, path)
				}
				return nil
			})
			if err != nil {
				panic(err)
			}

			gcovToolPath, err := exec.LookPath("gcov-tool")
			if err != nil {
				panic(err)
			}
			for _, d := range dirs {
				gcovToolCmd := exec.Command(gcovToolPath, "rewrite", "--scale", "0.0", "--output", d, d)
				gcovToolCmd.Stdout = io.Discard
				gcovToolCmd.Stderr = io.Discard
				err := gcovToolCmd.Start()
				if err != nil {
					panic(err)
				}
			}
			return
		}
		if arg == "-ph" || arg == "--print-header" {
			fmt.Println("lines_covered,lines_total,branches_covered,branches_total," +
				"functions_covered,functions_total,files_covered,files_total")
		}
	}

	gcnoFiles := make([]string, 0, 1)
	err := filepath.WalkDir(workDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() {
			if strings.HasSuffix(path, ".gcno") {
				gcnoFiles = append(gcnoFiles, path)
			}
		}
		return nil
	})
	if err != nil {
		panic(err)
	}

	gcovPath, err := exec.LookPath("gcov")
	if err != nil {
		panic(err)
	}
	args := append(
		[]string{"--no-output", "--branch-probabilities", "--branch-counts", "--unconditional-branches",
			"--json-format", "--stdout"}, gcnoFiles...)
	gcovCmd := exec.Command(gcovPath, args...)
	gcovCmd.Stderr = io.Discard
	stdout, err := gcovCmd.StdoutPipe()
	if err != nil {
		panic(err)
	}
	if err := gcovCmd.Start(); err != nil {
		panic(err)
	}

	reader := bufio.NewReader(stdout)
	allStats := make(map[string]*FileStats)
	var allStatsMutex sync.Mutex
	semaphore := make(chan struct{}, runtime.NumCPU())
	for {
		data, err := reader.ReadBytes('\n')
		if err != nil && errors.Is(err, io.EOF) {
			if errors.Is(err, io.EOF) {
				break
			}
			panic(err)
		}
		obj := &RootObj{}
		if err := json.Unmarshal(data, obj); err != nil {
			panic(err)
		}
		for _, f := range obj.Files {
			f.Name, _ = filepath.Abs(f.Name)
			if !strings.HasPrefix(f.Name, workDir) || strings.HasSuffix(f.Name, "<stdout>") {
				continue
			}
			semaphore <- struct{}{}
			go func(f FileObj) {
				defer func() {
					<-semaphore
				}()
				allStatsMutex.Lock()
				fileStats, ok := allStats[f.Name]
				if !ok {
					fileStats = NewFileStats()
					allStats[f.Name] = fileStats
				}
				allStatsMutex.Unlock()
				fileStats.Mutex.Lock()
				defer fileStats.Mutex.Unlock()

				for _, line := range f.Lines {
					// lines
					if line.Count > 0 {
						if _, ok := fileStats.Lines.Covered[line.Number]; !ok {
							fileStats.Lines.Covered[line.Number] = struct{}{}
						}
					}
					if _, ok := fileStats.Lines.Total[line.Number]; !ok {
						fileStats.Lines.Total[line.Number] = struct{}{}
					}

					// branches
					if len(line.Branches) == 0 {
						continue
					}
					prevBranchCounts, ok := fileStats.Branches[line.Number]
					var curBranchCounts []bool
					if !ok {
						curBranchCounts = make([]bool, len(line.Branches))
						fileStats.Branches[line.Number] = curBranchCounts
					} else if len(line.Branches) <= len(prevBranchCounts) {
						curBranchCounts = prevBranchCounts
					} else {
						curBranchCounts = make([]bool, len(line.Branches))
						copy(curBranchCounts, prevBranchCounts)
						fileStats.Branches[line.Number] = curBranchCounts
					}
					for i, branch := range line.Branches {
						if branch.Count > 0 {
							curBranchCounts[i] = true
						}
					}
				}

				// functions
				for _, function := range f.Functions {
					if function.Count > 0 {
						if _, ok := fileStats.Functions.Covered[function.Name]; !ok {
							fileStats.Functions.Covered[function.Name] = struct{}{}
						}
					}
					if _, ok := fileStats.Functions.Total[function.Name]; !ok {
						fileStats.Functions.Total[function.Name] = struct{}{}
					}
				}
			}(f)
		}
		obj = nil
	}
	for i := 0; i < cap(semaphore); i++ {
		semaphore <- struct{}{}
	}

	type Ratio struct {
		Covered int
		Total   int
	}

	type Summary struct {
		Lines     Ratio
		Branches  Ratio
		Functions Ratio
		Files     Ratio
	}

	var summary Summary

	for _, fileStat := range allStats {
		summary.Lines.Covered += len(fileStat.Lines.Covered)
		summary.Lines.Total += len(fileStat.Lines.Total)
		for _, branchInfo := range fileStat.Branches {
			for _, covered := range branchInfo {
				if covered {
					summary.Branches.Covered += 1
				}
			}
			summary.Branches.Total += len(branchInfo)
		}
		summary.Functions.Covered += len(fileStat.Functions.Covered)
		summary.Functions.Total += len(fileStat.Functions.Total)
		if len(fileStat.Lines.Covered) > 0 {
			summary.Files.Covered += 1
		}
	}
	summary.Files.Total = len(allStats)

	fmt.Printf("%d,%d,%d,%d,%d,%d,%d,%d\n",
		summary.Lines.Covered, summary.Lines.Total,
		summary.Branches.Covered, summary.Branches.Total,
		summary.Functions.Covered, summary.Functions.Total,
		summary.Files.Covered, summary.Files.Total)
}
