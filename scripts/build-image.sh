#!/bin/bash

echo "Init build environment"

SCRIPT_SOURCED=false
(return 0 2>/dev/null) && SCRIPT_SOURCED=true
SCRIPT_NAME="${BASH_SOURCE[0]:-$0}"

MACHINE=""
REQUESTED_BUILD_DIR=""
UPDATE_RUST=false
UPDATE_DTS=false
CLEAN_IMAGE=false
CLEAN_PACKAGES=""
COMPRESS_IMAGE=false
ENV_ONLY=false

#*****************************************************************************#

while [[ $# -gt 0 ]]; do
    case "$1" in
        --machine)
            if [[ -z "${2:-}" || "$2" == --* ]]; then
                echo "Error: --machine requires a value."
                if [ "$SCRIPT_SOURCED" = true ]; then
                    return 1
                fi
                exit 1
            fi
            MACHINE="$2"
            shift 2
            ;;
        --build-dir)
            if [[ -z "${2:-}" || "$2" == --* ]]; then
                echo "Error: --build-dir requires a value."
                if [ "$SCRIPT_SOURCED" = true ]; then
                    return 1
                fi
                exit 1
            fi
            REQUESTED_BUILD_DIR="${2%/}"
            shift 2
            ;;
        --rust)
            UPDATE_RUST=true
            shift
            ;;
        --dts)
            UPDATE_DTS=true
            shift
            ;;
        --clean)
            CLEAN_IMAGE=true
            shift
            ;;
        --clean-package)
            CLEAN_PACKAGES="${CLEAN_PACKAGES} $2"
            shift 2
            ;;
        --gz)
            COMPRESS_IMAGE=true
            shift
            ;;
        --env)
            ENV_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $SCRIPT_NAME --machine <name> [OPTIONS]"
            echo ""
            echo "Artifacts, under deploy/, named image-<machine>-v<version>-<kind>.tar.gz:"
            echo "  eMMC boards     -emmc         programmed over USB"
            echo "  sdcard boards   -sdcard-raw   image for a card reader"
            echo "                  -sdcard-usb   same card, written over USB"
            echo ""
            echo "Required:"
            echo "  --machine <name>        Specify the machine/board name"
            echo ""
            echo "Optional:"
            echo "  --build-dir <dir>       Build directory (default: build-<machine>-image under ~/yocto)"
            echo "  --rust                  Update Rust crates for kaonic packages"
            echo "  --dts                   Clean and rebuild DeviceTree components (tf-a, optee, u-boot, kernel)"
            echo "  --clean                 Clean image before building"
            echo "  --clean-package <pkg>   Clean specific package (can be used multiple times)"
            echo "  --gz                    Compress final image with gzip (Etcher-compatible)"
            echo "                          (sdcard boards only; ignored on eMMC boards)"
            echo "  --env                   Initialize Yocto/BitBake environment only"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $SCRIPT_NAME --machine stm32mp1-kaonic-protoc"
            echo "  $SCRIPT_NAME --machine stm32mp1-kaonic-protoc --build-dir build-protoc"
            echo "  source $SCRIPT_NAME --machine stm32mp1-kaonic-protoc --env"
            echo "  $SCRIPT_NAME --machine stm32mp1-kaonic-protoc --rust --dts"
            echo "  $SCRIPT_NAME --machine stm32mp1-kaonic-protoc --gz"
            echo "  $SCRIPT_NAME --machine stm32mp1-kaonic-protoc --clean-package kaonic-comm --gz"
            if [ "$SCRIPT_SOURCED" = true ]; then
                return 0
            fi
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            if [ "$SCRIPT_SOURCED" = true ]; then
                return 1
            fi
            exit 1
            ;;
    esac
done

if [[ -z "$MACHINE" ]]; then
    echo "Error: --machine argument is required."
    echo "Use --help for usage information"
    if [ "$SCRIPT_SOURCED" = true ]; then
        return 1
    fi
    exit 1
fi

set -e

#*****************************************************************************#

ROOT_DIR=$HOME/yocto
KAONIC_REPO=$ROOT_DIR/layers/meta-st/meta-kaonic
KAONIC_DEPLOY_DIR=$KAONIC_REPO/deploy
KAONIC_MACHINE_DEPLOY_DIR=$KAONIC_DEPLOY_DIR/${MACHINE}
# Only used by sdcard boards, which deploy two artifacts. eMMC boards have no
# raw image, so their USB package is the machine directory itself.
KAONIC_USB_DEPLOY_DIR=$KAONIC_DEPLOY_DIR/${MACHINE}-usb

if [[ -z "$REQUESTED_BUILD_DIR" ]]; then
    KAONIC_BUILD_DIR_NAME=build-${MACHINE}-image
    KAONIC_BUILD_DIR=$ROOT_DIR/$KAONIC_BUILD_DIR_NAME
    ENVSETUP_BUILD_DIR=$KAONIC_BUILD_DIR_NAME
elif [[ "$REQUESTED_BUILD_DIR" = /* ]]; then
    KAONIC_BUILD_DIR=$REQUESTED_BUILD_DIR
    KAONIC_BUILD_DIR_NAME=$(basename "$REQUESTED_BUILD_DIR")
    ENVSETUP_BUILD_DIR=$KAONIC_BUILD_DIR
else
    KAONIC_BUILD_DIR_NAME=$REQUESTED_BUILD_DIR
    KAONIC_BUILD_DIR=$ROOT_DIR/$KAONIC_BUILD_DIR_NAME
    ENVSETUP_BUILD_DIR=$KAONIC_BUILD_DIR_NAME
fi

IMAGE_DIR=$KAONIC_BUILD_DIR/tmp-glibc/deploy/images/$MACHINE

# One `bitbake -e` call is slow, so cache it and read every variable from there.
bitbake_env() {
    if [[ -z "${BITBAKE_ENV_CACHE:-}" ]]; then
        BITBAKE_ENV_CACHE="$(bitbake -e kaonic-st-image-core 2>/dev/null)"
    fi
    printf '%s' "$BITBAKE_ENV_CACHE"
}

bitbake_var() {
    bitbake_env | awk -F= -v key="^$1=" '
        $0 ~ key {
            sub(/^[^=]*=/, "", $0)
            gsub(/^"/, "", $0)
            gsub(/"$/, "", $0)
            print
            exit
        }
    '
}

get_cubemx_dtb() {
    bitbake_var CUBEMX_DTB
}

# SoC part number, derived from the CubeMX device tree name:
# stm32mp151a-kaonic1s-r30-mx -> STM32MP151A
get_soc() {
    get_cubemx_dtb | cut -d- -f1 | tr '[:lower:]' '[:upper:]'
}

# Write manifest.toml describing a deploy directory.
#
# This is what lets a flashing tool decide, before touching hardware, whether a
# bundle fits the board in front of it and which of the two flashing routes to
# take. $1=dir  $2=emmc|sdcard  $3=flashlayout name (emmc)  $4=raw image (sdcard)
write_manifest() {
    local dir="$1" boot="$2" layout="$3" raw="$4"
    local manifest="$dir/manifest.toml"

    {
        echo 'schema = 1'
        echo "machine = \"${MACHINE}\""
        echo "soc = \"$(get_soc)\""
        echo "boot_device = \"${boot}\""
        echo "version = \"${KAONIC_VERSION}\""
        echo "built = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
        [[ -n "$layout" ]] && echo "flashlayout = \"${layout}\""
        [[ -n "$raw" ]] && echo "raw_image = \"${raw}\""
        # Every payload file with its size and hash, so a truncated or altered
        # bundle is detectable rather than failing obscurely mid-flash. These are
        # array-of-tables entries, so they must come after every scalar key above.
        while IFS= read -r f; do
            local rel="${f#./}"
            [[ "$rel" == "manifest.toml" ]] && continue
            local size sha
            size=$(stat -c%s "$dir/$rel" 2>/dev/null || stat -f%z "$dir/$rel")
            sha=$(sha256sum "$dir/$rel" | cut -d' ' -f1)
            printf '\n[[files]]\npath = "%s"\nsize = %s\nsha256 = "%s"\n' "$rel" "$size" "$sha"
        done < <(cd "$dir" && find . -type f | sort)
    } > "$manifest"

    echo "Wrote $manifest"
}

# Pack a deploy directory into a single .tar.gz for distribution.
#
# $1=dir  $2=kind, naming the storage the bundle targets and — where a board
# produces more than one — how it is delivered: `emmc`, `sdcard-raw`,
# `sdcard-usb`. The medium is in the name because it decides what an operator
# does with the file, and two bundles of the same build are otherwise
# indistinguishable.
make_bundle() {
    local dir="$1" kind="$2"
    # `image-` marks a file as something to publish: the flashing tool offers
    # only these, so a folder can hold working files without them being listed
    # as things to write to a board. No `kaonic-` here — MACHINE already carries
    # the board name, and the old name said it twice.
    local name="image-${MACHINE}-v${KAONIC_VERSION}-${kind}.tar.gz"
    BUNDLE_PATH="${KAONIC_DEPLOY_DIR}/${name}"

    echo "Packing bundle: $BUNDLE_PATH"
    rm -f "$BUNDLE_PATH"
    # Archived without a leading directory so manifest paths are the entry paths.
    tar -czf "$BUNDLE_PATH" -C "$dir" .
    sha256sum "$BUNDLE_PATH" > "$BUNDLE_PATH.sha256"
    echo "Bundle: $(du -h "$BUNDLE_PATH" | cut -f1)"
}

# Assemble a USB programming package: the flashlayout TSV plus every binary it
# references, laid out so STM32CubeProgrammer can be pointed straight at the TSV.
#
# This is boot-device independent. The ROM's USB DFU route does not care where
# the image ends up — the TSV's `IP` column does — so an SD-card board is
# programmed over USB exactly like an eMMC one, from the sdcard flashlayout.
# $1=destination dir  $2=flashlayout TSV path (relative to $IMAGE_DIR)
deploy_usb_package() {
    local dir="$1" tsv="$2"

    rm -rf "$dir"
    mkdir -p "$dir"

    # Place the flashlayout TSV at the package root; STM32CubeProgrammer
    # resolves the Binary column paths relative to the TSV location.
    cp "$tsv" "$dir/"

    # Copy every binary referenced by the flashlayout, keeping relative paths
    while IFS=$'\t' read -r opt id name type ip offset binary; do
        case "$opt" in \#*|"") continue ;; esac
        [[ -z "$binary" || "$binary" = "none" ]] && continue
        if [[ ! -f "$binary" ]]; then
            # Only ever a non-zero return: `exit` here would kill the caller's
            # shell when this script is sourced, and `return` from inside a
            # function would not stop the script. The call site decides.
            echo "Error: flashlayout references missing binary: $binary" >&2
            return 1
        fi
        mkdir -p "$dir/$(dirname "$binary")"
        cp "$binary" "$dir/$binary"
    done < "$tsv"
}

# The boot scheme is part of every artifact name (`-optee-`, `-opteemin-`, ...),
# so it is read from the machine configuration rather than hardcoded — switching
# ST_OPTEE_PROFILE renames all of them.
get_bootscheme() {
    local labels
    labels="$(bitbake_var BOOTSCHEME_LABELS)"
    # Last label wins, matching how the machine conf appends.
    printf '%s' "$labels" | tr ' ' '\n' | grep -E '^optee' | tail -n1
}

find_meta_rust_bin_dir() {
    local candidates=(
        "${META_RUST_BIN_DIR:-}"
        "$ROOT_DIR/layers/meta-rust-bin"
        "$ROOT_DIR/layers/meta-st/meta-rust-bin"
        "$ROOT_DIR/layers/meta-openembedded/meta-rust-bin"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -n "$candidate" && -f "$candidate/conf/layer.conf" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

#*****************************************************************************#

cd $KAONIC_REPO

git config --global --add safe.directory $KAONIC_REPO

KAONIC_VERSION=$(git describe --tags | cut -d '-' -f1 | sed 's/^v//')

echo "Kaonic machine: $MACHINE"
echo "Kaonic version: $KAONIC_VERSION"
echo "Build directory: $KAONIC_BUILD_DIR"

cd $ROOT_DIR

unset BUILD_DIR
DISTRO=openstlinux-weston MACHINE=${MACHINE} source ./layers/meta-st/scripts/envsetup.sh --no-ui "$ENVSETUP_BUILD_DIR" << 'EOF'
y
n
y
EOF

if ! bitbake-layers show-layers | grep -q 'meta-rust-bin'; then
    META_RUST_BIN_PATH="$(find_meta_rust_bin_dir)" || {
        echo "Error: meta-rust-bin is required by meta-kaonic but was not enabled by envsetup.sh." >&2
        echo "Set META_RUST_BIN_DIR or place the layer in one of:" >&2
        echo "  $ROOT_DIR/layers/meta-rust-bin" >&2
        echo "  $ROOT_DIR/layers/meta-st/meta-rust-bin" >&2
        echo "  $ROOT_DIR/layers/meta-openembedded/meta-rust-bin" >&2
        if [ "$SCRIPT_SOURCED" = true ]; then
            return 1
        fi
        exit 1
    }

    echo "Adding meta-rust-bin from: $META_RUST_BIN_PATH"
    bitbake-layers add-layer "$META_RUST_BIN_PATH"
fi

if [ "$ENV_ONLY" = true ]; then
    echo "Yocto/BitBake environment initialized in: $KAONIC_BUILD_DIR"
    if [ "$SCRIPT_SOURCED" = true ]; then
        return 0
    fi
    exit 0
fi

#*****************************************************************************#

if [ "$UPDATE_RUST" = true ]; then
    echo "Updating Rust crates..."
    bitbake -c update_crates kaonic-factory
    bitbake -c update_crates kaonic-comm
    bitbake -c cleansstate kaonic-comm
    bitbake -c cleansstate kaonic-factory
fi

if [ "$CLEAN_IMAGE" = true ]; then
    echo "Cleaning image..."
    bitbake -c cleanall kaonic-st-image-core
fi

if [ -n "$CLEAN_PACKAGES" ]; then
    for pkg in $CLEAN_PACKAGES; do
        echo "Cleaning package: $pkg"
        bitbake -c cleansstate $pkg
    done
fi

if [ "$UPDATE_DTS" = true ]; then
    echo "Cleaning and rebuilding DeviceTree components..."
    bitbake -c cleansstate optee-os-stm32mp
    bitbake -c compile optee-os-stm32mp
    bitbake -c cleansstate tf-a-stm32mp
    bitbake -c compile tf-a-stm32mp
    bitbake -c cleansstate u-boot
    bitbake -c compile u-boot
    bitbake -c cleansstate virtual/kernel
    bitbake -c compile virtual/kernel
fi

# bitbake -c cleansstate linux-firmware
# bitbake -c cleansstate linux-firmware-addons-bcm43xx

echo "Building image..."
bitbake kaonic-st-image-core 

#*****************************************************************************#

echo "Generate bootable image"
cd $IMAGE_DIR

FLASHLAYOUT_DTB="$(get_cubemx_dtb)"

if [[ -z "$FLASHLAYOUT_DTB" ]]; then
    echo "Error: unable to determine CUBEMX_DTB from the BitBake environment."
    if [ "$SCRIPT_SOURCED" = true ]; then
        return 1
    fi
    exit 1
fi

BOOTSCHEME="$(get_bootscheme)"
if [[ -z "$BOOTSCHEME" ]]; then
    echo "Error: unable to determine the optee boot scheme from BOOTSCHEME_LABELS."
    if [ "$SCRIPT_SOURCED" = true ]; then
        return 1
    fi
    exit 1
fi
echo "Boot scheme: $BOOTSCHEME"

FLASHLAYOUT_DIR=./flashlayout_kaonic-st-image-core/${BOOTSCHEME}
SDCARD_FLASHLAYOUT_TSV=${FLASHLAYOUT_DIR}/FlashLayout_sdcard_${FLASHLAYOUT_DTB}-${BOOTSCHEME}.tsv
EMMC_FLASHLAYOUT_TSV=${FLASHLAYOUT_DIR}/FlashLayout_emmc_${FLASHLAYOUT_DTB}-${BOOTSCHEME}.tsv

if [[ -f "$SDCARD_FLASHLAYOUT_TSV" ]]; then
    BOOT_DEVICE=sdcard
    FLASHLAYOUT_TSV=$SDCARD_FLASHLAYOUT_TSV
elif [[ -f "$EMMC_FLASHLAYOUT_TSV" ]]; then
    BOOT_DEVICE=emmc
    FLASHLAYOUT_TSV=$EMMC_FLASHLAYOUT_TSV
else
    echo "Error: no flashlayout TSV found for sdcard or emmc in: $FLASHLAYOUT_DIR"
    if [ "$SCRIPT_SOURCED" = true ]; then
        return 1
    fi
    exit 1
fi

echo "Boot device: $BOOT_DEVICE"

mkdir -p ${KAONIC_DEPLOY_DIR}

if [[ "$BOOT_DEVICE" = "emmc" ]]; then
    echo "eMMC boot device: no raw sdcard image is generated."
    echo "Deploy eMMC USB programming artifacts"

    if ! deploy_usb_package "$KAONIC_MACHINE_DEPLOY_DIR" "$FLASHLAYOUT_TSV"; then
        if [ "$SCRIPT_SOURCED" = true ]; then
            return 1
        fi
        exit 1
    fi

    write_manifest "$KAONIC_MACHINE_DEPLOY_DIR" emmc "$(basename "$FLASHLAYOUT_TSV")" ""
    # No delivery qualifier: an eMMC board has exactly one artifact, and USB is
    # the only way to write it.
    make_bundle "$KAONIC_MACHINE_DEPLOY_DIR" emmc

    echo "Deployed to: $KAONIC_MACHINE_DEPLOY_DIR"
    echo "Flash the board over USB with:"
    echo "  kaonic-flash flash $KAONIC_MACHINE_DEPLOY_DIR/$(basename "$FLASHLAYOUT_TSV") --wipe"
    echo "or hand the bundle to the GUI:"
    echo "  $BUNDLE_PATH"
    if [ "$SCRIPT_SOURCED" = true ]; then
        return 0
    fi
    exit 0
fi

IMAGE_FILENAME=${MACHINE}-v${KAONIC_VERSION}-sdcard.raw
FLASHLAYOUT_RAW=$(basename "${FLASHLAYOUT_TSV%.tsv}.raw")

rm -f "$FLASHLAYOUT_RAW"
./scripts/create_sdcard_from_flashlayout.sh "$FLASHLAYOUT_TSV"

mv "$FLASHLAYOUT_RAW" ./${IMAGE_FILENAME}
sha256sum ${IMAGE_FILENAME} > ${IMAGE_FILENAME}.sha256

if [ "$COMPRESS_IMAGE" = true ]; then
    echo "Compressing image with gzip..."
    rm -f ${IMAGE_FILENAME}.gz
    gzip -v -k ${IMAGE_FILENAME}
else
    echo "Skipping compression (use --gz to enable)"
fi

#*****************************************************************************#

echo "Deploy artifacts"
# Cleaned rather than added to: the manifest describes every file in the
# directory, so images left over from an earlier version would be listed — and
# shipped in the bundle — as if they belonged to this build.
rm -rf ${KAONIC_MACHINE_DEPLOY_DIR}
mkdir -p ${KAONIC_MACHINE_DEPLOY_DIR}

cp ${IMAGE_FILENAME} $KAONIC_MACHINE_DEPLOY_DIR/
cp ${IMAGE_FILENAME}.sha256 $KAONIC_MACHINE_DEPLOY_DIR/
# cp ./u-boot/u-boot-stm32mp151a-kaonic-mx.dtb $KAONIC_MACHINE_DEPLOY_DIR/
# cp ./kernel/stm32mp151a-kaonic-mx.dtb $KAONIC_MACHINE_DEPLOY_DIR/

if [ "$COMPRESS_IMAGE" = true ] && [ -f ${IMAGE_FILENAME}.gz ]; then
    cp ${IMAGE_FILENAME}.gz $KAONIC_MACHINE_DEPLOY_DIR/
    echo "Deployed compressed image: ${IMAGE_FILENAME}.gz"
fi

# The raw image is already the payload here, so the bundle carries it plus the
# manifest. It is deliberately the same shape as the eMMC bundle, so the GUI has
# one thing to open regardless of how the board is programmed.
write_manifest "$KAONIC_MACHINE_DEPLOY_DIR" sdcard "" "${IMAGE_FILENAME}"
make_bundle "$KAONIC_MACHINE_DEPLOY_DIR" sdcard-raw
RAW_BUNDLE_PATH="$BUNDLE_PATH"

#*****************************************************************************#

# Second artifact for the same build: the SD card written over USB instead of in
# a card reader. The board is held in USB boot by the BOOT pins, the ROM takes
# TF-A and U-Boot into DDR from the `-programmer-usb` binaries, and U-Boot writes
# the partitions to the card in the slot. Same TSV the raw image is built from —
# only the delivery differs — so the two artifacts cannot drift apart.
echo "Deploy USB programming artifacts"

if ! deploy_usb_package "$KAONIC_USB_DEPLOY_DIR" "$FLASHLAYOUT_TSV"; then
    if [ "$SCRIPT_SOURCED" = true ]; then
        return 1
    fi
    exit 1
fi

write_manifest "$KAONIC_USB_DEPLOY_DIR" sdcard "$(basename "$FLASHLAYOUT_TSV")" ""
make_bundle "$KAONIC_USB_DEPLOY_DIR" sdcard-usb

echo
echo "SD card image (write to a card with Etcher/dd):"
echo "  $RAW_BUNDLE_PATH"
echo "USB programming package:"
echo "  $BUNDLE_PATH"
echo "Flash the board over USB with:"
echo "  kaonic-flash flash $KAONIC_USB_DEPLOY_DIR/$(basename "$FLASHLAYOUT_TSV") --wipe"

#*****************************************************************************#
