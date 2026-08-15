FROM ubuntu:24.04

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
            gperf \
            bc \
            bsdmainutils \
            libgmp-dev libmpc-dev libsdl1.2-dev libssl-dev \
            libclang-dev \
            gcc-arm-linux-gnueabihf \
            && rm -rf /var/lib/apt/lists/* \
            && mkdir -p /opt/ \
            && dpkg-reconfigure locales \
            && locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
            && apt-get clean && rm -rf /var/lib/apt/lists/* \
            && rm /bin/sh && ln -s /bin/bash /bin/sh

ENV LANG=en_US.utf8

# Create user and group
RUN groupadd kanoic-builder -f -g 1000 \
    && useradd -ms /bin/bash -p kanoic-builder kanoic-builder -u 1028 -g 1000 \
    && usermod -aG sudo kanoic-builder && echo "kanoic-builder:kanoic-builder" | chpasswd \
    && echo "kanoic-builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER kanoic-builder

ENV DISTRO=openstlinux-weston

RUN git config --global user.email "yocto-build@beechat.network" && git config --global user.name "Yocto Build" \
    && mkdir /home/kanoic-builder/yocto && mkdir /home/kanoic-builder/bin && cd /home/kanoic-builder/yocto \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > /home/kanoic-builder/bin/repo \
    && chmod +x /home/kanoic-builder/bin/repo \
    && /home/kanoic-builder/bin/repo init -u https://github.com/STMicroelectronics/oe-manifest.git -b refs/tags/openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10 \
    && /home/kanoic-builder/bin/repo sync \
    && cd /home/kanoic-builder/yocto/layers/meta-st/ && git clone https://github.com/rust-embedded/meta-rust-bin.git \
    && ln -s /home/kanoic-builder/yocto/layers/meta-st/meta-kaonic/scripts/build-image.sh /home/kanoic-builder/yocto/build_image.sh

WORKDIR /home/kanoic-builder/yocto

CMD ["/bin/bash"]
