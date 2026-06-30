/*
 * Max SDK bridge for the Cryptographic Sequencer core.
 *
 * This file requires Cycling '74 Max SDK headers and is the platform-specific
 * external entry point that wraps cryptoseq_max_model.
 */

#include "cryptoseq_max_model.h"
#include "cryptoseq_internal.h"

#include "ext.h"
#include "ext_obex.h"
#include "ext_obex_util.h"

#include <stdio.h>
#include <string.h>

#define CRYPTOSEQ_FILE_BUFFER_SIZE 32768u

typedef struct cryptoseq_object_t {
    t_object object;
    void *event_outlet;
    cs_max_model_t model;
} cryptoseq_object_t;

static t_class *cryptoseq_class = NULL;

static void cryptoseq_post_status(cryptoseq_object_t *x, cs_status_t status)
{
    if (status != CS_OK) {
        object_error((t_object *)x, "%s", cs_status_string(status));
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

static void cryptoseq_setup(cryptoseq_object_t *x)
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
        object_error((t_object *)x, "step index must be non-negative");
        return;
    }

    event = cs_max_model_event_at(&x->model, (size_t)index);
    if (event == NULL) {
        object_error((t_object *)x, "step index out of range");
        return;
    }

    cryptoseq_output_event(x, event);
}

static void cryptoseq_source(cryptoseq_object_t *x, t_symbol *selector, long argc, t_atom *argv)
{
    char *text = NULL;
    long text_size = 0;
    t_max_err err;

    (void)selector;

    if (argc <= 0 || argv == NULL) {
        object_error((t_object *)x, "source requires text");
        return;
    }

    err = atom_gettext(
        argc,
        argv,
        &text_size,
        &text,
        OBEX_UTIL_ATOM_GETTEXT_SYM_NO_QUOTE
    );

    if (err != MAX_ERR_NONE || text == NULL) {
        object_error((t_object *)x, "could not parse source text");
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_source_bytes(&x->model, (const uint8_t *)text, strlen(text))
    );

    sysmem_freeptr(text);
}

static char *cryptoseq_atoms_to_text(long argc, t_atom *argv)
{
    char *text = NULL;
    long text_size = 0;
    const t_max_err err = atom_gettext(
        argc,
        argv,
        &text_size,
        &text,
        OBEX_UTIL_ATOM_GETTEXT_SYM_NO_QUOTE
    );

    if (err != MAX_ERR_NONE) {
        return NULL;
    }

    return text;
}

static void cryptoseq_sourcefile(cryptoseq_object_t *x, t_symbol *selector, long argc, t_atom *argv)
{
    char *path;
    FILE *file;
    long file_size;
    uint8_t buffer[CRYPTOSEQ_FILE_BUFFER_SIZE];
    uint8_t digest[CS_SHA256_DIGEST_SIZE];
    size_t bytes_read;
    size_t total_read = 0u;
    cs_sha256_t sha;
    cs_status_t status;

    (void)selector;

    if (argc <= 0 || argv == NULL) {
        object_error((t_object *)x, "sourcefile requires a path");
        return;
    }

    path = cryptoseq_atoms_to_text(argc, argv);
    if (path == NULL) {
        object_error((t_object *)x, "could not parse sourcefile path");
        return;
    }

    file = fopen(path, "rb");
    if (file == NULL) {
        object_error((t_object *)x, "could not open source file");
        sysmem_freeptr(path);
        return;
    }

    if (fseek(file, 0, SEEK_END) != 0) {
        object_error((t_object *)x, "could not inspect source file");
        fclose(file);
        sysmem_freeptr(path);
        return;
    }

    file_size = ftell(file);
    if (file_size < 0 || (size_t)file_size > CS_MAX_SOURCE_BYTES) {
        object_error(
            (t_object *)x,
            "source file must be %lu MiB or smaller",
            (unsigned long)(CS_MAX_SOURCE_BYTES / (1024u * 1024u))
        );
        fclose(file);
        sysmem_freeptr(path);
        return;
    }

    if (fseek(file, 0, SEEK_SET) != 0) {
        object_error((t_object *)x, "could not read source file");
        fclose(file);
        sysmem_freeptr(path);
        return;
    }

    cs_sha256_init(&sha);
    while ((bytes_read = fread(buffer, 1u, sizeof(buffer), file)) > 0u) {
        total_read += bytes_read;
        cs_sha256_update(&sha, buffer, bytes_read);
    }
    fclose(file);

    if (total_read != (size_t)file_size) {
        object_error((t_object *)x, "could not hash complete source file");
        sysmem_freeptr(path);
        return;
    }

    cs_sha256_final(&sha, digest);
    status = cs_max_model_set_source_digest(&x->model, digest);
    cryptoseq_post_status(x, status);
    if (status == CS_OK) {
        object_post((t_object *)x, "cryptoseq: loaded source file (%ld bytes)", file_size);
    }

    sysmem_freeptr(path);
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

static void cryptoseq_e(cryptoseq_object_t *x, long e)
{
    if (e < 0) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_exponent(&x->model, (uint32_t)e));
}

static void cryptoseq_rsa(cryptoseq_object_t *x, long p, long q, long e)
{
    if (p < 0 || q < 0 || e < 0) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_rsa(&x->model, (uint32_t)p, (uint32_t)q, (uint32_t)e)
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

static void cryptoseq_shift(cryptoseq_object_t *x, long shift)
{
    if (shift < 0) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_sequence_shift(&x->model, (size_t)shift));
}

static void cryptoseq_scene(cryptoseq_object_t *x, long scene)
{
    if (scene < 0 || scene > CS_MAX_SCENE_VALUE) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_scene(&x->model, (uint8_t)scene));
}

static void cryptoseq_root(cryptoseq_object_t *x, long root)
{
    if (root < 0 || root > 127) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_root_note(&x->model, (uint8_t)root));
}

static void cryptoseq_melodyrange(cryptoseq_object_t *x, long low_note, long high_note)
{
    if (low_note < 0 || low_note > 127 || high_note < 0 || high_note > 127) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_melody_range(&x->model, (uint8_t)low_note, (uint8_t)high_note)
    );
}

static void cryptoseq_padcount(cryptoseq_object_t *x, long pad_count)
{
    if (pad_count < 1 || pad_count > 128) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_drum_pad_count(&x->model, (uint8_t)pad_count));
}

static void cryptoseq_mode(cryptoseq_object_t *x, t_symbol *mode)
{
    cryptoseq_post_status(x, cs_max_model_set_mode(&x->model, mode->s_name));
}

static void cryptoseq_scale(cryptoseq_object_t *x, t_symbol *scale)
{
    cryptoseq_post_status(x, cs_max_model_set_scale(&x->model, scale->s_name));
}

static void cryptoseq_scaleintervals(cryptoseq_object_t *x, t_symbol *selector, long argc, t_atom *argv)
{
    int8_t intervals[CS_MAX_SCALE_LENGTH];
    long i;

    (void)selector;

    if (argc <= 0 || argc > (long)CS_MAX_SCALE_LENGTH || argv == NULL) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    for (i = 0; i < argc; ++i) {
        const long value = atom_getlong(argv + i);
        intervals[i] = (int8_t)value;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_scale_intervals(&x->model, intervals, (size_t)argc)
    );
}

static void cryptoseq_rhythm(cryptoseq_object_t *x, long divisor, long threshold)
{
    if (divisor < 0 || threshold < 0) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_rhythm(&x->model, (uint32_t)divisor, (uint32_t)threshold)
    );
}

static void cryptoseq_lock(cryptoseq_object_t *x, t_symbol *target, long enabled)
{
    if (target == NULL) {
        cryptoseq_post_status(x, CS_ERROR_NULL);
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_pattern_lock(&x->model, target->s_name, enabled != 0 ? 1u : 0u)
    );
}

static void cryptoseq_lockpitch(cryptoseq_object_t *x, long enabled)
{
    cryptoseq_post_status(
        x,
        cs_max_model_set_pattern_lock(&x->model, "pitch", enabled != 0 ? 1u : 0u)
    );
}

static void cryptoseq_lockrhythm(cryptoseq_object_t *x, long enabled)
{
    cryptoseq_post_status(
        x,
        cs_max_model_set_pattern_lock(&x->model, "rhythm", enabled != 0 ? 1u : 0u)
    );
}

static void cryptoseq_lockvelocity(cryptoseq_object_t *x, long enabled)
{
    cryptoseq_post_status(
        x,
        cs_max_model_set_pattern_lock(&x->model, "velocity", enabled != 0 ? 1u : 0u)
    );
}

static void cryptoseq_lockgate(cryptoseq_object_t *x, long enabled)
{
    cryptoseq_post_status(
        x,
        cs_max_model_set_pattern_lock(&x->model, "gate", enabled != 0 ? 1u : 0u)
    );
}

static void cryptoseq_morphamount(cryptoseq_object_t *x, long amount)
{
    if (amount < 0 || amount > 100) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_morph_amount(&x->model, (uint8_t)amount));
}

static void cryptoseq_morphscene(cryptoseq_object_t *x, long scene)
{
    if (scene < 0 || scene > CS_MAX_SCENE_VALUE) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_morph_scene(&x->model, (uint8_t)scene));
}

static void cryptoseq_morphmode(cryptoseq_object_t *x, t_symbol *mode)
{
    if (mode == NULL) {
        cryptoseq_post_status(x, CS_ERROR_NULL);
        return;
    }

    cryptoseq_post_status(x, cs_max_model_set_morph_mode(&x->model, mode->s_name));
}

static void cryptoseq_morph(cryptoseq_object_t *x, t_symbol *selector, long argc, t_atom *argv)
{
    cs_status_t status;

    (void)selector;

    if (argc <= 0 || argv == NULL) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_morphamount(x, atom_getlong(argv));
    if (argc >= 2) {
        cryptoseq_morphscene(x, atom_getlong(argv + 1));
    }
    if (argc >= 3) {
        t_symbol *mode = atom_getsym(argv + 2);
        status = cs_max_model_set_morph_mode(&x->model, mode->s_name);
        cryptoseq_post_status(x, status);
    }
}

static void cryptoseq_velocity(cryptoseq_object_t *x, long min_velocity, long max_velocity)
{
    if (min_velocity < 0 || min_velocity > 127 || max_velocity < 0 || max_velocity > 127) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_velocity_range(&x->model, (uint8_t)min_velocity, (uint8_t)max_velocity)
    );
}

static void cryptoseq_gate(cryptoseq_object_t *x, long min_permille, long max_permille)
{
    if (min_permille < 0 || min_permille > 1000 || max_permille < 0 || max_permille > 1000) {
        cryptoseq_post_status(x, CS_ERROR_INVALID_PARAM);
        return;
    }

    cryptoseq_post_status(
        x,
        cs_max_model_set_gate_range(&x->model, (uint16_t)min_permille, (uint16_t)max_permille)
    );
}

static void cryptoseq_assist(cryptoseq_object_t *x, void *b, long m, long a, char *s)
{
    (void)x;
    (void)b;
    (void)a;

    if (m == ASSIST_INLET) {
        strcpy(s, "messages: source, sourcefile, rsa, p, q, e, scene, length, shift, root, mode, rhythm, lock, morph, setup, generate");
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
    class_addmethod(c, (method)cryptoseq_source, "source", A_GIMME, 0);
    class_addmethod(c, (method)cryptoseq_sourcefile, "sourcefile", A_GIMME, 0);
    class_addmethod(c, (method)cryptoseq_p, "p", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_q, "q", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_e, "e", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_e, "exponent", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_rsa, "rsa", A_LONG, A_LONG, A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_length, "length", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_shift, "shift", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_scene, "scene", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_root, "root", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_melodyrange, "melodyrange", A_LONG, A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_melodyrange, "noterange", A_LONG, A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_padcount, "padcount", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_mode, "mode", A_SYM, 0);
    class_addmethod(c, (method)cryptoseq_scale, "scale", A_SYM, 0);
    class_addmethod(c, (method)cryptoseq_scaleintervals, "scaleintervals", A_GIMME, 0);
    class_addmethod(c, (method)cryptoseq_scaleintervals, "scale_intervals", A_GIMME, 0);
    class_addmethod(c, (method)cryptoseq_rhythm, "rhythm", A_LONG, A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_lock, "lock", A_SYM, A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_lockpitch, "lockpitch", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_lockrhythm, "lockrhythm", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_lockvelocity, "lockvelocity", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_lockgate, "lockgate", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_morph, "morph", A_GIMME, 0);
    class_addmethod(c, (method)cryptoseq_morphamount, "morphamount", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_morphscene, "morphscene", A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_morphmode, "morphmode", A_SYM, 0);
    class_addmethod(c, (method)cryptoseq_velocity, "velocity", A_LONG, A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_gate, "gate", A_LONG, A_LONG, 0);
    class_addmethod(c, (method)cryptoseq_setup, "setup", 0);
    class_addmethod(c, (method)cryptoseq_generate, "generate", 0);
    class_addmethod(c, (method)cryptoseq_dump, "dump", 0);
    class_addmethod(c, (method)cryptoseq_step, "step", A_LONG, 0);

    class_register(CLASS_BOX, c);
    cryptoseq_class = c;

    (void)r;
}
