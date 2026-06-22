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

static int test_scale_does_not_affect_percussive_modes(void)
{
    static const uint32_t values[] = {0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u};
    cs_params_t params = cs_default_params();
    cs_event_t major_events[8];
    cs_event_t minor_events[8];
    cs_status_t status;
    size_t minor_len = 0u;
    size_t i;

    params.length = 8u;
    params.root_note = 36u;
    params.rhythm_threshold = params.rhythm_divisor;

    params.mode = CS_MODE_HYBRID;
    status = cs_map_values(values, 8u, &params, major_events, 8u);
    if (expect_status(status, CS_OK, "hybrid major map")) {
        return 1;
    }

    params.scale_intervals = cs_minor_scale(&minor_len);
    params.scale_len = minor_len;
    status = cs_map_values(values, 8u, &params, minor_events, 8u);
    if (expect_status(status, CS_OK, "hybrid minor map")) {
        return 1;
    }

    for (i = 0u; i < 8u; ++i) {
        if (major_events[i].note != minor_events[i].note ||
            major_events[i].active != minor_events[i].active ||
            major_events[i].velocity != minor_events[i].velocity) {
            fprintf(stderr, "hybrid mode should ignore scale\n");
            return 1;
        }
    }

    params.mode = CS_MODE_RHYTHM;
    status = cs_map_values(values, 8u, &params, major_events, 8u);
    if (expect_status(status, CS_OK, "rhythm first map")) {
        return 1;
    }

    params.scale_intervals = NULL;
    params.scale_len = 0u;
    status = cs_map_values(values, 8u, &params, minor_events, 8u);
    if (expect_status(status, CS_OK, "rhythm without scale map")) {
        return 1;
    }

    for (i = 0u; i < 8u; ++i) {
        if (major_events[i].note != minor_events[i].note ||
            major_events[i].active != minor_events[i].active ||
            major_events[i].velocity != minor_events[i].velocity) {
            fprintf(stderr, "rhythm mode should ignore scale\n");
            return 1;
        }
    }

    return 0;
}

static int test_root_note_is_reachable_in_each_mode(void)
{
    static const uint32_t root_pad_values[] = {0u, 4u, 8u, 12u};
    static const uint32_t melodic_values[] = {0u, 1u, 2u, 3u};
    cs_params_t params = cs_default_params();
    cs_event_t events[4];
    cs_status_t status;
    size_t i;

    params.mode = CS_MODE_HYBRID;
    params.root_note = 36u;
    params.drum_pad_count = 4u;
    params.rhythm_divisor = 16u;
    params.rhythm_threshold = 1u;
    status = cs_map_values(root_pad_values, 4u, &params, events, 4u);
    if (expect_status(status, CS_OK, "hybrid root pad map")) {
        return 1;
    }

    if (events[0].note != 36u || events[0].active != 1u) {
        fprintf(stderr, "hybrid root pad should be active when density is above zero\n");
        return 1;
    }

    for (i = 0u; i < 4u; ++i) {
        if (events[i].note != 36u) {
            fprintf(stderr, "hybrid pad should be selected from the event value\n");
            return 1;
        }
    }

    params.mode = CS_MODE_RHYTHM;
    params.rhythm_threshold = params.rhythm_divisor;
    status = cs_map_values(root_pad_values, 4u, &params, events, 4u);
    if (expect_status(status, CS_OK, "rhythm root map")) {
        return 1;
    }

    for (i = 0u; i < 4u; ++i) {
        if (events[i].note != 36u || events[i].active != 1u) {
            fprintf(stderr, "rhythm mode should play only the root note when active\n");
            return 1;
        }
    }

    params = cs_default_params();
    params.mode = CS_MODE_MELODY;
    params.root_note = 60u;
    params.melody_note_min = 60u;
    params.melody_note_max = 72u;
    params.rhythm_threshold = params.rhythm_divisor;
    status = cs_map_values(melodic_values, 4u, &params, events, 4u);
    if (expect_status(status, CS_OK, "melodic root map")) {
        return 1;
    }

    if (events[0].note != 60u || events[0].active != 1u) {
        fprintf(stderr, "melodic mode should be able to emit the root note\n");
        return 1;
    }

    return 0;
}

static int test_hybrid_pads_follow_values_not_step_order(void)
{
    static const uint32_t values[] = {7u, 2u, 5u, 0u};
    static const uint8_t expected_notes[] = {39u, 38u, 37u, 36u};
    cs_params_t params = cs_default_params();
    cs_event_t events[4];
    cs_status_t status;
    size_t i;

    params.mode = CS_MODE_HYBRID;
    params.root_note = 36u;
    params.drum_pad_count = 4u;
    params.rhythm_threshold = params.rhythm_divisor;

    status = cs_map_values(values, 4u, &params, events, 4u);
    if (expect_status(status, CS_OK, "hybrid value-based pad map")) {
        return 1;
    }

    for (i = 0u; i < 4u; ++i) {
        if (events[i].note != expected_notes[i]) {
            fprintf(stderr, "hybrid pads should not follow step order\n");
            return 1;
        }
    }

    return 0;
}

static int test_note_range_controls(void)
{
    static const uint32_t values[] = {0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u};
    cs_params_t params = cs_default_params();
    cs_event_t events[8];
    cs_status_t status;
    size_t i;

    params.mode = CS_MODE_MELODY;
    params.root_note = 60u;
    params.melody_note_min = 60u;
    params.melody_note_max = 64u;
    status = cs_map_values(values, 8u, &params, events, 8u);
    if (expect_status(status, CS_OK, "melodic note range map")) {
        return 1;
    }

    for (i = 0u; i < 8u; ++i) {
        if (events[i].note < 60u || events[i].note > 64u) {
            fprintf(stderr, "melodic note outside requested range\n");
            return 1;
        }
    }

    params.melody_note_min = 61u;
    params.melody_note_max = 61u;
    status = cs_validate_params(&params);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "melodic range without scale note")) {
        return 1;
    }

    params = cs_default_params();
    params.mode = CS_MODE_HYBRID;
    params.root_note = 36u;
    params.drum_pad_count = 4u;
    params.rhythm_threshold = params.rhythm_divisor;
    status = cs_map_values(values, 8u, &params, events, 8u);
    if (expect_status(status, CS_OK, "hybrid pad count map")) {
        return 1;
    }

    for (i = 0u; i < 8u; ++i) {
        if (events[i].note < 36u || events[i].note > 39u) {
            fprintf(stderr, "hybrid note outside requested pad range\n");
            return 1;
        }
    }

    params.root_note = 120u;
    params.drum_pad_count = 16u;
    status = cs_validate_params(&params);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "hybrid pad count beyond midi range")) {
        return 1;
    }

    return 0;
}

static int test_density_controls_melodic_activity(void)
{
    static const uint32_t values[] = {0u, 1u, 2u, 3u};
    cs_params_t params = cs_default_params();
    cs_event_t events[4];
    cs_status_t status;
    size_t i;

    params.mode = CS_MODE_MELODY;
    params.rhythm_threshold = 0u;

    status = cs_map_values(values, 4u, &params, events, 4u);
    if (expect_status(status, CS_OK, "melodic zero density map")) {
        return 1;
    }

    for (i = 0u; i < 4u; ++i) {
        if (events[i].active != 0u) {
            fprintf(stderr, "melodic density should control active state\n");
            return 1;
        }
    }

    params.rhythm_threshold = params.rhythm_divisor;
    status = cs_map_values(values, 4u, &params, events, 4u);
    if (expect_status(status, CS_OK, "melodic full density map")) {
        return 1;
    }

    for (i = 0u; i < 4u; ++i) {
        if (events[i].active != 1u) {
            fprintf(stderr, "melodic full density should activate all steps\n");
            return 1;
        }
    }

    return 0;
}

static int test_sequence_shift_rotates_events(void)
{
    static const uint32_t values[] = {10u, 20u, 30u, 40u};
    cs_params_t params = cs_default_params();
    cs_event_t events[4];
    cs_status_t status;

    params.length = 4u;
    params.mode = CS_MODE_RHYTHM;
    params.sequence_shift = 1u;

    status = cs_map_values(values, 4u, &params, events, 4u);
    if (expect_status(status, CS_OK, "shifted rhythm map")) {
        return 1;
    }

    if (events[0].step_index != 0u || events[0].value != 40u ||
        events[1].step_index != 1u || events[1].value != 10u ||
        events[2].step_index != 2u || events[2].value != 20u ||
        events[3].step_index != 3u || events[3].value != 30u) {
        fprintf(stderr, "sequence shift should rotate events right while preserving order\n");
        return 1;
    }

    params.sequence_shift = 5u;
    status = cs_map_values(values, 4u, &params, events, 4u);
    if (expect_status(status, CS_OK, "wrapped shifted rhythm map")) {
        return 1;
    }

    if (events[0].value != 40u || events[1].value != 10u) {
        fprintf(stderr, "sequence shift should wrap by sequence length\n");
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

    if (test_scale_does_not_affect_percussive_modes()) {
        return 1;
    }

    if (test_root_note_is_reachable_in_each_mode()) {
        return 1;
    }

    if (test_hybrid_pads_follow_values_not_step_order()) {
        return 1;
    }

    if (test_note_range_controls()) {
        return 1;
    }

    if (test_density_controls_melodic_activity()) {
        return 1;
    }

    if (test_sequence_shift_rotates_events()) {
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
