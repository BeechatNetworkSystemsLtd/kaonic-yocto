SUMMARY = "Kaonic Core Image for ST"
LICENSE = "Open"

include recipes-st/images/st-image.inc

inherit core-image

ROOTFS_POSTPROCESS_COMMAND += "kaonic_install_alsa_state; kaonic_write_image_version; "

# The image version from VERSION at the layer root; the recipe is parsed again when it changes.
def kaonic_image_version(d):
    import os
    path = os.path.normpath(os.path.join(d.getVar('FILE_DIRNAME'), '..', '..', 'VERSION'))
    bb.parse.mark_dependency(d, path)
    with open(path) as file:
        return file.read().strip()

KAONIC_IMAGE_VERSION := "${@kaonic_image_version(d)}"

IMAGE_LINGUAS = "en-us"

IMAGE_FEATURES += "\
    package-management  \
    ssh-server-dropbear \
    "

# Networking
IMAGE_INSTALL:append = " hostapd iw dnsmasq rsync iproute2 iptables iputils procps net-tools"
IMAGE_INSTALL:append = " avahi-daemon"
IMAGE_INSTALL:append = " grpc protobuf"

# Audio
IMAGE_INSTALL:append = " \
    alsa-lib \
    alsa-utils \
    alsa-state \
    alsa-plugins \
"
# Push-to-talk loads libopus at run time.
IMAGE_INSTALL:append = " libopus"

# Testing, Development and Runtime
IMAGE_INSTALL:append = " spidev-test devmem2 evtest sqlite3"
IMAGE_INSTALL:append = " python3 python3-pip"
IMAGE_INSTALL:append = " \
    x264 \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-python \
    gstreamer1.0-rtsp-server \
"

# Kaonic Applications
IMAGE_INSTALL:append = " kaonic-init kaonic-comm kaonic-hub kaonic-hub-installer"
IMAGE_INSTALL:append = " kaonic-rf215"
IMAGE_INSTALL:append = " kaonic-slot"
IMAGE_INSTALL:append = " kaonic-user"
IMAGE_INSTALL:append:stm32mp1-kaonic1s-r24 = " kaonic-audio-defaults"
IMAGE_INSTALL:append:stm32mp1-kaonic1s-r30 = " kaonic-audio-defaults"
IMAGE_INSTALL:append:stm32mp1-kaonic1x-r09 = " kaonic-audio-defaults"

IMAGE_INSTALL:remove = "st-hostname"

TOOLCHAIN_HOST_TASK += "\
    nativesdk-grpc \
    nativesdk-grpc-dev \
    nativesdk-python3-cryptography \
"

TOOLCHAIN_TARGET_TASK += "protobuf-staticdev"

#
# INSTALL addons
#
CORE_IMAGE_EXTRA_INSTALL += " \
    resize-helper \
    st-hostname \
    \
    packagegroup-framework-core-base    \
    packagegroup-framework-tools-base   \
    \
    ${@bb.utils.contains('COMBINED_FEATURES', 'optee', 'packagegroup-optee-core', '', d)}   \
    ${@bb.utils.contains('COMBINED_FEATURES', 'optee', 'packagegroup-optee-test', '', d)}   \
    kernel-modules \
    tcpdump \
    "

# ST's userfs image is too small for resize2fs to grow on first boot: rebuild it
# at a size it can grow from.
KAONIC_USERFS_IMAGE_SIZE ?= "32M"

IMAGE_CMD:stsplitpartitions:append () {
    for img in ${IMGDEPLOYDIR}/*.splitted-userfs*.ext4; do
        [ -f "${img}" ] && [ ! -L "${img}" ] || continue
        bbnote "rebuilding $(basename ${img}) at ${KAONIC_USERFS_IMAGE_SIZE}"
        rm -f "${img}"
        mkfs.ext4 -F -q -L userfs -d ${IMAGE_ROOTFS}/usr/local "${img}" ${KAONIC_USERFS_IMAGE_SIZE}
    done
}

kaonic_install_alsa_state() {
    if [ -f ${IMAGE_ROOTFS}${sysconfdir}/alsa/kaonic-asound.state ]; then
        install -d ${IMAGE_ROOTFS}${localstatedir}/lib/alsa
        install -m 0644 ${IMAGE_ROOTFS}${sysconfdir}/alsa/kaonic-asound.state \
            ${IMAGE_ROOTFS}${localstatedir}/lib/alsa/asound.state
    fi
}

kaonic_write_image_version() {
    install -d ${IMAGE_ROOTFS}${sysconfdir}/kaonic
    echo "${KAONIC_IMAGE_VERSION}" > ${IMAGE_ROOTFS}${sysconfdir}/kaonic/image.version
}
