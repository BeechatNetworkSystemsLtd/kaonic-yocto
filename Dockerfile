FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    gawk \
    wget \
    git \
    git-lfs \
    diffstat \
    unzip \
    texinfo \
    gcc \
    g++ \
    build-essential \
    chrpath \
    socat \
    cpio \
    python3 \
    python3-pip \
    python3-pexpect \
    python3-git \
    python3-jinja2 \
    python3-subunit \
    python3-dev \
    xz-utils \
    debianutils \
    iputils-ping \
    libsdl1.2-dev \
    pylint3 \
    xterm \
    mesa-common-dev \
    libegl1-mesa \
    zstd \
    liblz4-tool \
    file \
    locales \
    curl \
    sudo \
    ca-certificates \
    clang \
    libclang-dev \
    llvm-dev \
    pkg-config \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd builduser -g 1000 \
    && useradd -ms /bin/bash builduser -u 1028 -g 1000 \
    && usermod -aG sudo builduser \
    && echo "builduser:builduser" | chpasswd \
    && echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER builduser
WORKDIR /home/builduser

RUN git config --global user.email "yocto-build@beechat.network" && \
    git config --global user.name "Yocto Build" && \
    mkdir -p /home/builduser/yocto /home/builduser/bin && \
    cd /home/builduser/yocto && \
    curl -L https://storage.googleapis.com/git-repo-downloads/repo > /home/builduser/bin/repo && \
    chmod +x /home/builduser/bin/repo && \
    /home/builduser/bin/repo init \
        -u https://github.com/STMicroelectronics/oe-manifest.git \
        -b refs/tags/openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06 && \
    /home/builduser/bin/repo sync -c --no-clone-bundle --no-tags -j4 && \
    cd /home/builduser/yocto/layers && \
    git clone https://github.com/rust-embedded/meta-rust-bin.git

WORKDIR /home/builduser/yocto
