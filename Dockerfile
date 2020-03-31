# Dockerfile may have two Arguments: tag, branch
# tag - tag for the Base image, (e.g. 1.10.0-py3 for tensorflow)
# branch - user repository branch to clone (default: master, other option: test)

#ARG tag=9.0-cudnn7-devel-ubuntu16.04
ARG tag=1.12.0-gpu-py3

#testbed
#ARG tag=9.2-cudnn7-devel-ubuntu18.04
#ARG tag=10.0-cudnn7-devel-ubuntu18.04

# Base image, e.g. tensorflow/tensorflow:1.12.0-gpu-py3
FROM tensorflow/tensorflow:${tag}

LABEL maintainer='Carlos Garcia'
LABEL version='0.01'
# tax class

# What user branch to clone (!)
ARG branch=master

ARG pyVer=python3

ENV DEBIAN_FRONTEND=noninteractive

#ENV TZ Europe/Berlin
#RUN echo $TZ > /etc/timezone

# Install ubuntu updates and python related stuff
# link python3 to python, pip3 to pip, if needed
RUN DEBIAN_FRONTEND='noninteractive' apt-get update && \
    apt-get install -y --no-install-recommends \
         git \
         curl \
         wget \
         $pyVer-setuptools \
         $pyVer-pip \
         $pyVer-wheel && \
         $pyVer-wheel \
         $pyVer-tk \
         $pyVer-matplotlib \
         $pyVer-dev &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    if [ "$pyVer" = "python3" ] ; then \
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
RUN DEBIAN_FRONTEND='noninteractive' apt-get update && apt-get install -y --no-install-recommends \
  g++ \
  tk-dev \
  nano

# Install Tensorfow
#RUN pip install --upgrade pip
RUN pip install --upgrade six
RUN pip install --upgrade flask
RUN pip install --upgrade pandas==0.24.2
RUN pip install --upgrade numpy==1.16.4
RUN pip install --upgrade sklearn
#RUN pip --default-timeout=1000 install tensorflow-gpu==1.12
RUN pip install --upgrade keras==2.2.4


#######################################################################
# If to install JupyterLab
ARG jlab=true

# Install JupyterLab
ENV JUPYTER_CONFIG_DIR /srv/.jupyter/
ENV SHELL /bin/bash
RUN if [ "$jlab" = true ]; then \
       # by default has to work (1.2.0 wrongly required nodejs and npm)
       pip install --no-cache-dir jupyterlab ; \
       git clone https://github.com/deephdc/deep-jupyter /srv/.jupyter ; \
    else echo "[INFO] Skip JupyterLab installation!"; fi


# Set LANG environment
ENV LANG C.UTF-8

# Set the working directory
WORKDIR /srv

# Install rclone
RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    apt-get install -f && \
    mkdir /srv/.rclone/ && touch /srv/.rclone/rclone.conf && \
    rm rclone-current-linux-amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Install DEEPaaS from PyPi
# Install FLAAT (FLAsk support for handling Access Tokens)
RUN pip install --no-cache-dir \
        'deepaas==0.5.1' \
        flaat && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Disable FLAAT authentication by default
ENV DISABLE_AUTHENTICATION_AND_ASSUME_AUTHENTICATED_USER yes


# Install user app:
RUN git clone https://github.com/charlos1204/firsttest && \
    cd  firsttest && \
    pip install --no-cache-dir -e . && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    cd ..


# Open DEEPaaS port
EXPOSE 5000

# Open Monitoring port
EXPOSE 6006

# Open Jupyterlab port
EXPOSE 8888


CMD ["deepaas-run", "--openwhisk-detect", "--listen-ip", "0.0.0.0", "--listen-port", "5000"]


# Account for OpenWisk functionality (deepaas >=0.3.0)
#CMD ["sh", "-c", "deepaas-run --openwhisk-detect --listen-ip 0.0.0.0"]
