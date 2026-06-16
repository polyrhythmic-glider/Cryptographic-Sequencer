autowatch = 1;
inlets = 1;
outlets = 6;

var MAX_PRIME = 65521;
var DEFAULT_P = 251;
var DEFAULT_Q = 257;
var DEFAULT_E = 65537;
var rhythm_divisor = 16;
var rhythm_threshold = 8;
var current_p = DEFAULT_P;
var current_q = DEFAULT_Q;
var current_e = DEFAULT_E;
var primes = [];
var exponent_candidates = [3, 5, 17, 257, 65537];
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

function init()
{
    ensure_primes();
    current_p = DEFAULT_P;
    current_q = DEFAULT_Q;
    current_e = DEFAULT_E;
    fill_prime_menu(1, current_p);
    fill_prime_menu(2, current_q);
    fill_exponent_menu(current_e);
    fill_root_menu(4, 60);
    outlet(3, 16);
    outlet(0, "p", current_p);
    outlet(0, "q", current_q);
    send_checked_exponent();
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
        send_checked_exponent();
        outlet(0, "q", current_q);
    } else {
        send_checked_exponent();
    }

    outlet(0, "p", current_p);
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
        send_checked_exponent();
        outlet(0, "p", current_p);
    } else {
        send_checked_exponent();
    }

    outlet(0, "q", current_q);
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
    outlet(0, "e", current_e);
}

function length(value)
{
    var parsed = parse_int(value, 1, 4096);

    if (parsed === null) {
        return;
    }

    outlet(0, "length", parsed);
    outlet(3, parsed);
}

function root(value)
{
    var parsed = note_name_to_midi(value);

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
    outlet(0, "mode", value.toString());
}

function scale(value)
{
    outlet(0, "scale", value.toString());
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

function send_checked_exponent()
{
    var valid = valid_exponents(current_p, current_q);
    var next_e = choose_smallest_exponent(valid);

    current_e = next_e;
    fill_exponent_menu(current_e);
    outlet(0, "e", current_e);
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

    if (midi < 24 || midi > 96) {
        post("cryptoseq-ui: ignored out-of-range root " + text + "\n");
        return null;
    }

    return midi;
}
