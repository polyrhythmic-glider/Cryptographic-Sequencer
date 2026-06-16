add_library(cryptoseq_max_model STATIC
    src/cryptoseq_max_model.c
)

target_include_directories(cryptoseq_max_model
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(cryptoseq_max_model PUBLIC cryptoseq_core)
target_compile_features(cryptoseq_max_model PUBLIC c_std_99)

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(cryptoseq_max_model PRIVATE
        -Wall
        -Wextra
        -Wpedantic
    )
endif()

option(CRYPTOSEQ_BUILD_MAX_EXTERNAL "Build the Max SDK external" OFF)
set(MAX_SDK_ROOT "" CACHE PATH "Path to the Cycling '74 Max SDK root")
set(MAX_SDK_BASE_ROOT "" CACHE PATH "Path to a local Cycling '74 max-sdk-base checkout")

if(CRYPTOSEQ_BUILD_MAX_EXTERNAL)
    if(NOT WIN32)
        message(FATAL_ERROR "cryptoseq_max_external is currently wired as a Windows .mxe64 target")
    endif()

    if(CMAKE_VERSION VERSION_LESS 3.25)
        message(FATAL_ERROR "The current Cycling '74 Max SDK CMake support requires CMake 3.25 or newer")
    endif()

    set(_cryptoseq_max_sdk_base_hints)
    if(MAX_SDK_BASE_ROOT)
        list(APPEND _cryptoseq_max_sdk_base_hints "${MAX_SDK_BASE_ROOT}")
    endif()
    if(MAX_SDK_ROOT)
        list(APPEND _cryptoseq_max_sdk_base_hints
            "${MAX_SDK_ROOT}/max-sdk-base"
            "${MAX_SDK_ROOT}/build/_deps/max-sdk-base-src"
        )
    endif()
    if(DEFINED ENV{MAX_SDK_ROOT})
        list(APPEND _cryptoseq_max_sdk_base_hints
            "$ENV{MAX_SDK_ROOT}/max-sdk-base"
            "$ENV{MAX_SDK_ROOT}/build/_deps/max-sdk-base-src"
        )
    endif()
    if(DEFINED ENV{MAXSDK_ROOT})
        list(APPEND _cryptoseq_max_sdk_base_hints
            "$ENV{MAXSDK_ROOT}/max-sdk-base"
            "$ENV{MAXSDK_ROOT}/build/_deps/max-sdk-base-src"
        )
    endif()

    foreach(_cryptoseq_max_sdk_base_hint IN LISTS _cryptoseq_max_sdk_base_hints)
        if(EXISTS "${_cryptoseq_max_sdk_base_hint}/CMakeLists.txt" AND
           EXISTS "${_cryptoseq_max_sdk_base_hint}/c74support/max-includes/ext.h")
            set(CRYPTOSEQ_MAX_SDK_BASE_DIR "${_cryptoseq_max_sdk_base_hint}")
            break()
        endif()
    endforeach()

    if(CRYPTOSEQ_MAX_SDK_BASE_DIR)
        add_subdirectory("${CRYPTOSEQ_MAX_SDK_BASE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/max-sdk-base")
    else()
        include(FetchContent)
        message(STATUS "Fetching max-sdk-base")
        FetchContent_Declare(
            max-sdk-base
            GIT_REPOSITORY https://github.com/Cycling74/max-sdk-base.git
            GIT_TAG main
        )
        FetchContent_MakeAvailable(max-sdk-base)
    endif()

    find_package(MaxSDK REQUIRED)

    add_library(cryptoseq_max_external MODULE
        src/cryptoseq_max_external.c
        src/cryptoseq_max_external.def
    )

    target_link_libraries(cryptoseq_max_external
        PRIVATE
            cryptoseq_max_model
            Max::Max
    )

    target_compile_features(cryptoseq_max_external PRIVATE c_std_99)

    if(MSVC)
        target_compile_definitions(cryptoseq_max_external
            PRIVATE
                MAXAPI_USE_MSCRT
                WIN_VERSION
                _USE_MATH_DEFINES
                _CRT_SECURE_NO_WARNINGS
        )
    endif()

    set_target_properties(cryptoseq_max_external PROPERTIES
        OUTPUT_NAME cryptoseq
        PREFIX ""
        SUFFIX ".mxe64"
    )
endif()
