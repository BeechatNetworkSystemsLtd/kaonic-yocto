FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Fetch the ST-patched kernel tree from ST's GitHub mirror instead of the
# kernel.org tarball. The GitHub revision already includes ST's stm32mp patch.
SRC_URI:remove = "https://cdn.kernel.org/pub/linux/kernel/v6.x/${LINUX_TARNAME};name=kernel"
SRC_URI:remove = "file://${LINUX_VERSION}/${LINUX_VERSION}${LINUX_SUBVERSION}/0001-v${LINUX_VERSION}-stm32mp-${LINUX_RELEASE}.patch"
SRC_URI:prepend = "git://github.com/STMicroelectronics/linux.git;protocol=https;branch=${ARCHIVER_ST_BRANCH} "
SRCREV = "548f960c059bc4b9165cb69895fd67551f6061ca"
S = "${WORKDIR}/git"

# SRC_URI:append = " file://0001-fix-cpufreq-crash-for-kaonic.patch"
SRC_URI:append = " file://${LINUX_VERSION}/fragment-kaonic.config;subdir=fragments"

KERNEL_CONFIG_FRAGMENTS:append = " \
    ${WORKDIR}/fragments/${LINUX_VERSION}/fragment-kaonic.config \
"
SRC_URI:class-devupstream += "file://${LINUX_VERSION}/fragment-kaonic.config;subdir=fragments/features"
