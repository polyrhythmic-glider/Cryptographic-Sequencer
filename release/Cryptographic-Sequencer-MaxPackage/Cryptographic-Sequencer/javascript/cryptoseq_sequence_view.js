autowatch = 1;
mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;

var MAX_STEPS = 128;
var events = [];
var length_value = 16;
var current_step = 0;
var current_mode = "hybrid";

function length(value)
{
    length_value = clamp(parseInt(value, 10), 1, MAX_STEPS);
    trim_events();
    mgraphics.redraw();
}

function mode(value)
{
    current_mode = value.toString();
    mgraphics.redraw();
}

function step(value)
{
    current_step = clamp(parseInt(value, 10), 0, MAX_STEPS - 1);
    mgraphics.redraw();
}

function list(step_index, active, note, velocity, accent, duration, gate, value)
{
    var index = clamp(parseInt(step_index, 10), 0, MAX_STEPS - 1);

    events[index] = {
        active: parseInt(active, 10) ? 1 : 0,
        note: parseInt(note, 10),
        velocity: parseInt(velocity, 10),
        accent: parseInt(accent, 10),
        duration: parseInt(duration, 10),
        gate: parseInt(gate, 10),
        value: parseInt(value, 10)
    };
    mgraphics.redraw();
}

function paint()
{
    var width = box.rect[2] - box.rect[0];
    var height = box.rect[3] - box.rect[1];
    var i;
    var x;
    var w = Math.max(2, Math.min(18, Math.floor((width - 20) / length_value)));
    var total_width = w * length_value;
    var left = Math.max(10, Math.floor((width - total_width) / 2));
    var lane_top = 34;
    var lane_height = height - 86;

    background(width, height);
    header();

    for (i = 0; i < length_value; i += 1) {
        x = left + (i * w);
        draw_step(x, lane_top, Math.max(1, w - 3), lane_height, i, events[i]);
    }
}

function draw_step(x, y, w, h, index, event)
{
    var active = event && event.active;
    var velocity = event ? clamp(event.velocity, 1, 127) : 0;
    var note = event ? clamp(event.note, 0, 127) : 60;
    var bar_height = active ? Math.max(4, Math.round((velocity / 127) * (h - 8))) : 3;
    var note_y = y + h - bar_height;
    var hue = (note % 12) / 12;

    mgraphics.set_source_rgba(0.17, 0.18, 0.18, 1);
    mgraphics.rectangle(x, y, w, h);
    mgraphics.fill();

    if (active) {
        if (current_mode === "melodic" || current_mode === "melody") {
            color_from_pitch(hue, 0.82);
        } else if (current_mode === "hybrid") {
            mgraphics.set_source_rgba(0.22, 0.62, 0.82, 0.92);
        } else {
            mgraphics.set_source_rgba(0.87, 0.62, 0.22, 0.92);
        }
        mgraphics.rectangle(x, note_y, w, bar_height);
        mgraphics.fill();
    }

    if (index === current_step) {
        mgraphics.set_source_rgba(0.98, 0.96, 0.68, 1);
        mgraphics.rectangle(x, y, w, h);
        mgraphics.stroke();
    }
}

function background(width, height)
{
    mgraphics.set_source_rgba(0.08, 0.09, 0.10, 1);
    mgraphics.rectangle(0, 0, width, height);
    mgraphics.fill();
    mgraphics.set_source_rgba(0.27, 0.29, 0.30, 1);
    mgraphics.rectangle(0.5, 0.5, width - 1, height - 1);
    mgraphics.stroke();
}

function header()
{
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(12);
    mgraphics.set_source_rgba(0.82, 0.90, 0.92, 1);
    mgraphics.move_to(10, 20);
    mgraphics.show_text("sequence " + length_value + " steps");
}

function color_from_pitch(hue, alpha)
{
    var r = 0.40 + (0.45 * Math.sin((hue + 0.00) * 6.28318));
    var g = 0.40 + (0.45 * Math.sin((hue + 0.33) * 6.28318));
    var b = 0.40 + (0.45 * Math.sin((hue + 0.66) * 6.28318));
    mgraphics.set_source_rgba(clamp_float(r), clamp_float(g), clamp_float(b), alpha);
}

function trim_events()
{
    if (events.length > length_value) {
        events.length = length_value;
    }
}

function clamp(value, min_value, max_value)
{
    if (isNaN(value)) {
        return min_value;
    }
    return Math.max(min_value, Math.min(max_value, value));
}

function clamp_float(value)
{
    return Math.max(0, Math.min(1, value));
}
