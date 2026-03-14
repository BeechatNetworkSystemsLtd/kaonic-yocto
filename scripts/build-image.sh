#!/bin/bash

echo "Init build environment"

MACHINE=""
UPDATE_RUST=false
UPDATE_DTS=false
CLEAN_IMAGE=false
CLEAN_PACKAGES=""
COMPRESS_IMAGE=false

#*****************************************************************************#

while [[ $# -gt 0 ]]; do
    case "$1" in
        --machine)
            MACHINE="$2"
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
        --xz)
            COMPRESS_IMAGE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 --machine <name> [OPTIONS]"
            echo ""
            echo "Required:"
            echo "  --machine <name>        Specify the machine/board name"
            echo ""
            echo "Optional:"
            echo "  --rust                  Update Rust crates for kaonic packages"
            echo "  --dts                   Recompile DeviceTree (tf-a, optee, u-boot, kernel)"
            echo "  --clean                 Clean image before building"
            echo "  --clean-package <pkg>   Clean specific package (can be used multiple times)"
            echo "  --xz                    Compress final image with xz"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --machine stm32mp1-kaonic-protoc"
            echo "  $0 --machine stm32mp1-kaonic-protoc --rust --dts"
            echo "  $0 --machine stm32mp1-kaonic-protoc --xz"
            echo "  $0 --machine stm32mp1-kaonic-protoc --clean-package kaonic-comm --xz"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [[ -z "$MACHINE" ]]; then
    echo "Error: --machine argument is required."
    echo "Use --help for usage information"
    exit 1
fi

set -e

#*****************************************************************************#

ROOT_DIR=$HOME/yocto
KAONIC_REPO=$ROOT_DIR/layers/meta-st/meta-kaonic
KAONIC_DEPLOY_DIR=$KAONIC_REPO/deploy
KAONIC_MACHINE_DEPLOY_DIR=$KAONIC_DEPLOY_DIR/${MACHINE}
KAONIC_BUILD_DIR_NAME=build-${MACHINE}-image
KAONIC_BUILD_DIR=$ROOT_DIR/$KAONIC_BUILD_DIR_NAME
IMAGE_DIR=$KAONIC_BUILD_DIR/tmp-glibc/deploy/images/$MACHINE

#*****************************************************************************#

cd $KAONIC_REPO

git config --global --add safe.directory $KAONIC_REPO

KAONIC_VERSION=$(git describe --tags | cut -d '-' -f1 | sed 's/^v//')

echo "Kaonic machine: $MACHINE"
echo "Kaonic version: $KAONIC_VERSION"

cd $ROOT_DIR

DISTRO=openstlinux-weston MACHINE=${MACHINE} source ./layers/meta-st/scripts/envsetup.sh --no-ui $KAONIC_BUILD_DIR_NAME << 'EOF'
y
n
y
EOF

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
    echo "Recompiling DeviceTree components..."
    bitbake -c compile -f tf-a-stm32mp
    bitbake -c compile -f optee-os-stm32mp
    bitbake -c compile -f u-boot
    bitbake -c cleansstate virtual/kernel
    bitbake -c compile -f virtual/kernel
fi

echo "Building image..."
bitbake kaonic-st-image-core 

#*****************************************************************************#

echo "Generate bootable image"
cd $IMAGE_DIR

IMAGE_FILENAME=${MACHINE}-v${KAONIC_VERSION}-sdcard.raw

rm -f FlashLayout_sdcard_stm32mp151a-kaonic-mx-opteemin.raw
./scripts/create_sdcard_from_flashlayout.sh ./flashlayout_kaonic-st-image-core/opteemin/FlashLayout_sdcard_stm32mp151a-kaonic-mx-opteemin.tsv

mv FlashLayout_sdcard_stm32mp151a-kaonic-mx-opteemin.raw ./${IMAGE_FILENAME}
sha256sum ${IMAGE_FILENAME} > ${IMAGE_FILENAME}.sha256

if [ "$COMPRESS_IMAGE" = true ]; then
    echo "Compressing image with xz..."
    rm -f ${IMAGE_FILENAME}.xz
    xz -z -v -k ${IMAGE_FILENAME}
else
    echo "Skipping compression (use --xz to enable)"
fi

#*****************************************************************************#

echo "Deploy artifacts"
mkdir -p ${KAONIC_DEPLOY_DIR}
mkdir -p ${KAONIC_MACHINE_DEPLOY_DIR}

rm -rf $KAONIC_MACHINE_DEPLOY_DIR/${IMAGE_FILENAME}*

cp ${IMAGE_FILENAME} $KAONIC_MACHINE_DEPLOY_DIR/
cp ${IMAGE_FILENAME}.sha256 $KAONIC_MACHINE_DEPLOY_DIR/

if [ "$COMPRESS_IMAGE" = true ] && [ -f ${IMAGE_FILENAME}.xz ]; then
    cp ${IMAGE_FILENAME}.xz $KAONIC_MACHINE_DEPLOY_DIR/
    echo "Deployed compressed image: ${IMAGE_FILENAME}.xz"
fi

#*****************************************************************************#

