#!/bin/sh
#export ANDROID_SDK_HOME=/home/shivan/AndroidSDK
#export ANDROID_NDK_HOME=/home/shivan/android-ndk-r27d
#export ANDROID_PLATFORM=android-28
#export TARGET_PREBUILT_FOLDER=/home/shivan/prebuilt_android
#export TEMP_FOLDER=libs

# Build prebuilt libs
rm -rf $TEMP_FOLDER
rm -rf $TARGET_PREBUILT_FOLDER
mkdir $TARGET_PREBUILT_FOLDER
mkdir $TEMP_FOLDER && cd $TEMP_FOLDER

# FFMPEG
git clone https://github.com/Javernaut/ffmpeg-android-maker
cd ffmpeg-android-maker
./ffmpeg-android-maker.sh --source-git-tag=n5.0

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

# SDL
git clone https://github.com/libsdl-org/SDL
cd SDL && git checkout SDL2 && cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2
cmake cmake -S SDL -B sdl2-android1  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="arm64-v8a" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2
cd sdl2-android1 && make -j4 install
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/bin
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/share
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/lib/cmake
rm $TARGET_PREBUILT_FOLDER/arm64-v8a/sdl2/lib/libSDL2main.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2
cmake cmake -S SDL -B sdl2-android2  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="armeabi-v7a" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2
cd sdl2-android2 && make -j4 install
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/bin
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/share
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/lib/cmake
rm $TARGET_PREBUILT_FOLDER/armeabi-v7a/sdl2/lib/libSDL2main.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/x86/sdl2
cmake cmake -S SDL -B sdl2-android3  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="x86" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/x86/sdl2
cd sdl2-android3 && make -j4 install
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/bin
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/share
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/x86/sdl2/lib/cmake
rm $TARGET_PREBUILT_FOLDER/x86/sdl2/lib/libSDL2main.a
cd ..

mkdir -p $TARGET_PREBUILT_FOLDER/x86_64/sdl2
cmake cmake -S SDL -B sdl2-android4 -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake -DANDROID_ABI="x86_64" -DANDROID_PLATFORM=$ANDROID_PLATFORM -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_AUDIO=ON -DSDL_VIDEO=ON -DSDL_RENDER=ON -DCMAKE_INSTALL_PREFIX=$TARGET_PREBUILT_FOLDER/x86_64/sdl2
cd sdl2-android4 && make -j4 install
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/bin
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/share
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/lib/pkgconfig
rm -rf $TARGET_PREBUILT_FOLDER/x86_64/sdl2/lib/cmake
rm $TARGET_PREBUILT_FOLDER/x86_64/sdl2/lib/libSDL2main.a
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
