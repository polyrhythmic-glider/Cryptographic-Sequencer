autowatch = 1;
inlets = 1;
outlets = 3;

function list(step, active, note, velocity, accent, duration, gate, value)
{
    var duration_ms;

    if (!active) {
        return;
    }

    duration_ms = Math.max(20, parseInt(duration, 10) * 125);

    outlet(2, duration_ms);
    outlet(1, parseInt(velocity, 10));
    outlet(0, parseInt(note, 10));
}
