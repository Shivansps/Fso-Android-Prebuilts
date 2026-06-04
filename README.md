Prebuilts libs for FSO for Android and FSO builds to use with the wrapper<br />


<br />
<br />

Build System: Ubuntu 24.04 x86\_64

<br />
<br />
Note: Keep in mind the script will only compile the libs and FSO with the right settings, getting and installing all dependencies for OpenAL, Oboe, FFmpeg, SDL and FSO must be done before using the scripts.

<br /><br />


Compiling Prebuilt libs used by FSO for all Android ABIs

<br />
export ANDROID\_SDK\_HOME=/path/to/AndroidSDK
chmod +x build\_libs.sh
./build\_libs.sh

<br /><br />

The result will be a directory with all prebuilt libs used by FSO for all ABIs

<br /><br /><br />


Compiling FSO for all Android ABIs (you will need the libs compiled in the previous step)

<br /><br />
chmod +x build\_fso\_android.sh
./build\_fso\_android.sh

<br /><br />
The result will be a "jniLibs" directory ready to drop in the Fsowrapper project




<br /><br /><br /><br />



Note: this is only for the vulkan version (based on old branch)
<br /><br />

export ANDROID\_NDK\_HOME=/path/to/android-ndk-r27d<br />
export ANDROID\_PLATFORM=android-28<br />
export PREBUILT\_FOLDER=/libs/output/directory/path/prebuilt\_android<br />
export TEMP\_FOLDER=fso\_android<br />
<br /><br />
chmod +x build\_fso\_android\_vulkan.sh<br />
./build\_fso\_android\_vulkan.sh<br />
<br /><br />
The result will be a "jniLibs" directory ready to drop in the Fsowrapper project

