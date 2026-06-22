#include "cryptoseq.h"
#include "cryptoseq_internal.h"

#include <limits.h>
#include <string.h>

#define CS_STEP_SEED_SIZE (CS_SHA256_DIGEST_SIZE + 12u)

static const int8_t k_major_scale[] = {0, 2, 4, 5, 7, 9, 11};
static const int8_t k_minor_scale[] = {0, 2, 3, 5, 7, 8, 10};
static const uint16_t k_default_durations[] = {1, 2, 4, 8};

typedef struct cs_generation_context_t {
    uint8_t step_seed[CS_STEP_SEED_SIZE];
    uint32_t modulus;
    uint32_t exponent;
} cs_generation_context_t;

static uint32_t gcd_u64(uint64_t a, uint64_t b)
{
    while (b != 0u) {
        const uint64_t rem = a % b;
        a = b;
        b = rem;
    }
    return (uint32_t)a;
}

static int is_prime_u32(uint32_t value)
{
    uint32_t divisor;

    if (value < 2u) {
        return 0;
    }

    if (value == 2u || value == 3u) {
        return 1;
    }

    if ((value % 2u) == 0u || (value % 3u) == 0u) {
        return 0;
    }

    for (divisor = 5u; divisor <= (value / divisor); divisor += 6u) {
        if ((value % divisor) == 0u || (value % (divisor + 2u)) == 0u) {
            return 0;
        }
    }

    return 1;
}

static void store_be32(uint8_t out[4], uint32_t value)
{
    out[0] = (uint8_t)(value >> 24u);
    out[1] = (uint8_t)(value >> 16u);
    out[2] = (uint8_t)(value >> 8u);
    out[3] = (uint8_t)value;
}

static void store_be64(uint8_t out[8], uint64_t value)
{
    out[0] = (uint8_t)(value >> 56u);
    out[1] = (uint8_t)(value >> 48u);
    out[2] = (uint8_t)(value >> 40u);
    out[3] = (uint8_t)(value >> 32u);
    out[4] = (uint8_t)(value >> 24u);
    out[5] = (uint8_t)(value >> 16u);
    out[6] = (uint8_t)(value >> 8u);
    out[7] = (uint8_t)value;
}

static uint32_t load_be32(const uint8_t bytes[4])
{
    return ((uint32_t)bytes[0] << 24u) |
           ((uint32_t)bytes[1] << 16u) |
           ((uint32_t)bytes[2] << 8u) |
           (uint32_t)bytes[3];
}

static uint32_t digest_mod_u32(const uint8_t digest[CS_SHA256_DIGEST_SIZE], uint32_t modulus)
{
    size_t i;
    uint64_t acc = 0u;

    for (i = 0u; i < CS_SHA256_DIGEST_SIZE; i += 4u) {
        acc = ((acc << 32u) | load_be32(digest + i)) % modulus;
    }

    return (uint32_t)acc;
}

static uint32_t pow_mod_u32(uint32_t base, uint32_t exponent, uint32_t modulus)
{
    uint64_t result = 1u;
    uint64_t factor = (uint64_t)(base % modulus);

    while (exponent > 0u) {
        if ((exponent & 1u) != 0u) {
            result = (result * factor) % modulus;
        }

        factor = (factor * factor) % modulus;
        exponent >>= 1u;
    }

    return (uint32_t)result;
}

static uint8_t clamp_u8_int(int value, int min_value, int max_value)
{
    if (value < min_value) {
        return (uint8_t)min_value;
    }

    if (value > max_value) {
        return (uint8_t)max_value;
    }

    return (uint8_t)value;
}

static uint16_t select_duration(uint32_t value, const cs_params_t *params)
{
    if (params->duration_count == 0u) {
        return 0u;
    }

    return params->durations_ticks[value % params->duration_count];
}

static uint16_t map_gate(uint32_t value, const cs_params_t *params)
{
    const uint32_t quantizer = 1024u;
    const uint32_t span = (uint32_t)(params->gate_max_permille - params->gate_min_permille);
    return (uint16_t)(params->gate_min_permille + (((value % quantizer) * span) / (quantizer - 1u)));
}

static uint8_t positive_mod_12(int value)
{
    int result = value % 12;

    if (result < 0) {
        result += 12;
    }

    return (uint8_t)result;
}

static int note_is_in_scale(uint8_t note, const cs_params_t *params)
{
    const uint8_t relative_pitch = positive_mod_12((int)note - (int)params->root_note);
    size_t i;

    for (i = 0u; i < params->scale_len; ++i) {
        if (positive_mod_12((int)params->scale_intervals[i]) == relative_pitch) {
            return 1;
        }
    }

    return 0;
}

static uint32_t count_melodic_notes_in_range(const cs_params_t *params)
{
    uint32_t count = 0u;
    uint16_t note;

    for (note = params->melody_note_min; note <= params->melody_note_max; ++note) {
        if (note_is_in_scale((uint8_t)note, params)) {
            ++count;
        }
    }

    return count;
}

static uint8_t map_melodic_note(uint32_t value, const cs_params_t *params)
{
    const uint32_t note_count = count_melodic_notes_in_range(params);
    const uint32_t target = (note_count == 0u) ? 0u : (value % note_count);
    uint32_t index = 0u;
    uint16_t note;

    for (note = params->melody_note_min; note <= params->melody_note_max; ++note) {
        if (note_is_in_scale((uint8_t)note, params)) {
            if (index == target) {
                return (uint8_t)note;
            }
            ++index;
        }
    }

    return clamp_u8_int((int)params->root_note, (int)params->melody_note_min, (int)params->melody_note_max);
}

static uint8_t map_drum_rack_note(uint32_t value, const cs_params_t *params)
{
    const int note = (int)params->root_note + (int)(value % params->drum_pad_count);
    return clamp_u8_int(note, 0, 127);
}

static uint8_t map_melodic_velocity(uint32_t value, const cs_params_t *params)
{
    const uint32_t span = (uint32_t)params->velocity_max - (uint32_t)params->velocity_min + 1u;
    return (uint8_t)(params->velocity_min + (uint8_t)(value % span));
}

static uint8_t map_rhythm_active(uint32_t value, const cs_params_t *params)
{
    return ((value % params->rhythm_divisor) < params->rhythm_threshold) ? 1u : 0u;
}

static uint8_t map_rhythm_accent(uint32_t value, const cs_params_t *params)
{
    return (uint8_t)(value % params->accent_levels);
}

static uint8_t map_rhythm_velocity(uint32_t value, uint8_t accent, const cs_params_t *params)
{
    const uint32_t jitter = (params->rhythm_jitter_range == 0u) ? 0u : (value % params->rhythm_jitter_range);
    const uint32_t raw = (uint32_t)params->rhythm_velocity_base +
                         ((uint32_t)params->rhythm_accent_step * accent) +
                         jitter;

    return clamp_u8_int((int)raw, 1, 127);
}

static void init_generation_context(
    cs_generation_context_t *ctx,
    const uint8_t source_digest[CS_SHA256_DIGEST_SIZE],
    const cs_params_t *params
)
{
    memcpy(ctx->step_seed, source_digest, CS_SHA256_DIGEST_SIZE);
    store_be32(ctx->step_seed + CS_SHA256_DIGEST_SIZE, params->p);
    store_be32(ctx->step_seed + CS_SHA256_DIGEST_SIZE + 4u, params->q);
    store_be32(ctx->step_seed + CS_SHA256_DIGEST_SIZE + 8u, params->e);

    ctx->modulus = (uint32_t)((uint64_t)params->p * (uint64_t)params->q);
    ctx->exponent = params->e;
}

static uint32_t generate_value_for_index(
    const cs_generation_context_t *ctx,
    uint64_t index
)
{
    cs_sha256_t sha;
    uint8_t expanded_digest[CS_SHA256_DIGEST_SIZE];
    uint8_t encoded_u64[8];
    uint32_t m;

    cs_sha256_init(&sha);
    cs_sha256_update(&sha, ctx->step_seed, sizeof(ctx->step_seed));

    store_be64(encoded_u64, index);
    cs_sha256_update(&sha, encoded_u64, sizeof(encoded_u64));
    cs_sha256_final(&sha, expanded_digest);

    m = digest_mod_u32(expanded_digest, ctx->modulus);
    return pow_mod_u32(m, ctx->exponent, ctx->modulus);
}

static void map_melody_event(uint32_t index, uint32_t value, const cs_params_t *params, cs_event_t *event)
{
    event->step_index = index;
    event->value = value;
    event->active = map_rhythm_active(value, params);
    event->note = map_melodic_note(value, params);
    event->velocity = map_melodic_velocity(value, params);
    event->accent = 0u;
    event->duration_ticks = select_duration(value, params);
    event->gate_permille = map_gate(value, params);
}

static void map_rhythm_event(uint32_t index, uint32_t value, const cs_params_t *params, cs_event_t *event)
{
    const uint8_t accent = map_rhythm_accent(value, params);

    event->step_index = index;
    event->value = value;
    event->active = map_rhythm_active(value, params);
    event->note = params->root_note;
    event->velocity = map_rhythm_velocity(value, accent, params);
    event->accent = accent;
    event->duration_ticks = select_duration(value, params);
    event->gate_permille = map_gate(value, params);
}

static void map_hybrid_event(uint32_t index, uint32_t value, const cs_params_t *params, cs_event_t *event)
{
    const uint8_t accent = map_rhythm_accent(value, params);
    const uint8_t is_root_pad = ((value % params->drum_pad_count) == 0u) ? 1u : 0u;

    event->step_index = index;
    event->value = value;
    event->active = (is_root_pad && params->rhythm_threshold > 0u) ? 1u : map_rhythm_active(value, params);
    event->note = map_drum_rack_note(value, params);
    event->velocity = map_rhythm_velocity(value, accent, params);
    event->accent = accent;
    event->duration_ticks = select_duration(value, params);
    event->gate_permille = map_gate(value, params);
}

static cs_status_t map_values_for_mode(
    const uint32_t *values,
    size_t value_count,
    const cs_params_t *params,
    cs_event_t *events
)
{
    size_t i;

    switch (params->mode) {
    case CS_MODE_MELODY:
        for (i = 0u; i < value_count; ++i) {
            map_melody_event((uint32_t)i, values[i], params, &events[i]);
        }
        return CS_OK;
    case CS_MODE_RHYTHM:
        for (i = 0u; i < value_count; ++i) {
            map_rhythm_event((uint32_t)i, values[i], params, &events[i]);
        }
        return CS_OK;
    case CS_MODE_HYBRID:
        for (i = 0u; i < value_count; ++i) {
            map_hybrid_event((uint32_t)i, values[i], params, &events[i]);
        }
        return CS_OK;
    default:
        return CS_ERROR_INVALID_PARAM;
    }
}

static void apply_sequence_shift(cs_event_t *events, size_t length, size_t shift)
{
    cs_event_t shifted[CS_MAX_SEQUENCE_LENGTH];
    size_t i;
    const size_t normalized_shift = (length == 0u) ? 0u : (shift % length);

    if (normalized_shift == 0u) {
        return;
    }

    for (i = 0u; i < length; ++i) {
        const size_t source_index = (i + length - normalized_shift) % length;
        shifted[i] = events[source_index];
        shifted[i].step_index = (uint32_t)i;
    }

    memcpy(events, shifted, length * sizeof(events[0]));
}

static cs_status_t generate_events_for_mode(
    const cs_generation_context_t *ctx,
    const cs_params_t *params,
    cs_event_t *events
)
{
    size_t i;

    switch (params->mode) {
    case CS_MODE_MELODY:
        for (i = 0u; i < params->length; ++i) {
            const uint32_t value = generate_value_for_index(ctx, (uint64_t)i);
            map_melody_event((uint32_t)i, value, params, &events[i]);
        }
        return CS_OK;
    case CS_MODE_RHYTHM:
        for (i = 0u; i < params->length; ++i) {
            const uint32_t value = generate_value_for_index(ctx, (uint64_t)i);
            map_rhythm_event((uint32_t)i, value, params, &events[i]);
        }
        return CS_OK;
    case CS_MODE_HYBRID:
        for (i = 0u; i < params->length; ++i) {
            const uint32_t value = generate_value_for_index(ctx, (uint64_t)i);
            map_hybrid_event((uint32_t)i, value, params, &events[i]);
        }
        return CS_OK;
    default:
        return CS_ERROR_INVALID_PARAM;
    }
}

const char *cs_status_string(cs_status_t status)
{
    switch (status) {
    case CS_OK:
        return "ok";
    case CS_ERROR_NULL:
        return "null pointer";
    case CS_ERROR_OUTPUT_TOO_SMALL:
        return "output buffer too small";
    case CS_ERROR_INVALID_PARAM:
        return "invalid parameter";
    case CS_ERROR_NOT_PRIME:
        return "p and q must be prime";
    case CS_ERROR_ARITHMETIC_OVERFLOW:
        return "arithmetic overflow";
    case CS_ERROR_NOT_COPRIME:
        return "e must be coprime with phi(n)";
    case CS_ERROR_SOURCE_TOO_LARGE:
        return "source is too large";
    default:
        return "unknown error";
    }
}

const int8_t *cs_major_scale(size_t *length)
{
    if (length != NULL) {
        *length = sizeof(k_major_scale) / sizeof(k_major_scale[0]);
    }

    return k_major_scale;
}

const int8_t *cs_minor_scale(size_t *length)
{
    if (length != NULL) {
        *length = sizeof(k_minor_scale) / sizeof(k_minor_scale[0]);
    }

    return k_minor_scale;
}

const uint16_t *cs_default_durations(size_t *length)
{
    if (length != NULL) {
        *length = sizeof(k_default_durations) / sizeof(k_default_durations[0]);
    }

    return k_default_durations;
}

cs_params_t cs_default_params(void)
{
    cs_params_t params;

    memset(&params, 0, sizeof(params));
    params.p = 251u;
    params.q = 257u;
    params.e = CS_DEFAULT_EXPONENT;
    params.length = 16u;
    params.sequence_shift = 0u;
    params.mode = CS_MODE_HYBRID;
    params.root_note = 60u;
    params.octave_min = 0;
    params.octave_count = 2u;
    params.melody_note_min = 60u;
    params.melody_note_max = 84u;
    params.drum_pad_count = 16u;
    params.scale_intervals = cs_major_scale(&params.scale_len);
    params.durations_ticks = cs_default_durations(&params.duration_count);
    params.velocity_min = 48u;
    params.velocity_max = 112u;
    params.gate_min_permille = 100u;
    params.gate_max_permille = 900u;
    params.rhythm_divisor = 16u;
    params.rhythm_threshold = 8u;
    params.accent_levels = 4u;
    params.rhythm_velocity_base = 64u;
    params.rhythm_accent_step = 12u;
    params.rhythm_jitter_range = 8u;

    return params;
}

cs_status_t cs_validate_params(const cs_params_t *params)
{
    uint64_t n;
    uint64_t phi;

    if (params == NULL) {
        return CS_ERROR_NULL;
    }

    if (params->length == 0u ||
        params->length > CS_MAX_SEQUENCE_LENGTH ||
        params->e == 0u) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (params->mode != CS_MODE_MELODY &&
        params->mode != CS_MODE_RHYTHM &&
        params->mode != CS_MODE_HYBRID) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (params->p > CS_MAX_PRIME_VALUE || params->q > CS_MAX_PRIME_VALUE) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (!is_prime_u32(params->p) || !is_prime_u32(params->q)) {
        return CS_ERROR_NOT_PRIME;
    }

    if (params->p == params->q) {
        return CS_ERROR_INVALID_PARAM;
    }

    n = (uint64_t)params->p * (uint64_t)params->q;
    if (n > UINT32_MAX || n < 2u) {
        return CS_ERROR_ARITHMETIC_OVERFLOW;
    }

    phi = (uint64_t)(params->p - 1u) * (uint64_t)(params->q - 1u);
    if (gcd_u64(params->e, phi) != 1u) {
        return CS_ERROR_NOT_COPRIME;
    }

    if (params->root_note > 127u) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (params->scale_len > CS_MAX_SCALE_LENGTH ||
        (params->scale_len > 0u && params->scale_intervals == NULL)) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (params->mode == CS_MODE_MELODY) {
        if (params->scale_intervals == NULL ||
            params->scale_len == 0u ||
            params->octave_count == 0u ||
            params->melody_note_min > 127u ||
            params->melody_note_max > 127u ||
            params->melody_note_min > params->melody_note_max) {
            return CS_ERROR_INVALID_PARAM;
        }

        if (count_melodic_notes_in_range(params) == 0u) {
            return CS_ERROR_INVALID_PARAM;
        }
    }

    if (params->durations_ticks == NULL ||
        params->duration_count == 0u ||
        params->duration_count > CS_MAX_DURATION_COUNT) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (params->velocity_min < 1u ||
        params->velocity_max > 127u ||
        params->velocity_min > params->velocity_max) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (params->gate_min_permille > params->gate_max_permille ||
        params->gate_max_permille > 1000u) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (params->rhythm_divisor == 0u ||
        params->rhythm_divisor > CS_MAX_RHYTHM_DIVISOR ||
        params->rhythm_threshold > params->rhythm_divisor ||
        params->accent_levels == 0u ||
        params->accent_levels > CS_MAX_ACCENT_LEVELS) {
        return CS_ERROR_INVALID_PARAM;
    }

    if (params->mode == CS_MODE_HYBRID) {
        if (params->drum_pad_count == 0u ||
            params->drum_pad_count > 128u ||
            (uint16_t)params->root_note + (uint16_t)params->drum_pad_count - 1u > 127u) {
            return CS_ERROR_INVALID_PARAM;
        }
    }

    return CS_OK;
}

cs_status_t cs_source_digest(
    const uint8_t *source_bytes,
    size_t source_len,
    uint8_t digest[CS_SHA256_DIGEST_SIZE]
)
{
    cs_sha256_t sha;

    if (digest == NULL) {
        return CS_ERROR_NULL;
    }

    if (source_len > 0u && source_bytes == NULL) {
        return CS_ERROR_NULL;
    }

    if (source_len > CS_MAX_SOURCE_BYTES) {
        return CS_ERROR_SOURCE_TOO_LARGE;
    }

    cs_sha256_init(&sha);
    cs_sha256_update(&sha, source_bytes, source_len);
    cs_sha256_final(&sha, digest);

    return CS_OK;
}

cs_status_t cs_generate_values_from_digest(
    const uint8_t source_digest[CS_SHA256_DIGEST_SIZE],
    const cs_params_t *params,
    uint32_t *values,
    size_t value_capacity
)
{
    cs_status_t status;
    cs_generation_context_t ctx;
    size_t i;

    if (source_digest == NULL || params == NULL || values == NULL) {
        return CS_ERROR_NULL;
    }

    status = cs_validate_params(params);
    if (status != CS_OK) {
        return status;
    }

    if (value_capacity < params->length) {
        return CS_ERROR_OUTPUT_TOO_SMALL;
    }

    init_generation_context(&ctx, source_digest, params);

    for (i = 0u; i < params->length; ++i) {
        values[i] = generate_value_for_index(&ctx, (uint64_t)i);
    }

    return CS_OK;
}

cs_status_t cs_map_values(
    const uint32_t *values,
    size_t value_count,
    const cs_params_t *params,
    cs_event_t *events,
    size_t event_capacity
)
{
    cs_status_t status;

    if (values == NULL || params == NULL || events == NULL) {
        return CS_ERROR_NULL;
    }

    status = cs_validate_params(params);
    if (status != CS_OK) {
        return status;
    }

    if (value_count > event_capacity) {
        return CS_ERROR_OUTPUT_TOO_SMALL;
    }

    if (value_count > UINT32_MAX) {
        return CS_ERROR_INVALID_PARAM;
    }

    status = map_values_for_mode(values, value_count, params, events);
    if (status == CS_OK) {
        apply_sequence_shift(events, value_count, params->sequence_shift);
    }

    return status;
}

cs_status_t cs_generate_from_digest(
    const uint8_t source_digest[CS_SHA256_DIGEST_SIZE],
    const cs_params_t *params,
    cs_event_t *events,
    size_t event_capacity
)
{
    cs_status_t status;
    cs_generation_context_t ctx;

    if (source_digest == NULL || params == NULL || events == NULL) {
        return CS_ERROR_NULL;
    }

    status = cs_validate_params(params);
    if (status != CS_OK) {
        return status;
    }

    if (event_capacity < params->length) {
        return CS_ERROR_OUTPUT_TOO_SMALL;
    }

    init_generation_context(&ctx, source_digest, params);
    status = generate_events_for_mode(&ctx, params, events);
    if (status == CS_OK) {
        apply_sequence_shift(events, params->length, params->sequence_shift);
    }

    return status;
}

cs_status_t cs_generate_from_bytes(
    const uint8_t *source_bytes,
    size_t source_len,
    const cs_params_t *params,
    cs_event_t *events,
    size_t event_capacity
)
{
    cs_status_t status;
    uint8_t digest[CS_SHA256_DIGEST_SIZE];
    cs_generation_context_t ctx;

    if (params == NULL || events == NULL) {
        return CS_ERROR_NULL;
    }

    status = cs_validate_params(params);
    if (status != CS_OK) {
        return status;
    }

    if (event_capacity < params->length) {
        return CS_ERROR_OUTPUT_TOO_SMALL;
    }

    status = cs_source_digest(source_bytes, source_len, digest);
    if (status != CS_OK) {
        return status;
    }

    init_generation_context(&ctx, digest, params);
    status = generate_events_for_mode(&ctx, params, events);
    if (status == CS_OK) {
        apply_sequence_shift(events, params->length, params->sequence_shift);
    }

    return status;
}
