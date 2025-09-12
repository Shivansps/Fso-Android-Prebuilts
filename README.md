
Prebuilts libs for FSO for Android and FSO builds to use with the wrapper<br />
<br />
Build System: Ubuntu 24.04 x86_64
<br />
Note: Keep in mind the script will only compile the libs and FSO with the right settings, getting and installing the NDK, SDK and individual libs and FSO dependencies must be done before using the scripts.
<br />
<br />
Compiling Prebuilt libs used by FSO for all Android ABIs
<br />
export ANDROID_SDK_HOME=/path/to/AndroidSDK<br />
export ANDROID_NDK_HOME=/path/to/android-ndk-r27d<br />
export ANDROID_PLATFORM=android-28<br />
export TARGET_PREBUILT_FOLDER=/libs/output/directory/path/prebuilt_android<br />
export TEMP_FOLDER=libs<br />
<br />
chmod +x build_libs.sh<br />
./build_libs.sh<br />
<br />
The result will be a directory with all prebuilt libs used by FSO for all ABIs
<br />
<br />
Compiling FSO for all Android ABIs (you will need the libs compiled in the previous step)<br />
<br />
export ANDROID_NDK_HOME=/path/to/android-ndk-r27d<br />
export ANDROID_PLATFORM=android-28<br />
export PREBUILT_FOLDER=/libs/output/directory/path/prebuilt_android<br />
export TEMP_FOLDER=fso_android<br />
<br />
chmod +x build_fso_android.sh<br />
./build_fso_android.sh<br /><br />
The result will be a "jniLibs" directory ready to drop in the Fsowrapper project