# <img src="./.github/assets/kaonic-logo.png" height="20pt"/> Kaonic Image


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
    * `./layers/meta-st/meta-kaonic/scripts/build-image.sh --machine stm32mp1-kaonic-protoa`
    * `./layers/meta-st/meta-kaonic/scripts/build-image.sh --machine stm32mp1-kaonic-protob`
    * `./layers/meta-st/meta-kaonic/scripts/build-image.sh --machine stm32mp1-kaonic-protoc`

## More information

STM32MP Wiki
* [Distribution Package](https://wiki.st.com/stm32mpu/wiki/STM32MPU_Distribution_Package)
* [WLAN and Bluetooth](https://wiki.st.com/stm32mpu/wiki/WLAN_and_Bluetooth_hardware_component)
* [WLAN Device Tree](https://wiki.st.com/stm32mpu/wiki/WLAN_device_tree_configuration#cite_note-3)
* [SDMMC Device Tree](https://wiki.st.com/stm32mpu/wiki/SDMMC_device_tree_configuration)
