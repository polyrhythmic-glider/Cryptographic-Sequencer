autowatch = 1;
inlets = 1;
outlets = 2;

var midi_controls = {
    poly: 1,
    ratchetamount: 1,
    ratchetmax: 1,
    fillmode: 1,
    fillamount: 1,
    filltarget: 1,
    mode: 1,
    length: 1
};

var immediate_setup_controls = {
    morphamount: 1,
    morphscene: 1,
    morphmode: 1,
    morph: 1
};

function anything()
{
    var args = arrayfromargs(arguments);
    var name = messagename.toString();
    var goes_to_core = name !== "poly" &&
        name !== "ratchetamount" &&
        name !== "ratchetmax" &&
        name !== "fillmode" &&
        name !== "fillamount" &&
        name !== "filltarget";

    if (midi_controls[name]) {
        outlet.apply(this, [1, name].concat(args));
    }

    if (goes_to_core) {
        outlet.apply(this, [0, name].concat(args));
        if (immediate_setup_controls[name]) {
            outlet(0, "setup");
        }
    }
}

function msg_int(value)
{
    outlet(1, "length", value);
}

function msg_float(value)
{
    outlet(1, "length", Math.round(value));
}

function list()
{
    outlet(0, arrayfromargs(arguments));
}

function bang()
{
    outlet(0, "bang");
}
