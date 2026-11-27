cmake_minimum_required(VERSION 3.16)
project(fso_arm_asr LANGUAGES CXX)

set(ARM_ASR_SOURCE_DIR "" CACHE PATH "Source tree of the Arm ASR Generic Library")
set(ARM_ASR_VULKAN_INCLUDE_DIR "" CACHE PATH "Directory containing vulkan/vulkan.h")
set(asr "${ARM_ASR_SOURCE_DIR}")
set(backend "${asr}/src/backends")

add_library(Arm_ASR_api STATIC
    "${asr}/src/shared/ffxm_assert.cpp"
    "${asr}/src/shared/ffxm_object_management.cpp"
    "${asr}/src/components/fsr2/ffxm_fsr2.cpp"
)
target_include_directories(Arm_ASR_api PRIVATE
    "${asr}" "${asr}/include" "${asr}/include/host" "${asr}/include/gpu"
)

add_library(Arm_ASR_backend STATIC
    "${backend}/vk/ffxm_hash.cpp"
    "${backend}/vk/ffxm_vk.cpp"
    "${backend}/shared/ffxm_shader_blobs.cpp"
    "${backend}/shared/blob_accessors/ffxm_fsr2_shaderblobs.cpp"
)
target_compile_definitions(Arm_ASR_backend PRIVATE FFXM_FSR VK_NO_PROTOTYPES)
target_include_directories(Arm_ASR_backend PRIVATE
    "${ARM_ASR_VULKAN_INCLUDE_DIR}"
    "${asr}/include" "${asr}/include/gpu" "${asr}/src/components"
    "${backend}/vk" "${backend}/shared" "${backend}/shared/blob_accessors/prebuilt_shaders"
)

set_target_properties(Arm_ASR_api Arm_ASR_backend PROPERTIES
    CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON CXX_VISIBILITY_PRESET hidden VISIBILITY_INLINES_HIDDEN ON
)
install(TARGETS Arm_ASR_api Arm_ASR_backend ARCHIVE DESTINATION lib)
install(DIRECTORY "${asr}/include/host" DESTINATION include)
install(FILES "${asr}/LICENSES/MIT.txt" DESTINATION licenses RENAME arm-asr.txt)
