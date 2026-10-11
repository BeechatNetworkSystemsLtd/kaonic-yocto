FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Fetch the ST-patched kernel tree from ST's GitHub mirror instead of the
# kernel.org tarball. The GitHub revision already includes ST's stm32mp patch.
SRC_URI:remove = "https://cdn.kernel.org/pub/linux/kernel/v6.x/${LINUX_TARNAME};name=kernel"
SRC_URI:remove = "file://${LINUX_VERSION}/${LINUX_VERSION}${LINUX_SUBVERSION}/0001-v${LINUX_VERSION}-stm32mp-${LINUX_RELEASE}.patch"
SRC_URI:prepend = "git://github.com/STMicroelectronics/linux.git;protocol=https;branch=${ARCHIVER_ST_BRANCH} "
SRCREV = "548f960c059bc4b9165cb69895fd67551f6061ca"
S = "${WORKDIR}/git"

# SRC_URI:append = " file://0001-fix-cpufreq-crash-for-kaonic.patch"

# The SPI driver logs two deprecation warnings per transfer once a transfer
# carries a word delay, which the RF215 needs above 8 MHz (tSPI_5). At radio
# rates that is thousands of messages a second.
SRC_URI:append = " file://0002-spi-stm32-warn-once-about-deprecated-midi.patch"
# SPI6 is clocked through SCMI, so Linux cannot hold the PLL output OP-TEE
# feeds it from; without this the unused-clock pass gates pll4_q and the
# controller hangs on first access. Keeping it on is what lets SPI6 run at
# 25 MHz instead of the 16 MHz HSI allows.
SRC_URI:append = " file://0003-clk-stm32mp1-keep-pll3_q-pll4_q-running.patch"
SRC_URI:append = " file://${LINUX_VERSION}/fragment-kaonic.config;subdir=fragments"

KERNEL_CONFIG_FRAGMENTS:append = " \
    ${WORKDIR}/fragments/${LINUX_VERSION}/fragment-kaonic.config \
"
SRC_URI:class-devupstream += "file://${LINUX_VERSION}/fragment-kaonic.config;subdir=fragments/features"
