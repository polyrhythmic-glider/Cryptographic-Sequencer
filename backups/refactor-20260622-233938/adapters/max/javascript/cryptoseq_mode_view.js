autowatch = 1;
mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;

var current_mode = "hybrid";

function mode(value)
{
    current_mode = value.toString();
    mgraphics.redraw();
}

function paint()
{
    var width = box.rect[2] - box.rect[0];
    var height = box.rect[3] - box.rect[1];

    background(width, height);

    if (current_mode === "melodic" || current_mode === "melody") {
        title("mode: " + current_mode);
    } else if (current_mode === "hybrid") {
        return;
    } else {
        title("mode: " + current_mode);
    }
}

function background(width, height)
{
    mgraphics.set_source_rgba(0.10, 0.10, 0.09, 1);
    mgraphics.rectangle(0, 0, width, height);
    mgraphics.fill();
    mgraphics.set_source_rgba(0.32, 0.32, 0.28, 1);
    mgraphics.rectangle(0.5, 0.5, width - 1, height - 1);
    mgraphics.stroke();
}

function title(text)
{
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(13);
    mgraphics.set_source_rgba(0.93, 0.84, 0.54, 1);
    mgraphics.move_to(14, 22);
    mgraphics.show_text(text);
}
