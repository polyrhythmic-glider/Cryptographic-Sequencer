autowatch = 1;
inlets = 1;
outlets = 1;

var MAX_STEPS = 128;
var events = [];
var length_value = 16;
var interval_name = "16n";
var ratchet_amount = 0;
var ratchet_max = 1;
var fill_amount = 0;
var fill_mode = "off";
var fill_target = "all";

function length(value)
{
    length_value = clamp_int(value, 1, MAX_STEPS, length_value);
}

function interval(value)
{
    interval_name = value.toString();
}

function ratchetamount(value)
{
    ratchet_amount = clamp_int(value, 0, 100, ratchet_amount);
}

function ratchetmax(value)
{
    ratchet_max = clamp_int(value, 1, 8, ratchet_max);
}

function fillamount(value)
{
    fill_amount = clamp_int(value, 0, 100, fill_amount);
}

function fillmode(value)
{
    fill_mode = value.toString();
}

function filltarget(value)
{
    var text = value.toString();

    fill_target = (text === "al") ? "all" : text;
}

function event()
{
    list.apply(this, arrayfromargs(arguments));
}

function list(step, active, note, velocity, accent, duration, gate, value)
{
    var index = clamp_int(step, 0, MAX_STEPS - 1, 0);

    events[index] = {
        active: parseInt(active, 10) ? 1 : 0,
        note: clamp_int(note, 0, 127, 60),
        velocity: clamp_int(velocity, 1, 127, 96),
        accent: clamp_int(accent, 0, 127, 0),
        duration: Math.max(1, parseInt(duration, 10)),
        gate: clamp_int(gate, 1, 1000, 1000),
        value: parseInt(value, 10)
    };
}

function exportclip()
{
    export_clip();
}

function bang()
{
    export_clip();
}

function export_clip()
{
    var clip_slot;
    var clip;
    var clip_length = Math.max(1, length_value * interval_to_beats(interval_name));
    var notes = build_notes();

    if (notes.length === 0) {
        post("cryptoseq export: no active notes to export\n");
        return;
    }

    try {
        if (typeof LiveAPI === "undefined") {
            post("cryptoseq export: Live API unavailable\n");
            return;
        }

        clip_slot = new LiveAPI("live_set view highlighted_clip_slot");
        if (!live_api_has_object(clip_slot)) {
            post("cryptoseq export: select a MIDI clip slot first\n");
            return;
        }

        if (parseInt(clip_slot.get("has_clip"), 10) === 0) {
            clip_slot.call("create_clip", clip_length);
        }

        clip = live_api_from_id(clip_slot.get("clip"));
        if (!live_api_has_object(clip)) {
            post("cryptoseq export: could not access target clip\n");
            return;
        }

        clip.call("select_all_notes");
        clip.call("replace_selected_notes");
        clip.call("notes", notes.length);
        write_notes(clip, notes);
        clip.call("done");
        clip.set("loop_start", 0);
        clip.set("loop_end", clip_length);
        clip.set("looping", 1);
        clip.set("name", "CryptoSeq");
        post("cryptoseq export: wrote " + notes.length + " notes to highlighted clip slot\n");
    } catch (err) {
        post("cryptoseq export: " + err + "\n");
    }
}

function build_notes()
{
    var notes = [];
    var step_beats = interval_to_beats(interval_name);
    var i;
    var event;
    var start;
    var duration;
    var velocity;
    var gate_scale;
    var fill_strength;
    var fill_active;
    var ratchets;
    var ratchet_spacing;
    var j;

    for (i = 0; i < length_value; i += 1) {
        event = events[i];
        if (!event) {
            continue;
        }

        fill_strength = fill_probability(i, event.accent, event.velocity);
        fill_active = target_allows("density") && fill_hits(fill_strength, event.value);

        if (!event.active && !fill_active) {
            continue;
        }

        velocity = event.velocity;
        gate_scale = event.gate / 1000;

        if (!event.active && fill_active) {
            velocity = clamp_int(Math.max(40, Math.round(velocity * 0.75)), 1, 127, velocity);
        } else if (target_allows("velocity") && fill_hits(fill_strength, event.value ^ 0x5e1ec7)) {
            velocity = clamp_int(velocity + Math.floor(fill_strength / 10), 1, 127, velocity);
        }

        if (target_allows("gate") && fill_hits(fill_strength, event.value ^ 0x6a7e)) {
            gate_scale = Math.max(0.05, gate_scale * (1 - (fill_strength / 300)));
        }

        ratchets = Math.max(
            ratchet_count(event.accent, velocity, event.value),
            target_allows("ratchet") ? fill_ratchet_count(fill_strength, event.value) : 1
        );
        ratchet_spacing = step_beats / ratchets;
        start = i * step_beats;
        duration = Math.max(0.03125, ratchet_spacing * gate_scale);

        for (j = 0; j < ratchets; j += 1) {
            notes.push({
                pitch: event.note,
                start: start + (ratchet_spacing * j),
                duration: duration,
                velocity: velocity,
                muted: 0
            });
        }
    }

    return notes;
}

function write_notes(clip, notes)
{
    var i;
    var note;

    for (i = 0; i < notes.length; i += 1) {
        note = notes[i];
        clip.call(
            "note",
            note.pitch,
            note.start,
            note.duration,
            note.velocity,
            note.muted
        );
    }
}

function live_api_from_id(id_value)
{
    var id = id_value;
    var api;

    if (id instanceof Array) {
        id = id.join(" ");
    }

    api = new LiveAPI(null);
    api.id = id;
    return api;
}

function live_api_has_object(api)
{
    var id;

    if (!api) {
        return false;
    }

    id = api.id;
    if (id instanceof Array) {
        id = id.join(" ");
    }

    return !(id === 0 || id === "0" || id === "id 0" || id === null || typeof id === "undefined");
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
        if (isNaN(step) || length_value <= 1) {
            return 0;
        }
        tail = Math.max(1, Math.floor(length_value / 4));
        if (step < length_value - tail) {
            return 0;
        }
        position = step - (length_value - tail);
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

function interval_to_beats(interval)
{
    var match = interval.toString().match(/^([0-9]+)n([td]?)$/);
    var denominator;
    var beats;

    if (!match) {
        return 0.25;
    }

    denominator = parseInt(match[1], 10);
    if (denominator <= 0) {
        return 0.25;
    }

    beats = 4 / denominator;
    if (match[2] === "t") {
        beats *= 2 / 3;
    } else if (match[2] === "d") {
        beats *= 3 / 2;
    }

    return Math.max(0.03125, beats);
}

function clamp_int(value, min_value, max_value, fallback)
{
    var parsed = parseInt(value, 10);

    if (isNaN(parsed)) {
        return fallback;
    }

    return Math.max(min_value, Math.min(max_value, parsed));
}

function anything()
{
}
