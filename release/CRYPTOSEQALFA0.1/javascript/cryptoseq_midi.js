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
var fill_amount = 0;
var fill_mode = "off";
var fill_target = "all";
var tempo_cache = DEFAULT_TEMPO;
var step_ms_cache = interval_to_ms(current_interval, tempo_cache);
var scheduled_tasks = [];

function interval(value)
{
    current_interval = value.toString();
    update_step_ms_cache();
}

function tempo(value)
{
    var parsed = parseFloat(value);

    if (!isNaN(parsed) && parsed > 0) {
        DEFAULT_TEMPO = parsed;
        tempo_cache = parsed;
        update_step_ms_cache();
    }
}

function mode(value)
{
    current_mode = value.toString();
}

function length(value)
{
    var parsed = parse_int_or(value, current_length);

    if (parsed > 0) {
        current_length = parsed;
    }
}

function poly(value)
{
    var parsed = parse_int_or(value, 0);

    poly_enabled = (parsed !== 0) ? 1 : 0;
}

function ratchetamount(value)
{
    ratchet_amount = clamp_int(value, 0, 100, ratchet_amount);
}

function ratchetmax(value)
{
    ratchet_max = clamp_int(value, 1, 8, ratchet_max);
}

function fillmode(value)
{
    fill_mode = value.toString();
}

function fillamount(value)
{
    fill_amount = clamp_int(value, 0, 100, fill_amount);
}

function filltarget(value)
{
    var text = value.toString();

    if (text === "al") {
        text = "all";
    }

    if (
        text === "density" ||
        text === "ratchet" ||
        text === "velocity" ||
        text === "gate" ||
        text === "all"
    ) {
        fill_target = text;
    }
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
    var parsed_active;
    var fill_strength;
    var fill_active;
    var ratchets;
    var ratchet_spacing;
    var ratchet_duration;
    var i;

    step_ms = step_ms_cache;
    duration_units = Math.max(1, parse_int_or(duration, 1));
    gate_scale = Math.max(0.05, Math.min(1, parse_int_or(gate, 1000) / 1000));
    duration_ms = Math.max(20, Math.round(step_ms * duration_units * gate_scale));
    parsed_active = parse_int_or(active, 0);
    parsed_step = parse_int_or(step, 0);
    parsed_note = clamp_midi(parseInt(note, 10));
    parsed_velocity = clamp_midi(parseInt(velocity, 10));
    parsed_accent = parse_int_or(accent, 0);
    parsed_value = parseInt(value, 10);
    fill_strength = fill_probability(parsed_step, parsed_accent, parsed_velocity);
    fill_active = target_allows("density") && fill_hits(fill_strength, parsed_value);

    if (!parsed_active && !fill_active) {
        return;
    }

    if (!parsed_active && fill_active) {
        parsed_velocity = clamp_midi(Math.max(40, Math.round(parsed_velocity * 0.75)));
    } else if (target_allows("velocity") && fill_hits(fill_strength, parsed_value ^ 0x5e1ec7)) {
        parsed_velocity = clamp_midi(parsed_velocity + Math.floor(fill_strength / 10));
    }

    if (target_allows("gate") && fill_hits(fill_strength, parsed_value ^ 0x6a7e)) {
        gate_scale = Math.max(0.05, gate_scale * (1 - (fill_strength / 300)));
        duration_ms = Math.max(20, Math.round(step_ms * duration_units * gate_scale));
    }

    ratchets = Math.max(
        ratchet_count(parsed_accent, parsed_velocity, parsed_value),
        target_allows("ratchet") ? fill_ratchet_count(fill_strength, parsed_value) : 1
    );
    ratchet_spacing = step_ms / ratchets;
    ratchet_duration = Math.max(20, Math.round(ratchet_spacing * gate_scale));

    emit_voice_set(parsed_note, parsed_velocity, ratchet_duration, parsed_value);

    for (i = 1; i < ratchets; i += 1) {
        emit_voice_set_later(
            parsed_note,
            parsed_velocity,
            ratchet_duration,
            parsed_value,
            Math.round(ratchet_spacing * i)
        );
    }
}

function playevent()
{
    var args = arrayfromargs(arguments);

    list.apply(this, args);
}

function anything()
{
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
    var task;

    task = new Task(function() {
        emit_voice_set(note, velocity, duration_ms, value);
        remove_task(task);
    }, this);

    scheduled_tasks.push(task);
    task.schedule(Math.max(1, delay_ms));
}

function emit_note(note, velocity, duration_ms)
{
    outlet(2, duration_ms);
    outlet(1, clamp_midi(velocity));
    outlet(0, clamp_midi(note));
}

function ratchet_count(accent, velocity, value)
{
    var selector;
    var max_extra;

    if (ratchet_max <= 1 || ratchet_amount <= 0 || isNaN(value)) {
        return 1;
    }

    selector = positive_mod(mix32(value ^ (accent * 131) ^ (velocity * 17)), 100);
    if (selector >= ratchet_amount) {
        return 1;
    }

    max_extra = Math.max(1, ratchet_max - 1);
    return 2 + positive_mod(mix32(value ^ 0x9e3779b9), max_extra);
}

function fill_probability(step, accent, velocity)
{
    var tail;
    var position;
    var strength = 0;

    if (fill_mode === "off" || fill_amount <= 0) {
        return 0;
    }

    if (fill_mode === "end") {
        if (isNaN(step) || current_length <= 1) {
            return 0;
        }

        tail = Math.max(1, Math.floor(current_length / 4));
        if (step < current_length - tail) {
            return 0;
        }

        position = step - (current_length - tail);
        strength = Math.min(100, 35 + Math.round((65 * (position + 1)) / tail));
    } else if (fill_mode === "accent") {
        strength = Math.min(100, Math.max(0, accent) * 28);
    } else if (fill_mode === "velocity") {
        if (velocity >= 72) {
            strength = Math.min(100, (velocity - 72) * 2);
        }
    } else if (fill_mode === "all") {
        strength = 100;
    }

    return Math.round((strength * fill_amount) / 100);
}

function fill_hits(strength, value)
{
    if (strength <= 0 || isNaN(value)) {
        return false;
    }

    return positive_mod(mix32(value ^ 0x51f15eed), 100) < strength;
}

function fill_ratchet_count(strength, value)
{
    var max_extra;

    if (ratchet_max <= 1 || !fill_hits(strength, value ^ 0x7a771e11)) {
        return 1;
    }

    max_extra = Math.max(1, ratchet_max - 1);
    return 2 + positive_mod(mix32(value ^ 0xf111), max_extra);
}

function target_allows(target)
{
    return fill_target === "all" || fill_target === target;
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
    value = multiply32(value, 0x7feb352d);
    value ^= value >>> 15;
    value = multiply32(value, 0x846ca68b);
    value ^= value >>> 16;
    return value >>> 0;
}

function multiply32(a, b)
{
    var ah = (a >>> 16) & 0xffff;
    var al = a & 0xffff;
    var bh = (b >>> 16) & 0xffff;
    var bl = b & 0xffff;

    return ((al * bl) + (((ah * bl + al * bh) & 0xffff) << 16)) | 0;
}

function positive_mod(value, modulo)
{
    var result = value % modulo;
    return result < 0 ? result + modulo : result;
}

function parse_int_or(value, fallback)
{
    var parsed = parseInt(value, 10);

    if (isNaN(parsed)) {
        return fallback;
    }

    return parsed;
}

function clamp_int(value, min_value, max_value, fallback)
{
    var parsed = parse_int_or(value, fallback);

    return Math.max(min_value, Math.min(max_value, parsed));
}

function remove_task(task)
{
    var i;

    for (i = scheduled_tasks.length - 1; i >= 0; i -= 1) {
        if (scheduled_tasks[i] === task) {
            scheduled_tasks.splice(i, 1);
            return;
        }
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
    return tempo_cache;
}

function update_step_ms_cache()
{
    step_ms_cache = interval_to_ms(current_interval, tempo_cache);
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
