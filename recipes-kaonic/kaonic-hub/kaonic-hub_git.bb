SUMMARY = "Kaonic hub: web UI, API, Wi-Fi, mesh, VPN, push-to-talk and plugins"
DESCRIPTION = "kaonic-hub with its web UI built in, and kaonic-hub-installer, which \
installs, runs and updates plugins and the hub. Both come from the kaonic-hub workspace."

SECTION = "kaonic"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=256737f5f795479e8ae7c476f5b9aeb0"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# SRCREV picks everything: the web UI is the hub's submodule, and reticulum-rs and
# kaonic-radio's crates are pinned by its Cargo.lock.
SRC_URI = " \
    gitsm://github.com/BeechatNetworkSystemsLtd/kaonic-hub.git;protocol=https;branch=main \
    file://kaonic-hub.service \
    file://kaonic-hub-installer.service \
"
SRCREV = "3c74d2d5460b38c15536440a87ea1408a8c7f29c"

PV = "0.3.2+git"

S = "${WORKDIR}/git"
WEBUI = "${S}/resources/kaonic-webui"

inherit cargo_bin systemd

# npm builds the web UI (meta-oe's Node; the UI builds with Node 20).
DEPENDS += "nodejs-native"

# cargo fetches the crates (reticulum-rs and kaonic-radio's from GitHub) and npm the UI's.
do_compile[network] = "1"

EXTRA_CARGO_FLAGS = "--locked -p kaonic-hub -p kaonic-hub-installer"
export KAONIC_WEBUI_REQUIRED = "1"

do_compile:prepend() {
    (
        cd ${WEBUI}
        export npm_config_cache=${WORKDIR}/npm-cache
        npm ci --no-audit --no-fund
        npm run build
    )
}

PACKAGES =+ "kaonic-hub-installer"

SYSTEMD_PACKAGES = "${PN} kaonic-hub-installer"
SYSTEMD_SERVICE:${PN} = "kaonic-hub.service"
SYSTEMD_SERVICE:kaonic-hub-installer = "kaonic-hub-installer.service"
SYSTEMD_AUTO_ENABLE = "enable"

# What the hub runs: systemctl, ip, iw, iptables (nft when present), hostapd, wpa_supplicant,
# dnsmasq; fw_setenv/fw_printenv, mkfs.ext4 and blkid for kernel updates and the A/B boot
# switch. libopus and ALSA are opened at run time for push-to-talk. Plugins and updates go
# through kaonic-hub-installer.
RDEPENDS:${PN} += " \
    kaonic-hub-installer \
    systemd \
    iproute2 \
    iw \
    iptables \
    hostapd \
    wpa-supplicant \
    dnsmasq \
    u-boot-fw-utils \
    e2fsprogs-mke2fs \
    util-linux-blkid \
    alsa-lib \
    libopus \
"
# It writes plugin units and starts them with systemctl; plugins run as numeric users, so no
# useradd is needed. Runs as root and answers only kaonic-hub, over a root-only Unix socket.
RDEPENDS:kaonic-hub-installer += "systemd"

FILES:${PN} = " \
    ${bindir}/kaonic-hub \
    ${systemd_system_unitdir}/kaonic-hub.service \
    ${sysconfdir}/kaonic/kaonic-hub.version \
"
FILES:kaonic-hub-installer = " \
    ${bindir}/kaonic-hub-installer \
    ${systemd_system_unitdir}/kaonic-hub-installer.service \
    ${sysconfdir}/kaonic/kaonic-hub-installer.version \
"

do_install() {
    install -d ${D}${bindir} ${D}${systemd_system_unitdir} ${D}${sysconfdir}/kaonic
    for id in kaonic-hub kaonic-hub-installer; do
        install -m 0755 ${CARGO_BINDIR}/$id ${D}${bindir}/$id
        install -m 0644 ${WORKDIR}/$id.service ${D}${systemd_system_unitdir}/$id.service
    done

    # The image's versions, read by the hub's software page (`<id>-version=`), and what they
    # were built from.
    version() { sed -n 's/^version *= *"\(.*\)"/\1/p' ${S}/$1/Cargo.toml | head -n 1; }
    # The commit Cargo.lock pins a GitHub repository at.
    locked() { sed -n "s/^source = \"git+https:\/\/github.com\/BeechatNetworkSystemsLtd\/$1.git.*#\(.\{12\}\).*\"/\1/p" ${S}/Cargo.lock | head -n 1; }
    hub=$(echo ${SRCREV} | cut -c1-12)
    {
        echo "kaonic-hub-version=$(version kaonic-hub)"
        echo "kaonic-hub-rev=$hub"
        echo "kaonic-webui-rev=$(git -C ${WEBUI} rev-parse --short=12 HEAD)"
        echo "kaonic-radio-rev=$(locked kaonic-radio)"
        echo "reticulum-rs-rev=$(locked Reticulum-rs)"
    } > ${D}${sysconfdir}/kaonic/kaonic-hub.version
    {
        echo "kaonic-hub-installer-version=$(version kaonic-hub-installer)"
        echo "kaonic-hub-rev=$hub"
    } > ${D}${sysconfdir}/kaonic/kaonic-hub-installer.version
    chmod 0644 ${D}${sysconfdir}/kaonic/*.version
}
