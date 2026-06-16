#ifndef CRYPTOSEQ_MAX_MODEL_H
#define CRYPTOSEQ_MAX_MODEL_H

#include "cryptoseq.h"

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct cs_max_model_t {
    cs_params_t params;
    uint8_t source_digest[CS_SHA256_DIGEST_SIZE];
    uint8_t has_source;
    cs_event_t events[CS_MAX_SEQUENCE_LENGTH];
    size_t event_count;
} cs_max_model_t;

void cs_max_model_init(cs_max_model_t *model);

cs_status_t cs_max_model_set_source_bytes(
    cs_max_model_t *model,
    const uint8_t *source_bytes,
    size_t source_len
);

cs_status_t cs_max_model_set_primes(cs_max_model_t *model, uint32_t p, uint32_t q);
cs_status_t cs_max_model_set_exponent(cs_max_model_t *model, uint32_t e);
cs_status_t cs_max_model_set_length(cs_max_model_t *model, size_t length);
cs_status_t cs_max_model_set_mode(cs_max_model_t *model, const char *mode);
cs_status_t cs_max_model_set_root_note(cs_max_model_t *model, uint8_t root_note);
cs_status_t cs_max_model_set_velocity_range(cs_max_model_t *model, uint8_t min_velocity, uint8_t max_velocity);
cs_status_t cs_max_model_set_gate_range(cs_max_model_t *model, uint16_t min_permille, uint16_t max_permille);
cs_status_t cs_max_model_set_rhythm(cs_max_model_t *model, uint32_t divisor, uint32_t threshold);

cs_status_t cs_max_model_generate(cs_max_model_t *model);

size_t cs_max_model_event_count(const cs_max_model_t *model);
const cs_event_t *cs_max_model_event_at(const cs_max_model_t *model, size_t index);

#ifdef __cplusplus
}
#endif

#endif
