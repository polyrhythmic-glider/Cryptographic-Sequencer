{
    "patcher": {
        "fileversion": 1,
        "appversion": {
            "major": 8,
            "minor": 6,
            "revision": 0,
            "architecture": "x64",
            "modernui": 1
        },
        "rect": [100.0, 100.0, 360.0, 180.0],
        "default_fontsize": 12.0,
        "default_fontface": 0,
        "default_fontname": "Arial",
        "gridonopen": 1,
        "gridsize": [15.0, 15.0],
        "boxes": [
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "inlet",
                    "numoutlets": 1,
                    "patching_rect": [30.0, 30.0, 30.0, 30.0],
                    "comment": "refresh"
                }
            },
            {
                "box": {
                    "id": "obj-2",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": ["bang"],
                    "patching_rect": [80.0, 30.0, 65.0, 22.0],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": ["bang"],
                    "patching_rect": [80.0, 70.0, 65.0, 22.0],
                    "text": "delay 500"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [30.0, 110.0, 180.0, 22.0],
                    "text": "js cryptoseq_live_scale.js"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "patching_rect": [230.0, 110.0, 30.0, 30.0],
                    "comment": "livescale intervals"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": ["bang"],
                    "patching_rect": [250.0, 30.0, 95.0, 22.0],
                    "text": "live.thisdevice"
                }
            },
            {
                "box": {
                    "id": "obj-7",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [""],
                    "patching_rect": [250.0, 70.0, 60.0, 22.0],
                    "text": "prepend ready"
                }
            }
        ],
        "lines": [
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-4", 0]}},
            {"patchline": {"source": ["obj-2", 0], "destination": ["obj-3", 0]}},
            {"patchline": {"source": ["obj-3", 0], "destination": ["obj-4", 0]}},
            {"patchline": {"source": ["obj-4", 0], "destination": ["obj-5", 0]}},
            {"patchline": {"source": ["obj-6", 0], "destination": ["obj-7", 0]}},
            {"patchline": {"source": ["obj-7", 0], "destination": ["obj-4", 0]}}
        ]
    }
}
