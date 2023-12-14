# syntax = docker/dockerfile:1.0-experimental

# Stage #1: build all executables
FROM ubuntu:latest
SHELL ["/bin/bash", "-c"]

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

# install OpenRoad
WORKDIR /toolsrc
RUN git clone --recursive https://www.github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git
WORKDIR OpenROAD-flow-scripts
RUN apt-get -y install sudo
RUN SUDO_USER="root" ./setup.sh
RUN ./build_openroad.sh --local --install-path /opt/openroad --nice
RUN mv dependencies /opt/or-tools

# install ACT
RUN pwd
WORKDIR /toolsrc
RUN apt-get install -y libedit-dev zlib1g-dev m4 git gcc g++ make libboost-all-dev
RUN git clone https://www.github.com/asyncvlsi/actflow.git
WORKDIR actflow
RUN git submodule update --init --recursive
ENV ACT_HOME=/opt/cad
ENV VLSI_TOOLS_SRC=/toolsrc/actflow
RUN ./build

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
RUN --mount=type=secret,id=user --mount=type=secret,id=token git clone https://$(cat /run/secrets/user):$(cat /run/secrets/token)@git.broccolimicro.io/Broccoli/act-06.git --branch v1.0.1
WORKDIR act-06/prsim
RUN ./grab_xyce.sh /toolsrc/Xyce/build
WORKDIR ..
RUN XYCE_INSTALL="/opt/cad" ENABLE_MPI=1 make
RUN cp prsim/prsim chan.py measure.py sim2vcd.py tlint/tlint spi2act/spi2act.py v2act/v2act /opt/cad/bin

# install graphviz DOT
RUN apt-get install -y graphviz

# install Haystack
RUN echo "building haystack"
WORKDIR /toolsrc
RUN git clone https://github.com/nbingham1/haystack.git --branch v0.1.2
WORKDIR haystack
RUN git submodule update --init --recursive
WORKDIR lib
RUN make
WORKDIR ../bin
RUN make
RUN cp hsesim/hsesim /opt/cad/bin
RUN cp hseenc/hseenc /opt/cad/bin
RUN cp hseplot/plot /opt/cad/bin
RUN cp bubble/bubble /opt/cad/bin
RUN cp prsim/prsim /opt/cad/bin/prsimh # don't overwrite act's prsim
RUN cp gated/gated /opt/cad/bin
RUN cp prsize/size /opt/cad/bin
WORKDIR ../old/chp2hse
RUN make
RUN cp chp2hse /opt/cad/bin
WORKDIR ../hse2prs
RUN make
RUN cp hse2prs /opt/cad/bin

# install go
WORKDIR /toolsrc
RUN apt-get -y install wget
RUN /usr/bin/wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
RUN tar -C /opt -xzf go1.19.1.linux-amd64.tar.gz
RUN GOPATH=/opt/go /opt/go/bin/go install golang.org/x/tools/gopls@latest
RUN GOPATH=/opt/go /opt/go/bin/go install golang.org/x/lint/golint@latest

# install gaw
RUN apt-get update --fix-missing; DEBIAN_FRONTEND=noninteractive apt-get install -y libgtk-3-dev libcanberra-gtk3-module
WORKDIR /toolsrc
RUN git clone https://git.broccolimicro.io/Broccoli/waveview.git
WORKDIR waveview
RUN ./configure --prefix=/opt/cad
RUN make
RUN make install

# install gtkwave
RUN apt-get update --fix-missing; DEBIAN_FRONTEND=noninteractive apt-get install -y gtkwave

# install prspice
WORKDIR /toolsrc
RUN git clone https://github.com/nbingham1/prspice.git --branch v0.0.1
WORKDIR prspice
RUN make
RUN cp prdbase prspice /opt/cad/bin

# install pr
WORKDIR /toolsrc
RUN --mount=type=secret,id=user --mount=type=secret,id=token git clone https://$(cat /run/secrets/user):$(cat /run/secrets/token)@git.broccolimicro.io/Broccoli/pr.git --branch v0.0.3
RUN cp pr/pr pr/scripts/* /opt/cad/bin

# install magic layout tool
WORKDIR /toolsrc
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tcsh m4 csh libx11-dev tcl-dev tk-dev libcairo2-dev mesa-common-dev libglu1-mesa-dev libncurses-dev
RUN git clone https://www.github.com/RTimothyEdwards/magic.git
WORKDIR magic
RUN ./configure --prefix=/opt/magic
RUN make
RUN make install

# Stage 2: Copy everything over to final image
FROM ubuntu:latest
SHELL ["/bin/bash", "-c"]

RUN mkdir toolsrc
RUN apt-get update --fix-missing; DEBIAN_FRONTEND=noninteractive apt-get -y install wget make gcc g++ gfortran make cmake autoconf automake git libhwloc15 libopenmpi-dev openmpi-bin openmpi-common python3 pip bison libgtk-3-dev libcanberra-gtk3-module gtkwave tcsh m4 csh libx11-dev tcl-dev tk-dev libcairo2-dev mesa-common-dev libglu1-mesa-dev libncurses-dev libedit-dev zlib1g-dev m4 git gcc g++ make libboost-all-dev graphviz sudo vim flex libfl-dev libfftw3-dev libsuitesparse-dev libblas-dev liblapack-dev libtool; apt-get update --fix-missing

WORKDIR /toolsrc
COPY --from=0 /toolsrc/OpenROAD-flow-scripts/etc/DependencyInstaller.sh /toolsrc/etc/DependencyInstaller.sh
COPY --from=0 /toolsrc/OpenROAD-flow-scripts/tools/OpenROAD/etc/DependencyInstaller.sh /toolsrc/tools/OpenROAD/etc/DependencyInstaller.sh
RUN ./etc/DependencyInstaller.sh -base
RUN ./tools/OpenROAD/etc/DependencyInstaller.sh -base

COPY --from=0 /opt/* /opt

WORKDIR /toolsrc
RUN wget https://download.open-mpi.org/release/hwloc/v2.8/hwloc-2.8.0.tar.gz
RUN tar -xzvf hwloc-2.8.0.tar.gz
WORKDIR hwloc-2.8.0
RUN ./configure
RUN make
RUN make install

# Clean up source code folder
RUN rm -rf /toolsrc

# install editors
WORKDIR "/"
ADD home template
RUN mkdir -p /template/.vim/pack/plugins/start
RUN git clone https://www.github.com/fatih/vim-go.git /template/.vim/pack/plugins/start/vim-go
RUN git clone https://github.com/tpope/vim-fugitive /template/.vim/pack/plugins/start/fugitive
RUN git clone https://www.github.com/preservim/nerdtree.git /template/.vim/pack/plugins/start/nerdtree
#RUN vim +GoInstallBinaries +qall

# Connect user home directory of host machine
RUN mkdir "/host"
WORKDIR "/host"
RUN rm -rf /opt/cad/conf
RUN mkdir /opt/cad/conf

ENV USER "bcli"
ENV USER_ID "1000" 
ENV GROUP_ID "1000"
ENV MEMBERS ""

RUN echo "version: 17"
CMD exec /bin/bash -c "echo \"127.0.0.1 bcli-$USER\" >> /etc/hosts; \
  echo \"$MEMBERS\" | sed 's/[0-9]* \\(adm\|cdrom\|sudo\|dip\|plugdev\|lxd\|docker\|dialout\|sambashare\|lpadmin\\) \?//g' | sed 's/ /\n/g' | xargs -n 2 /usr/sbin/groupadd -g; \
  /usr/sbin/useradd -u $USER_ID -g $USER $USER; \
  echo \"$MEMBERS\" | sed 's/[0-9]* \\(adm\|cdrom\|sudo\|dip\|plugdev\|lxd\|docker\|dialout\|sambashare\\) \?//g' | sed 's/ [0-9]\+ /,/g' | sed 's/[0-9]\+ //g' | xargs -I{} /usr/sbin/usermod -aG {} $USER; \
  cp -r /template /home/$USER; \
  chown -R $USER:$USER /home/$USER; \
  echo \"$USER ALL=NOPASSWD: /usr/bin/apt-get install *\" > /etc/sudoers.d/apt-get; \
  echo \"$USER ALL=NOPASSWD: /usr/bin/apt install *\" > /etc/sudoers.d/apt; \
  trap : TERM INT; sleep infinity & wait"


# In case we need to add a password for sudo.
# However, its possible for someone to break out of the docker container and
# have root access on the host if they are given sudo access in the container.
# So, we really shouldn't give them sudo access
# /usr/sbin/usermod -p \$(openssl passwd -1 'bcli') $USER; \ 
