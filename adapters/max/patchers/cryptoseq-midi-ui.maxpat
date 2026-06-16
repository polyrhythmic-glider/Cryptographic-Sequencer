{
    "patcher": {
        "fileversion": 1,
        "appversion": {
            "major": 8,
            "minor": 6,
            "revision": 5,
            "architecture": "x64",
            "modernui": 1
        },
        "classnamespace": "box",
        "rect": [40.0, 40.0, 1180.0, 720.0],
        "gridsize": [15.0, 15.0],
        "boxes": [
            {"box": {"id": "obj-1", "maxclass": "newobj", "text": "loadbang", "numinlets": 1, "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [30.0, 30.0, 60.0, 22.0]}},
            {"box": {"id": "obj-2", "maxclass": "newobj", "text": "js cryptoseq_ui.js", "numinlets": 1, "numoutlets": 6, "outlettype": ["", "", "", "int", "", ""], "patching_rect": [30.0, 70.0, 130.0, 22.0]}},
            {"box": {"id": "obj-3", "maxclass": "newobj", "text": "cryptoseq", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [520.0, 260.0, 80.0, 22.0]}},
            {"box": {"id": "obj-4", "maxclass": "comment", "text": "Cryptoseq MIDI UI", "numinlets": 1, "numoutlets": 0, "patching_rect": [30.0, 5.0, 160.0, 22.0]}},

            {"box": {"id": "obj-5", "maxclass": "button", "numinlets": 1, "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [30.0, 42.0, 24.0, 24.0]}},
            {"box": {"id": "obj-6", "maxclass": "comment", "text": "file", "numinlets": 1, "numoutlets": 0, "patching_rect": [60.0, 43.0, 45.0, 22.0]}},
            {"box": {"id": "obj-7", "maxclass": "newobj", "text": "opendialog", "numinlets": 1, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [30.0, 610.0, 80.0, 22.0]}},
            {"box": {"id": "obj-8", "maxclass": "newobj", "text": "prepend sourcefile", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [125.0, 610.0, 115.0, 22.0]}},
            {"box": {"id": "obj-9", "maxclass": "message", "text": "source demo source", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [30.0, 78.0, 130.0, 22.0]}},

            {"box": {"id": "obj-10", "maxclass": "umenu", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "", ""], "patching_rect": [455.0, 42.0, 90.0, 22.0]}},
            {"box": {"id": "obj-11", "maxclass": "comment", "text": "p prime", "numinlets": 1, "numoutlets": 0, "patching_rect": [455.0, 18.0, 90.0, 20.0]}},
            {"box": {"id": "obj-12", "maxclass": "newobj", "text": "prepend p", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [455.0, 610.0, 75.0, 22.0]}},

            {"box": {"id": "obj-13", "maxclass": "umenu", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "", ""], "patching_rect": [555.0, 42.0, 90.0, 22.0]}},
            {"box": {"id": "obj-14", "maxclass": "comment", "text": "q prime", "numinlets": 1, "numoutlets": 0, "patching_rect": [555.0, 18.0, 90.0, 20.0]}},
            {"box": {"id": "obj-15", "maxclass": "newobj", "text": "prepend q", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [540.0, 610.0, 75.0, 22.0]}},

            {"box": {"id": "obj-16", "maxclass": "umenu", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "", ""], "patching_rect": [655.0, 42.0, 90.0, 22.0]}},
            {"box": {"id": "obj-17", "maxclass": "comment", "text": "RSA e", "numinlets": 1, "numoutlets": 0, "patching_rect": [655.0, 18.0, 90.0, 20.0]}},
            {"box": {"id": "obj-18", "maxclass": "newobj", "text": "prepend e", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [625.0, 610.0, 75.0, 22.0]}},
            {"box": {"id": "obj-19", "maxclass": "message", "text": "clear, append 65537, setsymbol 65537", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [625.0, 640.0, 210.0, 22.0]}},

            {"box": {"id": "obj-20", "maxclass": "umenu", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "", ""], "patching_rect": [755.0, 42.0, 75.0, 22.0]}},
            {"box": {"id": "obj-21", "maxclass": "comment", "text": "root note", "numinlets": 1, "numoutlets": 0, "patching_rect": [755.0, 18.0, 75.0, 20.0]}},
            {"box": {"id": "obj-22", "maxclass": "newobj", "text": "prepend root", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [710.0, 610.0, 90.0, 22.0]}},
            {"box": {"id": "obj-23", "maxclass": "message", "text": "setsymbol C3", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [850.0, 640.0, 85.0, 22.0]}},

            {"box": {"id": "obj-24", "maxclass": "umenu", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "", ""], "patching_rect": [850.0, 42.0, 95.0, 22.0]}},
            {"box": {"id": "obj-25", "maxclass": "comment", "text": "mode", "numinlets": 1, "numoutlets": 0, "patching_rect": [850.0, 18.0, 65.0, 20.0]}},
            {"box": {"id": "obj-26", "maxclass": "newobj", "text": "prepend mode", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [810.0, 610.0, 90.0, 22.0]}},
            {"box": {"id": "obj-27", "maxclass": "message", "text": "clear, append melodic, append hybrid, append rhythm, setsymbol hybrid", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [30.0, 640.0, 330.0, 22.0]}},

            {"box": {"id": "obj-28", "maxclass": "umenu", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "", ""], "patching_rect": [965.0, 42.0, 125.0, 22.0]}},
            {"box": {"id": "obj-29", "maxclass": "comment", "text": "scale", "numinlets": 1, "numoutlets": 0, "patching_rect": [965.0, 18.0, 65.0, 20.0]}},
            {"box": {"id": "obj-30", "maxclass": "newobj", "text": "prepend scale", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [910.0, 610.0, 90.0, 22.0]}},
            {"box": {"id": "obj-31", "maxclass": "message", "text": "clear, append major, append minor, append major_pentatonic, append minor_pentatonic, append chromatic, setsymbol major", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [30.0, 670.0, 520.0, 22.0]}},

            {"box": {"id": "obj-32", "maxclass": "umenu", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "", ""], "patching_rect": [455.0, 102.0, 75.0, 22.0]}},
            {"box": {"id": "obj-33", "maxclass": "comment", "text": "length", "numinlets": 1, "numoutlets": 0, "patching_rect": [455.0, 78.0, 65.0, 20.0]}},
            {"box": {"id": "obj-34", "maxclass": "newobj", "text": "prepend length", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [1010.0, 610.0, 105.0, 22.0]}},
            {"box": {"id": "obj-35", "maxclass": "message", "text": "clear, append 8, append 16, append 32, append 64, append 128, setsymbol 16", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [565.0, 670.0, 390.0, 22.0]}},

            {"box": {"id": "obj-36", "maxclass": "umenu", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "", ""], "patching_rect": [555.0, 102.0, 75.0, 22.0]}},
            {"box": {"id": "obj-37", "maxclass": "comment", "text": "division", "numinlets": 1, "numoutlets": 0, "patching_rect": [555.0, 78.0, 75.0, 20.0]}},
            {"box": {"id": "obj-38", "maxclass": "newobj", "text": "prepend interval", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [565.0, 640.0, 105.0, 22.0]}},
            {"box": {"id": "obj-39", "maxclass": "message", "text": "clear, append 4n, append 8n, append 16n, append 32n, setsymbol 16n", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [565.0, 695.0, 360.0, 22.0]}},

            {"box": {"id": "obj-40", "maxclass": "dial", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "size": 101, "parameter_enable": 0, "patching_rect": [655.0, 102.0, 48.0, 48.0]}},
            {"box": {"id": "obj-41", "maxclass": "comment", "text": "density %", "numinlets": 1, "numoutlets": 0, "patching_rect": [655.0, 78.0, 80.0, 20.0]}},
            {"box": {"id": "obj-42", "maxclass": "newobj", "text": "prepend density", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [680.0, 640.0, 110.0, 22.0]}},
            {"box": {"id": "obj-43", "maxclass": "message", "text": "50", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [565.0, 720.0, 35.0, 22.0]}},

            {"box": {"id": "obj-44", "maxclass": "button", "numinlets": 1, "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [190.0, 42.0, 28.0, 28.0]}},
            {"box": {"id": "obj-45", "maxclass": "comment", "text": "generate", "numinlets": 1, "numoutlets": 0, "patching_rect": [225.0, 44.0, 80.0, 22.0]}},
            {"box": {"id": "obj-46", "maxclass": "message", "text": "generate", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [250.0, 610.0, 70.0, 22.0]}},

            {"box": {"id": "obj-47", "maxclass": "toggle", "numinlets": 1, "numoutlets": 1, "outlettype": ["int"], "patching_rect": [340.0, 42.0, 28.0, 28.0]}},
            {"box": {"id": "obj-48", "maxclass": "comment", "text": "play", "numinlets": 1, "numoutlets": 0, "patching_rect": [375.0, 44.0, 60.0, 22.0]}},
            {"box": {"id": "obj-49", "maxclass": "newobj", "text": "metro 16n @active 1", "numinlets": 2, "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [210.0, 430.0, 135.0, 22.0]}},
            {"box": {"id": "obj-50", "maxclass": "newobj", "text": "counter", "numinlets": 5, "numoutlets": 4, "outlettype": ["int", "", "", "int"], "patching_rect": [210.0, 470.0, 70.0, 22.0]}},
            {"box": {"id": "obj-51", "maxclass": "newobj", "text": "% 16", "numinlets": 2, "numoutlets": 1, "outlettype": ["int"], "patching_rect": [210.0, 510.0, 55.0, 22.0]}},
            {"box": {"id": "obj-52", "maxclass": "message", "text": "step $1", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [210.0, 550.0, 65.0, 22.0]}},

            {"box": {"id": "obj-53", "maxclass": "newobj", "text": "route event", "numinlets": 1, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [520.0, 305.0, 75.0, 22.0]}},
            {"box": {"id": "obj-54", "maxclass": "newobj", "text": "print cryptoseq", "numinlets": 1, "numoutlets": 0, "patching_rect": [640.0, 305.0, 105.0, 22.0]}},
            {"box": {"id": "obj-55", "maxclass": "newobj", "text": "gate 1 0", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [520.0, 345.0, 65.0, 22.0]}},
            {"box": {"id": "obj-56", "maxclass": "newobj", "text": "unpack i i i i i i i i", "numinlets": 1, "numoutlets": 8, "outlettype": ["int", "int", "int", "int", "int", "int", "int", "int"], "patching_rect": [520.0, 385.0, 230.0, 22.0]}},

            {"box": {"id": "obj-57", "maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "patching_rect": [520.0, 430.0, 45.0, 22.0]}},
            {"box": {"id": "obj-58", "maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "patching_rect": [575.0, 430.0, 45.0, 22.0]}},
            {"box": {"id": "obj-59", "maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "patching_rect": [630.0, 430.0, 45.0, 22.0]}},
            {"box": {"id": "obj-60", "maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "patching_rect": [685.0, 430.0, 45.0, 22.0]}},
            {"box": {"id": "obj-61", "maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "patching_rect": [740.0, 430.0, 45.0, 22.0]}},
            {"box": {"id": "obj-62", "maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "patching_rect": [795.0, 430.0, 45.0, 22.0]}},
            {"box": {"id": "obj-63", "maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "patching_rect": [850.0, 430.0, 45.0, 22.0]}},
            {"box": {"id": "obj-64", "maxclass": "number", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "bang"], "patching_rect": [905.0, 430.0, 70.0, 22.0]}},

            {"box": {"id": "obj-65", "maxclass": "newobj", "text": "js cryptoseq_midi.js", "numinlets": 1, "numoutlets": 3, "outlettype": ["int", "int", "int"], "patching_rect": [520.0, 485.0, 135.0, 22.0]}},
            {"box": {"id": "obj-66", "maxclass": "newobj", "text": "makenote 100 250", "numinlets": 3, "numoutlets": 2, "outlettype": ["int", "int"], "patching_rect": [520.0, 530.0, 115.0, 22.0]}},
            {"box": {"id": "obj-67", "maxclass": "newobj", "text": "noteout", "numinlets": 3, "numoutlets": 0, "patching_rect": [520.0, 575.0, 60.0, 22.0]}},

            {"box": {"id": "obj-68", "maxclass": "comment", "text": "step", "numinlets": 1, "numoutlets": 0, "patching_rect": [520.0, 455.0, 45.0, 18.0]}},
            {"box": {"id": "obj-69", "maxclass": "comment", "text": "active", "numinlets": 1, "numoutlets": 0, "patching_rect": [575.0, 455.0, 45.0, 18.0]}},
            {"box": {"id": "obj-70", "maxclass": "comment", "text": "note", "numinlets": 1, "numoutlets": 0, "patching_rect": [630.0, 455.0, 45.0, 18.0]}},
            {"box": {"id": "obj-71", "maxclass": "comment", "text": "vel", "numinlets": 1, "numoutlets": 0, "patching_rect": [685.0, 455.0, 45.0, 18.0]}},
            {"box": {"id": "obj-72", "maxclass": "comment", "text": "accent", "numinlets": 1, "numoutlets": 0, "patching_rect": [740.0, 455.0, 50.0, 18.0]}},
            {"box": {"id": "obj-73", "maxclass": "comment", "text": "dur", "numinlets": 1, "numoutlets": 0, "patching_rect": [795.0, 455.0, 45.0, 18.0]}},
            {"box": {"id": "obj-74", "maxclass": "comment", "text": "gate", "numinlets": 1, "numoutlets": 0, "patching_rect": [850.0, 455.0, 45.0, 18.0]}},
            {"box": {"id": "obj-75", "maxclass": "comment", "text": "value", "numinlets": 1, "numoutlets": 0, "patching_rect": [905.0, 455.0, 60.0, 18.0]}},
            {"box": {"id": "obj-76", "maxclass": "comment", "text": "Manual scale for now. Live global scale follow is a next integration step.", "numinlets": 1, "numoutlets": 0, "patching_rect": [585.0, 165.0, 470.0, 22.0]}}
            ,
            {"box": {"id": "obj-77", "maxclass": "newobj", "text": "t b l", "numinlets": 1, "numoutlets": 2, "outlettype": ["bang", ""], "patching_rect": [390.0, 225.0, 45.0, 22.0]}}
            ,
            {"box": {"id": "obj-78", "maxclass": "newobj", "text": "speedlim 200", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [655.0, 575.0, 85.0, 22.0]}}
        ],
        "lines": [
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-9", 0]}},
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-23", 0]}},
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-27", 0]}},
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-31", 0]}},
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-35", 0]}},
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-39", 0]}},
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-43", 0]}},

            {"patchline": {"source": ["obj-2", 0], "destination": ["obj-77", 0]}},
            {"patchline": {"source": ["obj-2", 1], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-2", 2], "destination": ["obj-13", 0]}},
            {"patchline": {"source": ["obj-2", 3], "destination": ["obj-51", 1]}},
            {"patchline": {"source": ["obj-2", 4], "destination": ["obj-20", 0]}},
            {"patchline": {"source": ["obj-2", 5], "destination": ["obj-16", 0]}},

            {"patchline": {"source": ["obj-5", 0], "destination": ["obj-7", 0]}},
            {"patchline": {"source": ["obj-7", 0], "destination": ["obj-8", 0]}},
            {"patchline": {"source": ["obj-8", 0], "destination": ["obj-77", 0]}},
            {"patchline": {"source": ["obj-9", 0], "destination": ["obj-77", 0]}},

            {"patchline": {"source": ["obj-10", 1], "destination": ["obj-12", 0]}},
            {"patchline": {"source": ["obj-12", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-13", 1], "destination": ["obj-15", 0]}},
            {"patchline": {"source": ["obj-15", 0], "destination": ["obj-2", 0]}},

            {"patchline": {"source": ["obj-16", 1], "destination": ["obj-18", 0]}},
            {"patchline": {"source": ["obj-18", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-19", 0], "destination": ["obj-16", 0]}},

            {"patchline": {"source": ["obj-20", 1], "destination": ["obj-22", 0]}},
            {"patchline": {"source": ["obj-22", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-23", 0], "destination": ["obj-20", 0]}},

            {"patchline": {"source": ["obj-24", 1], "destination": ["obj-26", 0]}},
            {"patchline": {"source": ["obj-26", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-27", 0], "destination": ["obj-24", 0]}},

            {"patchline": {"source": ["obj-28", 1], "destination": ["obj-30", 0]}},
            {"patchline": {"source": ["obj-30", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-31", 0], "destination": ["obj-28", 0]}},

            {"patchline": {"source": ["obj-32", 1], "destination": ["obj-34", 0]}},
            {"patchline": {"source": ["obj-34", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-35", 0], "destination": ["obj-32", 0]}},

            {"patchline": {"source": ["obj-36", 1], "destination": ["obj-38", 0]}},
            {"patchline": {"source": ["obj-38", 0], "destination": ["obj-49", 0]}},
            {"patchline": {"source": ["obj-39", 0], "destination": ["obj-36", 0]}},

            {"patchline": {"source": ["obj-40", 0], "destination": ["obj-78", 0]}},
            {"patchline": {"source": ["obj-78", 0], "destination": ["obj-42", 0]}},
            {"patchline": {"source": ["obj-42", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-43", 0], "destination": ["obj-40", 0]}},

            {"patchline": {"source": ["obj-44", 0], "destination": ["obj-46", 0]}},
            {"patchline": {"source": ["obj-46", 0], "destination": ["obj-3", 0]}},
            {"patchline": {"source": ["obj-77", 0], "destination": ["obj-46", 0]}},
            {"patchline": {"source": ["obj-77", 1], "destination": ["obj-3", 0]}},
            {"patchline": {"source": ["obj-47", 0], "destination": ["obj-49", 0]}},
            {"patchline": {"source": ["obj-47", 0], "destination": ["obj-55", 0]}},
            {"patchline": {"source": ["obj-49", 0], "destination": ["obj-50", 0]}},
            {"patchline": {"source": ["obj-50", 0], "destination": ["obj-51", 0]}},
            {"patchline": {"source": ["obj-51", 0], "destination": ["obj-52", 0]}},
            {"patchline": {"source": ["obj-52", 0], "destination": ["obj-3", 0]}},

            {"patchline": {"source": ["obj-3", 0], "destination": ["obj-53", 0]}},
            {"patchline": {"source": ["obj-53", 0], "destination": ["obj-54", 0]}},
            {"patchline": {"source": ["obj-53", 0], "destination": ["obj-55", 1]}},
            {"patchline": {"source": ["obj-55", 0], "destination": ["obj-56", 0]}},
            {"patchline": {"source": ["obj-55", 0], "destination": ["obj-65", 0]}},

            {"patchline": {"source": ["obj-56", 0], "destination": ["obj-57", 0]}},
            {"patchline": {"source": ["obj-56", 1], "destination": ["obj-58", 0]}},
            {"patchline": {"source": ["obj-56", 2], "destination": ["obj-59", 0]}},
            {"patchline": {"source": ["obj-56", 3], "destination": ["obj-60", 0]}},
            {"patchline": {"source": ["obj-56", 4], "destination": ["obj-61", 0]}},
            {"patchline": {"source": ["obj-56", 5], "destination": ["obj-62", 0]}},
            {"patchline": {"source": ["obj-56", 6], "destination": ["obj-63", 0]}},
            {"patchline": {"source": ["obj-56", 7], "destination": ["obj-64", 0]}},

            {"patchline": {"source": ["obj-65", 0], "destination": ["obj-66", 0]}},
            {"patchline": {"source": ["obj-65", 1], "destination": ["obj-66", 1]}},
            {"patchline": {"source": ["obj-65", 2], "destination": ["obj-66", 2]}},
            {"patchline": {"source": ["obj-66", 0], "destination": ["obj-67", 0]}},
            {"patchline": {"source": ["obj-66", 1], "destination": ["obj-67", 1]}}
        ]
    }
}
