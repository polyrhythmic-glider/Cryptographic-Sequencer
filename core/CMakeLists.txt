add_library(cryptoseq_core STATIC
    src/cryptoseq.c
    src/cryptoseq_hash.c
)

target_include_directories(cryptoseq_core
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(cryptoseq_core PUBLIC c_std_99)

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(cryptoseq_core PRIVATE
        -Wall
        -Wextra
        -Wpedantic
    )
endif()
