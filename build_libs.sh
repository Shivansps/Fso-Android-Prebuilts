#!/bin/sh
# Resolve the directory where this script lives (absolute path).
# This is important so that $ANDROID_NDK_HOME is absolute and resolves
# correctly from the deep cmake build subdirectories below.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

export ANDROID_PLATFORM=android-28
export TARGET_PREBUILT_FOLDER="$SCRIPT_DIR/prebuilt_android"
export TEMP_FOLDER="$TARGET_PREBUILT_FOLDER/libs_temp"
# Honor a pre-installed NDK (e.g. baked into a Docker image) via $ANDROID_NDK_HOME.
# When unset, default to a location inside the (wiped) prebuilt folder.
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$TARGET_PREBUILT_FOLDER/android-ndk}"

#############################################################################################################
# --- Android SDK = cmdline-tools + sdkmanager ---
#############################################################################################################
# Honor a pre-installed SDK via $ANDROID_SDK_HOME (default: inside prebuilt folder).
export ANDROID_SDK_HOME="${ANDROID_SDK_HOME:-$TARGET_PREBUILT_FOLDER/android-sdk}"

# Skip SDK setup if a usable SDK is already present (e.g. baked into a Docker image
# at $ANDROID_SDK_HOME, outside $TARGET_PREBUILT_FOLDER so it survives the rm below).
if [ -x "$ANDROID_SDK_HOME/cmdline-tools/latest/bin/sdkmanager" ] && [ -f "$ANDROID_SDK_HOME/platforms/android-35/android.jar" ]; then
    echo "Using pre-installed SDK at $ANDROID_SDK_HOME (skipping cmdline-tools/sdkmanager)"
else
CMDLINE_FALLBACK_URL="https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip"
CMDLINE_ZIP="$SCRIPT_DIR/commandlinetools-linux.zip"

CMDLINE_URL=$(curl -fsSL https://developer.android.com/studio 2>/dev/null \
  | grep -o "https://dl.google.com/android/repository/commandlinetools-linux-[0-9]*_latest.zip" \
  | head -n 1)
[ -n "$CMDLINE_URL" ] || CMDLINE_URL="$CMDLINE_FALLBACK_URL"

if [ ! -f "$CMDLINE_ZIP" ]; then
    echo "Downloading Android cmdline-tools from $CMDLINE_URL ..."
    if command -v curl >/dev/null 2>&1; then
        curl -L --fail -o "$CMDLINE_ZIP" "$CMDLINE_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$CMDLINE_ZIP" "$CMDLINE_URL"
    else
        echo "Error: neither 'curl' nor 'wget' is available." >&2
        exit 1
    fi
fi

# Extract sdkmanager expects: <sdk-root>/cmdline-tools/latest/
echo "Setting up cmdline-tools in $ANDROID_SDK_HOME ..."
rm -rf "$ANDROID_SDK_HOME/cmdline-tools"
mkdir -p "$ANDROID_SDK_HOME/cmdline-tools"
CMDLINE_TMP="$TARGET_PREBUILT_FOLDER/cmdline_extract"
rm -rf "$CMDLINE_TMP" && mkdir -p "$CMDLINE_TMP"
unzip -q "$CMDLINE_ZIP" -d "$CMDLINE_TMP"
mv "$CMDLINE_TMP/cmdline-tools" "$ANDROID_SDK_HOME/cmdline-tools/latest"
rm -rf "$CMDLINE_TMP"

SDKMANAGER="$ANDROID_SDK_HOME/cmdline-tools/latest/bin/sdkmanager"

# Needs JDK on PATH (java 17+). Early check :
command -v java >/dev/null 2>&1 || { echo "Error: JDK (java 17+) is needed for sdkmanager." >&2; exit 1; }

# Accept licenses and install platform 35 + build-tools 35
yes | "$SDKMANAGER" --sdk_root="$ANDROID_SDK_HOME" --licenses >/dev/null
"$SDKMANAGER" --sdk_root="$ANDROID_SDK_HOME" "platforms;android-35" "build-tools;35.0.0"

# Sanity check
[ -f "$ANDROID_SDK_HOME/platforms/android-35/android.jar" ] || { echo "Error: android-35 not installed." >&2; exit 1; }
echo "SDK ready on $ANDROID_SDK_HOME (platforms/android-35, build-tools/35.0.0)"
fi  # end: SDK setup (skipped when pre-baked)

######################################################################################################################
# --- Android NDK r29 download settings ---
######################################################################################################################
NDK_URL="https://dl.google.com/android/repository/android-ndk-r29-linux.zip"
NDK_ZIP="$SCRIPT_DIR/android-ndk-r29-linux.zip"   # kept next to the script (survives rm of $TEMP_FOLDER)
NDK_SHA1="87e2bb7e9be5d6a1c6cdf5ec40dd4e0c6d07c30b"

rm -rf "$TEMP_FOLDER" && rm -rf "$TARGET_PREBUILT_FOLDER"
mkdir "$TARGET_PREBUILT_FOLDER" && mkdir "$TEMP_FOLDER"
cd "$TEMP_FOLDER"

# If a usable NDK is already present (e.g. baked into a Docker image at
# $ANDROID_NDK_HOME, outside $TARGET_PREBUILT_FOLDER), reuse it and skip download.
NDK_PREBAKED=0
if [ -f "$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" ]; then
    NDK_PREBAKED=1
    echo "Using pre-installed NDK at $ANDROID_NDK_HOME (skipping download/extract)"
fi

if [ "$NDK_PREBAKED" = "0" ]; then
# ----------------------------------------------------------------------
# Get Android NDK R29 (linux x64)
#   - Download to the same location as this script ($NDK_ZIP).
#   - If the zip already exists, verify its SHA1; reuse it on match,
#     otherwise re-download.
#   - Extract the NDK into $ANDROID_NDK_HOME.
# ----------------------------------------------------------------------
verify_ndk_zip() {
    [ -f "$NDK_ZIP" ] || return 1
    actual=$(sha1sum "$NDK_ZIP" | awk '{print $1}')
    [ "$actual" = "$NDK_SHA1" ]
}

download_ndk() {
    echo "Downloading Android NDK r29 from $NDK_URL ..."
    if command -v curl >/dev/null 2>&1; then
        curl -L --fail -o "$NDK_ZIP" "$NDK_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$NDK_ZIP" "$NDK_URL"
    else
        echo "Error: neither 'curl' nor 'wget' is available to download the NDK." >&2
        exit 1
    fi
}

if verify_ndk_zip; then
    echo "Existing NDK zip checksum matches, reusing $NDK_ZIP"
else
    if [ -f "$NDK_ZIP" ]; then
        echo "NDK zip checksum mismatch, re-downloading..."
        rm -f "$NDK_ZIP"
    fi
    download_ndk
    if ! verify_ndk_zip; then
        echo "Error: downloaded NDK failed SHA1 verification (expected $NDK_SHA1)." >&2
        exit 1
    fi
    echo "NDK download verified OK."
fi

# Extract into $ANDROID_NDK_HOME. The zip contains a single top-level
# directory (e.g. android-ndk-r29), so unzip to a staging dir and move
# its contents into $ANDROID_NDK_HOME.
echo "Extracting NDK to $ANDROID_NDK_HOME ..."
command -v unzip >/dev/null 2>&1 || { echo "Error: 'unzip' is required." >&2; exit 1; }
rm -rf "$ANDROID_NDK_HOME"
NDK_EXTRACT_TMP="$TARGET_PREBUILT_FOLDER/ndk_extract"
rm -rf "$NDK_EXTRACT_TMP" && mkdir -p "$NDK_EXTRACT_TMP"
unzip -q "$NDK_ZIP" -d "$NDK_EXTRACT_TMP"
NDK_INNER=$(find "$NDK_EXTRACT_TMP" -mindepth 1 -maxdepth 1 -type d | head -n 1)
if [ -z "$NDK_INNER" ]; then
    echo "Error: could not find extracted NDK directory." >&2
    exit 1
fi
mv "$NDK_INNER" "$ANDROID_NDK_HOME"
rm -rf "$NDK_EXTRACT_TMP"
fi  # end: download/extract NDK (skipped when pre-baked)

# Sanity check: the toolchain file must exist.
if [ ! -f "$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" ]; then
    echo "Error: NDK toolchain not found at $ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" >&2
    exit 1
fi
echo "NDK ready at $ANDROID_NDK_HOME"

########################################################################################################
# Build prebuilt libs
########################################################################################################

# ShaderC
ANDROID_NDK_STRIP="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
git clone https://github.com/google/shaderc.git
cd shaderc
./utils/git-sync-deps

mkdir arm64-v8a && mkdir armeabi-v7a && mkdir x86 && mkdir x86_64

cd arm64-v8a

cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=$ANDROID_PLATFORM \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DBUILD_SHARED_LIBS=OFF \
  -DSHADERC_SKIP_TESTS=ON \
  -DANDROID_STL=c++_static \
  ..

ninja

"$ANDROID_NDK_STRIP" --strip-debug libshaderc/libshaderc_shared.so -o libshaderc/libshaderc.so
mkdir -p $TARGET_PREBUILT_FOLDER/arm64-v8a/shaderc/lib
cp -r libshaderc/libshaderc.so "$TARGET_PREBUILT_FOLDER"/arm64-v8a/shaderc/lib/libshaderc.so

cd ..
cd armeabi-v7a

cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=$ANDROID_PLATFORM \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DBUILD_SHARED_LIBS=OFF \
  -DSHADERC_SKIP_TESTS=ON \
  -DANDROID_STL=c++_static \
  ..

ninja

"$ANDROID_NDK_STRIP" --strip-debug libshaderc/libshaderc_shared.so -o libshaderc/libshaderc.so
mkdir -p $TARGET_PREBUILT_FOLDER/armeabi-v7a/shaderc/lib
cp -r libshaderc/libshaderc.so "$TARGET_PREBUILT_FOLDER"/armeabi-v7a/shaderc/lib/libshaderc.so

cd ..
cd x86

cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=x86 \
  -DANDROID_PLATFORM=$ANDROID_PLATFORM \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DBUILD_SHARED_LIBS=OFF \
  -DSHADERC_SKIP_TESTS=ON \
  -DANDROID_STL=c++_static \
  ..

ninja

"$ANDROID_NDK_STRIP" --strip-debug libshaderc/libshaderc_shared.so -o libshaderc/libshaderc.so
mkdir -p $TARGET_PREBUILT_FOLDER/x86/shaderc/lib
cp -r libshaderc/libshaderc.so "$TARGET_PREBUILT_FOLDER"/x86/shaderc/lib/libshaderc.so

cd ..
cd x86_64

cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=x86_64 \
  -DANDROID_PLATFORM=$ANDROID_PLATFORM \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DBUILD_SHARED_LIBS=OFF \
  -DSHADERC_SKIP_TESTS=ON \
  -DANDROID_STL=c++_static \
  ..

ninja

"$ANDROID_NDK_STRIP" --strip-debug libshaderc/libshaderc_shared.so -o libshaderc/libshaderc.so
mkdir -p $TARGET_PREBUILT_FOLDER/x86_64/shaderc/lib
cp -r libshaderc/libshaderc.so "$TARGET_PREBUILT_FOLDER"/x86_64/shaderc/lib/libshaderc.so

cd ..
# Shaderc public headers
for ABI in arm64-v8a armeabi-v7a x86 x86_64; do
	mkdir -p "$TARGET_PREBUILT_FOLDER/$ABI/shaderc/include"
	cp -r libshaderc/include/shaderc "$TARGET_PREBUILT_FOLDER/$ABI/shaderc/include/"
done
cd ..

# Vulkan Headers (1.4.341) 
git clone --depth 1 --branch v1.4.341 https://github.com/KhronosGroup/Vulkan-Headers.git
for ABI in arm64-v8a armeabi-v7a x86 x86_64; do
	mkdir -p "$TARGET_PREBUILT_FOLDER/$ABI/vulkan-headers"
	cp -r Vulkan-Headers/include "$TARGET_PREBUILT_FOLDER/$ABI/vulkan-headers/"
done

# FFMPEG
git clone https://github.com/Javernaut/ffmpeg-android-maker
cd ffmpeg-android-maker
./ffmpeg-android-maker.sh --source-git-tag=n6.1

mkdir -p $TARGET_PREBUILT_FOLDER/arm64-v8a/ffmpeg
cp -r build/ffmpeg/arm64-v8a/include $TARGET_PREBUILT_FOLDER/arm64-v8a/ffmpeg
cp -r build/ffmpeg/arm64-v8a/lib $TARGET_PREBUILT_FOLDER/arm64-v8a/ffmpeg
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/ffmpeg/lib/pkgconfig

mkdir -p $TARGET_PREBUILT_FOLDER/armeabi-v7a/ffmpeg
cp -r build/ffmpeg/armeabi-v7a/include $TARGET_PREBUILT_FOLDER/armeabi-v7a/ffmpeg
cp -r build/ffmpeg/armeabi-v7a/lib $TARGET_PREBUILT_FOLDER/armeabi-v7a/ffmpeg
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/ffmpeg/lib/pkgconfig

mkdir -p $TARGET_PREBUILT_FOLDER/x86/ffmpeg
cp -r build/ffmpeg/x86/include $TARGET_PREBUILT_FOLDER/x86/ffmpeg
cp -r build/ffmpeg/x86/lib $TARGET_PREBUILT_FOLDER/x86/ffmpeg
rm -rf $TARGET_PREBUILT_FOLDER/x86/ffmpeg/lib/pkgconfig

mkdir -p $TARGET_PREBUILT_FOLDER/x86_64/ffmpeg
cp -r build/ffmpeg/x86_64/include $TARGET_PREBUILT_FOLDER/x86_64/ffmpeg
cp -r build/ffmpeg/x86_64/lib $TARGET_PREBUILT_FOLDER/x86_64/ffmpeg
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/ffmpeg/lib/pkgconfig

cd ..

# OpenAL Soft
git clone https://github.com/google/oboe
git clone https://github.com/kcat/openal-soft
cd openal-soft

mkdir build1 && cd build1
mkdir -p $TARGET_PREBUILT_FOLDER/arm64-v8a/openal
cmake -DCMAKE_SYSTEM_NAME=Android -DANDROID_NDK=$ANDROID_NDK_HOME -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/arm64-v8a/openal -DALSOFT_REQUIRE_OBOE=ON -DOBOE_SOURCE=../oboe -DALSOFT_REQUIRE_OPENSL=OFF .. && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/arm64-v8a/openal/include/AL/*.* $TARGET_PREBUILT_FOLDER/arm64-v8a/openal/include
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/openal/bin
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/openal/share
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/openal/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/openal/lib/cmake
cd ..

mkdir build2 && cd build2
mkdir -p $TARGET_PREBUILT_FOLDER/armeabi-v7a/openal
cmake -DCMAKE_SYSTEM_NAME=Android -DANDROID_NDK=$ANDROID_NDK_HOME -DCMAKE_ANDROID_ARCH_ABI=armeabi-v7a -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/armeabi-v7a/openal -DALSOFT_REQUIRE_OBOE=ON -DOBOE_SOURCE=../oboe -DALSOFT_REQUIRE_OPENSL=OFF .. && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/armeabi-v7a/openal/include/AL/*.* $TARGET_PREBUILT_FOLDER/armeabi-v7a/openal/include
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/openal/bin
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/openal/share
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/openal/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/openal/lib/cmake
cd ..

mkdir build3 && cd build3
mkdir -p $TARGET_PREBUILT_FOLDER/x86/openal
cmake -DCMAKE_SYSTEM_NAME=Android -DANDROID_NDK=$ANDROID_NDK_HOME -DCMAKE_ANDROID_ARCH_ABI=x86 -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/x86/openal -DALSOFT_REQUIRE_OBOE=ON -DOBOE_SOURCE=../oboe -DALSOFT_REQUIRE_OPENSL=OFF .. && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/x86/openal/include/AL/*.* $TARGET_PREBUILT_FOLDER/x86/openal/include
rm -rf $TARGET_PREBUILT_FOLDER/x86/openal/bin
rm -rf $TARGET_PREBUILT_FOLDER/x86/openal/share
rm -rf $TARGET_PREBUILT_FOLDER/x86/openal/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/x86/openal/lib/cmake
cd ..

mkdir build4 && cd build4
mkdir -p $TARGET_PREBUILT_FOLDER/x86_64/openal
cmake -DCMAKE_SYSTEM_NAME=Android -DANDROID_NDK=$ANDROID_NDK_HOME -DCMAKE_ANDROID_ARCH_ABI=x86_64 -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/x86_64/openal -DALSOFT_REQUIRE_OBOE=ON -DOBOE_SOURCE=../oboe -DALSOFT_REQUIRE_OPENSL=OFF .. && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/x86_64/openal/include/AL/*.* $TARGET_PREBUILT_FOLDER/x86_64/openal/include
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/openal/bin
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/openal/share
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/openal/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/openal/lib/cmake
cd ..

cd ..

# SDL 2
git clone https://github.com/libsdl-org/SDL
cd SDL && git checkout SDL2 && cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2
cmake cmake -S SDL -B sdl2-android1  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="arm64-v8a" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2
cd sdl2-android1 && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/include/SDL2/*.* $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/include
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/include/SDL2
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/bin
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/share
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/lib/cmake
rm $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/lib/libSDL2main.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2
cmake cmake -S SDL -B sdl2-android2  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="armeabi-v7a" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2
cd sdl2-android2 && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/include/SDL2/*.* $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/include
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/include/SDL2
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/bin
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/share
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/lib/cmake
rm $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/lib/libSDL2main.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/x86/sdl2
cmake cmake -S SDL -B sdl2-android3  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="x86" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/x86/sdl2
cd sdl2-android3 && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/x86/sdl2/include/SDL2/*.* $TARGET_PREBUILT_FOLDER/x86/sdl2/include
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/include/SDL2
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/bin
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/share
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/lib/cmake
rm $TARGET_PREBUILT_FOLDER/x86/sdl2/lib/libSDL2main.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/x86_64/sdl2
cmake cmake -S SDL -B sdl2-android4 -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="x86_64" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/x86_64/sdl2
cd sdl2-android4 && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/x86_64/sdl2/include/SDL2/*.* $TARGET_PREBUILT_FOLDER/x86_64/sdl2/include
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/include/SDL2
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/bin
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/share
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/lib/cmake
rm $TARGET_PREBUILT_FOLDER/x86_64/sdl2/lib/libSDL2main.a
cd ..

# SDL 3
git clone https://github.com/libsdl-org/SDL SDL3
cd SDL3 && git checkout release-3.4.x && cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3
cmake cmake -S SDL3 -B sdl3-android1  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="arm64-v8a" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3
cd sdl3-android1 && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/include/SDL3/*.* $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/include
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/include/SDL3
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/bin
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/share
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/lib/cmake
rm $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/lib/libSDL3main.a
rm $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl3/lib/libSDL3_test.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3
cmake cmake -S SDL3 -B sdl3-android2  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="armeabi-v7a" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3
cd sdl3-android2 && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/include/SDL3/*.* $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/include
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/include/SDL3
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/bin
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/share
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/lib/cmake
rm $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/lib/libSDL3main.a
rm $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl3/lib/libSDL3_test.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/x86/sdl3
cmake cmake -S SDL3 -B sdl3-android3  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="x86" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/x86/sdl3
cd sdl3-android3 && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/x86/sdl3/include/SDL3/*.* $TARGET_PREBUILT_FOLDER/x86/sdl3/include
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl3/include/SDL3
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl3/bin
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl3/share
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl3/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl3/lib/cmake
rm $TARGET_PREBUILT_FOLDER/x86/sdl3/lib/libSDL3main.a
rm $TARGET_PREBUILT_FOLDER/x86/sdl3/lib/libSDL3_test.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/x86_64/sdl3
cmake cmake -S SDL3 -B sdl3-android4 -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="x86_64" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/x86_64/sdl3
cd sdl3-android4 && make -j4 install
cp -r $TARGET_PREBUILT_FOLDER/x86_64/sdl3/include/SDL3/*.* $TARGET_PREBUILT_FOLDER/x86_64/sdl3/include
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl3/include/SDL3
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl3/bin
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl3/share
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl3/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl3/lib/cmake
rm $TARGET_PREBUILT_FOLDER/x86_64/sdl3/lib/libSDL3main.a
rm $TARGET_PREBUILT_FOLDER/x86_64/sdl3/lib/libSDL3_test.a
cd ..

# Freetype
git clone https://github.com/cdave1/freetype2-android
cd freetype2-android
rm Android/jni/Application.mk
echo "APP_ABI := arm64-v8a armeabi-v7a x86 x86_64" >> Android/jni/Application.mk
echo "APP_PLATFORM := $ANDROID_PLATFORM" >> Android/jni/Application.mk
export PATH=$PATH:$ANDROID_NDK_HOME
cd Android && cd jni
ndk-build
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/arm64-v8a/freetype/lib
cp -r ../include $TARGET_PREBUILT_FOLDER/arm64-v8a/freetype
cp -r obj/local/arm64-v8a/libfreetype2-static.a $TARGET_PREBUILT_FOLDER/arm64-v8a/freetype/lib/libfreetype.a

mkdir -p $TARGET_PREBUILT_FOLDER/armeabi-v7a/freetype/lib
cp -r ../include $TARGET_PREBUILT_FOLDER/armeabi-v7a/freetype
cp -r obj/local/armeabi-v7a/libfreetype2-static.a $TARGET_PREBUILT_FOLDER/armeabi-v7a/freetype/lib/libfreetype.a

mkdir -p $TARGET_PREBUILT_FOLDER/x86/freetype/lib
cp -r ../include $TARGET_PREBUILT_FOLDER/x86/freetype
cp -r obj/local/x86/libfreetype2-static.a $TARGET_PREBUILT_FOLDER/x86/freetype/lib/libfreetype.a

mkdir -p $TARGET_PREBUILT_FOLDER/x86_64/freetype/lib
cp -r ../include $TARGET_PREBUILT_FOLDER/x86_64/freetype
cp -r obj/local/x86_64/libfreetype2-static.a $TARGET_PREBUILT_FOLDER/x86_64/freetype/lib/libfreetype.a

cd .. && cd ..

########################################################################################################
# Qt6 for Android (qtFRED)
########################################################################################################
# Qt ships precompiled Android binaries per-ABI, so we download instead of building
# from source. Qt-for-Android is a CROSS package: it needs a HOST Qt of the SAME
# version at FSO-configure time (QT_HOST_PATH). We fetch that too and ship it apart.
#
# NOTE: qtFRED links Core/Gui/Widgets/OpenGL (all in qtbase). The Help module lives
# in qttools and is NOT reliably available for Android, so we grab qtbase only and
# disable Help in qtFRED's Android build.

QT_VER="${QT_VER:-6.8.3}"          # must exist for android on aqt; keep host==target
QT_HOST_ARCH="linux_gcc_64"        # Qt >= 6.7 name; for < 6.7 use "gcc_64"
QT_DL="$TEMP_FOLDER/qt"
mkdir -p "$QT_DL"

# aqt in an isolated venv (Ubuntu 24.04 python is externally-managed)
python3 -m venv "$TEMP_FOLDER/aqtenv"
. "$TEMP_FOLDER/aqtenv/bin/activate"
pip install --upgrade pip aqtinstall

# Optional sanity check of what's actually published for this version:
#   aqt list-qt linux android --arch "$QT_VER"

# --- Host Qt (desktop linux) — used via QT_HOST_PATH, packaged separately ---
aqt install-qt linux desktop "$QT_VER" "$QT_HOST_ARCH" -O "$QT_DL" --archives qtbase icu
mkdir -p "$TARGET_PREBUILT_FOLDER/host/Qt6"
cp -a "$QT_DL/$QT_VER/$QT_HOST_ARCH/." "$TARGET_PREBUILT_FOLDER/host/Qt6/"

# --- Per-ABI Android target Qt ---
qt_android_arch() {
    case "$1" in
        arm64-v8a)   echo android_arm64_v8a ;;
        armeabi-v7a) echo android_armv7 ;;
        x86)         echo android_x86 ;;
        x86_64)      echo android_x86_64 ;;
    esac
}

for ABI in arm64-v8a armeabi-v7a x86 x86_64; do
    AQT_ARCH=$(qt_android_arch "$ABI")
    aqt install-qt linux android "$QT_VER" "$AQT_ARCH" -O "$QT_DL" --archives qtbase
    # aqt layout: $QT_DL/$QT_VER/$AQT_ARCH/{bin,include,lib,libexec,mkspecs,plugins,...}
    mkdir -p "$TARGET_PREBUILT_FOLDER/$ABI/Qt6"
    cp -a "$QT_DL/$QT_VER/$AQT_ARCH/." "$TARGET_PREBUILT_FOLDER/$ABI/Qt6/"
done

deactivate

# Cleanup + packaging
cd ..
rm -rf "$TEMP_FOLDER"
[ "$NDK_PREBAKED" = "1" ] || rm -rf "$ANDROID_NDK_HOME"   # keep a pre-baked NDK

cd "$TARGET_PREBUILT_FOLDER"
for ABI in arm64-v8a x86_64 armeabi-v7a x86; do
    case "$ABI" in
        arm64-v8a)    FILENAME="bin-android-arm64.tar.gz" ;;
        x86_64)       FILENAME="bin-android-x64.tar.gz" ;;
        armeabi-v7a)  FILENAME="bin-android-arm32.tar.gz" ;;
        x86)          FILENAME="bin-android-x86.tar.gz" ;;
    esac
    echo "Packaging $ABI -> $FILENAME"
    tar -czf "$FILENAME" -C "$ABI" .
done

# Host Qt6 (QT_HOST_PATH)
if [ -d "host" ]; then
    echo "Packaging host Qt6 -> bin-android-qt6-host.tar.gz"
    tar -czf "bin-android-qt6-host.tar.gz" -C host .
fi