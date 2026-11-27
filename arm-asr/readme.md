# Arm ASR Android prebuilts

The [build script](build.sh) extracts a pinned revision of the Arm ASR Generic Library and applies [portable-vulkan.patch](portable-vulkan.patch) before configuring CMake. The [main prebuilts script](../build_libs.sh) calls this recipe after installing the Vulkan headers for each ABI. The recipe installs the ASR API and Vulkan backend static libraries, their matching headers, and the MIT license under `arm-asr/` in each of the four Android ABI packages.

## Why the patch is needed

- **Vulkan function loading.** FSO loads Vulkan dynamically. The recipe builds the ASR backend with `VK_NO_PROTOTYPES`, and the patch lets it resolve physical-device queries through FSO's `vkGetInstanceProcAddr` and load the viewport and scissor commands through `vkGetDeviceProcAddr`.
- **Vulkan synchronization.** ASR uses fragment passes that write to color attachments. The patch gives those writes the color-attachment stage and access flags and includes both the fragment and compute stages for resources accessed by both.
- **32-bit Android ABIs.** Vulkan image, buffer, and pipeline handles are still 64 bits on `armeabi-v7a` and `x86`. The patch stores the full handle values on those ABIs and uses `VK_NULL_HANDLE` where Vulkan expects a null handle. The 64-bit ABIs retain the existing pointer representation. Consumers should use the headers shipped with their ABI's libraries so the handle types and structure layout match.
- **Scratch memory and shader lookup.** The patch accounts for the resource-view table when sizing Vulkan scratch memory and checks that the public ASR context storage meets the private context's alignment. Unknown shader passes return `FFXM_ERROR_INVALID_ENUM` so callers can detect a failed lookup.
