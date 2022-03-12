#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

echo "Downloading few Dependecies . . ."
# Kernel Sources
git clone https://github.com/CincauEXE/kernel_redmi_mt6768 -b base-q-oss-tetha kernel

# Main Declaration
# export KERNEL_NAME=$(cat "arch/arm64/configs/$DEVICE_DEFCONFIG" | grep "CONFIG_LOCALVERSION=" | sed 's/CONFIG_LOCALVERSION="-*//g' | sed 's/"*//g' )
KERNEL_ROOTDIR=$(pwd)/kernel # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_CODENAME=$DEVICE_CODENAME
DEVICE_DEFCONFIG=$DEVICE_DEFCONFIG # IMPORTANT ! Declare your kernel source defconfig file here.
CLANG_ROOTDIR=$(pwd)/clang # IMPORTANT! Put your clang directory here.
GCC_ROOTDIR=$(pwd)/gcc
GCC32_ROOTDIR=$(pwd)/gcc32
export KBUILD_BUILD_USER=CincauEXE # Change with your own name or else.
export KBUILD_BUILD_HOST=Isekai # Change with your own hostname.
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version)"
LLD_VER="$("$CLANG_ROOTDIR"/bin/ld.lld --version)"
GCC_VER="$("$GCC_ROOTDIR"/bin/aarch64-zyc-linux-gnu- --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
IMAGE=$(pwd)/kernel/out/arch/arm64/boot/Image.gz-dtb
HEADCOMMITID="$(git log --pretty=format:'%h' -n1)"
DATE=$(date +"%F-%S")
DATE2=$(date +"%m%d")
START=$(date +"%s")
PATH="${PATH}:${CLANG_ROOTDIR}/bin:$(pwd)/gcc/bin:$(pwd)/gcc32/bin:${PATH}"
DTB=$(pwd)/kernel/out/arch/arm64/boot/dts/mediatek/mt6768.dtb
DTBO=$(pwd)/kernel/out/arch/arm64/boot/dtbo.img

#Check Kernel Version
cd ${KERNEL_ROOTDIR}
LINUXVER= $(make kernelversion)
KERVER= $(make kernelversion)

# Checking environtment
# Warning !! Dont Change anything there without known reason.
function check() {
echo ================================================
echo xKernelCompiler
echo version : rev1.5 - gaspoll
echo ================================================
echo BUILDER NAME = ${KBUILD_BUILD_USER}
echo BUILDER HOSTNAME = ${KBUILD_BUILD_HOST}
echo DEVICE_DEFCONFIG = ${DEVICE_DEFCONFIG}
echo TOOLCHAIN_VERSION = ${KBUILD_COMPILER_STRING}
echo CLANG_ROOTDIR = ${CLANG_ROOTDIR}
echo KERNEL_ROOTDIR = ${KERNEL_ROOTDIR}
echo ================================================
}

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Post Main Information
tg_post_msg "<b>KernelCompiler</b>%0AKernel Name : <code>${KERNEL_NAME}</code>%0AKernel Version : <code>${LINUXVER}</code>%0ABuild Date : <code>${DATE}</code>%0ABuilder Name : <code>${KBUILD_BUILD_USER}</code>%0ABuilder Host : <code>${KBUILD_BUILD_HOST}</code>%0ADevice Defconfig: <code>${DEVICE_DEFCONFIG}</code>%0AClang Version : <code>${KBUILD_COMPILER_STRING}</code>%0AClang Rootdir : <code>${CLANG_ROOTDIR}</code>%0AKernel Rootdir : <code>${KERNEL_ROOTDIR}</code>"

# Compile
compile(){
tg_post_msg "<b>KernelCompiler:</b><code>Compilation has started</code>"
cd ${KERNEL_ROOTDIR}
make -j$(nproc) O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
make -j$(nproc) ARCH=arm64 O=out \
    LD_LIBRARY_PATH="${CLANG_ROOTDIR}/lib64:${LD_LIBRARY_PATH}" \
    CC=${CLANG_ROOTDIR}/bin/clang \
    AR=${CLANG_ROOTDIR}/bin/llvm-ar \
    NM=${CLANG_ROOTDIR}/bin/llvm-nm \
    OBJCOPY=${CLANG_ROOTDIR}/bin/llvm-objcopy \
    OBJDUMP=${CLANG_ROOTDIR}/bin/llvm-objdump \
    STRIP=${CLANG_ROOTDIR}/bin/llvm-strip \
    LD=${CLANG_ROOTDIR}/bin/ld.lld \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-zyc-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-zyc-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
   fi

  git clone --depth=1 https://github.com/CincauEXE/AnyKernel3 AnyKernel
	cp $IMAGE AnyKernel
#        cp $DTBO AnyKernel
#        mv $DTB AnyKernel/dtb
}

# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅ Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>${KBUILD_COMPILER_STRING}</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="❌ Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</b>"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 [$DATE2][DTC][$LINUXVER][Q-OSS]$KERNEL_NAME[$DEVICE_CODENAME]$HEADCOMMITID.zip *
    cd ..
}
check
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
