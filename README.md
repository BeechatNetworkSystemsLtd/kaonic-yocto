# Kaonic Image

## Overview

## Build instructions

* Change directory to the root of this repository
* Build docker image
    * `docker buildx build --platform=linux/arm64 . -t kaonic-yocto` - for aarch64
    * `docker buildx build --platform=linux/amd64 . -t kaonic-yocto` - for x86_64
* Run docker container
    * `docker run -it -v ./:/home/builduser/yocto/layers/meta-st/meta-kaonic --name kaonic-yocto kaonic-yocto`
* Initialize build environment
    * `cd ~/yocto/`
    * `source ./layers/meta-st/scripts/envsetup.sh`
    * `bitbake st-image-core`

## More information

https://wiki.st.com/stm32mpu/wiki/STM32MPU_Distribution_Package
