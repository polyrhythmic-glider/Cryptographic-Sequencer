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
    "rect": [100.0, 100.0, 720.0, 420.0],
    "default_fontsize": 12.0,
    "default_fontface": 0,
    "default_fontname": "Arial",
    "gridonopen": 1,
    "gridsize": [15.0, 15.0],
    "boxes": [
      {"box": {"id": "obj-1", "maxclass": "inlet", "patching_rect": [30.0, 30.0, 30.0, 30.0], "comment": "commands"}},
      {"box": {"id": "obj-2", "maxclass": "inlet", "patching_rect": [180.0, 30.0, 30.0, 30.0], "comment": "division interval"}},
      {"box": {"id": "obj-3", "maxclass": "inlet", "patching_rect": [330.0, 30.0, 30.0, 30.0], "comment": "length"}},
      {"box": {"id": "obj-4", "maxclass": "inlet", "patching_rect": [480.0, 30.0, 30.0, 30.0], "comment": "arm"}},
      {"box": {"id": "obj-5", "maxclass": "newobj", "numinlets": 1, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [30.0, 120.0, 150.0, 22.0], "text": "cryptoseq_auto_setup"}},
      {"box": {"id": "obj-6", "maxclass": "newobj", "numinlets": 1, "numoutlets": 1, "outlettype": [""], "patching_rect": [30.0, 170.0, 90.0, 22.0], "text": "cryptoseq"}},
      {"box": {"id": "obj-7", "maxclass": "newobj", "numinlets": 3, "numoutlets": 2, "outlettype": ["", "int"], "patching_rect": [245.0, 170.0, 125.0, 22.0], "text": "cryptoseq_clock"}},
      {"box": {"id": "obj-8", "maxclass": "newobj", "numinlets": 2, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [30.0, 220.0, 85.0, 22.0], "text": "route event"}},
      {"box": {"id": "obj-9", "maxclass": "newobj", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [155.0, 275.0, 70.0, 22.0], "text": "gate 1 1"}},
      {"box": {"id": "obj-10", "maxclass": "newobj", "numinlets": 3, "numoutlets": 0, "patching_rect": [155.0, 330.0, 145.0, 22.0], "text": "cryptoseq_midi_out"}},
      {"box": {"id": "obj-11", "maxclass": "outlet", "patching_rect": [30.0, 275.0, 30.0, 30.0], "comment": "event list"}},
      {"box": {"id": "obj-12", "maxclass": "outlet", "patching_rect": [365.0, 220.0, 30.0, 30.0], "comment": "step index"}},
      {"box": {"id": "obj-13", "maxclass": "newobj", "numinlets": 1, "numoutlets": 2, "outlettype": ["", ""], "patching_rect": [30.0, 75.0, 170.0, 22.0], "text": "js cryptoseq_engine_router.js"}},
      {"box": {"id": "obj-14", "maxclass": "newobj", "numinlets": 1, "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [520.0, 80.0, 70.0, 22.0], "text": "loadbang"}},
      {"box": {"id": "obj-15", "maxclass": "message", "numinlets": 2, "numoutlets": 1, "outlettype": [""], "patching_rect": [520.0, 120.0, 35.0, 22.0], "text": "1"}}
    ],
    "lines": [
      {"patchline": {"source": ["obj-1", 0], "destination": ["obj-13", 0]}},
      {"patchline": {"source": ["obj-13", 0], "destination": ["obj-5", 0]}},
      {"patchline": {"source": ["obj-13", 1], "destination": ["obj-10", 2]}},
      {"patchline": {"source": ["obj-5", 0], "destination": ["obj-6", 0]}},
      {"patchline": {"source": ["obj-5", 1], "destination": ["obj-6", 0]}},
      {"patchline": {"source": ["obj-6", 0], "destination": ["obj-8", 0]}},
      {"patchline": {"source": ["obj-8", 0], "destination": ["obj-11", 0]}},
      {"patchline": {"source": ["obj-8", 1], "destination": ["obj-11", 0]}},
      {"patchline": {"source": ["obj-8", 1], "destination": ["obj-9", 1]}},
      {"patchline": {"source": ["obj-9", 0], "destination": ["obj-10", 0]}},
      {"patchline": {"source": ["obj-2", 0], "destination": ["obj-7", 1]}},
      {"patchline": {"source": ["obj-2", 0], "destination": ["obj-10", 1]}},
      {"patchline": {"source": ["obj-3", 0], "destination": ["obj-7", 2]}},
      {"patchline": {"source": ["obj-3", 0], "destination": ["obj-13", 0]}},
      {"patchline": {"source": ["obj-4", 0], "destination": ["obj-7", 0]}},
      {"patchline": {"source": ["obj-4", 0], "destination": ["obj-9", 0]}},
      {"patchline": {"source": ["obj-7", 0], "destination": ["obj-12", 0]}},
      {"patchline": {"source": ["obj-7", 1], "destination": ["obj-6", 0]}},
      {"patchline": {"source": ["obj-14", 0], "destination": ["obj-15", 0]}},
      {"patchline": {"source": ["obj-15", 0], "destination": ["obj-7", 0]}},
      {"patchline": {"source": ["obj-15", 0], "destination": ["obj-9", 0]}}
    ]
  }
}
