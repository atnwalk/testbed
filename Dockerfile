FROM rockylinux:9

# epel installation and 'crb enable' is needed for 're2c'
RUN dnf update -y && dnf install -y epel-release && crb enable && dnf install -y \
  # for user interaction, downloads, and password management
  vim tmux wget passwd \
  # AFL++ dependencies
  python3-devel automake cmake git flex bison glib2-devel pixman-devel python3-setuptools gtk3-devel lld llvm llvm-devel clang \
  # atnwalk (build) dependencies
  java-latest-openjdk \
  # Gramatron dependencies
  libtool \
  # SQLite dependencies
  tcl \
  # mruby dependencies
  rake \
  # lua dependencies
  readline-devel \
  # php dependencies
  re2c

# create the 'rocky' group and user
RUN groupadd --gid 9973 rocky \
  && useradd --uid 9973 --gid 9973 --no-user-group --home-dir /home/rocky --create-home --shell /bin/bash rocky \
  # for the 'rocky and 'root' users, delete their passwords and lock the accounts
  && passwd --delete rocky \
  && passwd --lock rocky \
  && passwd --delete root \
  && passwd --lock root

USER rocky
WORKDIR /home/rocky
