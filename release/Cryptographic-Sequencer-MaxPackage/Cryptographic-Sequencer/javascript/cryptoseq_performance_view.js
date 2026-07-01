autowatch = 1;
mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;

var scene_value = 0;
var ratchet_amount = 0;
var ratchet_max = 1;
var fill_amount = 0;
var fill_mode = "off";
var fill_target = "all";
var crt_split = "off";
var morph_amount = 0;
var morph_scene = 1;
var morph_mode = "all";
var redraw_task = null;
var redraw_pending = 0;

function scene(value)
{
    scene_value = clamp_int(value, 0, 127, scene_value);
    request_redraw();
}

function ratchetamount(value)
{
    ratchet_amount = clamp_int(value, 0, 100, ratchet_amount);
    request_redraw();
}

function ratchetmax(value)
{
    ratchet_max = clamp_int(value, 1, 8, ratchet_max);
    request_redraw();
}

function fillmode(value)
{
    fill_mode = value.toString();
    request_redraw();
}

function fillamount(value)
{
    fill_amount = clamp_int(value, 0, 100, fill_amount);
    request_redraw();
}

function filltarget(value)
{
    var text = value.toString();

    fill_target = (text === "al") ? "all" : text;
    request_redraw();
}

function morphamount(value)
{
    morph_amount = clamp_int(value, 0, 100, morph_amount);
    request_redraw();
}

function morphscene(value)
{
    morph_scene = clamp_int(value, 0, 127, morph_scene);
    request_redraw();
}

function morphmode(value)
{
    morph_mode = value.toString();
    request_redraw();
}

function crtsplit(value)
{
    crt_split = value.toString();
    request_redraw();
}

function anything()
{
}

function request_redraw()
{
    if (redraw_pending) {
        return;
    }

    redraw_pending = 1;
    if (redraw_task === null) {
        redraw_task = new Task(flush_redraw, this);
    }
    redraw_task.schedule(24);
}

function flush_redraw()
{
    redraw_pending = 0;
    mgraphics.redraw();
}

function paint()
{
    var width = box.rect[2] - box.rect[0];
    var height = box.rect[3] - box.rect[1];

    background(width, height);
    title("performance");
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

function title(text)
{
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(13);
    mgraphics.set_source_rgba(0.78, 0.90, 0.92, 1);
    mgraphics.move_to(12, 20);
    mgraphics.show_text(text);
}

function clamp_int(value, min_value, max_value, fallback)
{
    var parsed = parseInt(value, 10);

    if (isNaN(parsed)) {
        return fallback;
    }

    return Math.max(min_value, Math.min(max_value, parsed));
}
