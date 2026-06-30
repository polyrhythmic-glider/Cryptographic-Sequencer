autowatch = 1;
inlets = 1;
outlets = 3;

var DEFAULT_TEMPO = 120;
var current_interval = "16n";
var current_mode = "hybrid";
var current_length = 16;
var poly_enabled = 0;
var ratchet_amount = 0;
var ratchet_max = 1;
var fill_mode = "off";
var live_set = null;
var scheduled_tasks = [];

function interval(value)
{
    current_interval = value.toString();
}

function tempo(value)
{
    var parsed = parseFloat(value);

    if (!isNaN(parsed) && parsed > 0) {
        DEFAULT_TEMPO = parsed;
    }
}

function mode(value)
{
    current_mode = value.toString();
}

function length(value)
{
    var parsed = parseInt(value, 10);

    if (!isNaN(parsed) && parsed > 0) {
        current_length = parsed;
    }
}

function poly(value)
{
    var parsed = parseInt(value, 10);

    poly_enabled = (!isNaN(parsed) && parsed !== 0) ? 1 : 0;
}

function ratchetamount(value)
{
    var parsed = parseInt(value, 10);

    if (!isNaN(parsed)) {
        ratchet_amount = Math.max(0, Math.min(100, parsed));
    }
}

function ratchetmax(value)
{
    var parsed = parseInt(value, 10);

    if (!isNaN(parsed)) {
        ratchet_max = Math.max(1, Math.min(8, parsed));
    }
}

function fillmode(value)
{
    fill_mode = value.toString();
}

function list(step, active, note, velocity, accent, duration, gate, value)
{
    var duration_ms;
    var step_ms;
    var duration_units;
    var gate_scale;
    var parsed_note;
    var parsed_velocity;
    var parsed_value;
    var parsed_step;
    var parsed_accent;
    var ratchets;
    var ratchet_duration;
    var i;

    if (!active) {
        return;
    }

    step_ms = interval_to_ms(current_interval, current_tempo());
    duration_units = Math.max(1, parseInt(duration, 10));
    gate_scale = Math.max(0.05, Math.min(1, parseInt(gate, 10) / 1000));
    duration_ms = Math.max(20, Math.round(step_ms * duration_units * gate_scale));
    parsed_step = parseInt(step, 10);
    parsed_note = clamp_midi(parseInt(note, 10));
    parsed_velocity = clamp_midi(parseInt(velocity, 10));
    parsed_accent = parseInt(accent, 10);
    parsed_value = parseInt(value, 10);
    ratchets = ratchet_count(parsed_step, parsed_accent, parsed_velocity, parsed_value);
    ratchet_duration = Math.max(20, Math.round((step_ms / ratchets) * gate_scale));

    emit_voice_set(parsed_note, parsed_velocity, ratchet_duration, parsed_value);

    for (i = 1; i < ratchets; i += 1) {
        emit_voice_set_later(
            parsed_note,
            parsed_velocity,
            ratchet_duration,
            parsed_value,
            Math.round((step_ms / ratchets) * i)
        );
    }
}

function emit_voice_set(note, velocity, duration_ms, value)
{
    var third;

    emit_note(note, velocity, duration_ms);

    if (poly_enabled && mode_is_melodic()) {
        third = (!isNaN(value) && (value % 2)) ? 3 : 4;
        emit_note(note + third, velocity - 8, duration_ms);
        emit_note(note + 7, velocity - 12, duration_ms);
    }
}

function emit_voice_set_later(note, velocity, duration_ms, value, delay_ms)
{
    var task = new Task(function() {
        emit_voice_set(note, velocity, duration_ms, value);
    }, this);

    scheduled_tasks.push(task);
    task.schedule(Math.max(1, delay_ms));
    cleanup_tasks();
}

function emit_note(note, velocity, duration_ms)
{
    outlet(2, duration_ms);
    outlet(1, clamp_midi(velocity));
    outlet(0, clamp_midi(note));
}

function ratchet_count(step, accent, velocity, value)
{
    var amount = ratchet_amount;
    var selector;
    var max_extra;

    if (ratchet_max <= 1 || amount <= 0 || isNaN(value)) {
        return 1;
    }

    if (fill_mode === "end" && is_end_fill_step(step)) {
        amount = Math.min(100, amount + 35);
    } else if (fill_mode === "accent" && accent > 1) {
        amount = Math.min(100, amount + 25);
    } else if (fill_mode === "velocity" && velocity > 96) {
        amount = Math.min(100, amount + 20);
    } else if (fill_mode === "off") {
        amount = ratchet_amount;
    }

    selector = positive_mod(mix32(value ^ (accent * 131) ^ (velocity * 17)), 100);
    if (selector >= amount) {
        return 1;
    }

    max_extra = Math.max(1, ratchet_max - 1);
    return 2 + positive_mod(mix32(value ^ 0x9e3779b9), max_extra);
}

function is_end_fill_step(step)
{
    var tail;

    if (isNaN(step) || current_length <= 1) {
        return false;
    }

    tail = Math.max(1, Math.floor(current_length / 4));
    return step >= current_length - tail;
}

function mix32(value)
{
    value = value | 0;
    value ^= value >>> 16;
    value = Math.imul(value, 0x7feb352d);
    value ^= value >>> 15;
    value = Math.imul(value, 0x846ca68b);
    value ^= value >>> 16;
    return value >>> 0;
}

function positive_mod(value, modulo)
{
    var result = value % modulo;
    return result < 0 ? result + modulo : result;
}

function cleanup_tasks()
{
    if (scheduled_tasks.length > 64) {
        scheduled_tasks = scheduled_tasks.slice(scheduled_tasks.length - 32);
    }
}

function clamp_midi(value)
{
    if (isNaN(value)) {
        return 0;
    }

    return Math.max(0, Math.min(127, parseInt(value, 10)));
}

function mode_is_melodic()
{
    return current_mode === "melodic" || current_mode === "melody";
}

function current_tempo()
{
    var tempo;

    try {
        if (typeof LiveAPI !== "undefined") {
            if (live_set === null) {
                live_set = new LiveAPI(null, "live_set");
            }

            if (!live_set || live_set.id === 0) {
                return DEFAULT_TEMPO;
            }

            tempo = live_set.get("tempo");
            if (tempo && tempo.length) {
                tempo = tempo[0];
            }

            tempo = parseFloat(tempo);
            if (!isNaN(tempo) && tempo > 0) {
                return tempo;
            }
        }
    } catch (err) {
        live_set = null;
    }

    return DEFAULT_TEMPO;
}

function interval_to_ms(interval_name, bpm)
{
    var match = interval_name.toString().match(/^([0-9]+)n([td]?)$/);
    var denominator;
    var quarters;
    var ms;

    if (!match) {
        return 60000 / bpm / 4;
    }

    denominator = parseInt(match[1], 10);
    if (denominator <= 0) {
        return 60000 / bpm / 4;
    }

    quarters = 4 / denominator;
    if (match[2] === "t") {
        quarters *= 2 / 3;
    } else if (match[2] === "d") {
        quarters *= 3 / 2;
    }

    ms = (60000 / bpm) * quarters;
    return Math.max(1, ms);
}
