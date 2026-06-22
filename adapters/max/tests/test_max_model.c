#include "cryptoseq_max_model.h"

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

static int test_max_model_generation(void)
{
    static const uint8_t source[] = "max model source";
    cs_max_model_t model;
    cs_status_t status;
    const cs_event_t *event;

    cs_max_model_init(&model);

    status = cs_max_model_set_source_bytes(&model, source, sizeof(source) - 1u);
    if (expect_status(status, CS_OK, "set source")) {
        return 1;
    }

    status = cs_max_model_set_primes(&model, 251u, 257u);
    if (expect_status(status, CS_OK, "set primes")) {
        return 1;
    }

    status = cs_max_model_set_length(&model, 8u);
    if (expect_status(status, CS_OK, "set length")) {
        return 1;
    }

    status = cs_max_model_set_mode(&model, "hybrid");
    if (expect_status(status, CS_OK, "set mode")) {
        return 1;
    }

    status = cs_max_model_set_mode(&model, "melodic");
    if (expect_status(status, CS_OK, "set melodic alias")) {
        return 1;
    }

    status = cs_max_model_set_mode(&model, "hybrid");
    if (expect_status(status, CS_OK, "restore hybrid mode")) {
        return 1;
    }

    status = cs_max_model_set_scale(&model, "minor_pentatonic");
    if (expect_status(status, CS_OK, "set scale")) {
        return 1;
    }

    status = cs_max_model_set_exponent(&model, CS_DEFAULT_EXPONENT);
    if (expect_status(status, CS_OK, "set exponent")) {
        return 1;
    }

    status = cs_max_model_set_rhythm(&model, 16u, 8u);
    if (expect_status(status, CS_OK, "set rhythm")) {
        return 1;
    }

    status = cs_max_model_set_melody_range(&model, 60u, 84u);
    if (expect_status(status, CS_OK, "set melody range")) {
        return 1;
    }

    status = cs_max_model_set_drum_pad_count(&model, 16u);
    if (expect_status(status, CS_OK, "set drum pad count")) {
        return 1;
    }

    status = cs_max_model_generate(&model);
    if (expect_status(status, CS_OK, "generate")) {
        return 1;
    }

    if (cs_max_model_event_count(&model) != 8u) {
        fprintf(stderr, "event count mismatch\n");
        return 1;
    }

    event = cs_max_model_event_at(&model, 0u);
    if (event == NULL || event->note > 127u || event->velocity < 1u || event->velocity > 127u) {
        fprintf(stderr, "first event invalid\n");
        return 1;
    }

    if (cs_max_model_event_at(&model, 8u) != NULL) {
        fprintf(stderr, "out-of-range event should be null\n");
        return 1;
    }

    return 0;
}

static int test_max_model_validation(void)
{
    cs_max_model_t model;
    cs_status_t status;

    cs_max_model_init(&model);

    status = cs_max_model_generate(&model);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "generate without source")) {
        return 1;
    }

    status = cs_max_model_set_mode(&model, "wrong");
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "invalid mode")) {
        return 1;
    }

    status = cs_max_model_set_scale(&model, "wrong");
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "invalid scale")) {
        return 1;
    }

    status = cs_max_model_set_length(&model, CS_MAX_SEQUENCE_LENGTH + 1u);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "invalid length")) {
        return 1;
    }

    status = cs_max_model_set_mode(&model, "melodic");
    if (expect_status(status, CS_OK, "switch to melodic")) {
        return 1;
    }

    status = cs_max_model_set_melody_range(&model, 61u, 61u);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "invalid melody range")) {
        return 1;
    }

    status = cs_max_model_set_mode(&model, "hybrid");
    if (expect_status(status, CS_OK, "switch to hybrid")) {
        return 1;
    }

    status = cs_max_model_set_root_note(&model, 120u);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "invalid hybrid root for pad count")) {
        return 1;
    }

    if (model.params.length != cs_default_params().length) {
        fprintf(stderr, "invalid setter should restore previous length\n");
        return 1;
    }

    return 0;
}

static int test_max_model_atomic_rsa(void)
{
    cs_max_model_t model;
    cs_status_t status;

    cs_max_model_init(&model);

    status = cs_max_model_set_rsa(&model, 251u, 257u, 3u);
    if (expect_status(status, CS_OK, "set initial rsa")) {
        return 1;
    }

    status = cs_max_model_set_primes(&model, 271u, 277u);
    if (expect_status(status, CS_ERROR_NOT_COPRIME, "separate prime change should reject stale e")) {
        return 1;
    }

    status = cs_max_model_set_rsa(&model, 271u, 277u, 17u);
    if (expect_status(status, CS_OK, "atomic rsa change")) {
        return 1;
    }

    if (model.params.p != 271u || model.params.q != 277u || model.params.e != 17u) {
        fprintf(stderr, "atomic rsa did not update all values\n");
        return 1;
    }

    return 0;
}

static int test_max_model_source_digest(void)
{
    static const uint8_t source[] = "digest source";
    uint8_t digest[CS_SHA256_DIGEST_SIZE];
    cs_max_model_t from_bytes;
    cs_max_model_t from_digest;
    cs_status_t status;
    const cs_event_t *byte_event;
    const cs_event_t *digest_event;

    status = cs_source_digest(source, sizeof(source) - 1u, digest);
    if (expect_status(status, CS_OK, "source digest")) {
        return 1;
    }

    cs_max_model_init(&from_bytes);
    cs_max_model_init(&from_digest);

    status = cs_max_model_set_source_bytes(&from_bytes, source, sizeof(source) - 1u);
    if (expect_status(status, CS_OK, "set source bytes")) {
        return 1;
    }

    status = cs_max_model_set_source_digest(&from_digest, digest);
    if (expect_status(status, CS_OK, "set source digest")) {
        return 1;
    }

    status = cs_max_model_generate(&from_bytes);
    if (expect_status(status, CS_OK, "generate from bytes")) {
        return 1;
    }

    status = cs_max_model_generate(&from_digest);
    if (expect_status(status, CS_OK, "generate from digest")) {
        return 1;
    }

    byte_event = cs_max_model_event_at(&from_bytes, 0u);
    digest_event = cs_max_model_event_at(&from_digest, 0u);
    if (byte_event == NULL || digest_event == NULL || byte_event->value != digest_event->value) {
        fprintf(stderr, "digest-backed source should match byte-backed source\n");
        return 1;
    }

    return 0;
}

static int test_max_model_custom_scale_intervals(void)
{
    static const int8_t whole_tone[] = {0, 2, 4, 6, 8, 10};
    cs_max_model_t model;
    cs_status_t status;
    size_t i;

    cs_max_model_init(&model);

    status = cs_max_model_set_mode(&model, "melodic");
    if (expect_status(status, CS_OK, "switch to melodic for custom scale")) {
        return 1;
    }

    status = cs_max_model_set_scale_intervals(
        &model,
        whole_tone,
        sizeof(whole_tone) / sizeof(whole_tone[0])
    );
    if (expect_status(status, CS_OK, "set custom scale intervals")) {
        return 1;
    }

    if (model.params.scale_intervals != model.scale_intervals ||
        model.params.scale_len != sizeof(whole_tone) / sizeof(whole_tone[0])) {
        fprintf(stderr, "custom scale was not installed on model params\n");
        return 1;
    }

    for (i = 0u; i < model.params.scale_len; ++i) {
        if (model.params.scale_intervals[i] != whole_tone[i]) {
            fprintf(stderr, "custom scale interval mismatch\n");
            return 1;
        }
    }

    status = cs_max_model_set_scale_intervals(&model, whole_tone, 0u);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "empty custom scale")) {
        return 1;
    }

    return 0;
}

static int test_max_model_sequence_shift(void)
{
    static const uint8_t source[] = "shift source";
    cs_max_model_t unshifted;
    cs_max_model_t shifted;
    cs_status_t status;
    uint32_t expected_wrapped_value;
    const cs_event_t *event;

    cs_max_model_init(&unshifted);
    cs_max_model_init(&shifted);

    status = cs_max_model_set_source_bytes(&unshifted, source, sizeof(source) - 1u);
    if (expect_status(status, CS_OK, "set unshifted source")) {
        return 1;
    }

    status = cs_max_model_set_source_bytes(&shifted, source, sizeof(source) - 1u);
    if (expect_status(status, CS_OK, "set shifted source")) {
        return 1;
    }

    status = cs_max_model_set_length(&unshifted, 4u);
    if (expect_status(status, CS_OK, "set unshifted length")) {
        return 1;
    }

    status = cs_max_model_set_length(&shifted, 4u);
    if (expect_status(status, CS_OK, "set shifted length")) {
        return 1;
    }

    status = cs_max_model_generate(&unshifted);
    if (expect_status(status, CS_OK, "generate unshifted")) {
        return 1;
    }

    expected_wrapped_value = cs_max_model_event_at(&unshifted, 3u)->value;

    status = cs_max_model_set_sequence_shift(&shifted, 1u);
    if (expect_status(status, CS_OK, "set sequence shift")) {
        return 1;
    }

    status = cs_max_model_generate(&shifted);
    if (expect_status(status, CS_OK, "generate shifted")) {
        return 1;
    }

    event = cs_max_model_event_at(&shifted, 0u);
    if (event == NULL || event->step_index != 0u || event->value != expected_wrapped_value) {
        fprintf(stderr, "max model shift should rotate generated events\n");
        return 1;
    }

    return 0;
}

int main(void)
{
    if (test_max_model_generation()) {
        return 1;
    }

    if (test_max_model_validation()) {
        return 1;
    }

    if (test_max_model_atomic_rsa()) {
        return 1;
    }

    if (test_max_model_source_digest()) {
        return 1;
    }

    if (test_max_model_custom_scale_intervals()) {
        return 1;
    }

    if (test_max_model_sequence_shift()) {
        return 1;
    }

    return 0;
}
