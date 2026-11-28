DESCRIPTION = "Kaonic Radio Package" 

SECTION = "kaonic"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=f978e2caad0e533cf3b63ddb6d8dec6f"

DEPENDS:append = " libgpiod protobuf protobuf-native grpc grpc-native"
RDEPENDS:${PN} += "systemd"

DEPENDS += "cargo-bin-cross-${TARGET_ARCH}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

INSANE_SKIP:${PN} += "already-stripped"

inherit cargo_bin systemd pkgconfig

PV = "0.2.5+git"
PR = "r5"
SRC_URI = "gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-radio.git;protocol=https;branch=main;"
SRCREV = "5f268fcb5beab4b3481081e7b66364b42de829a2"

do_compile[network] = "1"

# The radios are owned by the kaonic_rf215 driver on every machine in this
# layer (see the radio nodes in the kernel device trees), so commd is built
# against its network interfaces: the -ks machine feature. kaonic-factory
# still drives the chips itself and so needs the default -us feature; the two
# cannot share one cargo invocation, so commd is rebuilt on its own after the
# workspace build.
RDEPENDS:${PN} += "kaonic-rf215"

# commd and the factory server are core programs the hub updates: their units start them
# through the installer, which runs an update when there is a good one (run-core).
RDEPENDS:${PN} += "kaonic-hub-installer"

do_compile:append() {
    bbnote cargo build ${CARGO_BUILD_FLAGS} -p kaonic-commd --no-default-features --features machine-kaonic1s-ks
    cargo build ${CARGO_BUILD_FLAGS} -p kaonic-commd --no-default-features --features machine-kaonic1s-ks
}

# Systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "kaonic-commd.service kaonic-factory.service"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Files
FILES:${PN} += " \
    ${bindir}/kaonic-commd \
    ${bindir}/kaonic-factory \
    ${systemd_system_unitdir}/kaonic-commd.service \
    ${systemd_system_unitdir}/kaonic-factory.service \
    ${sysconfdir}/kaonic/kaonic_machine \
    ${sysconfdir}/kaonic/kaonic-commd.version \
    ${sysconfdir}/kaonic/kaonic-factory.version \
    ${datadir}/kaonic-core \
"

S = "${WORKDIR}/git"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-commd ${D}${bindir}/kaonic-commd
    install -m 0755 ${B}/${RUST_TARGET}/${CARGO_BUILD_PROFILE}/kaonic-factory ${D}${bindir}/kaonic-factory

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/kaonic-commd/kaonic-commd.service ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/kaonic-factory/kaonic-factory.service ${D}${systemd_system_unitdir}

    # Which board this is: commd picks the radio wiring and filters by it.
    install -d ${D}${sysconfdir}/kaonic
    echo ${MACHINE} > ${D}${sysconfdir}/kaonic/kaonic_machine

    # Start each through the installer (it picks an update the hub installed, if good), and
    # say which version the image's copy is.
    for id in kaonic-commd kaonic-factory; do
        version=$(sed -n 's/^version *= *"\(.*\)"/\1/p' ${S}/$id/Cargo.toml | head -n 1)
        [ -n "$version" ] || bbfatal "no version in $id/Cargo.toml"
        sed -i "s|^ExecStart=${bindir}/$id\b|ExecStart=${bindir}/kaonic-hub-installer run-core $id ${bindir}/$id $version|" ${D}${systemd_system_unitdir}/$id.service
        grep -q "run-core $id" ${D}${systemd_system_unitdir}/$id.service || bbfatal "$id.service: ExecStart not rewritten"
        # Logged under its own name, not the launcher's.
        sed -i "/^\[Service\]/a SyslogIdentifier=$id" ${D}${systemd_system_unitdir}/$id.service
        echo "$id-version=$version" > ${D}${sysconfdir}/kaonic/$id.version

        # Its manifest and icon, laid out as in its package: the hub shows its name and icon from here.
        install -d ${D}${datadir}/kaonic-core/$id/files
        sed "s/{version}/$version/" ${S}/$id/kaonic-plugin.toml > ${D}${datadir}/kaonic-core/$id/kaonic-plugin.toml
        install -m 0644 ${S}/$id/files/icon.png ${D}${datadir}/kaonic-core/$id/files/icon.png
    done
}
