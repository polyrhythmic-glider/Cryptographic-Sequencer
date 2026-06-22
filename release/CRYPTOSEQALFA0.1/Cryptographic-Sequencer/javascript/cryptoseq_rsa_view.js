autowatch = 1;
mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;

var p_value = 251;
var q_value = 257;
var e_value = 65537;

function rsa(p, q, e)
{
    p_value = parseInt(p, 10);
    q_value = parseInt(q, 10);
    e_value = parseInt(e, 10);
    mgraphics.redraw();
}

function paint()
{
    var width = box.rect[2] - box.rect[0];
    var height = box.rect[3] - box.rect[1];
    var n = p_value * q_value;
    var phi = (p_value - 1) * (q_value - 1);
    var coprime = gcd(e_value, phi) === 1;

    background(width, height);
    label(12, 20, "RSA");
    line(12, 42, "n = p * q = " + p_value + " * " + q_value + " = " + n);
    line(12, 64, "phi(n) = (p - 1)(q - 1) = " + phi);
    line(12, 86, "gcd(e, phi) = gcd(" + e_value + ", " + phi + ") = " + gcd(e_value, phi));
    badge(width - 80, 14, coprime ? "valid" : "invalid", coprime);
}

function background(width, height)
{
    mgraphics.set_source_rgba(0.09, 0.10, 0.11, 1);
    mgraphics.rectangle(0, 0, width, height);
    mgraphics.fill();
    mgraphics.set_source_rgba(0.30, 0.33, 0.35, 1);
    mgraphics.rectangle(0.5, 0.5, width - 1, height - 1);
    mgraphics.stroke();
}

function label(x, y, text)
{
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(13);
    mgraphics.set_source_rgba(0.78, 0.90, 0.92, 1);
    mgraphics.move_to(x, y);
    mgraphics.show_text(text);
}

function line(x, y, text)
{
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(11);
    mgraphics.set_source_rgba(0.86, 0.86, 0.82, 1);
    mgraphics.move_to(x, y);
    mgraphics.show_text(text);
}

function badge(x, y, text, ok)
{
    mgraphics.set_source_rgba(ok ? 0.18 : 0.55, ok ? 0.52 : 0.16, ok ? 0.32 : 0.18, 1);
    mgraphics.rectangle(x, y, 64, 20);
    mgraphics.fill();
    mgraphics.set_source_rgba(0.95, 0.95, 0.90, 1);
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(10);
    mgraphics.move_to(x + 10, y + 14);
    mgraphics.show_text(text);
}

function gcd(a, b)
{
    var temp;

    a = Math.abs(parseInt(a, 10));
    b = Math.abs(parseInt(b, 10));
    while (b !== 0) {
        temp = a % b;
        a = b;
        b = temp;
    }

    return a;
}
