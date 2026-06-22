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
            {"box": {"id": "obj-1", "maxclass": "inlet", "numoutlets": 1, "patching_rect": [30.0, 30.0, 30.0, 30.0], "comment": "parameter/source command"}},
            {"box": {"id": "obj-2", "maxclass": "newobj", "numinlets": 1, "numoutlets": 2, "outlettype": ["bang", ""], "patching_rect": [30.0, 75.0, 45.0, 22.0], "text": "t b l"}},
            {"box": {"id": "obj-3", "maxclass": "newobj", "numinlets": 2, "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [30.0, 115.0, 75.0, 22.0], "text": "delay 120"}},
            {"box": {"id": "obj-4", "maxclass": "message", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [30.0, 145.0, 50.0, 22.0], "text": "setup"}},
            {"box": {"id": "obj-5", "maxclass": "outlet", "numinlets": 1, "patching_rect": [125.0, 115.0, 30.0, 30.0], "comment": "command"}},
            {"box": {"id": "obj-6", "maxclass": "outlet", "numinlets": 1, "patching_rect": [90.0, 145.0, 30.0, 30.0], "comment": "debounced setup"}}
        ],
        "lines": [
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-2", 0]}},
            {"patchline": {"source": ["obj-2", 0], "destination": ["obj-3", 0]}},
            {"patchline": {"source": ["obj-2", 1], "destination": ["obj-5", 0]}},
            {"patchline": {"source": ["obj-3", 0], "destination": ["obj-4", 0]}},
            {"patchline": {"source": ["obj-4", 0], "destination": ["obj-6", 0]}}
        ]
    }
}
