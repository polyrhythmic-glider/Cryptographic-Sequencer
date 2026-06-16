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

    status = cs_max_model_set_length(&model, CS_MAX_SEQUENCE_LENGTH + 1u);
    if (expect_status(status, CS_ERROR_INVALID_PARAM, "invalid length")) {
        return 1;
    }

    if (model.params.length != cs_default_params().length) {
        fprintf(stderr, "invalid setter should restore previous length\n");
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

    return 0;
}
