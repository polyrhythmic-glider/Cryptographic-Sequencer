autowatch = 1;
inlets = 1;
outlets = 11;

var MAX_PRIME = 65521;
var DEFAULT_P = 251;
var DEFAULT_Q = 257;
var DEFAULT_E = 65537;
var DEFAULT_MELODY_LOW = 60;
var DEFAULT_MELODY_HIGH = 84;
var DEFAULT_PAD_COUNT = 16;
var rhythm_divisor = 16;
var rhythm_threshold = 8;
var current_p = DEFAULT_P;
var current_q = DEFAULT_Q;
var current_e = DEFAULT_E;
var current_mode = "hybrid";
var current_melody_low = DEFAULT_MELODY_LOW;
var current_melody_high = DEFAULT_MELODY_HIGH;
var current_pad_count = DEFAULT_PAD_COUNT;
var current_scale = "major";
var live_scale_intervals = null;
var primes = [];
var exponent_candidates = [3, 5, 17, 257, 65537];
var pad_count_candidates = [1, 4, 8, 12, 16, 24, 32];
var note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

function is_prime(value)
{
    var divisor;

    if (value < 2) {
        return false;
    }

    if (value === 2 || value === 3) {
        return true;
    }

    if ((value % 2) === 0 || (value % 3) === 0) {
        return false;
    }

    for (divisor = 5; divisor <= Math.floor(value / divisor); divisor += 6) {
        if ((value % divisor) === 0 || (value % (divisor + 2)) === 0) {
            return false;
        }
    }

    return true;
}

function ensure_primes()
{
    var value;

    if (primes.length > 0) {
        return;
    }

    for (value = 2; value <= MAX_PRIME; value += 1) {
        if (is_prime(value)) {
            primes.push(value);
        }
    }
}

function fill_prime_menu(outlet_index, selected)
{
    var i;
    var selected_index = 0;

    outlet(outlet_index, "clear");
    for (i = 0; i < primes.length; i += 1) {
        if (primes[i] === selected) {
            selected_index = i;
        }
        outlet(outlet_index, "append", primes[i].toString());
    }
    outlet(outlet_index, "setsymbol", selected.toString());
    outlet(outlet_index, "set", selected_index);
}

function fill_root_menu(outlet_index, selected)
{
    var midi;

    outlet(outlet_index, "clear");
    for (midi = 24; midi <= 96; midi += 1) {
        outlet(outlet_index, "append", midi_to_note_name(midi));
    }
    outlet(outlet_index, "setsymbol", midi_to_note_name(selected));
}

function fill_note_menu(outlet_index, selected, min_note, max_note)
{
    var midi;

    outlet(outlet_index, "clear");
    for (midi = min_note; midi <= max_note; midi += 1) {
        outlet(outlet_index, "append", midi_to_note_name(midi));
    }
    outlet(outlet_index, "setsymbol", midi_to_note_name(selected));
}

function fill_pad_count_menu(outlet_index, selected)
{
    var i;

    outlet(outlet_index, "clear");
    for (i = 0; i < pad_count_candidates.length; i += 1) {
        outlet(outlet_index, "append", pad_count_candidates[i].toString());
    }
    outlet(outlet_index, "setsymbol", selected.toString());
}

function init()
{
    ensure_primes();
    current_p = DEFAULT_P;
    current_q = DEFAULT_Q;
    current_e = DEFAULT_E;
    current_mode = "hybrid";
    current_melody_low = DEFAULT_MELODY_LOW;
    current_melody_high = DEFAULT_MELODY_HIGH;
    current_pad_count = DEFAULT_PAD_COUNT;
    fill_prime_menu(1, current_p);
    fill_prime_menu(2, current_q);
    fill_exponent_menu(current_e);
    fill_root_menu(4, 60);
    fill_note_menu(6, current_melody_low, 24, 108);
    fill_note_menu(7, current_melody_high, 24, 108);
    fill_pad_count_menu(8, current_pad_count);
    show_mode(current_mode);
    outlet(3, 16);
    send_checked_rsa();
    outlet(0, "melodyrange", current_melody_low, current_melody_high);
    outlet(0, "padcount", current_pad_count);
    outlet(9, "rsa", current_p, current_q, current_e);
    outlet(10, "mode", current_mode);
}

function bang()
{
    init();
}

function p(value)
{
    var prime = parse_prime("p", value);

    if (prime === null) {
        return;
    }

    current_p = prime;
    if (current_p === current_q) {
        current_q = nearest_different_prime(current_p);
        fill_prime_menu(2, current_q);
    }

    send_checked_rsa();
}

function q(value)
{
    var prime = parse_prime("q", value);

    if (prime === null) {
        return;
    }

    current_q = prime;
    if (current_q === current_p) {
        current_p = nearest_different_prime(current_q);
        fill_prime_menu(1, current_p);
    }

    send_checked_rsa();
}

function e(value)
{
    var parsed = parse_int(value, 1, 2147483647);

    if (parsed === null) {
        return;
    }

    if (!is_coprime_with_phi(parsed, current_p, current_q)) {
        post("cryptoseq-ui: ignored non-coprime e " + parsed + "\n");
        fill_exponent_menu(current_e);
        return;
    }

    current_e = parsed;
    outlet(0, "rsa", current_p, current_q, current_e);
    outlet(9, "rsa", current_p, current_q, current_e);
}

function length(value)
{
    var parsed = parse_int(value, 1, 128);

    if (parsed === null) {
        return;
    }

    send_length(parsed);
}

function uilength(value)
{
    var parsed = parse_int(value, 0, 127);

    if (parsed === null) {
        return;
    }

    send_length(parsed + 1);
}

function send_length(value)
{
    outlet(0, "length", value);
    outlet(3, value);
}

function shift(value)
{
    var parsed = parse_int(value, 0, 127);

    if (parsed === null) {
        return;
    }

    outlet(0, "shift", parsed);
}

function scene(value)
{
    var parsed = parse_int(value, 0, 127);

    if (parsed === null) {
        return;
    }

    outlet(0, "scene", parsed);
}

function ratchetamount(value)
{
    var parsed = parse_int(value, 0, 100);

    if (parsed === null) {
        return;
    }

    outlet(0, "ratchetamount", parsed);
}

function ratchetmax(value)
{
    var parsed = parse_int(value, 1, 8);

    if (parsed === null) {
        return;
    }

    outlet(0, "ratchetmax", parsed);
}

function fillmode(value)
{
    var text = value.toString();

    if (text !== "off" && text !== "end" && text !== "accent" && text !== "velocity") {
        post("cryptoseq-ui: ignored fill mode " + text + "\n");
        return;
    }

    outlet(0, "fillmode", text);
}

function lockpitch(value)
{
    send_lock("pitch", value);
}

function lockrhythm(value)
{
    send_lock("rhythm", value);
}

function lockvelocity(value)
{
    send_lock("velocity", value);
}

function lockgate(value)
{
    send_lock("gate", value);
}

function send_lock(name, value)
{
    var parsed = parse_int(value, 0, 1);

    if (parsed === null) {
        return;
    }

    outlet(0, "lock", name, parsed);
}

function morphamount(value)
{
    var parsed = parse_int(value, 0, 100);

    if (parsed === null) {
        return;
    }

    outlet(0, "morphamount", parsed);
}

function morphscene(value)
{
    var parsed = parse_int(value, 0, 127);

    if (parsed === null) {
        return;
    }

    outlet(0, "morphscene", parsed);
}

function morphmode(value)
{
    var text = value.toString();

    if (text !== "all" && text !== "pitch" && text !== "rhythm" && text !== "velocity") {
        post("cryptoseq-ui: ignored morph mode " + text + "\n");
        return;
    }

    outlet(0, "morphmode", text);
}

function root(value)
{
    var parsed = note_name_to_midi(value);

    if (parsed !== null && (parsed < 24 || parsed > 96)) {
        post("cryptoseq-ui: ignored out-of-range root " + value + "\n");
        return;
    }

    if (parsed === null) {
        parsed = parse_int(value, 24, 96);
    }

    if (parsed === null) {
        return;
    }

    outlet(0, "root", parsed);
}

function mode(value)
{
    current_mode = value.toString();
    show_mode(current_mode);
    outlet(0, "mode", current_mode);
    outlet(10, "mode", current_mode);
    if (current_scale === "live" && mode_uses_musical_scale(current_mode)) {
        send_live_scale();
    }
}

function scale(value)
{
    current_scale = value.toString();

    if (!mode_uses_musical_scale(current_mode)) {
        return;
    }

    if (current_scale === "live") {
        send_live_scale();
        return;
    }

    outlet(0, "scale", current_scale);
}

function livescale()
{
    live_scale_intervals = parse_live_scale(arrayfromargs(arguments));
    if (current_scale === "live" && mode_uses_musical_scale(current_mode)) {
        send_live_scale();
    }
}

function send_live_scale()
{
    var message;

    if (live_scale_intervals === null || live_scale_intervals.length === 0) {
        post("cryptoseq-ui: Live scale is not available, using chromatic fallback\n");
        live_scale_intervals = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    }

    message = ["scaleintervals"].concat(live_scale_intervals);
    outlet.apply(this, [0].concat(message));
}

function parse_live_scale(values)
{
    var result = [];
    var i;
    var parsed;

    for (i = 0; i < values.length; i += 1) {
        parsed = parseInt(values[i], 10);
        if (!isNaN(parsed)) {
            result.push(positive_mod(parsed, 12));
        }
    }

    if (result.length > 12) {
        result = result.slice(0, 12);
    }

    return result;
}

function density(value)
{
    var percent = parse_int(value, 0, 100);

    if (percent === null) {
        return;
    }

    rhythm_threshold = Math.round((percent * rhythm_divisor) / 100);
    outlet(0, "rhythm", rhythm_divisor, rhythm_threshold);
}

function melodylow(value)
{
    var parsed = parse_note(value, 0, 127, "melody low");

    if (parsed === null) {
        return;
    }

    current_melody_low = parsed;
    if (current_melody_low > current_melody_high) {
        current_melody_high = current_melody_low;
        fill_note_menu(7, current_melody_high, 24, 108);
    }

    outlet(0, "melodyrange", current_melody_low, current_melody_high);
}

function melodyhigh(value)
{
    var parsed = parse_note(value, 0, 127, "melody high");

    if (parsed === null) {
        return;
    }

    current_melody_high = parsed;
    if (current_melody_high < current_melody_low) {
        current_melody_low = current_melody_high;
        fill_note_menu(6, current_melody_low, 24, 108);
    }

    outlet(0, "melodyrange", current_melody_low, current_melody_high);
}

function padcount(value)
{
    var parsed = parse_int(value, 1, 128);

    if (parsed === null) {
        return;
    }

    current_pad_count = parsed;
    outlet(0, "padcount", current_pad_count);
}

function send_prime(name, value)
{
    var prime = parse_prime(name, value);

    if (prime === null) {
        return;
    }

    outlet(0, name, prime);
}

function parse_prime(name, value)
{
    var prime = parseInt(value, 10);

    if (isNaN(prime) || prime > MAX_PRIME || !is_prime(prime)) {
        post("cryptoseq-ui: ignored non-prime " + name + " value " + value + "\n");
        return null;
    }

    return prime;
}

function send_int(name, value, min_value, max_value)
{
    var parsed = parse_int(value, min_value, max_value);

    if (parsed === null) {
        return;
    }

    outlet(0, name, parsed);
}

function parse_int(value, min_value, max_value)
{
    var parsed = parseInt(value, 10);

    if (isNaN(parsed) || parsed < min_value || parsed > max_value) {
        post("cryptoseq-ui: ignored " + value + "\n");
        return null;
    }

    return parsed;
}

function parse_note(value, min_value, max_value, label)
{
    var parsed = note_name_to_midi(value);

    if (parsed === null) {
        parsed = parse_int(value, min_value, max_value);
    }

    if (parsed === null || parsed < min_value || parsed > max_value) {
        post("cryptoseq-ui: ignored " + label + " " + value + "\n");
        return null;
    }

    return parsed;
}

function show_mode(mode)
{
    var is_melodic = mode_uses_musical_scale(mode);
    var is_hybrid = mode === "hybrid";

    set_hidden_many([
        "cs_scale_label",
        "cs_scale_menu",
        "cs_scale_note",
        "cs_melody_low_label",
        "cs_melody_low_menu",
        "cs_melody_high_label",
        "cs_melody_high_menu",
        "cs_poly_label",
        "cs_poly_toggle"
    ], !is_melodic);

    set_hidden_many([
        "cs_pad_count_label",
        "cs_pad_count_menu"
    ], !is_hybrid);

    set_hidden_many([
        "cs_density_label",
        "cs_density_dial"
    ], false);
}

function mode_uses_musical_scale(mode)
{
    return mode === "melodic" || mode === "melody";
}

function set_hidden_many(names, hidden)
{
    var i;

    for (i = 0; i < names.length; i += 1) {
        set_hidden(names[i], hidden);
    }
}

function set_hidden(name, hidden)
{
    var box;

    if (!this.patcher) {
        return;
    }

    box = this.patcher.getnamed(name);
    if (box) {
        try {
            box.hidden = hidden ? 1 : 0;
        } catch (err) {
            post("cryptoseq-ui: could not set hidden for " + name + "\n");
        }
    }
}

function fill_exponent_menu(selected)
{
    var valid = valid_exponents(current_p, current_q);
    var i;

    if (array_index_of(valid, selected) < 0) {
        selected = choose_smallest_exponent(valid);
    }

    current_e = selected;
    outlet(5, "clear");
    for (i = 0; i < valid.length; i += 1) {
        outlet(5, "append", valid[i].toString());
    }
    outlet(5, "setsymbol", selected.toString());
}

function send_checked_rsa()
{
    var valid = valid_exponents(current_p, current_q);
    var next_e = choose_smallest_exponent(valid);

    if (next_e === null) {
        post("cryptoseq-ui: no valid exponent for " + current_p + " and " + current_q + "\n");
        return;
    }

    current_e = next_e;
    fill_exponent_menu(current_e);
    outlet(0, "rsa", current_p, current_q, current_e);
    outlet(9, "rsa", current_p, current_q, current_e);
}

function valid_exponents(p_value, q_value)
{
    var result = [];
    var i;

    for (i = 0; i < exponent_candidates.length; i += 1) {
        if (is_coprime_with_phi(exponent_candidates[i], p_value, q_value)) {
            result.push(exponent_candidates[i]);
        }
    }

    return result;
}

function choose_smallest_exponent(valid)
{
    if (valid.length === 0) {
        return null;
    }

    return valid[0];
}

function is_coprime_with_phi(e_value, p_value, q_value)
{
    var phi = (p_value - 1) * (q_value - 1);
    return e_value > 1 && e_value < phi && gcd(e_value, phi) === 1;
}

function gcd(a, b)
{
    var temp;

    a = Math.abs(a);
    b = Math.abs(b);
    while (b !== 0) {
        temp = a % b;
        a = b;
        b = temp;
    }

    return a;
}

function positive_mod(value, modulo)
{
    var result = value % modulo;
    return result < 0 ? result + modulo : result;
}

function nearest_different_prime(value)
{
    var index = array_index_of(primes, value);

    if (index < 0) {
        return DEFAULT_Q;
    }

    if (index + 1 < primes.length) {
        return primes[index + 1];
    }

    return primes[index - 1];
}

function array_index_of(values, value)
{
    var i;

    for (i = 0; i < values.length; i += 1) {
        if (values[i] === value) {
            return i;
        }
    }

    return -1;
}

function midi_to_note_name(midi)
{
    var pitch_class = midi % 12;
    var octave = Math.floor(midi / 12) - 2;
    return note_names[pitch_class] + octave.toString();
}

function note_name_to_midi(value)
{
    var text = value.toString();
    var match = text.match(/^([A-Ga-g])(#?)(-?[0-9]+)$/);
    var base;
    var pitch_class;
    var octave;
    var midi;

    if (!match) {
        return null;
    }

    base = match[1].toUpperCase();
    pitch_class = {
        C: 0,
        D: 2,
        E: 4,
        F: 5,
        G: 7,
        A: 9,
        B: 11
    }[base];

    if (match[2] === "#") {
        pitch_class += 1;
    }

    octave = parseInt(match[3], 10);
    midi = ((octave + 2) * 12) + pitch_class;

    if (midi < 0 || midi > 127) {
        post("cryptoseq-ui: ignored out-of-range root " + text + "\n");
        return null;
    }

    return midi;
}
