# Testbed for Grammar-Based Fuzzers

This repository provides scripts to test, run, benchmark, and analyze grammar-based fuzzers. 

These fuzzers are:

- [ATNwalk](https://github.com/atnwalk/atnwalk)
- [Gramatron](https://github.com/HexHive/Gramatron)
- [Nautilus](https://github.com/nautilus-fuzz/nautilus)

We use a docker image as a runtime environment.
However, all fuzz targets and fuzzers are contained within a home directory on the host volume.
This home directory is then mounted as the `/home/rocky/` directory inside the container. 
Fuzzing campaign results are stored at `/home/rocky/campaign`.
Hence, if there is a need for a larger disk, please mount it to `/home/rocky/campaign` and make sure it has the correct user and group permissions.

## Table of contents
1. [Prerequisites](#prerequisites)
1. [Setup user, directories, and permissions](#setup-user-directories-and-permissions)
1. [Build and run the testbed Docker image](#build-and-run-the-testbed-docker-image)
1. [Install fuzz targets and fuzzers](#installing-fuzz-targets-and-fuzzers)
1. [Run a particular fuzzer](#run-a-particular-fuzzer)
    1. [List of fuzz targets](#list-of-fuzz-targets)
    1. [Run ATNwalk](#run-atnwalk)
    1. [Run Gramatron](#run-gramatron)
    1. [Run Nautilus](#run-nautilus)
1. [Benchmark campaigns](#benchmark-campaigns)


## Prerequisites

- Docker or podman must be installed (following examples are with docker)
- Privileges to become another user, starting docker/podman, and mounting volumes inside a container are required (e.g. via sudo) 
- Disable core dumps with `echo core >/proc/sys/kernel/core_pattern` as a privileged user when using AFL++ based fuzzers
- A user and a group, both preferably called `rocky`, with the uid `9973` and the gid `9973` must be present on the host system (instructions below)

## Setup user, directories, and permissions

**IMPORTANT:**
Before preparing the host system please check whether your host system has the required prerequisites.
Refer to the [Prerequisites](#prerequisites) section to check these.

**Note:** You can freely choose the username, uid, and gid. However, the uid and gid should match the ones in the `Dockerfile` otherwise you need to setup ACLs accordingly (not explained).

Create the `rocky` user
```bash
# fedora and rocky linux
sudo groupadd --gid 9973 rocky
sudo useradd --uid 9973 --gid 9973 --no-user-group --home-dir /home/rocky --create-home --shell /bin/bash rocky

# ubuntu and debian
sudo addgroup --gid 9973 rocky
sudo adduser --uid 9973 --gid 9973 --home /home/rocky --shell /bin/bash --disabled-password --gecos 'non-privileged user' rocky
```

Create the `/home/rocky/campaign` directory and set the owner to `rocky`
```bash
# create (or mount) the campaign directory
sudo mkdir /home/rocky/campaign
sudo chown rocky:rocky /home/rocky/campaign
```

Setup the ACLs accordingly
```bash
# check the current ACL config
sudo getfacl /home/rocky

# allow your current group to rwx files and dirs in /home/rocky and subdirs
sudo setfacl --recursive --modify default:group:$(id -g):rwx,group:$(id -g):rwx /home/rocky

# allow the rocky user to rwx files that are owned by anyone else,
# which also includes files created by your current user
sudo setfacl --recursive --modify default:user:rocky:rwx,user:rocky:rwx /home/rocky

# check that the command worked as expected by running
sudo getfacl /home/rocky

# # if ACLs were not set as intended, revert changes back to defaults with: 
# sudo setfacl --recursive --remove-all /home/rocky
```


## Build and run the testbed Docker image

**IMPORTANT:** 
Creating and, in particular, running the testbed Docker image requires preparation of the host system.
Refer to the "[Setup user, directories, and permissions](#setup-user-directories-and-permissions)" section on how to set it up.

Build the testbed Docker image
```bash
# clone the testbed repository
cd /home/rocky/
git clone https://github.com/atnwalk/testbed.git
cd testbed

# replace 'docker' with 'podman' on fedora and rocky linux
# (although podman can work without sudo, mounting the host volume
#  inside the container with the correct permissions requires it)
sudo docker build --tag testbed:"$(date +'%Y%m%d')" --file Dockerfile .
```

Run the testbed container
```bash
# note down your image name including its tag
sudo docker images

# IMPORTANT: replace the DATE placeholder below with the noted image tag

# start the container and mount the /home/rocky directory inside it (:z is used to work with SELinux)
sudo docker run --rm --interactive --tty --volume /home/rocky:/home/rocky:z testbed:DATE /bin/bash

# # short version, if preferred
# sudo docker run --rm -itv /home/rocky:/home/rocky:z testbed:DATE /bin/bash

# inside the container, make sure that you can list files from the host, including the testbed
ls -la
ls -la ~/testbed

# for convenience, you can setup the 'll' alias
echo 'alias ll="ls -l --color=auto"' >> ~/.bashrc
source ~/.bashrc
ll
```


## Installing fuzz targets and fuzzers

**IMPORTANT:** 
Execute all subsequent commands within the testbed container. 
Refer to the [Build and run the testbed Docker image](#build-and-run-the-testbed-docker-image) section on how to run it.

Install everything
```bash
# this takes some time...
for s in ~/testbed/install/*; do bash "${s}"; done
```

Install only a particular target or fuzzer
```bash
# alternatively, you can choose what to install by selecting the script
# this will take care of installing dependencies;
# e.g., to install JerryScript run
bash ~/testbed/install/jerry.bash

# or install ATNwalk and its dependencies
bash ~/testbed/install/atnwalk.bash
```


## Run a particular fuzzer

**IMPORTANT:** 
Execute all subsequent commands within the testbed container and install fuzzers and fuzz targets in advance.
Refer to the [Build and run the testbed Docker image](#build-and-run-the-testbed-docker-image) and [Install fuzz targets and fuzzers](#installing-fuzz-targets-and-fuzzers) sections on how to accomplish that.


### List of fuzz targets

```bash
# Mruby
~/mruby/bin/mruby

# SQLite3
~/sqlite3/sqlite3

# PHP
~/php-src/sapi/cli/php

# Lua
~/lua/lua

# JerryScript
~/jerryscript/build/bin/jerry
```


### Run ATNwalk

```bash
# create the required a random seed first
mkdir -p ~/campaign/example/seeds
cd ~/campaign/example/seeds
head -c1 /dev/urandom | ~/atnwalk/build/javascript/bin/decode -wb > seed.decoded 2> seed.encoded

# create the required atnwalk directory and copy the seed
cd ../
mkdir -p atnwalk/in
cp ./seeds/seed.encoded atnwalk/in/seed
cd atnwalk

# assign to a single core when benchmarking it, change the CPU number as required
CPU_ID=0

# start the ATNwalk server
nohup taskset -c ${CPU_ID} ${HOME}/atnwalk/build/javascript/bin/server 100 > server.log 2>&1 &

# start AFL++ with ATNwalk
AFL_SKIP_CPUFREQ=1 \
  AFL_DISABLE_TRIM=1 \
  AFL_CUSTOM_MUTATOR_ONLY=1 \
  AFL_CUSTOM_MUTATOR_LIBRARY=${HOME}/AFLplusplus/custom_mutators/atnwalk/atnwalk.so \
  AFL_POST_PROCESS_KEEP_ORIGINAL=1 \
  ~/AFLplusplus/afl-fuzz -t 100 -i in/ -o out -b ${CPU_ID} -- ~/jerryscript/build/bin/jerry

# make sure to kill the ATNwalk server process after you're done
kill "$(cat atnwalk.pid)"
```


### Run Gramatron

```bash
# create the required a random seed first or reuse the seed.decoded file if already worked with ATNwalk
mkdir -p ~/campaign/example/seeds
cd ~/campaign/example/seeds
head -c1 /dev/urandom | ~/atnwalk/build/javascript/bin/decode -wb > seed.decoded 2> seed.encoded

# create the required gramatron directory and copy the seed
cd ../
mkdir -p gramatron/in
cp ./seeds/seed.decoded gramatron/in/seed
cd gramatron

# assign to a single core when benchmarking it, change the CPU number as required
CPU_ID=0

# start AFL++ with Gramatron
AFL_SKIP_CPUFREQ=1 \
  AFL_DISABLE_TRIM=1 \
  AFL_CUSTOM_MUTATOR_ONLY=1 \
  AFL_CUSTOM_MUTATOR_LIBRARY=${HOME}/AFLplusplus/custom_mutators/gramatron/gramatron.so \
  GRAMATRON_AUTOMATION=${HOME}/grammars/gramatron/JavaScript_automata.json \
  ~/AFLplusplus/afl-fuzz -t 100 -i in/ -o out -b ${CPU_ID} -- ~/jerryscript/build/bin/jerry
```


### Run Nautilus

```bash
mkdir -p ~/campaign/example/nautilus/out
cd ~/campaign/example/nautilus

# set the grammar and the fuzz target and then create the config.ron
GRAMMAR=${HOME}/grammars/nautilus/JavaScript.py
TARGET=~/jerryscript/build/bin/jerry

cat <<EOF > config.ron
Config(
  //You probably want to change the follwoing options
  //File Paths
  path_to_bin_target:                     "${TARGET}",
  arguments:        [], //"@@" will be exchanged with the path of a file containing the current input
  path_to_grammar:                        "${GRAMMAR}",
  path_to_workdir:                        "$(pwd)/out",
  number_of_threads:      1,
  timeout_in_millis:      100,
  //The rest of the options are probably not something you want to change... 
  //Forkserver parameter
  bitmap_size:        65536, //1<<16
  //Thread Settings:
  thread_size:        4194304,
  hide_output: true, //hide stdout of the target program. Sometimes usefull for debuging
  
  //Mutation Settings
  number_of_generate_inputs:    100,  //see main.rs fuzzing_thread 
  max_tree_size:        1000,   //see state.rs generate random
  number_of_deterministic_mutations:  1,  //see main.rs process_input
)
EOF

# assign to a single core when benchmarking it, change the CPU number as required
CPU_ID=0

taskset -c ${CPU_ID} ${HOME}/nautilus/target/release/fuzzer
```


## Benchmark campaigns

**IMPORTANT:** Before running any campaigns, make sure to disable core dumps for AFL++ otherwise your fuzzers may not start. For that, run the following commands

The commands below need to be run with your local user that has sudo privileges (*not* `rocky`).
```bash
# become root
sudo -i

# disable core dumps
echo core >/proc/sys/kernel/core_pattern

# become your regular but privileged user
exit
```

Adjust the number of runs inside the `/home/rocky/testbed/start_campaign.bash`
```bash
vim ~/testbed/start_campaign.bash
# adjust RUNS=5 to a value suitable for your setup
# basically it is 3 fuzzers x 5 targets x RUNS = number of utilized cores
# hence RUNS=5 --> 75 cores, RUNS=1 --> 15 cores, and so on...
```

Lastly, start the fuzzing campaign with the following command
```bash
# make sure to be your privileged user to start docker and mount the volume

# IMPORTANT: replace the DATE placeholder below with the noted image via: sudo docker images

# the line starting with "--mount type=tmpfs ..." might not be required, 
# but Nautilus creates a lot of files in that directory, 
# so make sure to have enough space available at /tmp
sudo docker run --detach --rm \
  --ulimit core=0 --ulimit nofile=1000000:1000000 \
  --mount type=tmpfs,destination=/tmp,tmpfs-size=10737418240 \
  --volume /home/rocky:/home/rocky testbed:DATE \
  /bin/bash /home/rocky/testbed/start_campaign.bash
```

You can view logs with `sudo docker logs [-f] CONTAINER` and use the printed hash.

It should print something like this in the format: `fuzzer_name: target/campaign_number cpu_id`
```
atnwalk: mruby/1 11
atnwalk: sqlite3/1 12
atnwalk: php/1 13
atnwalk: lua/1 14
atnwalk: jerry/1 0
gramatron: mruby/1 1
gramatron: sqlite3/1 2
gramatron: php/1 3
gramatron: lua/1 4
gramatron: jerry/1 5
nautilus: mruby/1 6
nautilus: sqlite3/1 7
nautilus: php/1 8
nautilus: lua/1 9
nautilus: jerry/1 10
```

Check whether the dedicated cores have high utilization with a command like `htop` and confirm that processes are started with `top`. 
If you find that processes are not not running, then make sure to disable core dumps (see instructions above).

Results, can be found inside the `/home/rocky/campaign/` directory.

Access results preferably via an interactive docker container, so that programs can be executed with the found inputs
```bash
# IMPORTANT: replace the DATE placeholder below with the noted image
sudo docker run --rm -itv /home/rocky:/home/rocky:z testbed:DATE /bin/bash
```

To obtain AFL metrics in CSV format and decode all ATNwalk inputs, run the following commands:
```bash
# obtain the timestamp name of the resulting directory
ls -l /home/rocky/campaign/
# should list a folder in timestamp format like: 20221119-171727
# note that timestamp down

# 1. adjust the CAMPAIGNS array in start_stats.bash first and add the timestamp
# 2. adjust RUNS=5 to a value you have set for start_campaigns.bash
vim /home/rocky/testbed/start_stats.bash

# become the user that can run docker
exit

# IMPORTANT: replace the DATE placeholder below with the noted image

# run the stats script to obtain AFL++ metrics
sudo docker run --detach --rm \
  --ulimit core=0 --ulimit nofile=1000000:1000000 \
  --mount type=tmpfs,destination=/tmp,tmpfs-size=10737418240 \
  --volume /home/rocky:/home/rocky:z testbed:DATE \
  /bin/bash /home/rocky/testbed/start_stats.bash
```

To obtain GCOV metrics in CSV format and decode all ATNwalk inputs, run the following commands:
```bash
# obtain the timestamp name of the resulting directory
sudo su - rocky
ls -l /home/rocky/campaign/
# should list a folder in timestamp format like: 20221119-171727
# note that timestamp down

# IMPORTANT: adjust RUNS=5 to a value you have set for start_campaigns.bash in the following files:
vim /home/rocky/testbed/coverage_atnwalk.bash
vim /home/rocky/testbed/coverage_gramatron.bash
vim /home/rocky/testbed/coverage_nautilus.bash

# become the user that can run docker
exit

# run the stats script to obtain GCOV coverage metrics
# IMPORTANT: set the CAMPAIGN_DATE to the timestamps you've obtained from the above commands and DATE with the correct image tag
sudo docker run --detach --rm \
  --ulimit core=0 --ulimit nofile=1000000:1000000 \
  --mount type=tmpfs,destination=/tmp,tmpfs-size=10737418240 \
  --volume /home/rocky:/home/rocky:z testbed:DATE \
  /bin/bash /home/rocky/testbed/coverage_atnwalk.bash CAMPAIGN_DATE [CAMPAIGN_DATE ...]

sudo docker run --detach --rm \
  --ulimit core=0 --ulimit nofile=1000000:1000000 \
  --mount type=tmpfs,destination=/tmp,tmpfs-size=10737418240 \
  --volume /home/rocky:/home/rocky:z testbed:DATE \
  /bin/bash /home/rocky/testbed/coverage_gramatron.bash CAMPAIGN_DATE [CAMPAIGN_DATE ...]

sudo docker run --detach --rm \
  --ulimit core=0 --ulimit nofile=1000000:1000000 \
  --mount type=tmpfs,destination=/tmp,tmpfs-size=10737418240 \
  --volume /home/rocky:/home/rocky:z testbed:DATE \
  /bin/bash /home/rocky/testbed/coverage_nautilus.bash CAMPAIGN_DATE [CAMPAIGN_DATE ...]
```

Find all metrics inside `/home/rocky/campaign/stats_YOUR_CAMPAIGN_DATE`

Use the scripts in `~/testbed/analysis/` to generate plots and calculate statistical tests.
