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
        "rect": [60.0, 60.0, 900.0, 650.0],
        "gridsize": [15.0, 15.0],
        "boxes": [
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "button",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": ["bang"],
                    "patching_rect": [30.0, 45.0, 24.0, 24.0]
                }
            },
            {
                "box": {
                    "id": "obj-2",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 7,
                    "outlettype": ["bang", "bang", "bang", "bang", "bang", "bang", "bang"],
                    "patching_rect": [30.0, 85.0, 180.0, 22.0],
                    "text": "t b b b b b b b"
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [30.0, 130.0, 70.0, 22.0],
                    "text": "generate"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [115.0, 130.0, 55.0, 22.0],
                    "text": "root 60"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [185.0, 130.0, 90.0, 22.0],
                    "text": "mode hybrid"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [290.0, 130.0, 75.0, 22.0],
                    "text": "length 16"
                }
            },
            {
                "box": {
                    "id": "obj-7",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [380.0, 130.0, 50.0, 22.0],
                    "text": "q 257"
                }
            },
            {
                "box": {
                    "id": "obj-8",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [445.0, 130.0, 50.0, 22.0],
                    "text": "p 251"
                }
            },
            {
                "box": {
                    "id": "obj-9",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [510.0, 130.0, 135.0, 22.0],
                    "text": "source demo source"
                }
            },
            {
                "box": {
                    "id": "obj-10",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [340.0, 190.0, 80.0, 22.0],
                    "text": "cryptoseq"
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["", ""],
                    "patching_rect": [340.0, 230.0, 75.0, 22.0],
                    "text": "route event"
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [510.0, 230.0, 105.0, 22.0],
                    "text": "print cryptoseq"
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "toggle",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": ["int"],
                    "patching_rect": [30.0, 230.0, 24.0, 24.0]
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": ["bang"],
                    "patching_rect": [30.0, 270.0, 75.0, 22.0],
                    "text": "metro 16n @active 1"
                }
            },
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 5,
                    "numoutlets": 4,
                    "outlettype": ["int", "", "", "int"],
                    "patching_rect": [30.0, 310.0, 85.0, 22.0],
                    "text": "counter 0 15"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [30.0, 350.0, 65.0, 22.0],
                    "text": "step $1"
                }
            },
            {
                "box": {
                    "id": "obj-17",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [340.0, 270.0, 70.0, 22.0],
                    "text": "gate 1 0"
                }
            },
            {
                "box": {
                    "id": "obj-18",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 8,
                    "outlettype": ["int", "int", "int", "int", "int", "int", "int", "int"],
                    "patching_rect": [340.0, 310.0, 230.0, 22.0],
                    "text": "unpack i i i i i i i i"
                }
            },
            {
                "box": {
                    "id": "obj-19",
                    "maxclass": "number",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["int", "bang"],
                    "patching_rect": [340.0, 360.0, 45.0, 22.0]
                }
            },
            {
                "box": {
                    "id": "obj-20",
                    "maxclass": "number",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["int", "bang"],
                    "patching_rect": [395.0, 360.0, 45.0, 22.0]
                }
            },
            {
                "box": {
                    "id": "obj-21",
                    "maxclass": "number",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["int", "bang"],
                    "patching_rect": [450.0, 360.0, 45.0, 22.0]
                }
            },
            {
                "box": {
                    "id": "obj-22",
                    "maxclass": "number",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["int", "bang"],
                    "patching_rect": [505.0, 360.0, 45.0, 22.0]
                }
            },
            {
                "box": {
                    "id": "obj-23",
                    "maxclass": "number",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["int", "bang"],
                    "patching_rect": [560.0, 360.0, 45.0, 22.0]
                }
            },
            {
                "box": {
                    "id": "obj-24",
                    "maxclass": "number",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["int", "bang"],
                    "patching_rect": [615.0, 360.0, 45.0, 22.0]
                }
            },
            {
                "box": {
                    "id": "obj-25",
                    "maxclass": "number",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["int", "bang"],
                    "patching_rect": [670.0, 360.0, 45.0, 22.0]
                }
            },
            {
                "box": {
                    "id": "obj-26",
                    "maxclass": "number",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["int", "bang"],
                    "patching_rect": [725.0, 360.0, 70.0, 22.0]
                }
            },
            {
                "box": {
                    "id": "obj-27",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": ["int"],
                    "patching_rect": [615.0, 410.0, 45.0, 22.0],
                    "text": "* 125"
                }
            },
            {
                "box": {
                    "id": "obj-28",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [30.0, 15.0, 185.0, 22.0],
                    "text": "setup sequence"
                }
            },
            {
                "box": {
                    "id": "obj-29",
                    "maxclass": "newobj",
                    "numinlets": 4,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [395.0, 410.0, 100.0, 22.0],
                    "text": "pack i i i i"
                }
            },
            {
                "box": {
                    "id": "obj-30",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": ["", ""],
                    "patching_rect": [395.0, 450.0, 55.0, 22.0],
                    "text": "route 1"
                }
            },
            {
                "box": {
                    "id": "obj-31",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "outlettype": ["int", "int", "int"],
                    "patching_rect": [395.0, 490.0, 100.0, 22.0],
                    "text": "unpack i i i"
                }
            },
            {
                "box": {
                    "id": "obj-32",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "outlettype": ["int", "int"],
                    "patching_rect": [395.0, 530.0, 115.0, 22.0],
                    "text": "makenote 100 250"
                }
            },
            {
                "box": {
                    "id": "obj-33",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 0,
                    "patching_rect": [395.0, 570.0, 60.0, 22.0],
                    "text": "noteout"
                }
            },
            {
                "box": {
                    "id": "obj-34",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [60.0, 230.0, 170.0, 22.0],
                    "text": "play generated steps"
                }
            },
            {
                "box": {
                    "id": "obj-35",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [340.0, 385.0, 45.0, 18.0],
                    "text": "step"
                }
            },
            {
                "box": {
                    "id": "obj-36",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [395.0, 385.0, 45.0, 18.0],
                    "text": "active"
                }
            },
            {
                "box": {
                    "id": "obj-37",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [450.0, 385.0, 45.0, 18.0],
                    "text": "note"
                }
            },
            {
                "box": {
                    "id": "obj-38",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [505.0, 385.0, 45.0, 18.0],
                    "text": "vel"
                }
            },
            {
                "box": {
                    "id": "obj-39",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [560.0, 385.0, 45.0, 18.0],
                    "text": "accent"
                }
            },
            {
                "box": {
                    "id": "obj-40",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [615.0, 385.0, 45.0, 18.0],
                    "text": "dur"
                }
            },
            {
                "box": {
                    "id": "obj-41",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [670.0, 385.0, 45.0, 18.0],
                    "text": "gate"
                }
            },
            {
                "box": {
                    "id": "obj-42",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [725.0, 385.0, 70.0, 18.0],
                    "text": "value"
                }
            }
        ],
        "lines": [
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-2", 0], "destination": ["obj-3", 0]}},
            {"patchline": {"source": ["obj-2", 1], "destination": ["obj-4", 0]}},
            {"patchline": {"source": ["obj-2", 2], "destination": ["obj-5", 0]}},
            {"patchline": {"source": ["obj-2", 3], "destination": ["obj-6", 0]}},
            {"patchline": {"source": ["obj-2", 4], "destination": ["obj-7", 0]}},
            {"patchline": {"source": ["obj-2", 5], "destination": ["obj-8", 0]}},
            {"patchline": {"source": ["obj-2", 6], "destination": ["obj-9", 0]}},
            {"patchline": {"source": ["obj-3", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-4", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-5", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-6", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-7", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-8", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-9", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-10", 0], "destination": ["obj-11", 0]}},
            {"patchline": {"source": ["obj-11", 0], "destination": ["obj-12", 0]}},
            {"patchline": {"source": ["obj-11", 0], "destination": ["obj-17", 1]}},
            {"patchline": {"source": ["obj-13", 0], "destination": ["obj-14", 0]}},
            {"patchline": {"source": ["obj-13", 0], "destination": ["obj-17", 0]}},
            {"patchline": {"source": ["obj-14", 0], "destination": ["obj-15", 0]}},
            {"patchline": {"source": ["obj-15", 0], "destination": ["obj-16", 0]}},
            {"patchline": {"source": ["obj-16", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-17", 0], "destination": ["obj-18", 0]}},
            {"patchline": {"source": ["obj-18", 0], "destination": ["obj-19", 0]}},
            {"patchline": {"source": ["obj-18", 1], "destination": ["obj-20", 0]}},
            {"patchline": {"source": ["obj-18", 1], "destination": ["obj-29", 0]}},
            {"patchline": {"source": ["obj-18", 2], "destination": ["obj-21", 0]}},
            {"patchline": {"source": ["obj-18", 2], "destination": ["obj-29", 1]}},
            {"patchline": {"source": ["obj-18", 3], "destination": ["obj-22", 0]}},
            {"patchline": {"source": ["obj-18", 3], "destination": ["obj-29", 2]}},
            {"patchline": {"source": ["obj-18", 4], "destination": ["obj-23", 0]}},
            {"patchline": {"source": ["obj-18", 5], "destination": ["obj-24", 0]}},
            {"patchline": {"source": ["obj-18", 5], "destination": ["obj-27", 0]}},
            {"patchline": {"source": ["obj-18", 6], "destination": ["obj-25", 0]}},
            {"patchline": {"source": ["obj-18", 7], "destination": ["obj-26", 0]}},
            {"patchline": {"source": ["obj-27", 0], "destination": ["obj-29", 3]}},
            {"patchline": {"source": ["obj-29", 0], "destination": ["obj-30", 0]}},
            {"patchline": {"source": ["obj-30", 0], "destination": ["obj-31", 0]}},
            {"patchline": {"source": ["obj-31", 0], "destination": ["obj-32", 0]}},
            {"patchline": {"source": ["obj-31", 1], "destination": ["obj-32", 1]}},
            {"patchline": {"source": ["obj-31", 2], "destination": ["obj-32", 2]}},
            {"patchline": {"source": ["obj-32", 0], "destination": ["obj-33", 0]}},
            {"patchline": {"source": ["obj-32", 1], "destination": ["obj-33", 1]}}
        ]
    }
}
