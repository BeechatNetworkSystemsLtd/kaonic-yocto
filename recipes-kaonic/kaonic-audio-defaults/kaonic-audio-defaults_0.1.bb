SUMMARY = "Install default ALSA state template for the Kaonic audio card"

SECTION = "kaonic"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=f978e2caad0e533cf3b63ddb6d8dec6f"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

PR = "r0"

COMPATIBLE_MACHINE = "stm32mp1-kaonic-protoc"

SRC_URI = " \
    file://asound.state \
    file://LICENSE \
"

FILES:${PN} += " \
    ${sysconfdir}/alsa/kaonic-asound.state \
"

S = "${WORKDIR}"

do_install:append() {
    install -d ${D}${sysconfdir}/alsa
    install -m 0644 ${WORKDIR}/asound.state ${D}${sysconfdir}/alsa/kaonic-asound.state
}
