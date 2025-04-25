DESCRIPTION = "Kaonic Init" 

SECTION = "kaonic"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=f978e2caad0e533cf3b63ddb6d8dec6f"

DEPENDS:append = " python3"
RDEPENDS:${PN} += "systemd"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit systemd

PR = "r0" 

SRC_URI = " \
    file://kaonic-init.py \
    file://kaonic-init.service \
    file://LICENSE \
"

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-init.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    ${systemd_system_unitdir}/kaonic-init.service \
    ${bindir}/kaonic-init.py \
"

S = "${WORKDIR}"

do_install:append() {
    # Kaonic init scripts
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/kaonic-init.py ${D}${bindir}/kaonic-init.py

    # Kaonic systemd service
    install -d ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/kaonic-init.service ${D}${systemd_system_unitdir}
}

