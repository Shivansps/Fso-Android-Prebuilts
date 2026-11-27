#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: sh arm-asr/build.sh <work directory> <prebuilts directory>" >&2
    exit 2
fi

recipe_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
work_dir=$(CDPATH= cd -- "$1" && pwd -P)
prebuilts_dir=$2
revision=0501f490bd9946a2e1806b5363d7ab8a9a6a5e0a
source_dir="$work_dir/accuracy-super-resolution-generic-library-$revision"
archive="$work_dir/arm-asr-$revision.tar.gz"

if [ ! -f "$archive" ]; then
    curl -fsSL --retry 3 \
        "https://github.com/arm/accuracy-super-resolution-generic-library/archive/$revision.tar.gz" \
        -o "$archive.partial"
    mv "$archive.partial" "$archive"
fi
tar -xzf "$archive" -C "$work_dir"
# The extracted SDK can be inside the packaging repository.
GIT_CEILING_DIRECTORIES="$work_dir" git -C "$source_dir" apply --no-index "$recipe_dir/portable-vulkan.patch"

for abi in arm64-v8a armeabi-v7a x86 x86_64; do
    build_dir="$work_dir/arm-asr-build/$abi"
    prebuilt_dir="$prebuilts_dir/$abi"
    cmake -S "$recipe_dir" -B "$build_dir" -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$abi" -DANDROID_PLATFORM="$ANDROID_PLATFORM" -DANDROID_STL=c++_static \
        -DCMAKE_BUILD_TYPE=Release -DARM_ASR_SOURCE_DIR="$source_dir" \
        -DARM_ASR_VULKAN_INCLUDE_DIR="$prebuilt_dir/vulkan-headers/include"
    cmake --build "$build_dir"
    cmake --install "$build_dir" --prefix "$prebuilt_dir/arm-asr"
done
