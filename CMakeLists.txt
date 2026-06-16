cmake_minimum_required(VERSION 3.16)

project(CryptographicSequencerCore LANGUAGES C)

option(CRYPTOSEQ_BUILD_TESTS "Build cryptoseq core tests" ON)
option(CRYPTOSEQ_BUILD_EXAMPLES "Build cryptoseq core examples" ON)
option(CRYPTOSEQ_BUILD_MAX_MODEL "Build the Max adapter model that does not require the Max SDK" ON)

add_subdirectory(core)

if(CRYPTOSEQ_BUILD_MAX_MODEL)
    add_subdirectory(adapters/max)
endif()

if(CRYPTOSEQ_BUILD_EXAMPLES)
    add_executable(cryptoseq_print_sequence core/examples/print_sequence.c)
    target_link_libraries(cryptoseq_print_sequence PRIVATE cryptoseq_core)
endif()

if(CRYPTOSEQ_BUILD_TESTS)
    enable_testing()

    add_executable(cryptoseq_core_smoke core/tests/test_core.c)
    target_link_libraries(cryptoseq_core_smoke PRIVATE cryptoseq_core)

    add_test(NAME cryptoseq_core_smoke COMMAND cryptoseq_core_smoke)

    if(CRYPTOSEQ_BUILD_MAX_MODEL)
        add_executable(cryptoseq_max_model_smoke adapters/max/tests/test_max_model.c)
        target_link_libraries(cryptoseq_max_model_smoke PRIVATE cryptoseq_max_model)

        add_test(NAME cryptoseq_max_model_smoke COMMAND cryptoseq_max_model_smoke)
    endif()
endif()
