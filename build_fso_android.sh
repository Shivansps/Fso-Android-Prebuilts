#!/bin/sh

# Resolve the directory where this script lives (absolute path).
# This is important so that $ANDROID_NDK_HOME is absolute and resolves
# correctly from the deep cmake build subdirectories below.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

export ANDROID_PLATFORM=android-28
export TEMP_FOLDER="$SCRIPT_DIR/fso_android"
export ANDROID_NDK_HOME="$TEMP_FOLDER/android-ndk"

# --- Android NDK r29 download settings ---
NDK_URL="https://dl.google.com/android/repository/android-ndk-r29-linux.zip"
NDK_ZIP="$SCRIPT_DIR/android-ndk-r29-linux.zip"   # kept next to the script (survives rm of $TEMP_FOLDER)
NDK_SHA1="87e2bb7e9be5d6a1c6cdf5ec40dd4e0c6d07c30b"

rm -rf "$TEMP_FOLDER" && mkdir "$TEMP_FOLDER" && cd "$TEMP_FOLDER"

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
NDK_EXTRACT_TMP="$TEMP_FOLDER/ndk_extract"
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

# Clone FSO
git clone https://github.com/Shivansps/fs2open.github.com --recursive
cd fs2open.github.com && git checkout android-build

# Make embedfile
mkdir tool && cd tool
cmake .. -DFSO_BUILD_TOOLS=ON -G Ninja
ninja embedfile

cd ..

export TARGET_ABI=x86
mkdir "$TARGET_ABI"_debug && cd "$TARGET_ABI"_debug
cmake .. -DFSO_BUILD_WITH_OPENGL_DEBUG=ON -DFSO_BUILD_WITH_OPENXR=OFF -DFSO_BUILD_WITH_OPENGL_ES=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
mkdir "$TARGET_ABI"_release && cd "$TARGET_ABI"_release
cmake .. -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..

export TARGET_ABI=x86_64
mkdir "$TARGET_ABI"_debug && cd "$TARGET_ABI"_debug
cmake .. -DFSO_BUILD_WITH_OPENGL_DEBUG=ON -DFSO_BUILD_WITH_OPENXR=OFF -DFSO_BUILD_WITH_OPENGL_ES=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
mkdir "$TARGET_ABI"_release && cd "$TARGET_ABI"_release
cmake .. -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..

export TARGET_ABI=arm64-v8a
mkdir "$TARGET_ABI"_debug && cd "$TARGET_ABI"_debug
cmake .. -DFSO_BUILD_WITH_OPENGL_DEBUG=ON -DFSO_BUILD_WITH_OPENXR=OFF -DFSO_BUILD_WITH_OPENGL_ES=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
mkdir "$TARGET_ABI"_release && cd "$TARGET_ABI"_release
cmake .. -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..

export TARGET_ABI=armeabi-v7a
mkdir "$TARGET_ABI"_debug && cd "$TARGET_ABI"_debug
cmake .. -DFSO_BUILD_WITH_OPENGL_DEBUG=ON -DFSO_BUILD_WITH_OPENXR=OFF -DANDROID_ARM_NEON=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
mkdir "$TARGET_ABI"_release && cd "$TARGET_ABI"_release
cmake .. -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DANDROID_ARM_NEON=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
