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
        "rect": [100.0, 100.0, 430.0, 220.0],
        "default_fontsize": 12.0,
        "default_fontface": 0,
        "default_fontname": "Arial",
        "gridonopen": 1,
        "gridsize": [15.0, 15.0],
        "boxes": [
            {"box": {"id": "obj-1", "maxclass": "inlet", "numoutlets": 1, "patching_rect": [30.0, 30.0, 30.0, 30.0], "comment": "play"}},
            {"box": {"id": "obj-2", "maxclass": "inlet", "numoutlets": 1, "patching_rect": [120.0, 30.0, 30.0, 30.0], "comment": "interval message"}},
            {"box": {"id": "obj-3", "maxclass": "inlet", "numoutlets": 1, "patching_rect": [220.0, 30.0, 30.0, 30.0], "comment": "length"}},
            {"box": {"id": "obj-4", "maxclass": "newobj", "numinlets": 2, "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [30.0, 80.0, 150.0, 22.0], "text": "metro 16n @active 1"}},
            {"box": {"id": "obj-5", "maxclass": "newobj", "numinlets": 5, "numoutlets": 4, "outlettype": ["int", "", "", ""], "patching_rect": [30.0, 115.0, 80.0, 22.0], "text": "counter"}},
            {"box": {"id": "obj-6", "maxclass": "newobj", "numinlets": 2, "numoutlets": 1, "outlettype": ["int"], "patching_rect": [30.0, 150.0, 60.0, 22.0], "text": "% 16"}},
            {"box": {"id": "obj-7", "maxclass": "newobj", "numinlets": 1, "numoutlets": 2, "outlettype": ["int", "int"], "patching_rect": [30.0, 180.0, 40.0, 22.0], "text": "t i i"}},
            {"box": {"id": "obj-8", "maxclass": "message", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [100.0, 180.0, 60.0, 22.0], "text": "step $1"}},
            {"box": {"id": "obj-9", "maxclass": "outlet", "numinlets": 1, "patching_rect": [175.0, 180.0, 30.0, 30.0], "comment": "step message"}},
            {"box": {"id": "obj-10", "maxclass": "outlet", "numinlets": 1, "patching_rect": [30.0, 210.0, 30.0, 30.0], "comment": "step index"}}
        ],
        "lines": [
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-4", 0]}},
            {"patchline": {"source": ["obj-2", 0], "destination": ["obj-4", 0]}},
            {"patchline": {"source": ["obj-3", 0], "destination": ["obj-6", 1]}},
            {"patchline": {"source": ["obj-4", 0], "destination": ["obj-5", 0]}},
            {"patchline": {"source": ["obj-5", 0], "destination": ["obj-6", 0]}},
            {"patchline": {"source": ["obj-6", 0], "destination": ["obj-7", 0]}},
            {"patchline": {"source": ["obj-7", 0], "destination": ["obj-10", 0]}},
            {"patchline": {"source": ["obj-7", 1], "destination": ["obj-8", 0]}},
            {"patchline": {"source": ["obj-8", 0], "destination": ["obj-9", 0]}}
        ]
    }
}
