# <img src="./.github/assets/kaonic-logo.png" height="20pt"/> Kaonic Image

## Overview

A Yocto layer (`meta-kaonic`) building the OpenSTLinux image for Kaonic boards,
on top of ST's `meta-st` BSP.

## Boards

| Machine | Storage | Programmed by |
| --- | --- | --- |
| `stm32mp1-kaonic1s-r24` | SD card | USB, or writing the raw image to a card |
| `stm32mp1-kaonic1s-r30` | eMMC | USB |

Both boot from the SoC's ROM over USB when the `BOOT SEL` switches are strapped
that way, which is how an image is written in either case. The two revisions do
not use the same strap positions, and they throw different switches — see the
pictogram in `kaonic-flash`, which is generated per machine for that reason.

## Build instructions

* Change directory to the root of this repository
* Build docker image
    * `docker buildx build --platform=linux/arm64 . -t kaonic-yocto` - for aarch64
    * `docker buildx build --platform=linux/amd64 . -t kaonic-yocto` - for x86_64
* Run docker container
    * `docker run -it -v ./:/home/kanoic-builder/yocto/layers/meta-st/meta-kaonic --name kaonic-yocto kaonic-yocto`
* Build an image
    * `cd ~/yocto/`
    * `./layers/meta-st/meta-kaonic/scripts/build-image.sh --machine stm32mp1-kaonic1s-r24`
    * `./layers/meta-st/meta-kaonic/scripts/build-image.sh --machine stm32mp1-kaonic1s-r30`

### Options

| Option | Effect |
| --- | --- |
| `--machine <name>` | Board to build. Required. |
| `--build-dir <dir>` | Build directory. Default `build-<machine>-image` under `~/yocto`. |
| `--rust` | Update Rust crates for the Kaonic packages and rebuild them. |
| `--dts` | Clean and rebuild TF-A, OP-TEE, U-Boot and the kernel. Needed after a device tree change — a plain rebuild does not always pick one up. |
| `--clean` | Clean the image before building. |
| `--clean-package <pkg>` | `cleansstate` one recipe. Rarely needed: editing a recipe already changes its task signature. Cleaning a recipe with a large dependency chain, `systemd` in particular, forces a long rebuild of native tooling. |
| `--gz` | Also gzip the raw SD card image. |
| `--env` | Initialise the Yocto/BitBake environment only. |

## Artifacts

Everything lands in `deploy/`, named `image-<machine>-v<version>-<kind>.tar.gz`.
The medium is in the name because it decides what an operator does with the file.

| Kind | Board | What it is |
| --- | --- | --- |
| `emmc` | r30 | Flashlayout and binaries, written over USB |
| `sdcard-usb` | r24 | Flashlayout and binaries, written to the card over USB |
| `sdcard-raw` | r24 | The raw SD card image, for a card reader |

Each bundle carries a `manifest.toml` describing the machine, SoC, version and
payload, which is what lets a flashing tool check a bundle against the board in
front of it before touching anything.

## Flashing

Over USB, with [`kaonic-flash`](https://github.com/beechat-network/kaonic-flash):

```sh
kaonic-flash flash deploy/<machine>-usb/FlashLayout_*.tsv --wipe
```

Or hand the `.tar.gz` to the GUI. Strap `BOOT SEL` to USB boot and power-cycle
first — the boot source is only sampled at power-on, so a reset is not enough.
Strap it back afterwards, and power-cycle again.

To write an SD card directly instead, unpack the `sdcard-raw` bundle and write
the `.raw` inside it with Etcher or `dd`.

## Network

The board runs as a WiFi access point by default, switchable to station mode
with `wifi_mode.sh ap | sta <ssid> <passphrase>`. In AP mode `hostapd` puts
`wlan0` into the `br0` bridge, which also carries the USB gadget interface, and
`systemd-networkd` serves DHCP on `192.168.10.1/24`. Bridge membership belongs
to `hostapd` rather than a `.network` file: it sets the interface type first,
and that type change drops a membership `networkd` had already established.

## More information

STM32MP Wiki
* [Distribution Package](https://wiki.st.com/stm32mpu/wiki/STM32MPU_Distribution_Package)
* [WLAN and Bluetooth](https://wiki.st.com/stm32mpu/wiki/WLAN_and_Bluetooth_hardware_component)
* [WLAN Device Tree](https://wiki.st.com/stm32mpu/wiki/WLAN_device_tree_configuration#cite_note-3)
* [SDMMC Device Tree](https://wiki.st.com/stm32mpu/wiki/SDMMC_device_tree_configuration)
