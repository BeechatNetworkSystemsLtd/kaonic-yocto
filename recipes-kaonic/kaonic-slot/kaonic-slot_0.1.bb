SUMMARY = "A/B slot bookkeeping for the running system"
DESCRIPTION = "Marks the booted slot good once the system is up, so U-Boot keeps booting it"

SECTION = "kaonic"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} += "u-boot-fw-utils u-boot-fw-config-stm32mp"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit systemd

SRC_URI = " \
    file://kaonic-slot-good \
    file://kaonic-slot-good.service \
"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-slot-good.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

FILES:${PN} += " \
    ${sbindir}/kaonic-slot-good \
    ${systemd_system_unitdir}/kaonic-slot-good.service \
"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/kaonic-slot-good ${D}${sbindir}/kaonic-slot-good

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kaonic-slot-good.service ${D}${systemd_system_unitdir}
}
