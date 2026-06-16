#include "cryptoseq.h"

#include <stdio.h>
#include <string.h>

static int expect_status(cs_status_t actual, cs_status_t expected, const char *label)
{
    if (actual != expected) {
        fprintf(stderr, "%s: expected %s, got %s\n",
                label,
                cs_status_string(expected),
                cs_status_string(actual));
        return 1;
    }

    return 0;
}

static int test_sha256_known_vector(void)
{
    static const uint8_t input[] = {'a', 'b', 'c'};
    static const uint8_t expected[CS_SHA256_DIGEST_SIZE] = {
        0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
        0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
        0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
        0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad
    };
    uint8_t digest[CS_SHA256_DIGEST_SIZE];
    cs_status_t status = cs_source_digest(input, sizeof(input), digest);

    if (expect_status(status, CS_OK, "sha256 abc")) {
        return 1;
    }

    if (memcmp(digest, expected, sizeof(expected)) != 0) {
        fprintf(stderr, "sha256 abc: digest mismatch\n");
        return 1;
    }

    return 0;
}

static int test_deterministic_generation(void)
{
    static const uint8_t source[] = "cryptographic sequencer";
    cs_params_t params = cs_default_params();
    cs_event_t first[16];
    cs_event_t second[16];
    cs_status_t status;
    size_t i;

    params.length = 16u;
    status = cs_generate_from_bytes(source, sizeof(source) - 1u, &params, first, 16u);
    if (expect_status(status, CS_OK, "first generate")) {
        return 1;
    }

    status = cs_generate_from_bytes(source, sizeof(source) - 1u, &params, second, 16u);
    if (expect_status(status, CS_OK, "second generate")) {
        return 1;
    }

    if (memcmp(first, second, sizeof(first)) != 0) {
        fprintf(stderr, "deterministic generation: output mismatch\n");
        return 1;
    }

    for (i = 0u; i < params.length; ++i) {
        if (first[i].step_index != i ||
            first[i].note > 127u ||
            first[i].velocity < 1u ||
            first[i].velocity > 127u ||
            first[i].gate_permille < params.gate_min_permille ||
            first[i].gate_permille > params.gate_max_permille ||
            first[i].duration_ticks == 0u) {
            fprintf(stderr, "event %lu out of range\n", (unsigned long)i);
            return 1;
        }
    }

    return 0;
}

static int test_value_cache_and_remap(void)
{
    static const uint8_t source[] = {0, 1, 2, 3, 4, 5};
    uint8_t digest[CS_SHA256_DIGEST_SIZE];
    uint32_t values[8];
    cs_event_t major_events[8];
    cs_event_t minor_events[8];
    cs_params_t params = cs_default_params();
    cs_status_t status;
    size_t minor_len = 0u;

    params.length = 8u;

    status = cs_source_digest(source, sizeof(source), digest);
    if (expect_status(status, CS_OK, "digest for cache")) {
        return 1;
    }

    status = cs_generate_values_from_digest(digest, &params, values, 8u);
    if (expect_status(status, CS_OK, "value generation")) {
        return 1;
    }

    status = cs_map_values(values, 8u, &params, major_events, 8u);
    if (expect_status(status, CS_OK, "major remap")) {
        return 1;
    }

    params.scale_intervals = cs_minor_scale(&minor_len);
    params.scale_len = minor_len;
    status = cs_map_values(values, 8u, &params, minor_events, 8u);
    if (expect_status(status, CS_OK, "minor remap")) {
        return 1;
    }

    if (major_events[0].value != minor_events[0].value) {
        fprintf(stderr, "remap changed numeric source value\n");
        return 1;
    }

    return 0;
}

static int test_generation_paths_equivalent(void)
{
    static const uint8_t source[] = "same source through different api paths";
    cs_params_t params = cs_default_params();
    uint8_t digest[CS_SHA256_DIGEST_SIZE];
    uint32_t values[16];
    cs_event_t from_bytes[16];
    cs_event_t from_digest[16];
    cs_event_t from_values[16];
    cs_status_t status;

    params.length = 16u;

    status = cs_generate_from_bytes(source, sizeof(source) - 1u, &params, from_bytes, 16u);
    if (expect_status(status, CS_OK, "generate from bytes")) {
        return 1;
    }

    status = cs_source_digest(source, sizeof(source) - 1u, digest);
    if (expect_status(status, CS_OK, "source digest")) {
        return 1;
    }

    status = cs_generate_from_digest(digest, &params, from_digest, 16u);
    if (expect_status(status, CS_OK, "generate from digest")) {
        return 1;
    }

    status = cs_generate_values_from_digest(digest, &params, values, 16u);
    if (expect_status(status, CS_OK, "generate cached values")) {
        return 1;
    }

    status = cs_map_values(values, 16u, &params, from_values, 16u);
    if (expect_status(status, CS_OK, "map cached values")) {
        return 1;
    }

    if (memcmp(from_bytes, from_digest, sizeof(from_bytes)) != 0) {
        fprintf(stderr, "bytes and digest generation paths differ\n");
        return 1;
    }

    if (memcmp(from_bytes, from_values, sizeof(from_bytes)) != 0) {
        fprintf(stderr, "bytes and cached-value generation paths differ\n");
        return 1;
    }

    return 0;
}

static int test_validation_errors(void)
{
    cs_params_t params = cs_default_params();
    cs_event_t events[1];
    uint8_t digest[CS_SHA256_DIGEST_SIZE] = {0};
    cs_status_t status;

    params.length = 1u;
    params.p = 15u;
    status = cs_generate_from_digest(digest, &params, events, 1u);
    if (expect_status(status, CS_ERROR_NOT_PRIME, "composite p")) {
        return 1;
    }

    params = cs_default_params();
    params.length = 1u;
    params.p = 3u;
    params.q = 11u;
    params.e = 5u;
    status = cs_generate_from_digest(digest, &params, events, 1u);
    if (expect_status(status, CS_ERROR_NOT_COPRIME, "non coprime exponent")) {
        return 1;
    }

    params = cs_default_params();
    params.length = 2u;
    status = cs_generate_from_digest(digest, &params, events, 1u);
    if (expect_status(status, CS_ERROR_OUTPUT_TOO_SMALL, "small output")) {
        return 1;
    }

    params = cs_default_params();
    params.length = CS_MAX_SEQUENCE_LENGTH + 1u;
    status = cs_validate_params(&params);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "sequence too long")) {
        return 1;
    }

    params = cs_default_params();
    params.p = CS_MAX_PRIME_VALUE + 2u;
    status = cs_validate_params(&params);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "prime too large")) {
        return 1;
    }

    params = cs_default_params();
    params.scale_len = CS_MAX_SCALE_LENGTH + 1u;
    status = cs_validate_params(&params);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "scale too long")) {
        return 1;
    }

    params = cs_default_params();
    params.duration_count = CS_MAX_DURATION_COUNT + 1u;
    status = cs_validate_params(&params);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "too many durations")) {
        return 1;
    }

    status = cs_source_digest((const uint8_t *)"", CS_MAX_SOURCE_BYTES + 1u, digest);
    if (expect_status(status, CS_ERROR_SOURCE_TOO_LARGE, "source too large")) {
        return 1;
    }

    return 0;
}

int main(void)
{
    if (test_sha256_known_vector()) {
        return 1;
    }

    if (test_deterministic_generation()) {
        return 1;
    }

    if (test_value_cache_and_remap()) {
        return 1;
    }

    if (test_generation_paths_equivalent()) {
        return 1;
    }

    if (test_validation_errors()) {
        return 1;
    }

    return 0;
}
