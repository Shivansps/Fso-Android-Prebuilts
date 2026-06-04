#!/bin/sh

#export ANDROID_SDK_HOME=/home/shivan/AndroidSDK

# Resolve the directory where this script lives (absolute path).
# This is important so that $ANDROID_NDK_HOME is absolute and resolves
# correctly from the deep cmake build subdirectories below.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

export ANDROID_PLATFORM=android-28
export TARGET_PREBUILT_FOLDER="$SCRIPT_DIR/prebuilt_android"
export TEMP_FOLDER="$TARGET_PREBUILT_FOLDER/libs_temp"
export ANDROID_NDK_HOME="$TARGET_PREBUILT_FOLDER/android-ndk"


# --- Android NDK r29 download settings ---
NDK_URL="https://dl.google.com/android/repository/android-ndk-r29-linux.zip"
NDK_ZIP="$SCRIPT_DIR/android-ndk-r29-linux.zip"   # kept next to the script (survives rm of $TEMP_FOLDER)
NDK_SHA1="87e2bb7e9be5d6a1c6cdf5ec40dd4e0c6d07c30b"

rm -rf "$TEMP_FOLDER" && rm -rf "$TARGET_PREBUILT_FOLDER"
mkdir "$TARGET_PREBUILT_FOLDER" && mkdir "$TEMP_FOLDER"
cd "$TEMP_FOLDER"

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

# Sanity check: the toolchain file must exist.
if [ ! -f "$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" ]; then
    echo "Error: NDK toolchain not found at $ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" >&2
    exit 1
fi
echo "NDK ready at $ANDROID_NDK_HOME"


# Build prebuilt libs

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

cd .. && cd ..

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
cd SDL3 && cd ..

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


# Cleanup + packaging
cd ..
rm -rf "$TEMP_FOLDER"
rm -rf "$ANDROID_NDK_HOME"

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