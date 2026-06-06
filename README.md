# FSO for Android — prebuilt libraries & engine builds

Build scripts that cross-compile, for every Android ABI:

- **Prebuilt dependency libraries** used by FreeSpace Open — FFmpeg, SDL2/SDL3, OpenAL + Oboe, Freetype and shaderc.
- **FreeSpace Open itself** (Shivansps fork, `android-build` branch), producing a `jniLibs/` tree ready to drop into the FSOwrapper project.

Everything targets **Ubuntu 24.04 (x86_64)**. The Docker images are pinned to `linux/amd64` because the Android NDK r29 is a linux-x86_64 toolchain.

## Layout

```
.
├── build_libs.sh            # builds the prebuilt dependency libs
├── build_fso_android.sh     # builds FSO for all ABIs
├── compose.yaml             # both builds, as docker compose services
├── docker_libs/Dockerfile   # image for build_libs.sh       (NDK + SDK baked in)
├── docker_fso/Dockerfile    # image for build_fso_android.sh (NDK baked in)
└── patchs/                  # optional *.patch files applied to FSO (see below)
```

## Build with Docker (recommended)

```sh
docker compose build --no-cache
docker compose run --rm libs    # prebuilt dependency libs
docker compose run --rm fso     # FreeSpace Open
```

Outputs land in your project folder:

| Service | Output |
| --- | --- |
| `libs` | `prebuilt_android/bin-android-{arm64,x64,arm32,x86}.tar.gz` |
| `fso`  | `fso_android/jniLibs/` and `fso_android/jniLibs.tar.gz` |

The NDK (and, for `libs`, the SDK) are baked into the images at build time, so the runs don't re-download them. The two builds are independent: `fso` fetches its Android prebuilt libs from the `Fso-Android-Prebuilts` release, not from `prebuilt_android/`, so you don't need to run `libs` first.

> **On Windows:** the Docker path works as-is. The NDK is extracted *inside the image* (a case-sensitive Linux filesystem), so the `xt_RATEEST.h` / `xt_rateest.h` case collision never happens. A **manual** build (below) still needs a case-sensitive filesystem — use Linux or WSL2, and keep the repo on the Linux side (not under `/mnt/c`).

## Applying patches to FSO (optional)

Drop git-style `.patch` files into `patchs/`. `build_fso_android.sh` applies them — in alphabetical order — right after cloning and checking out the `android-build` branch, before any build starts.

- Number them to control order: `0001-…`, `0002-…`, etc.
- No `.patch` files (or no folder) → nothing happens; the build runs normally.
- A patch that fails to apply stops the build, so you notice it.

Generate one from a checked-out FSO tree:

```sh
git diff > /path/to/repo/patchs/0001-my-change.patch
```

Keep the folder present — the included `README.txt` (or a `.gitkeep`) is enough. The Docker image copies `patchs/`, and `COPY` fails if the folder is missing.

## Build manually (without Docker)

Build system: **Ubuntu 24.04 x86_64**.

Dependencies for the prebuilt libraries:

```sh
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build nasm pkg-config \
  meson autoconf automake libtool \
  git curl wget unzip xz-utils ca-certificates file \
  openjdk-17-jdk-headless python3
```

Dependencies for FSO:

```sh
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build git curl ca-certificates unzip \
  pkg-config libudev-dev libusb-1.0-0-dev
```

Then run whichever you need:

```sh
chmod +x build_libs.sh build_fso_android.sh

./build_libs.sh          # -> prebuilt_android/  (all ABIs)
./build_fso_android.sh   # -> fso_android/jniLibs/  for the FSOwrapper project
```

Both scripts download the NDK on demand and cache the zip next to themselves. If `ANDROID_NDK_HOME` already points at a valid NDK, they reuse it and skip the download.
