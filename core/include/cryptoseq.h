#ifndef CRYPTOSEQ_H
#define CRYPTOSEQ_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CS_SHA256_DIGEST_SIZE 32u
#define CS_DEFAULT_EXPONENT 65537u
#define CS_MAX_SOURCE_BYTES ((size_t)256u * 1024u * 1024u)
#define CS_MAX_SEQUENCE_LENGTH ((size_t)4096u)
#define CS_MAX_PRIME_VALUE 65521u
#define CS_MAX_SCALE_LENGTH ((size_t)24u)
#define CS_MAX_DURATION_COUNT ((size_t)32u)
#define CS_MAX_RHYTHM_DIVISOR 1024u
#define CS_MAX_ACCENT_LEVELS 16u

typedef enum cs_status_t {
    CS_OK = 0,
    CS_ERROR_NULL,
    CS_ERROR_OUTPUT_TOO_SMALL,
    CS_ERROR_INVALID_PARAM,
    CS_ERROR_NOT_PRIME,
    CS_ERROR_ARITHMETIC_OVERFLOW,
    CS_ERROR_NOT_COPRIME,
    CS_ERROR_SOURCE_TOO_LARGE
} cs_status_t;

typedef enum cs_mode_t {
    CS_MODE_MELODY = 0,
    CS_MODE_RHYTHM = 1,
    CS_MODE_HYBRID = 2
} cs_mode_t;

typedef struct cs_params_t {
    uint32_t p;
    uint32_t q;
    uint32_t e;
    size_t length;
    size_t sequence_shift;
    cs_mode_t mode;

    uint8_t root_note;
    int8_t octave_min;
    uint8_t octave_count;
    uint8_t melody_note_min;
    uint8_t melody_note_max;
    uint8_t drum_pad_count;
    const int8_t *scale_intervals;
    size_t scale_len;

    const uint16_t *durations_ticks;
    size_t duration_count;

    uint8_t velocity_min;
    uint8_t velocity_max;
    uint16_t gate_min_permille;
    uint16_t gate_max_permille;

    uint32_t rhythm_divisor;
    uint32_t rhythm_threshold;
    uint8_t accent_levels;
    uint8_t rhythm_velocity_base;
    uint8_t rhythm_accent_step;
    uint8_t rhythm_jitter_range;
} cs_params_t;

typedef struct cs_event_t {
    uint32_t step_index;
    uint32_t value;
    uint8_t active;
    uint8_t note;
    uint8_t velocity;
    uint8_t accent;
    uint16_t duration_ticks;
    uint16_t gate_permille;
} cs_event_t;

const char *cs_status_string(cs_status_t status);

const int8_t *cs_major_scale(size_t *length);
const int8_t *cs_minor_scale(size_t *length);
const uint16_t *cs_default_durations(size_t *length);

cs_params_t cs_default_params(void);

cs_status_t cs_validate_params(const cs_params_t *params);

cs_status_t cs_source_digest(
    const uint8_t *source_bytes,
    size_t source_len,
    uint8_t digest[CS_SHA256_DIGEST_SIZE]
);

cs_status_t cs_generate_values_from_digest(
    const uint8_t source_digest[CS_SHA256_DIGEST_SIZE],
    const cs_params_t *params,
    uint32_t *values,
    size_t value_capacity
);

cs_status_t cs_map_values(
    const uint32_t *values,
    size_t value_count,
    const cs_params_t *params,
    cs_event_t *events,
    size_t event_capacity
);

cs_status_t cs_generate_from_digest(
    const uint8_t source_digest[CS_SHA256_DIGEST_SIZE],
    const cs_params_t *params,
    cs_event_t *events,
    size_t event_capacity
);

cs_status_t cs_generate_from_bytes(
    const uint8_t *source_bytes,
    size_t source_len,
    const cs_params_t *params,
    cs_event_t *events,
    size_t event_capacity
);

#ifdef __cplusplus
}
#endif

#endif
