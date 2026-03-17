SUMMARY = "Kaonic Core Image for ST"
LICENSE = "Open"

include recipes-st/images/st-image.inc

inherit core-image

IMAGE_LINGUAS = "en-us"

IMAGE_FEATURES += "\
    package-management  \
    ssh-server-dropbear \
    "

# Networking
IMAGE_INSTALL:append = " hostapd iw dnsmasq rsync"
IMAGE_INSTALL:append = " grpc protobuf"

# Audio
IMAGE_INSTALL:append = " \
    alsa-lib \
    alsa-utils \
    alsa-state \
    alsa-plugins \
"

# Testing, Development and Runtime
IMAGE_INSTALL:append = " spidev-test devmem2 evtest"
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
IMAGE_INSTALL:append = " kaonic-init kaonic-comm kaonic-factory"

IMAGE_INSTALL:remove = "st-hostname"

TOOLCHAIN_HOST_TASK += "\
    nativesdk-grpc \
    nativesdk-grpc-dev \
    python3-cryptography \
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
    tcpdump \
    "
