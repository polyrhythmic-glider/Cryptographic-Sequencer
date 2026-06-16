#include "cryptoseq_internal.h"

#include <string.h>

#define ROTR32(x, n) (((x) >> (n)) | ((x) << (32u - (n))))
#define CH(x, y, z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define BSIG0(x) (ROTR32((x), 2u) ^ ROTR32((x), 13u) ^ ROTR32((x), 22u))
#define BSIG1(x) (ROTR32((x), 6u) ^ ROTR32((x), 11u) ^ ROTR32((x), 25u))
#define SSIG0(x) (ROTR32((x), 7u) ^ ROTR32((x), 18u) ^ ((x) >> 3u))
#define SSIG1(x) (ROTR32((x), 17u) ^ ROTR32((x), 19u) ^ ((x) >> 10u))

static const uint32_t k_sha256[64] = {
    0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u,
    0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,
    0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u,
    0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,
    0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
    0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
    0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
    0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,
    0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u,
    0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
    0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u,
    0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,
    0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
    0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
    0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
    0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u
};

static uint32_t load_be32(const uint8_t *bytes)
{
    return ((uint32_t)bytes[0] << 24u) |
           ((uint32_t)bytes[1] << 16u) |
           ((uint32_t)bytes[2] << 8u) |
           (uint32_t)bytes[3];
}

static void store_be32(uint8_t *bytes, uint32_t value)
{
    bytes[0] = (uint8_t)(value >> 24u);
    bytes[1] = (uint8_t)(value >> 16u);
    bytes[2] = (uint8_t)(value >> 8u);
    bytes[3] = (uint8_t)value;
}

static void store_be64(uint8_t *bytes, uint64_t value)
{
    bytes[0] = (uint8_t)(value >> 56u);
    bytes[1] = (uint8_t)(value >> 48u);
    bytes[2] = (uint8_t)(value >> 40u);
    bytes[3] = (uint8_t)(value >> 32u);
    bytes[4] = (uint8_t)(value >> 24u);
    bytes[5] = (uint8_t)(value >> 16u);
    bytes[6] = (uint8_t)(value >> 8u);
    bytes[7] = (uint8_t)value;
}

static void sha256_transform(cs_sha256_t *ctx, const uint8_t block[64])
{
    uint32_t w[64];
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
    uint32_t e;
    uint32_t f;
    uint32_t g;
    uint32_t h;
    size_t i;

    for (i = 0u; i < 16u; ++i) {
        w[i] = load_be32(block + (i * 4u));
    }

    for (i = 16u; i < 64u; ++i) {
        w[i] = SSIG1(w[i - 2u]) + w[i - 7u] + SSIG0(w[i - 15u]) + w[i - 16u];
    }

    a = ctx->state[0];
    b = ctx->state[1];
    c = ctx->state[2];
    d = ctx->state[3];
    e = ctx->state[4];
    f = ctx->state[5];
    g = ctx->state[6];
    h = ctx->state[7];

    for (i = 0u; i < 64u; ++i) {
        const uint32_t t1 = h + BSIG1(e) + CH(e, f, g) + k_sha256[i] + w[i];
        const uint32_t t2 = BSIG0(a) + MAJ(a, b, c);
        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    }

    ctx->state[0] += a;
    ctx->state[1] += b;
    ctx->state[2] += c;
    ctx->state[3] += d;
    ctx->state[4] += e;
    ctx->state[5] += f;
    ctx->state[6] += g;
    ctx->state[7] += h;
}

void cs_sha256_init(cs_sha256_t *ctx)
{
    ctx->state[0] = 0x6a09e667u;
    ctx->state[1] = 0xbb67ae85u;
    ctx->state[2] = 0x3c6ef372u;
    ctx->state[3] = 0xa54ff53au;
    ctx->state[4] = 0x510e527fu;
    ctx->state[5] = 0x9b05688cu;
    ctx->state[6] = 0x1f83d9abu;
    ctx->state[7] = 0x5be0cd19u;
    ctx->bit_len = 0u;
    ctx->buffer_len = 0u;
}

void cs_sha256_update(cs_sha256_t *ctx, const uint8_t *data, size_t len)
{
    size_t offset = 0u;

    if (len == 0u) {
        return;
    }

    ctx->bit_len += ((uint64_t)len * 8u);

    if (ctx->buffer_len > 0u) {
        const size_t to_copy = (len < (64u - ctx->buffer_len)) ? len : (64u - ctx->buffer_len);
        memcpy(ctx->buffer + ctx->buffer_len, data, to_copy);
        ctx->buffer_len += to_copy;
        offset += to_copy;

        if (ctx->buffer_len == 64u) {
            sha256_transform(ctx, ctx->buffer);
            ctx->buffer_len = 0u;
        }
    }

    while ((len - offset) >= 64u) {
        sha256_transform(ctx, data + offset);
        offset += 64u;
    }

    if (offset < len) {
        ctx->buffer_len = len - offset;
        memcpy(ctx->buffer, data + offset, ctx->buffer_len);
    }
}

void cs_sha256_final(cs_sha256_t *ctx, uint8_t digest[32])
{
    size_t i;

    ctx->buffer[ctx->buffer_len++] = 0x80u;

    if (ctx->buffer_len > 56u) {
        while (ctx->buffer_len < 64u) {
            ctx->buffer[ctx->buffer_len++] = 0u;
        }
        sha256_transform(ctx, ctx->buffer);
        ctx->buffer_len = 0u;
    }

    while (ctx->buffer_len < 56u) {
        ctx->buffer[ctx->buffer_len++] = 0u;
    }

    store_be64(ctx->buffer + 56u, ctx->bit_len);
    sha256_transform(ctx, ctx->buffer);

    for (i = 0u; i < 8u; ++i) {
        store_be32(digest + (i * 4u), ctx->state[i]);
    }
}
