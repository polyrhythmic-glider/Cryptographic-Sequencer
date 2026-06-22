autowatch = 1;
inlets = 1;
outlets = 3;

var DEFAULT_TEMPO = 120;
var current_interval = "16n";
var live_set = null;

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

function list(step, active, note, velocity, accent, duration, gate, value)
{
    var duration_ms;
    var step_ms;
    var duration_units;
    var gate_scale;

    if (!active) {
        return;
    }

    step_ms = interval_to_ms(current_interval, current_tempo());
    duration_units = Math.max(1, parseInt(duration, 10));
    gate_scale = Math.max(0.05, Math.min(1, parseInt(gate, 10) / 1000));
    duration_ms = Math.max(20, Math.round(step_ms * duration_units * gate_scale));

    outlet(2, duration_ms);
    outlet(1, parseInt(velocity, 10));
    outlet(0, parseInt(note, 10));
}

function current_tempo()
{
    var tempo;

    try {
        if (typeof LiveAPI !== "undefined") {
            if (live_set === null) {
                live_set = new LiveAPI(null, "live_set");
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
