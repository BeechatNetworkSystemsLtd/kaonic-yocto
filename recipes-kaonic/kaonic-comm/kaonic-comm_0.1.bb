SUMMARY = "Kaonic Communications Daemon"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=d32239bcb673463ab874e80d47fae504"

inherit cargo_bin systemd pkgconfig

SRC_URI = "git://github.com/BeechatNetworkSystemsLtd/kaonic_communication.git;protocol=https;branch=main"
SRC_URI += "file://kaonic-commd.service"
SRC_URI += "file://kaonic-factory.service"
SRC_URI += "file://kaonic-wifi-mode.service"
SRC_URI += "file://wifi_station.sh"
SRC_URI += "file://wifi_mode.sh"
SRCREV = "672e5bf03d318c1bb6771552a11859542a0821e9"
S = "${WORKDIR}/git"

DEPENDS += "protobuf-native openssl zeromq"
RDEPENDS:${PN} += "dnsmasq hostapd systemd wpa-supplicant"

CARGO_BUILD_FLAGS += "--bin kaonic-commd --bin kaonic-factory"

CARGO_FEATURES = ""

SYSTEMD_SERVICE:${PN} = "kaonic-commd.service kaonic-factory.service kaonic-wifi-mode.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

FILES:${PN} += "${systemd_system_unitdir} ${sysconfdir}/kaonic/plugins/kaonic-factory/current ${sysconfdir}/kaonic/plugins/kaonic-commd/current ${sysconfdir}/kaonic/kaonic_machine ${sysconfdir}/kaonic/wifi-mode"
CONFFILES:${PN} += "${sysconfdir}/kaonic/wifi-mode"

# Install the compiled binary
# for inspo, try: bitbake-getvar -r kaonic-comm WORKDIR B RUST_TARGET CARGO_BUILD_PROFILE
# after `bitbake kaonic-comm`
do_install() {
    install -d ${D}${bindir}
    install -d ${D}${sysconfdir}/kaonic

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kaonic-commd.service ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kaonic-factory.service ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kaonic-wifi-mode.service ${D}${systemd_system_unitdir}

    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-commd ${D}${bindir}/kaonic-commd
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-factory ${D}${bindir}/kaonic-factory

    install -m 0755 ${WORKDIR}/wifi_station.sh ${D}${bindir}/kaonic-wifi-station
    install -m 0755 ${WORKDIR}/wifi_mode.sh ${D}${bindir}/kaonic-wifi-mode
    printf 'ap\n' > ${D}${sysconfdir}/kaonic/wifi-mode

    echo "${MACHINE}" > ${D}${sysconfdir}/kaonic/kaonic_machine

    sha256sum ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-commd | cut -d ' ' -f 1 > ${D}${bindir}/kaonic-commd.sha256
    sha256sum ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-factory | cut -d ' ' -f 1 > ${D}${bindir}/kaonic-factory.sha256

    install -d ${D}${sysconfdir}/kaonic/plugins/kaonic-factory/current
    ln -sf ${bindir}/kaonic-factory ${D}${sysconfdir}/kaonic/plugins/kaonic-factory/current/kaonic-factory
    ln -sf ${bindir}/kaonic-factory.sha256 ${D}${sysconfdir}/kaonic/plugins/kaonic-factory/current/sha256

    install -d ${D}${sysconfdir}/kaonic/plugins/kaonic-commd/current
    ln -sf ${bindir}/kaonic-commd ${D}${sysconfdir}/kaonic/plugins/kaonic-commd/current/kaonic-commd
    ln -sf ${bindir}/kaonic-commd.sha256 ${D}${sysconfdir}/kaonic/plugins/kaonic-commd/current/sha256
}
