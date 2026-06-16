#include "cryptoseq_max_model.h"

#include <string.h>

static const int8_t k_major_pentatonic_scale[] = {0, 2, 4, 7, 9};
static const int8_t k_minor_pentatonic_scale[] = {0, 3, 5, 7, 10};
static const int8_t k_chromatic_scale[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};

static cs_status_t validate_after_change(cs_max_model_t *model, cs_params_t previous)
{
    const cs_status_t status = cs_validate_params(&model->params);

    if (status != CS_OK) {
        model->params = previous;
        return status;
    }

    model->event_count = 0u;
    return CS_OK;
}

void cs_max_model_init(cs_max_model_t *model)
{
    if (model == NULL) {
        return;
    }

    memset(model, 0, sizeof(*model));
    model->params = cs_default_params();
}

cs_status_t cs_max_model_set_source_bytes(
    cs_max_model_t *model,
    const uint8_t *source_bytes,
    size_t source_len
)
{
    cs_status_t status;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    status = cs_source_digest(source_bytes, source_len, model->source_digest);
    if (status != CS_OK) {
        return status;
    }

    model->has_source = 1u;
    model->event_count = 0u;
    return CS_OK;
}

cs_status_t cs_max_model_set_primes(cs_max_model_t *model, uint32_t p, uint32_t q)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.p = p;
    model->params.q = q;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_exponent(cs_max_model_t *model, uint32_t e)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.e = e;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_length(cs_max_model_t *model, size_t length)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.length = length;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_mode(cs_max_model_t *model, const char *mode)
{
    cs_params_t previous;

    if (model == NULL || mode == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;

    if (strcmp(mode, "melody") == 0 || strcmp(mode, "melodic") == 0) {
        model->params.mode = CS_MODE_MELODY;
    } else if (strcmp(mode, "rhythm") == 0) {
        model->params.mode = CS_MODE_RHYTHM;
    } else if (strcmp(mode, "hybrid") == 0) {
        model->params.mode = CS_MODE_HYBRID;
    } else {
        return CS_ERROR_INVALID_PARAM;
    }

    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_scale(cs_max_model_t *model, const char *scale)
{
    cs_params_t previous;

    if (model == NULL || scale == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;

    if (strcmp(scale, "major") == 0) {
        model->params.scale_intervals = cs_major_scale(&model->params.scale_len);
    } else if (strcmp(scale, "minor") == 0) {
        model->params.scale_intervals = cs_minor_scale(&model->params.scale_len);
    } else if (strcmp(scale, "major_pentatonic") == 0) {
        model->params.scale_intervals = k_major_pentatonic_scale;
        model->params.scale_len = sizeof(k_major_pentatonic_scale) / sizeof(k_major_pentatonic_scale[0]);
    } else if (strcmp(scale, "minor_pentatonic") == 0) {
        model->params.scale_intervals = k_minor_pentatonic_scale;
        model->params.scale_len = sizeof(k_minor_pentatonic_scale) / sizeof(k_minor_pentatonic_scale[0]);
    } else if (strcmp(scale, "chromatic") == 0) {
        model->params.scale_intervals = k_chromatic_scale;
        model->params.scale_len = sizeof(k_chromatic_scale) / sizeof(k_chromatic_scale[0]);
    } else {
        return CS_ERROR_INVALID_PARAM;
    }

    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_root_note(cs_max_model_t *model, uint8_t root_note)
{
    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    if (root_note > 127u) {
        return CS_ERROR_INVALID_PARAM;
    }

    model->params.root_note = root_note;
    model->event_count = 0u;
    return CS_OK;
}

cs_status_t cs_max_model_set_velocity_range(cs_max_model_t *model, uint8_t min_velocity, uint8_t max_velocity)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.velocity_min = min_velocity;
    model->params.velocity_max = max_velocity;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_gate_range(cs_max_model_t *model, uint16_t min_permille, uint16_t max_permille)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.gate_min_permille = min_permille;
    model->params.gate_max_permille = max_permille;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_rhythm(cs_max_model_t *model, uint32_t divisor, uint32_t threshold)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.rhythm_divisor = divisor;
    model->params.rhythm_threshold = threshold;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_generate(cs_max_model_t *model)
{
    cs_status_t status;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    if (model->has_source == 0u) {
        return CS_ERROR_INVALID_PARAM;
    }

    status = cs_generate_from_digest(
        model->source_digest,
        &model->params,
        model->events,
        sizeof(model->events) / sizeof(model->events[0])
    );

    if (status != CS_OK) {
        model->event_count = 0u;
        return status;
    }

    model->event_count = model->params.length;
    return CS_OK;
}

size_t cs_max_model_event_count(const cs_max_model_t *model)
{
    if (model == NULL) {
        return 0u;
    }

    return model->event_count;
}

const cs_event_t *cs_max_model_event_at(const cs_max_model_t *model, size_t index)
{
    if (model == NULL || index >= model->event_count) {
        return NULL;
    }

    return &model->events[index];
}
