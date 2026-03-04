#!/bin/sh
export ANDROID_NDK_HOME=/home/shivan/android-ndk-r28c
export ANDROID_PLATFORM=android-28
export PREBUILT_FOLDER=/home/shivan/prebuilt_android
export TEMP_FOLDER=fso_android

rm -rf $TEMP_FOLDER && mkdir $TEMP_FOLDER && cd $TEMP_FOLDER

git clone https://github.com/Shivansps/fs2open.github.com --recursive
cd fs2open.github.com && git checkout android-build-vulkan

# Make embedfile
mkdir tool && cd tool
cmake .. -DFSO_BUILD_TOOLS=ON -G Ninja
ninja embedfile

cd ..

export TARGET_ABI=x86
mkdir "$TARGET_ABI"_debug && cd "$TARGET_ABI"_debug
cmake .. -DFSO_BUILD_WITH_VULKAN=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DSHADERS_ENABLE_COMPILATION=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -DFSO_PREBUILT_OVERRIDE=$PREBUILT_FOLDER/$TARGET_ABI -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
mkdir "$TARGET_ABI"_release && cd "$TARGET_ABI"_release
cmake .. -DFSO_BUILD_WITH_VULKAN=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DSHADERS_ENABLE_COMPILATION=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -DFSO_PREBUILT_OVERRIDE=$PREBUILT_FOLDER/$TARGET_ABI -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..

export TARGET_ABI=x86_64
mkdir "$TARGET_ABI"_debug && cd "$TARGET_ABI"_debug
cmake .. -DFSO_BUILD_WITH_VULKAN=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DSHADERS_ENABLE_COMPILATION=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -DFSO_PREBUILT_OVERRIDE=$PREBUILT_FOLDER/$TARGET_ABI -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
mkdir "$TARGET_ABI"_release && cd "$TARGET_ABI"_release
cmake .. -DFSO_BUILD_WITH_VULKAN=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DSHADERS_ENABLE_COMPILATION=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -DFSO_PREBUILT_OVERRIDE=$PREBUILT_FOLDER/$TARGET_ABI -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..

export TARGET_ABI=arm64-v8a
mkdir "$TARGET_ABI"_debug && cd "$TARGET_ABI"_debug
cmake .. -DFSO_BUILD_WITH_VULKAN=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DFSO_BUILD_WITH_OPENXR=OFF -DSHADERS_ENABLE_COMPILATION=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -DFSO_PREBUILT_OVERRIDE=$PREBUILT_FOLDER/$TARGET_ABI -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
mkdir "$TARGET_ABI"_release && cd "$TARGET_ABI"_release
cmake .. -DFSO_BUILD_WITH_VULKAN=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DSHADERS_ENABLE_COMPILATION=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -DFSO_PREBUILT_OVERRIDE=$PREBUILT_FOLDER/$TARGET_ABI -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..

export TARGET_ABI=armeabi-v7a
mkdir "$TARGET_ABI"_debug && cd "$TARGET_ABI"_debug
cmake .. -DFSO_BUILD_WITH_VULKAN=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DANDROID_ARM_NEON=ON -DCMAKE_BUILD_TYPE=Debug -DSHADERS_ENABLE_COMPILATION=ON -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -DFSO_PREBUILT_OVERRIDE=$PREBUILT_FOLDER/$TARGET_ABI -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
mkdir "$TARGET_ABI"_release && cd "$TARGET_ABI"_release
cmake .. -DFSO_BUILD_WITH_VULKAN=ON -DFSO_BUILD_WITH_OPENGL_ES=ON -DSHADERS_ENABLE_COMPILATION=ON -DANDROID_ARM_NEON=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI=$TARGET_ABI -DANDROID_PLATFORM=$ANDROID_PLATFORM -DEMBEDFILE_PATH=../tool/bin/embedfile -DFSO_PREBUILT_OVERRIDE=$PREBUILT_FOLDER/$TARGET_ABI -G Ninja && sed -i 's/-lusb-1.0//' build.ninja
ninja
mkdir -p ../../jniLibs/"$TARGET_ABI"
cp -r bin/*.so  ../../jniLibs/"$TARGET_ABI"
cd ..
