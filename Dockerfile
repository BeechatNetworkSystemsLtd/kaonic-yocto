FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
            build-essential make ninja-build gcc \
            curl wget \
            git git-lfs \
            openssh-client \
            gawk \
            diffstat \
            unzip \
            texinfo \
            chrpath \
            socat \
            cpio \
            xz-utils \
            debianutils \
            iputils-ping \
            python3 python3-pip python3-pexpect \
            python3-git python3-jinja2 python3-subunit pylint \
            xterm \
            zstd \
            liblz4-tool \
            file \
            locales \
            libacl1 \
            neovim vim \
            sudo \
            gdisk \
            rsync \
            bc \
            bsdmainutils \
            libegl1-mesa libgmp-dev libmpc-dev libsdl1.2-dev libssl-dev \
            && rm -rf /var/lib/apt/lists/* \
            && mkdir -p /opt/ \
            && dpkg-reconfigure locales \
            && locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
            && apt-get clean && rm -rf /var/lib/apt/lists/* \
            && rm /bin/sh && ln -s /bin/bash /bin/sh

ENV LANG=en_US.utf8

# Create user and group
RUN groupadd builduser -g 1000 \
    && useradd -ms /bin/bash -p builduser builduser -u 1028 -g 1000 \
    && usermod -aG sudo builduser && echo "builduser:builduser" | chpasswd \
    && echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER builduser

ENV DISTRO=openstlinux-weston
# ENV MACHINE=stm32mp1

RUN git config --global user.email "yocto-build@beechat.network" && git config --global user.name "Yocto Build" \
    && mkdir /home/builduser/yocto && mkdir /home/builduser/bin && cd /home/builduser/yocto \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > /home/builduser/bin/repo \
    && chmod +x /home/builduser/bin/repo \
    && /home/builduser/bin/repo init -u https://github.com/STMicroelectronics/oe-manifest.git -b refs/tags/openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06 \
    && /home/builduser/bin/repo sync

CMD ["/bin/bash"]

