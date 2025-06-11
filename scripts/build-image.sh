#!/bin/bash

echo "Init build environment"

MACHINE=""

#*****************************************************************************#

while [[ $# -gt 0 ]]; do
    case "$1" in
        --machine)
            MACHINE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --machine <name>"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$MACHINE" ]]; then
    echo "Error: --machine argument is required."
    exit 1
fi

set -e

#*****************************************************************************#

ROOT_DIR=$HOME/yocto
KAONIC_REPO=$ROOT_DIR/layers/meta-st/meta-kaonic
KAONIC_DEPLOY_DIR=$KAONIC_REPO/deploy
KAONIC_BUILD_DIR_NAME=build-${MACHINE}-image
KAONIC_BUILD_DIR=$ROOT_DIR/$KAONIC_BUILD_DIR_NAME
IMAGE_DIR=$KAONIC_BUILD_DIR/tmp-glibc/deploy/images/$MACHINE
SDK_DIR=$KAONIC_BUILD_DIR/tmp-glibc/deploy/sdk

#*****************************************************************************#

cd $KAONIC_REPO

git config --global --add safe.directory $KAONIC_REPO

KAONIC_VERSION=$(git describe --tags | cut -d '-' -f1 | sed 's/^v//')

mkdir -p $KAONIC_DEPLOY_DIR

echo "Kaonic machine: $MACHINE"
echo "Kaonic version: $KAONIC_VERSION"

cd $ROOT_DIR

DISTRO=openstlinux-weston MACHINE=${MACHINE} source ./layers/meta-st/scripts/envsetup.sh --no-ui $KAONIC_BUILD_DIR_NAME << 'EOF'
y
n
y
EOF

#*****************************************************************************#

echo "Build image"
bitbake kaonic-st-image-core

echo "Build SDK"
bitbake kaonic-st-image-core -c populate_sdk

#*****************************************************************************#

echo "Generate bootable image"
cd $IMAGE_DIR

IMAGE_FILENAME=${MACHINE}-v${KAONIC_VERSION}-sdcard.raw

rm -f FlashLayout_sdcard_stm32mp151a-kaonic-mx-opteemin.raw
./scripts/create_sdcard_from_flashlayout.sh ./flashlayout_kaonic-st-image-core/opteemin/FlashLayout_sdcard_stm32mp151a-kaonic-mx-opteemin.tsv

mv FlashLayout_sdcard_stm32mp151a-kaonic-mx-opteemin.raw ./${IMAGE_FILENAME}
sha256sum ${IMAGE_FILENAME} > ${IMAGE_FILENAME}.sha256

rm -f ${IMAGE_FILENAME}.xz
xz -z -v ${IMAGE_FILENAME}

#*****************************************************************************#

echo "Deploy artifacts"
cp ${IMAGE_FILENAME} $KAONIC_DEPLOY_DIR/
cp ${IMAGE_FILENAME}.xz $KAONIC_DEPLOY_DIR/
cp ${IMAGE_FILENAME}.sha256 $KAONIC_DEPLOY_DIR/

cd $SDK_DIR
cp kaonic-st-image-core-openstlinux-weston-${MACHINE}.rootfs-$(eval "uname -m")-toolchain-5.0.3-snapshot.sh $KAONIC_DEPLOY_DIR/${MACHINE}-v${KAONIC_VERSION}-sdk-$(eval "uname -m").sh

#*****************************************************************************#

