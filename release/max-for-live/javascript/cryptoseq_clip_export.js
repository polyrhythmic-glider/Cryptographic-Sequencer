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
var current_mode = "hybrid";
var current_scene = 0;
var current_crt_split = "off";
var note_dict = null;

function mode(value)
{
    current_mode = value.toString();
}

function scene(value)
{
    current_scene = clamp_int(value, 0, 127, current_scene);
}

function crtsplit(value)
{
    current_crt_split = value.toString();
}

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
    var has_clip;
    var clip_id;
    var clip_length = Math.max(1, length_value * interval_to_beats(interval_name));
    var notes = build_notes();

    if (notes.length === 0) {
        status("no notes");
        return;
    }

    try {
        if (typeof LiveAPI === "undefined") {
            status("Live API off");
            return;
        }

        status("exporting " + notes.length);
        clip_slot = new LiveAPI("live_set view highlighted_clip_slot");
        if (!live_api_has_object(clip_slot)) {
            status("select slot");
            return;
        }

        has_clip = live_api_get(clip_slot, "has_clip");
        if (has_clip === null) {
            status("select slot");
            return;
        }

        if (parseInt(has_clip, 10) === 0) {
            clip_slot.call("create_clip", clip_length);
        }

        clip_id = live_api_get(clip_slot, "clip");
        clip = live_api_from_id(clip_id);
        if (!live_api_has_object(clip)) {
            status("clip error");
            return;
        }

        write_notes(clip, notes, clip_length);
        clip.set("loop_start", 0);
        clip.set("loop_end", clip_length);
        clip.set("looping", 1);
        clip.set("name", clip_name());
        status("exported " + notes.length);
    } catch (err) {
        status("export failed");
        post("cryptoseq export: " + err + "\n");
    }
}

function status(text)
{
    post("cryptoseq export: " + text + "\n");
    outlet(0, "set", text);
}

function clip_name()
{
    var split = current_crt_split;

    if (split === "p_pitch_q_rhythm") {
        split = "pPitch";
    } else if (split === "p_rhythm_q_pitch") {
        split = "pRhythm";
    } else if (split === "p_melody_q_drums") {
        split = "melDrums";
    }

    return "CryptoSeq " + current_mode + " s" + current_scene + " " + split;
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

function write_notes(clip, notes, clip_length)
{
    if (write_notes_extended(clip, notes, clip_length)) {
        return;
    }

    write_notes_legacy(clip, notes);
}

function write_notes_extended(clip, notes, clip_length)
{
    var dict;
    var payload = { notes: [] };
    var i;
    var note;

    if (typeof Dict === "undefined" || typeof JSON === "undefined") {
        return false;
    }

    try {
        for (i = 0; i < notes.length; i += 1) {
            note = notes[i];
            payload.notes.push({
                pitch: note.pitch,
                start_time: round_beats(note.start),
                duration: round_beats(note.duration),
                velocity: note.velocity,
                mute: note.muted,
                probability: 1,
                velocity_deviation: 0,
                release_velocity: 64
            });
        }

        if (!note_dict) {
            note_dict = new Dict();
        }
        dict = note_dict;
        dict.clear();
        dict.parse(JSON.stringify(payload));
        clip.call("remove_notes_extended", 0, 128, 0, clip_length);
        clip.call("add_new_notes", "dictionary", dict.name);
        return true;
    } catch (err) {
        post("cryptoseq export: extended note API unavailable\n");
        return false;
    }
}

function write_notes_legacy(clip, notes)
{
    var i;
    var note;

    clip.call("select_all_notes");
    clip.call("replace_selected_notes");
    clip.call("notes", notes.length);
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
    clip.call("done");
}

function live_api_from_id(id_value)
{
    var id = id_value;
    var api;

    if (id === null || typeof id === "undefined") {
        return null;
    }

    if (id instanceof Array) {
        id = id.length > 1 && id[0] === "id" ? id[1] : id[0];
    }

    if (typeof id === "string" && id.indexOf("id ") === 0) {
        id = id.substring(3);
    }

    api = new LiveAPI(null);
    api.id = id;
    return api;
}

function live_api_get(api, property)
{
    try {
        return api.get(property);
    } catch (err) {
        post("cryptoseq export: " + property + " unavailable\n");
        return null;
    }
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

function round_beats(value)
{
    return Math.round(value * 1000000) / 1000000;
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
