# syntax = docker/dockerfile:1.0-experimental

FROM ubuntu:latest

RUN apt-get update

RUN mkdir toolsrc
RUN mkdir /opt/cad

# Xyce and Trilinos takes the longest to execute, in the interest of caching, this should go first.
# install Trilinos
WORKDIR /toolsrc
# basic dependencies
RUN apt-get install -y gcc g++ gfortran make cmake flex libfl-dev libfftw3-dev libsuitesparse-dev libblas-dev liblapack-dev libtool
# building from git repo dependencies
RUN apt-get install -y autoconf automake git
# parallel dependencies
RUN apt-get install -y libopenmpi-dev openmpi-bin

RUN git clone https://github.com/trilinos/Trilinos.git
WORKDIR Trilinos
RUN git checkout tags/trilinos-release-12-12-1
RUN mkdir build
RUN mkdir /opt/trilinos
WORKDIR build
ADD trilinos/reconfigure .
RUN ./reconfigure
RUN make
RUN make install

# install Xyce
WORKDIR /toolsrc
RUN apt-get install -y bison
RUN git clone https://github.com/Xyce/Xyce.git
WORKDIR Xyce
RUN ./bootstrap
RUN mkdir build
WORKDIR build
RUN ../configure ARCHDIR=/opt/trilinos --enable-mpi --disable-verbose_linear --disable-verbose_nonlinear --disable-verbose_time --enable-shared --enable-xyce-shareable CC=mpicc CXX=mpicxx F77=mpifort CXXFLAGS="-O1 -fno-inline -std=c++11 -I/usr/lib/x86_64-linux-gnu/openmpi/include"
RUN make
RUN make install

# install ACT
WORKDIR /toolsrc
RUN apt-get install -y libedit-dev zlib1g-dev m4 git gcc g++ make
RUN git clone https://github.com/asyncvlsi/act.git
WORKDIR act
ENV ACT_HOME=/opt/cad
ENV VLSI_TOOLS_SRC=/toolsrc/act
RUN ./configure $ACT_HOME 
RUN ./build
RUN make install

# install Haystack
WORKDIR /toolsrc
RUN git clone https://github.com/nbingham1/haystack.git
WORKDIR haystack
RUN git submodule update --init --recursive
WORKDIR lib
RUN make
WORKDIR ../bin
RUN make
RUN cp hseplot/plot /opt/cad/bin
RUN cp hsesim/hsesim /opt/cad/bin
RUN cp hseenc/hseenc /opt/cad/bin

# install prspice
WORKDIR /toolsrc
RUN git clone https://github.com/nbingham1/prspice.git
WORKDIR prspice
RUN git checkout xyce
RUN make
RUN cp prdbase prspice /opt/cad/bin

# install ACT-06
RUN apt-get install -y libedit-dev zlib1g-dev m4 git gcc g++ make
WORKDIR /toolsrc
RUN --mount=type=secret,id=user --mount=type=secret,id=token git clone https://$(cat /run/secrets/user):$(cat /run/secrets/token)@git.broccolimicro.io/Broccoli/act-06.git
WORKDIR act-06
RUN XYCE_INSTALL="/usr/local" make
RUN cp prsim/prsim chan.py measure.py sim2vcd.py tlint/tlint spi2act/spi2act.py v2act/v2act /opt/cad/bin

# TODO(edward.bingham) install gaw

# TODO(edward.bingham) setup vnc

# TODO(edward.bingham) setup mounted source folder

# TODO(edward.bingham) setup network mounted tech folder

