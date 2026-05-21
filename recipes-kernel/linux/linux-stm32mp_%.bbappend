FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# SRC_URI:append = " file://0001-fix-cpufreq-crash-for-kaonic.patch"
SRC_URI:append = " file://${LINUX_VERSION}/fragment-kaonic.config;subdir=fragments"

KERNEL_CONFIG_FRAGMENTS:append = " \
    ${WORKDIR}/fragments/${LINUX_VERSION}/fragment-kaonic.config \
"
SRC_URI:class-devupstream += "file://${LINUX_VERSION}/fragment-kaonic.config;subdir=fragments/features"
