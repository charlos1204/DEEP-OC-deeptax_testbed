# Dockerfile may have two Arguments: tag, branch
# tag - tag for the Base image, (e.g. 1.10.0-py3 for tensorflow)
# branch - user repository branch to clone (default: master, other option: test)

ARG tag=9.1-cudnn7-devel-ubuntu16.04

# Base image, e.g. tensorflow/tensorflow:1.12.0-py3
FROM nvidia/cuda:${tag}

LABEL maintainer='Carlos Garcia'
LABEL version='0.01'
# tax class

# What user branch to clone (!)
ARG branch=master

# Install ubuntu updates and python related stuff
# link python3 to python, pip3 to pip, if needed
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
         git \
         curl \
         wget \
         python3-setuptools \
         python3-pip \
         python3-wheel && \ 
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    if [ "python3" = "python3" ] ; then \
       if [ ! -e /usr/bin/pip ]; then \
          ln -s /usr/bin/pip3 /usr/bin/pip; \
       fi; \
       if [ ! -e /usr/bin/python ]; then \
          ln -s /usr/bin/python3 /usr/bin/python; \
       fi; \
    fi && \
    python --version && \
    pip --version

##########################################################################################################
# Install git, wget, python-dev, pip, BLAS + LAPACK and other dependencies
RUN apt-get update && apt-get install -y \
  nano \
  gcc \
  g++ \
  gfortran \
  build-essential \
  tk-dev \
  checkinstall\
  liblapack-dev \
  libopenblas-dev \
  libreadline-gplv2-dev \
  libncursesw5-dev \
  libssl-dev \
  libsqlite3-dev \
  libgdbm-dev \
  libc6-dev \
  libbz2-dev \
  libatlas-dev \
  libatlas3-base \
  software-properties-common

# Set CUDA_ROOT
ENV CUDA_ROOT /usr/local/cuda/bin

# Install CMake 3
RUN cd /root && wget https://github.com/Kitware/CMake/releases/download/v3.14.0-rc1/cmake-3.14.0-rc1.tar.gz && \
  tar -xvf cmake-3.14.0-rc1.tar.gz && cd cmake-3.14.0-rc1 && \
  ./configure && \
  make -j "$(nproc)" && \
  make install

# Install Cython
RUN pip install Cython
RUN pip install --upgrade numpy

# Clone libgpuarray repo and move into it
RUN cd /root && git clone https://github.com/Theano/libgpuarray.git && cd libgpuarray && \
# Make and move into build directory
  mkdir Build && cd Build && \
# CMake
  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && \
# Make
  make -j"$(nproc)" && \
  make install
# Install pygpu
RUN cd /root/libgpuarray && \
  python3 setup.py build_ext -L /usr/lib -I /usr/include && \
  python3 setup.py install

# Install bleeding-edge Theano
RUN pip install --upgrade six
RUN pip install --upgrade --no-deps git+git://github.com/Theano/Theano.git
RUN pip install --upgrade https://github.com/Lasagne/Lasagne/archive/master.zip
RUN pip install biopython
RUN pip install nose
RUN pip install scipy
RUN pip install tqdm
RUN pip install flask
RUN pip install joblib
RUN pip install scikit-learn
RUN pip install tabulate
RUN pip install --upgrade --no-deps --force-reinstall git+https://github.com/dnouri/nolearn.git@master#egg=nolearn==0.7.git

# Set up .theanorc for CUDA
RUN echo "[global]\ndevice=cuda\nfloatX=float64\nroot=/usr/local/cuda-9.1\n[lib]\ncnmem=0.1\n[nvcc]\nfastmath=True\n[gpuarray]\npreallocate=1" > /root/.theanorc

COPY base.py /usr/local/lib/python3.5/site-packages/nolearn/lasagne
#######################################################################

# Set LANG environment
ENV LANG C.UTF-8

# Set the working directory
WORKDIR /srv

# Install rclone
RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    apt install -f && \
    mkdir /srv/.rclone/ && touch /srv/.rclone/rclone.conf && \
    rm rclone-current-linux-amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Install DEEPaaS from PyPi
# Install FLAAT (FLAsk support for handling Access Tokens)
RUN pip install --no-cache-dir \
        'deepaas>=0.3.0' \
        flaat && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Disable FLAAT authentication by default
ENV DISABLE_AUTHENTICATION_AND_ASSUME_AUTHENTICATED_USER yes


# Install user app:
RUN git clone -b $branch https://github.com/charlos1204/firsttest && \
    cd  firsttest && \
    pip install --no-cache-dir -e . && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    cd ..


# Open DEEPaaS port
EXPOSE 5000

# Open Monitoring port
EXPOSE 6006

# Account for OpenWisk functionality (deepaas >=0.3.0)
CMD ["sh", "-c", "deepaas-run --openwhisk-detect --listen-ip 0.0.0.0"]
