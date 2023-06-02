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
# install python
RUN apt-get update --fix-missing; DEBIAN_FRONTEND=noninteractive apt-get install -y python3 pip

RUN apt-get install -y bison
RUN git clone --shallow-since 2022-09-15 --branch develop https://github.com/trilinos/Trilinos.git
RUN git clone https://github.com/Xyce/Xyce.git --branch Release-7.6.0

WORKDIR Trilinos
RUN git checkout b91cc3dcd9
RUN mkdir build
RUN mkdir /opt/trilinos
WORKDIR build
RUN cmake \
  -D CMAKE_C_COMPILER=mpicc \
  -D CMAKE_CXX_COMPILER=mpic++ \
  -D CMAKE_Fortran_COMPILER=mpif77 \
  -D CMAKE_INSTALL_PREFIX="/opt/trilinos" \
  -D TPL_AMD_INCLUDE_DIRS="/usr/include/suitesparse" \
  -D AMD_LIBRARY_DIRS="/usr/lib" \
  -D MPI_BASE_DIR="/usr" \ 
  -C /toolsrc/Xyce/cmake/trilinos/trilinos-config-MPI.cmake \
    /toolsrc/Trilinos
RUN cmake --build . -j 40 -t install

# install Xyce
WORKDIR /toolsrc
WORKDIR Xyce
RUN mkdir build
WORKDIR build
RUN cmake \
  -D CMAKE_INSTALL_PREFIX=/opt/cad \
  -D Trilinos_ROOT=/opt/trilinos \
  /toolsrc/Xyce
RUN cmake --build . -j 16 -t install
RUN make xycecinterface
RUN make install

# install go
WORKDIR /toolsrc
RUN apt-get -y install wget
RUN /usr/bin/wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
RUN tar -C /opt -xzf go1.19.1.linux-amd64.tar.gz

# install editors
WORKDIR "/"
ADD home template
RUN apt-get install -y vim
RUN mkdir -p /template/.vim/pack/plugins/start
RUN git clone https://www.github.com/fatih/vim-go.git /template/.vim/pack/plugins/start/vim-go
RUN git clone https://github.com/tpope/vim-fugitive /template/.vim/pack/plugins/start/fugitive
RUN git clone https://www.github.com/preservim/nerdtree.git /template/.vim/pack/plugins/start/nerdtree
RUN vim +GoInstallBinaries +qall

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
RUN git clone https://www.github.com/RTimothyEdwards/magic.git
WORKDIR magic
RUN ./configure
RUN make
RUN make install

# install OpenRoad
#WORKDIR /toolsrc
#RUN git clone https://www.github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git
#WORKDIR OpenROAD-flow-scripts

# install ACT
RUN pwd
WORKDIR /toolsrc
RUN apt-get install -y libedit-dev zlib1g-dev m4 git gcc g++ make
RUN git clone https://www.github.com/asyncvlsi/act.git
WORKDIR act
ENV ACT_HOME=/opt/cad
ENV VLSI_TOOLS_SRC=/toolsrc/act
RUN ./configure $ACT_HOME CC=mpicc CXX=mpic++
RUN ./build
RUN make install

# install actsim
WORKDIR /toolsrc
RUN git clone https://github.com/asyncvlsi/actsim.git
WORKDIR actsim
RUN ./configure
RUN ./grab_xyce.sh /toolsrc/Xyce/build
#WORKDIR ext
RUN ./build.sh
#WORKDIR ..
RUN make CXX=mpic++ CC=mpicc install

# install ACT-06
RUN apt-get install -y libedit-dev zlib1g-dev m4 git gcc g++ make
WORKDIR /toolsrc
RUN --mount=type=secret,id=user --mount=type=secret,id=token git clone https://$(cat /run/secrets/user):$(cat /run/secrets/token)@git.broccolimicro.io/Broccoli/act-06.git
WORKDIR act-06/prsim
RUN ./grab_xyce.sh /toolsrc/Xyce/build
WORKDIR ..
RUN XYCE_INSTALL="/opt/cad" ENABLE_MPI=1 make
RUN cp prsim/prsim chan.py measure.py sim2vcd.py tlint/tlint spi2act/spi2act.py v2act/v2act /opt/cad/bin

# install Haystack
WORKDIR /toolsrc
RUN git clone https://github.com/nbingham1/haystack.git --branch v0.0.0
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

# install pr
WORKDIR /toolsrc
RUN --mount=type=secret,id=user --mount=type=secret,id=token git clone https://$(cat /run/secrets/user):$(cat /run/secrets/token)@git.broccolimicro.io/Broccoli/pr.git
RUN cp -r pr/* /opt/cad/bin

# Clean up source code folder
#RUN rm -rf /toolsrc

# Connect user home directory of host machine
RUN mkdir "/host"
WORKDIR "/host"
RUN rm -rf /opt/cad/conf
RUN mkdir /opt/cad/conf

ENV USER "bcli"
ENV USER_ID "1000" 
ENV GROUP_ID "1000"
ENV MEMBERS ""

RUN echo "HELLO!?!?"
CMD exec /bin/bash -c "echo \"$MEMBERS\" | sed 's/ /\n/g' | xargs -n 2 /usr/sbin/groupadd -g; \
  /usr/sbin/useradd -u $USER_ID -g $USER $USER; \
  echo \"$MEMBERS\" | sed 's/ [0-9]\+ /,/g' | sed 's/[0-9]\+ //g' | xargs -I{} /usr/sbin/usermod -aG {} $USER; \
  cp -r /template /home/$USER; \
  chown -R $USER:$USER /home/$USER; \
  trap : TERM INT; sleep infinity & wait"
