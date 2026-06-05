Prebuilts libs for FSO for Android and FSO builds to use with the wrapper<br />

<br />
<br />

Using the docker files:<br />
docker compose build --no-cache<br />
docker compose run --rm libs<br />
docker compose run --rm fso<br />

<br />
<br />

Running the scripts manually:
<br />
Build System: Ubuntu 24.04 x86\_64

<br />
<br />
Dependencies to build prebuilt libs:<br />
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build nasm pkg-config \
  meson autoconf automake libtool \
  git curl wget unzip xz-utils ca-certificates file \
  openjdk-17-jdk-headless python3

<br /><br />
For FSO just the regular ones.

Compiling Prebuilt libs used by FSO for all Android ABIs

<br />
chmod +x build\_libs.sh
./build\_libs.sh

<br /><br />

The result will be a directory with all prebuilt libs used by FSO for all ABIs

<br /><br /><br />


Compiling FSO for all Android ABIs

<br /><br />
chmod +x build\_fso\_android.sh
./build\_fso\_android.sh

<br /><br />
The result will be a "jniLibs" directory ready to drop in the Fsowrapper project



<br /><br /><br /><br />



