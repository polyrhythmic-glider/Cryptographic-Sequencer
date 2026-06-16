#ifndef CRYPTOSEQ_INTERNAL_H
#define CRYPTOSEQ_INTERNAL_H

#include <stddef.h>
#include <stdint.h>

typedef struct cs_sha256_t {
    uint32_t state[8];
    uint64_t bit_len;
    uint8_t buffer[64];
    size_t buffer_len;
} cs_sha256_t;

void cs_sha256_init(cs_sha256_t *ctx);
void cs_sha256_update(cs_sha256_t *ctx, const uint8_t *data, size_t len);
void cs_sha256_final(cs_sha256_t *ctx, uint8_t digest[32]);

#endif
