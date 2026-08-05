FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# SRC_URI += "file://0001-adjust-uart-console-and-gpioz-for-kaonic.patch"
SRC_URI += "file://0001-feat-change-uart-to-6.patch"

OPTEE_NO_CRYPTO_FLAGS = " \
    CFG_STM32_CRYP=n \
    CFG_STM32_PKA=n \
    CFG_STM32_SAES=n \
    CFG_STM32_RNG=n \
    CFG_HWRNG_PTA=n \
    CFG_WITH_SOFTWARE_PRNG=y \
"

EXTRA_OEMAKE:append:stm32mp1-kaonic1s-r30 = "${OPTEE_NO_CRYPTO_FLAGS}"
EXTRA_OEMAKE:append:stm32mp1-kaonic1s-r24 = "${OPTEE_NO_CRYPTO_FLAGS}"

