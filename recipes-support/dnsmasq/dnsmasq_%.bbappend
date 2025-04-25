
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " file://hostapd-dns.conf"

do_install:append() {
    install -d ${D}${sysconfdir}/dnsmasq.d
    install -m 0644 ${WORKDIR}/hostapd-dns.conf ${D}${sysconfdir}/dnsmasq.d/hostapd-dns.conf
}

FILES_${PN} += "${sysconfdir}/dnsmasq.d/hostapd-dns.conf"

