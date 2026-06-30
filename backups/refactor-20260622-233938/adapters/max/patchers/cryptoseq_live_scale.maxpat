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
        "rect": [100.0, 100.0, 420.0, 180.0],
        "default_fontsize": 12.0,
        "default_fontface": 0,
        "default_fontname": "Arial",
        "gridonopen": 1,
        "gridsize": [15.0, 15.0],
        "boxes": [
            {"box": {"id": "obj-1", "maxclass": "inlet", "numoutlets": 1, "patching_rect": [30.0, 30.0, 30.0, 30.0], "comment": "refresh"}},
            {"box": {"id": "obj-2", "maxclass": "newobj", "numinlets": 1, "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [80.0, 30.0, 65.0, 22.0], "text": "loadbang"}},
            {"box": {"id": "obj-3", "maxclass": "newobj", "numinlets": 1, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [30.0, 70.0, 110.0, 22.0], "text": "live.path live_set"}},
            {"box": {"id": "obj-4", "maxclass": "newobj", "numinlets": 2, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [30.0, 105.0, 165.0, 22.0], "text": "live.observer scale_intervals"}},
            {"box": {"id": "obj-5", "maxclass": "newobj", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [30.0, 140.0, 115.0, 22.0], "text": "prepend livescale"}},
            {"box": {"id": "obj-6", "maxclass": "outlet", "numinlets": 1, "patching_rect": [165.0, 140.0, 30.0, 30.0], "comment": "livescale intervals"}}
        ],
        "lines": [
            {"patchline": {"source": ["obj-1", 0], "destination": ["obj-3", 0]}},
            {"patchline": {"source": ["obj-2", 0], "destination": ["obj-3", 0]}},
            {"patchline": {"source": ["obj-3", 1], "destination": ["obj-4", 1]}},
            {"patchline": {"source": ["obj-4", 0], "destination": ["obj-5", 0]}},
            {"patchline": {"source": ["obj-5", 0], "destination": ["obj-6", 0]}}
        ]
    }
}
