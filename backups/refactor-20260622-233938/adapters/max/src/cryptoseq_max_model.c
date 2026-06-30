#include "cryptoseq_max_model.h"

#include <string.h>

static const int8_t k_major_pentatonic_scale[] = {0, 2, 4, 7, 9};
static const int8_t k_minor_pentatonic_scale[] = {0, 3, 5, 7, 10};
static const int8_t k_chromatic_scale[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};

static uint32_t mix_u32(uint32_t value)
{
    value ^= value >> 16u;
    value *= 0x7feb352du;
    value ^= value >> 15u;
    value *= 0x846ca68bu;
    value ^= value >> 16u;
    return value;
}

static uint8_t pattern_lock_for_target(const char *target)
{
    if (target == NULL) {
        return 0u;
    }

    if (strcmp(target, "pitch") == 0 || strcmp(target, "note") == 0) {
        return CS_MAX_LOCK_PITCH;
    }
    if (strcmp(target, "rhythm") == 0 || strcmp(target, "active") == 0) {
        return CS_MAX_LOCK_RHYTHM;
    }
    if (strcmp(target, "velocity") == 0 || strcmp(target, "vel") == 0) {
        return CS_MAX_LOCK_VELOCITY;
    }
    if (strcmp(target, "gate") == 0) {
        return CS_MAX_LOCK_GATE;
    }
    if (strcmp(target, "all") == 0) {
        return (uint8_t)(
            CS_MAX_LOCK_PITCH |
            CS_MAX_LOCK_RHYTHM |
            CS_MAX_LOCK_VELOCITY |
            CS_MAX_LOCK_GATE
        );
    }

    return 0u;
}

static int morph_mode_from_string(const char *mode, cs_max_morph_mode_t *out)
{
    if (mode == NULL || out == NULL) {
        return 0;
    }

    if (strcmp(mode, "all") == 0 || strcmp(mode, "full") == 0) {
        *out = CS_MAX_MORPH_ALL;
        return 1;
    }
    if (strcmp(mode, "pitch") == 0 || strcmp(mode, "note") == 0) {
        *out = CS_MAX_MORPH_PITCH;
        return 1;
    }
    if (strcmp(mode, "rhythm") == 0 || strcmp(mode, "active") == 0) {
        *out = CS_MAX_MORPH_RHYTHM;
        return 1;
    }
    if (strcmp(mode, "velocity") == 0 || strcmp(mode, "vel") == 0) {
        *out = CS_MAX_MORPH_VELOCITY;
        return 1;
    }

    return 0;
}

static cs_status_t validate_after_change(cs_max_model_t *model, cs_params_t previous)
{
    const cs_status_t status = cs_validate_params(&model->params);

    if (status != CS_OK) {
        model->params = previous;
        return status;
    }

    if (model->event_count > 0u) {
        memcpy(
            model->previous_events,
            model->events,
            model->event_count * sizeof(model->previous_events[0])
        );
        model->previous_event_count = model->event_count;
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
    model->morph_scene = 1u;
    model->morph_mode = CS_MAX_MORPH_ALL;
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

    if (model->event_count > 0u) {
        memcpy(
            model->previous_events,
            model->events,
            model->event_count * sizeof(model->previous_events[0])
        );
        model->previous_event_count = model->event_count;
    }
    model->has_source = 1u;
    model->event_count = 0u;
    return CS_OK;
}

cs_status_t cs_max_model_set_source_digest(
    cs_max_model_t *model,
    const uint8_t source_digest[CS_SHA256_DIGEST_SIZE]
)
{
    if (model == NULL || source_digest == NULL) {
        return CS_ERROR_NULL;
    }

    memcpy(model->source_digest, source_digest, CS_SHA256_DIGEST_SIZE);
    if (model->event_count > 0u) {
        memcpy(
            model->previous_events,
            model->events,
            model->event_count * sizeof(model->previous_events[0])
        );
        model->previous_event_count = model->event_count;
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

cs_status_t cs_max_model_set_rsa(cs_max_model_t *model, uint32_t p, uint32_t q, uint32_t e)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.p = p;
    model->params.q = q;
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

cs_status_t cs_max_model_set_sequence_shift(cs_max_model_t *model, size_t shift)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.sequence_shift = shift;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_scene(cs_max_model_t *model, uint8_t scene)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.scene = scene;
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

cs_status_t cs_max_model_set_scale_intervals(
    cs_max_model_t *model,
    const int8_t *intervals,
    size_t interval_count
)
{
    cs_params_t previous;
    size_t i;

    if (model == NULL || intervals == NULL) {
        return CS_ERROR_NULL;
    }

    if (interval_count == 0u || interval_count > CS_MAX_SCALE_LENGTH) {
        return CS_ERROR_INVALID_PARAM;
    }

    previous = model->params;
    for (i = 0u; i < interval_count; ++i) {
        model->scale_intervals[i] = (int8_t)(intervals[i] % 12);
        if (model->scale_intervals[i] < 0) {
            model->scale_intervals[i] = (int8_t)(model->scale_intervals[i] + 12);
        }
    }
    model->params.scale_intervals = model->scale_intervals;
    model->params.scale_len = interval_count;

    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_root_note(cs_max_model_t *model, uint8_t root_note)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    if (root_note > 127u) {
        return CS_ERROR_INVALID_PARAM;
    }

    previous = model->params;
    model->params.root_note = root_note;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_melody_range(cs_max_model_t *model, uint8_t low_note, uint8_t high_note)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.melody_note_min = low_note;
    model->params.melody_note_max = high_note;
    return validate_after_change(model, previous);
}

cs_status_t cs_max_model_set_drum_pad_count(cs_max_model_t *model, uint8_t pad_count)
{
    cs_params_t previous;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    previous = model->params;
    model->params.drum_pad_count = pad_count;
    return validate_after_change(model, previous);
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

cs_status_t cs_max_model_set_pattern_lock(
    cs_max_model_t *model,
    const char *target,
    uint8_t enabled
)
{
    const uint8_t flag = pattern_lock_for_target(target);

    if (model == NULL || target == NULL) {
        return CS_ERROR_NULL;
    }

    if (flag == 0u) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (enabled != 0u) {
        model->pattern_locks = (uint8_t)(model->pattern_locks | flag);
    } else {
        model->pattern_locks = (uint8_t)(model->pattern_locks & (uint8_t)(~flag));
    }

    return CS_OK;
}

cs_status_t cs_max_model_set_morph_amount(cs_max_model_t *model, uint8_t amount)
{
    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    if (amount > 100u) {
        return CS_ERROR_INVALID_PARAM;
    }

    model->morph_amount = amount;
    model->event_count = 0u;
    return CS_OK;
}

cs_status_t cs_max_model_set_morph_scene(cs_max_model_t *model, uint8_t scene)
{
    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    if (scene > CS_MAX_SCENE_VALUE) {
        return CS_ERROR_INVALID_PARAM;
    }

    model->morph_scene = scene;
    model->event_count = 0u;
    return CS_OK;
}

cs_status_t cs_max_model_set_morph_mode(cs_max_model_t *model, const char *mode)
{
    cs_max_morph_mode_t parsed;

    if (model == NULL || mode == NULL) {
        return CS_ERROR_NULL;
    }

    if (!morph_mode_from_string(mode, &parsed)) {
        return CS_ERROR_INVALID_PARAM;
    }

    model->morph_mode = parsed;
    model->event_count = 0u;
    return CS_OK;
}

static void apply_morph(
    cs_max_model_t *model,
    const cs_event_t *morph_events,
    size_t event_count
)
{
    size_t i;

    if (model->morph_amount == 0u || morph_events == NULL) {
        return;
    }

    for (i = 0u; i < event_count; ++i) {
        const cs_event_t *from_b = &morph_events[i];
        cs_event_t *event = &model->events[i];
        const uint32_t selector = mix_u32(
            event->value ^
            (from_b->value * 0x9e3779b9u) ^
            ((uint32_t)i * 0x85ebca6bu) ^
            ((uint32_t)model->params.scene << 8u) ^
            (uint32_t)model->morph_scene
        ) % 100u;

        if (model->morph_amount < 100u && selector >= model->morph_amount) {
            continue;
        }

        switch (model->morph_mode) {
        case CS_MAX_MORPH_ALL:
            *event = *from_b;
            event->step_index = (uint32_t)i;
            break;
        case CS_MAX_MORPH_PITCH:
            event->note = from_b->note;
            break;
        case CS_MAX_MORPH_RHYTHM:
            event->active = from_b->active;
            event->accent = from_b->accent;
            event->duration_ticks = from_b->duration_ticks;
            break;
        case CS_MAX_MORPH_VELOCITY:
            event->velocity = from_b->velocity;
            break;
        default:
            break;
        }
    }
}

static void apply_pattern_locks(
    cs_max_model_t *model,
    const cs_event_t *previous_events,
    size_t previous_count
)
{
    size_t i;
    const size_t event_count = model->event_count < previous_count ? model->event_count : previous_count;

    if (model->pattern_locks == 0u || previous_events == NULL || previous_count == 0u) {
        return;
    }

    for (i = 0u; i < event_count; ++i) {
        const cs_event_t *locked = &previous_events[i];
        cs_event_t *event = &model->events[i];

        if ((model->pattern_locks & CS_MAX_LOCK_PITCH) != 0u) {
            event->note = locked->note;
        }
        if ((model->pattern_locks & CS_MAX_LOCK_RHYTHM) != 0u) {
            event->active = locked->active;
            event->accent = locked->accent;
            event->duration_ticks = locked->duration_ticks;
        }
        if ((model->pattern_locks & CS_MAX_LOCK_VELOCITY) != 0u) {
            event->velocity = locked->velocity;
        }
        if ((model->pattern_locks & CS_MAX_LOCK_GATE) != 0u) {
            event->gate_permille = locked->gate_permille;
        }
    }
}

cs_status_t cs_max_model_generate(cs_max_model_t *model)
{
    cs_status_t status;
    cs_event_t previous_events[CS_MAX_SEQUENCE_LENGTH];
    cs_event_t morph_events[CS_MAX_SEQUENCE_LENGTH];
    size_t previous_count = 0u;
    cs_params_t morph_params;

    if (model == NULL) {
        return CS_ERROR_NULL;
    }

    if (model->has_source == 0u) {
        return CS_ERROR_INVALID_PARAM;
    }

    previous_count = model->event_count;
    if (previous_count > 0u) {
        memcpy(previous_events, model->events, previous_count * sizeof(previous_events[0]));
    } else if (model->previous_event_count > 0u) {
        previous_count = model->previous_event_count;
        memcpy(previous_events, model->previous_events, previous_count * sizeof(previous_events[0]));
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
    if (model->morph_amount > 0u) {
        morph_params = model->params;
        morph_params.scene = model->morph_scene;
        status = cs_generate_from_digest(
            model->source_digest,
            &morph_params,
            morph_events,
            sizeof(morph_events) / sizeof(morph_events[0])
        );
        if (status != CS_OK) {
            model->event_count = 0u;
            return status;
        }
        apply_morph(model, morph_events, model->event_count);
    }
    apply_pattern_locks(model, previous_events, previous_count);
    if (model->event_count > 0u) {
        memcpy(
            model->previous_events,
            model->events,
            model->event_count * sizeof(model->previous_events[0])
        );
        model->previous_event_count = model->event_count;
    }
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
