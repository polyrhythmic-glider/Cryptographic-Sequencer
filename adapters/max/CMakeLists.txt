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
