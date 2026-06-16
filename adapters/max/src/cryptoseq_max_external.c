/*
 * Max SDK bridge for the Cryptographic Sequencer core.
 *
 * This file is intentionally not built by the Linux CMake targets. It requires
 * Cycling '74 Max SDK headers and is meant to become the platform-specific
 * external entry point that wraps cryptoseq_max_model.
 */

#include "cryptoseq_max_model.h"

#include "ext.h"
#include "ext_obex.h"

#include <string.h>

typedef struct cryptoseq_object_t {
    t_object object;
    void *event_outlet;
    cs_max_model_t model;
} cryptoseq_object_t;

static t_class *cryptoseq_class = NULL;

static void cryptoseq_post_status(cryptoseq_object_t *x, cs_status_t status)
{
    if (status != CS_OK) {
        object_error((t_object *)x, "cryptoseq: %s", cs_status_string(status));
    }
}

static void cryptoseq_output_event(cryptoseq_object_t *x, const cs_event_t *event)
{
    t_atom atoms[8];

    atom_setlong(&atoms[0], (t_atom_long)event->step_index);
    atom_setlong(&atoms[1], (t_atom_long)event->active);
    atom_setlong(&atoms[2], (t_atom_long)event->note);
    atom_setlong(&atoms[3], (t_atom_long)event->velocity);
    atom_setlong(&atoms[4], (t_atom_long)event->accent);
    atom_setlong(&atoms[5], (t_atom_long)event->duration_ticks);
    atom_setlong(&atoms[6], (t_atom_long)event->gate_permille);
    atom_setlong(&atoms[7], (t_atom_long)event->value);

    outlet_anything(x->event_outlet, gensym("event"), 8, atoms);
}

static void cryptoseq_dump(cryptoseq_object_t *x)
{
    size_t i;
    const size_t count = cs_max_model_event_count(&x->model);

    for (i = 0u; i < count; ++i) {
        const cs_event_t *event = cs_max_model_event_at(&x->model, i);
        if (event != NULL) {
            cryptoseq_output_event(x, event);
        }
    }
}

static void cryptoseq_bang(cryptoseq_object_t *x)
{
    cryptoseq_dump(x);
}

static void cryptoseq_generate(cryptoseq_object_t *x)
{
    const cs_status_t status = cs_max_model_generate(&x->model);

    cryptoseq_post_status(x, status);
    if (status == CS_OK) {
        cryptoseq_dump(x);
    }
}

static void cryptoseq_step(cryptoseq_object_t *x, long index)
{
    const cs_event_t *event;

    if (index < 0) {
        object_error((t_object *)x, "cryptoseq: step index must be non-negative");
        return;
    }

    event = cs_max_model_event_at(&x->model, (size_t)index);
    if (event == NULL) {
        object_error((t_object *)x, "cryptoseq: step index out of range");
        return;
    }

    cryptoseq_output_event(x, event);
}

static void cryptoseq_source(cryptoseq_object_t *x, t_symbol *source)
{
    const char *text = source->s_name;
    cryptoseq_post_status(
        x,
        cs_max_model_set_source_bytes(&x->model, (const uint8_t *)text, strlen(text))
    );
}

static void cryptoseq_p(cryptoseq_object_t *x, long p)
{
    if (p < 0) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_primes(&x->model, (uint32_t)p, x->model.params.q)
    );
}

static void cryptoseq_q(cryptoseq_object_t *x, long q)
{
    if (q < 0) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_primes(&x->model, x->model.params.p, (uint32_t)q)
    );
}

static void cryptoseq_length(cryptoseq_object_t *x, long length)
{
    if (length < 0) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_length(&x->model, (size_t)length));
}

static void cryptoseq_root(cryptoseq_object_t *x, long root)
{
    if (root < 0 || root > 127) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_root_note(&x->model, (uint8_t)root));
}

static void cryptoseq_mode(cryptoseq_object_t *x, t_symbol *mode)
{
    cryptoseq_post_status(x, cs_max_model_set_mode(&x->model, mode->s_name));
}

static void cryptoseq_assist(cryptoseq_object_t *x, void *b, long m, long a, char *s)
{
    (void)x;
    (void)b;
    (void)a;

    if (m == ASSIST_INLET) {
        strcpy(s, "messages: source, p, q, length, root, mode, generate, dump, step");
    } else {
        strcpy(s, "event step active note velocity accent duration gate value");
    }
}

static void *cryptoseq_new(void)
{
    cryptoseq_object_t *x = (cryptoseq_object_t *)object_alloc(cryptoseq_class);

    if (x == NULL) {
        return NULL;
    }

    cs_max_model_init(&x->model);
    x->event_outlet = outlet_new((t_object *)x, NULL);
    return x;
}

void ext_main(void *r)
{
    t_class *c;

    c = class_new(
        "cryptoseq",
        (method)cryptoseq_new,
        NULL,
        (long)sizeof(cryptoseq_object_t),
        NULL,
        0
    );

    class_addmethod(c, (method)cryptoseq_bang, "bang", 0);
    class_addmethod(c, (method)cryptoseq_assist, "assist", A_CANT, 0);
    class_addmethod(c, (method)cryptoseq_source, "source", A_SYM, 0);
    class_addmethod(c, (method)cryptoseq_p, "p", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_q, "q", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_length, "length", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_root, "root", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_mode, "mode", A_SYM, 0);
    class_addmethod(c, (method)cryptoseq_generate, "generate", 0);
    class_addmethod(c, (method)cryptoseq_dump, "dump", 0);
    class_addmethod(c, (method)cryptoseq_step, "step", A_LONG, 0);

    class_register(CLASS_BOX, c);
    cryptoseq_class = c;

    (void)r;
}
