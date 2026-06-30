autowatch = 1;
inlets = 1;
outlets = 1;

var poll_task = null;
var last_signature = "";
var live_api_ready = false;
var live_set_api = null;
var live_scale_supported = null;

function bang()
{
    if (!live_api_ready) {
        return;
    }

    start_polling();
    refresh();
}

function ready(value)
{
    var parsed = parseInt(value, 10);

    live_api_ready = parsed !== 0;
    if (live_api_ready) {
        ensure_live_set_api();
        start_polling();
        refresh();
    }
}

function refresh()
{
    var intervals = read_live_scale_intervals();
    var signature;

    if (intervals === null || intervals.length === 0) {
        return;
    }

    signature = intervals.join(",");
    if (signature === last_signature) {
        return;
    }

    last_signature = signature;
    outlet.apply(this, [0, "livescale"].concat(intervals));
}

function start_polling()
{
    if (poll_task !== null) {
        return;
    }

    poll_task = new Task(refresh, this);
    poll_task.interval = 2000;
    poll_task.repeat();
}

function read_live_scale_intervals()
{
    var value;

    try {
        if (!live_api_ready || typeof LiveAPI === "undefined") {
            return null;
        }

        if (!ensure_live_set_api()) {
            return null;
        }

        if (!live_api_has_property(live_set_api, "scale_intervals")) {
            return null;
        }

        value = live_set_api.get("scale_intervals");
        return parse_intervals(value);
    } catch (err) {
        live_set_api = null;
        return null;
    }
}

function ensure_live_set_api()
{
    if (!live_api_ready || typeof LiveAPI === "undefined") {
        return false;
    }

    if (live_api_has_object(live_set_api)) {
        return true;
    }

    try {
        live_set_api = new LiveAPI(null);
        live_set_api.path = "live_set";
        live_scale_supported = null;
    } catch (err) {
        live_set_api = null;
        live_scale_supported = null;
        return false;
    }

    return live_api_has_object(live_set_api);
}

function live_api_has_property(api, name)
{
    var info;

    if (live_scale_supported !== null) {
        return live_scale_supported;
    }

    if (!live_api_has_object(api)) {
        live_scale_supported = false;
        return false;
    }

    try {
        info = api.info;
    } catch (err) {
        live_scale_supported = false;
        return false;
    }

    if (info === null || typeof info === "undefined") {
        live_scale_supported = false;
        return false;
    }

    live_scale_supported = info.toString().indexOf(name) >= 0;
    return live_scale_supported;
}

function parse_intervals(value)
{
    var raw = value;
    var result = [];
    var i;
    var parsed;

    if (raw === null || typeof raw === "undefined") {
        return result;
    }

    if (!(raw instanceof Array)) {
        raw = raw.toString().split(/\s+/);
    }

    for (i = 0; i < raw.length; i += 1) {
        if (raw[i] === "scale_intervals") {
            continue;
        }

        parsed = parseInt(raw[i], 10);
        if (!isNaN(parsed)) {
            result.push(positive_mod(parsed, 12));
        }
    }

    if (result.length > 12) {
        result = result.slice(0, 12);
    }

    return result;
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

function positive_mod(value, modulo)
{
    var result = value % modulo;
    return result < 0 ? result + modulo : result;
}
