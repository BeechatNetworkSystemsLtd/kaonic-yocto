SUMMARY = "Kaonic Core Image for ST"
LICENSE = "Open"

include recipes-st/images/st-image.inc

inherit core-image

IMAGE_LINGUAS = "en-us"

IMAGE_FEATURES += "\
    package-management  \
    ssh-server-dropbear \
    "

IMAGE_INSTALL:append = " hostapd iw dnsmasq spidev-test"
IMAGE_INSTALL:append = " kaonic-comm"
IMAGE_INSTALL:append = " grpc protobuf"

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
