#include "cryptoseq.h"

#include <stdio.h>
#include <string.h>

int main(void)
{
    static const uint8_t source[] = "cryptographic sequencer demo source";
    cs_params_t params = cs_default_params();
    cs_event_t events[16];
    cs_status_t status;
    size_t i;

    params.length = 16u;
    params.mode = CS_MODE_HYBRID;
    params.root_note = 60u;
    params.p = 251u;
    params.q = 257u;

    status = cs_generate_from_bytes(
        source,
        strlen((const char *)source),
        &params,
        events,
        sizeof(events) / sizeof(events[0])
    );

    if (status != CS_OK) {
        fprintf(stderr, "cryptoseq error: %s\n", cs_status_string(status));
        return 1;
    }

    printf("source: \"%s\"\n", source);
    printf("p=%u q=%u e=%u mode=hybrid length=%lu\n\n",
           params.p,
           params.q,
           params.e,
           (unsigned long)params.length);

    printf("step active note vel accent dur gate value\n");
    printf("---- ------ ---- --- ------ --- ---- ----------\n");

    for (i = 0u; i < params.length; ++i) {
        printf("%4lu %6u %4u %3u %6u %3u %4u %10u\n",
               (unsigned long)events[i].step_index,
               events[i].active,
               events[i].note,
               events[i].velocity,
               events[i].accent,
               events[i].duration_ticks,
               events[i].gate_permille,
               events[i].value);
    }

    return 0;
}
