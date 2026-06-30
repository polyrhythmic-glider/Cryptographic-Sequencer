autowatch = 1;
outlets = 1;
mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;

var source_path = "demo source";
var source_type = "text";
var image_box_name = "cs_source_image";

function file(path)
{
    source_path = path.toString();
    source_type = classify(source_path);
    if (source_type === "image") {
        set_image_hidden(false);
        outlet(0, "read", source_path);
    } else {
        set_image_hidden(true);
    }
    mgraphics.redraw();
}

function text()
{
    source_path = arrayfromargs(arguments).join(" ");
    source_type = "text";
    set_image_hidden(true);
    mgraphics.redraw();
}

function paint()
{
    var width = box.rect[2] - box.rect[0];
    var height = box.rect[3] - box.rect[1];

    background(width, height);
    if (source_type !== "image") {
        draw_preview(width, height);
    }
    label(12, 20, "source: " + source_type);
    small(12, height - 48, basename(source_path));
}

function draw_preview(width, height)
{
    if (source_type === "image") {
        image_placeholder(width, height);
    } else if (source_type === "audio") {
        waveform(width, height);
    } else if (source_type === "video") {
        filmstrip(width, height);
    } else {
        fingerprint(width, height);
    }
}

function image_placeholder(width, height)
{
    mgraphics.set_source_rgba(0.12, 0.13, 0.13, 1);
    mgraphics.rectangle(10, 34, width - 20, height - 82);
    mgraphics.fill();
    mgraphics.set_source_rgba(0.30, 0.34, 0.34, 1);
    mgraphics.rectangle(10.5, 34.5, width - 21, height - 83);
    mgraphics.stroke();
}

function waveform(width, height)
{
    var seed = hash(source_path);
    var mid = Math.floor(height * 0.55);
    var x;
    var amp;

    mgraphics.set_source_rgba(0.18, 0.46, 0.58, 1);
    for (x = 12; x < width - 12; x += 2) {
        seed = next(seed);
        amp = 8 + (seed % Math.max(12, Math.floor(height * 0.34)));
        mgraphics.rectangle(x, mid - amp / 2, 1, amp);
        mgraphics.fill();
    }
}

function filmstrip(width, height)
{
    var x;

    mgraphics.set_source_rgba(0.16, 0.16, 0.15, 1);
    mgraphics.rectangle(10, 36, width - 20, height - 62);
    mgraphics.fill();
    mgraphics.set_source_rgba(0.54, 0.48, 0.24, 1);
    for (x = 14; x < width - 18; x += 18) {
        mgraphics.rectangle(x, 40, 8, 5);
        mgraphics.rectangle(x, height - 32, 8, 5);
        mgraphics.fill();
    }
}

function fingerprint(width, height)
{
    var seed = hash(source_path);
    var i;
    var x;
    var y;

    mgraphics.set_source_rgba(0.34, 0.36, 0.36, 1);
    for (i = 0; i < 42; i += 1) {
        seed = next(seed);
        x = 14 + (seed % Math.max(1, width - 32));
        seed = next(seed);
        y = 36 + (seed % Math.max(1, height - 66));
        mgraphics.rectangle(x, y, 3 + (seed % 12), 3);
        mgraphics.fill();
    }
}

function background(width, height)
{
    mgraphics.set_source_rgba(0.08, 0.08, 0.08, 1);
    if (source_type !== "image") {
        mgraphics.rectangle(0, 0, width, height);
        mgraphics.fill();
    }
    mgraphics.set_source_rgba(0.28, 0.30, 0.30, 1);
    mgraphics.rectangle(0.5, 0.5, width - 1, height - 1);
    mgraphics.stroke();
}

function label(x, y, value)
{
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(12);
    mgraphics.set_source_rgba(0.85, 0.89, 0.88, 1);
    mgraphics.move_to(x, y);
    mgraphics.show_text(value);
}

function small(x, y, value)
{
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(10);
    mgraphics.set_source_rgba(0.72, 0.74, 0.72, 1);
    mgraphics.move_to(x, y);
    mgraphics.show_text(value.substring(0, 58));
}

function classify(path)
{
    var ext = extension(path);

    if (array_has(["jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", "webp"], ext)) {
        return "image";
    }
    if (array_has(["wav", "aif", "aiff", "mp3", "flac", "m4a", "ogg"], ext)) {
        return "audio";
    }
    if (array_has(["mov", "mp4", "avi", "mkv"], ext)) {
        return "video";
    }
    return "file";
}

function basename(path)
{
    var parts = path.toString().split(/[\/\\]/);
    return parts[parts.length - 1];
}

function extension(path)
{
    var name = basename(path);
    var dot = name.lastIndexOf(".");

    if (dot < 0) {
        return "";
    }

    return name.substring(dot + 1).toLowerCase();
}

function hash(text_value)
{
    var value = 2166136261;
    var i;

    for (i = 0; i < text_value.length; i += 1) {
        value ^= text_value.charCodeAt(i);
        value = (value * 16777619) >>> 0;
    }

    return value;
}

function next(value)
{
    return ((value * 1664525) + 1013904223) >>> 0;
}

function array_has(values, needle)
{
    var i;

    for (i = 0; i < values.length; i += 1) {
        if (values[i] === needle) {
            return true;
        }
    }
    return false;
}

function set_image_hidden(hidden)
{
    var image_box;

    if (!this.patcher) {
        return;
    }

    image_box = this.patcher.getnamed(image_box_name);
    if (image_box) {
        try {
            image_box.hidden = hidden ? 1 : 0;
        } catch (err) {
        }
    }
}
