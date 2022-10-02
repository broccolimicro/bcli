# syntax = docker/dockerfile:1.0-experimental

FROM ubuntu:latest

RUN apt-get update

RUN mkdir toolsrc
RUN mkdir /opt/cad

WORKDIR /toolsrc
RUN apt-get -y install wget make gcc g++
RUN wget https://download.open-mpi.org/release/hwloc/v2.8/hwloc-2.8.0.tar.gz
RUN tar -xzvf hwloc-2.8.0.tar.gz
WORKDIR hwloc-2.8.0
RUN ./configure
RUN make
RUN make install

# Xyce and Trilinos takes the longest to execute, in the interest of caching, this should go first.
# install Trilinos
WORKDIR /toolsrc
# basic dependencies
RUN apt-get install -y gcc g++ gfortran make cmake flex libfl-dev libfftw3-dev libsuitesparse-dev libblas-dev liblapack-dev libtool
# building from git repo dependencies
RUN apt-get install -y autoconf automake git
# parallel dependencies
RUN apt-get install -y libhwloc15 libopenmpi-dev openmpi-bin openmpi-common

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

# install ACT-06
RUN echo "hello"
RUN apt-get install -y libedit-dev zlib1g-dev m4 git gcc g++ make
WORKDIR /toolsrc
RUN --mount=type=secret,id=user --mount=type=secret,id=token git clone https://$(cat /run/secrets/user):$(cat /run/secrets/token)@git.broccolimicro.io/Broccoli/act-06.git
WORKDIR act-06
RUN XYCE_INSTALL="/usr/local" ENABLE_MPI=1 make
RUN cp prsim/prsim chan.py measure.py sim2vcd.py tlint/tlint spi2act/spi2act.py v2act/v2act /opt/cad/bin

# install go
WORKDIR /toolsrc
RUN apt-get -y install wget
RUN /usr/bin/wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
RUN tar -C /opt -xzf go1.19.1.linux-amd64.tar.gz

# install python
RUN apt-get install -y python3 pip

# install editors
WORKDIR "/"
ADD home template
RUN apt-get install -y vim
RUN mkdir -p /template/.vim/pack/plugins/start
RUN git clone https://github.com/fatih/vim-go.git /template/.vim/pack/plugins/start/vim-go
RUN git clone https://tpope.io/vim/fugitive.git /template/.vim/pack/plugins/start/fugitive
RUN git clone https://github.com/preservim/nerdtree.git /template/.vim/pack/plugins/start/nerdtree

# install gaw
RUN apt-get update --fix-missing; DEBIAN_FRONTEND=noninteractive apt-get install -y libgtk-3-dev libcanberra-gtk3-module
WORKDIR /toolsrc
RUN --mount=type=secret,id=user --mount=type=secret,id=token git clone https://$(cat /run/secrets/user):$(cat /run/secrets/token)@git.broccolimicro.io/Broccoli/waveview.git
WORKDIR waveview
RUN ./configure
RUN make
RUN make install

# install gtkwave
RUN apt-get update --fix-missing; DEBIAN_FRONTEND=noninteractive apt-get install -y gtkwave

# install magic layout tool
WORKDIR /toolsrc
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tcsh m4 csh libx11-dev tcl-dev tk-dev libcairo2-dev mesa-common-dev libglu1-mesa-dev libncurses-dev
RUN git clone https://github.com/RTimothyEdwards/magic.git
WORKDIR magic
RUN ./configure
RUN make
RUN make install

# install prspice
WORKDIR /toolsrc
RUN echo "hello"
RUN git clone https://github.com/nbingham1/prspice.git
WORKDIR prspice
RUN git checkout xyce
RUN make
RUN cp prdbase prspice /opt/cad/bin

# install pr
WORKDIR /toolsrc
RUN --mount=type=secret,id=user --mount=type=secret,id=token git clone https://$(cat /run/secrets/user):$(cat /run/secrets/token)@git.broccolimicro.io/Broccoli/pr.git
RUN cp pr/* /opt/cad/bin

# install OpenRoad
#WORKDIR /toolsrc
#RUN git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git
#WORKDIR OpenROAD-flow-scripts

# Clean up source code folder
#RUN rm -rf /toolsrc

# Connect user home directory of host machine
RUN mkdir "/host"
WORKDIR "/host"
RUN rm -rf /opt/cad/conf
RUN ln -s "/host/tech" "/opt/cad/conf"

ENV USER "bcli"
ENV USER_ID "1000" 
ENV GROUP_ID "1000"

CMD exec /bin/bash -c "/usr/sbin/groupadd -g $GROUP_ID $USER; \
  /usr/sbin/useradd -u $USER_ID -g $USER $USER; \
  cp -r /template /home/$USER; \
  chown -R $USER:$USER /home/$USER; \
  trap : TERM INT; sleep infinity & wait"
