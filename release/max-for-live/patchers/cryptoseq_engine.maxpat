{
    "patcher":  {
                    "fileversion":  1,
                    "appversion":  {
                                       "major":  8,
                                       "minor":  6,
                                       "revision":  0,
                                       "architecture":  "x64",
                                       "modernui":  1
                                   },
                    "rect":  [
                                 100.0,
                                 100.0,
                                 720.0,
                                 420.0
                             ],
                    "default_fontsize":  12.0,
                    "default_fontface":  0,
                    "default_fontname":  "Arial",
                    "gridonopen":  1,
                    "gridsize":  [
                                     15.0,
                                     15.0
                                 ],
                    "boxes":  [
                                  {
                                      "box":  {
                                                  "id":  "obj-1",
                                                  "maxclass":  "inlet",
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        30.0,
                                                                        30.0,
                                                                        30.0
                                                                    ],
                                                  "comment":  "commands"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-2",
                                                  "maxclass":  "inlet",
                                                  "patching_rect":  [
                                                                        180.0,
                                                                        30.0,
                                                                        30.0,
                                                                        30.0
                                                                    ],
                                                  "comment":  "division interval"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-3",
                                                  "maxclass":  "inlet",
                                                  "patching_rect":  [
                                                                        330.0,
                                                                        30.0,
                                                                        30.0,
                                                                        30.0
                                                                    ],
                                                  "comment":  "length"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-4",
                                                  "maxclass":  "inlet",
                                                  "patching_rect":  [
                                                                        480.0,
                                                                        30.0,
                                                                        30.0,
                                                                        30.0
                                                                    ],
                                                  "comment":  "arm"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-5",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  1,
                                                  "numoutlets":  2,
                                                  "outlettype":  [
                                                                     "",
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        90.0,
                                                                        150.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "cryptoseq_auto_setup"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-6",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  1,
                                                  "numoutlets":  1,
                                                  "outlettype":  [
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        145.0,
                                                                        90.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "cryptoseq"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-7",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  3,
                                                  "numoutlets":  2,
                                                  "outlettype":  [
                                                                     "",
                                                                     "int"
                                                                 ],
                                                  "patching_rect":  [
                                                                        245.0,
                                                                        145.0,
                                                                        125.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "cryptoseq_clock"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-8",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  2,
                                                  "numoutlets":  2,
                                                  "outlettype":  [
                                                                     "",
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        200.0,
                                                                        85.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "route event"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-9",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  2,
                                                  "numoutlets":  1,
                                                  "outlettype":  [
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        155.0,
                                                                        255.0,
                                                                        70.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "gate 1 1"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-10",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  3,
                                                  "numoutlets":  0,
                                                  "patching_rect":  [
                                                                        155.0,
                                                                        310.0,
                                                                        145.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "cryptoseq_midi_out"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-11",
                                                  "maxclass":  "outlet",
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        255.0,
                                                                        30.0,
                                                                        30.0
                                                                    ],
                                                  "comment":  "event list"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-12",
                                                  "maxclass":  "outlet",
                                                  "patching_rect":  [
                                                                        365.0,
                                                                        200.0,
                                                                        30.0,
                                                                        30.0
                                                                    ],
                                                  "comment":  "step index"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-13",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  1,
                                                  "numoutlets":  2,
                                                  "outlettype":  [
                                                                     "",
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        30,
                                                                        70,
                                                                        45,
                                                                        22
                                                                    ],
                                                  "text":  "t l l"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-14",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  2,
                                                  "numoutlets":  2,
                                                  "outlettype":  [
                                                                     "",
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        30,
                                                                        105,
                                                                        75,
                                                                        22
                                                                    ],
                                                  "text":  "route poly"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-15",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  1,
                                                  "numoutlets":  1,
                                                  "outlettype":  [
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        210,
                                                                        255,
                                                                        80,
                                                                        22
                                                                    ],
                                                  "text":  "prepend poly"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-16",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  2,
                                                  "numoutlets":  2,
                                                  "outlettype":  [
                                                                     "",
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        125,
                                                                        105,
                                                                        78,
                                                                        22
                                                                    ],
                                                  "text":  "route mode"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-17",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  1,
                                                  "numoutlets":  1,
                                                  "outlettype":  [
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        305,
                                                                        255,
                                                                        85,
                                                                        22
                                                                    ],
                                                  "text":  "prepend mode"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-18",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  1,
                                                  "numoutlets":  1,
                                                  "outlettype":  [
                                                                     "bang"
                                                                 ],
                                                  "patching_rect":  [
                                                                        500,
                                                                        90,
                                                                        70,
                                                                        22
                                                                    ],
                                                  "text":  "loadbang"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-19",
                                                  "maxclass":  "message",
                                                  "numinlets":  2,
                                                  "numoutlets":  1,
                                                  "outlettype":  [
                                                                     ""
                                                                 ],
                                                  "patching_rect":  [
                                                                        500,
                                                                        125,
                                                                        35,
                                                                        22
                                                                    ],
                                                  "text":  "1"
                                              }
                                  }
                              ],
                    "lines":  [
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-5",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-6",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-5",
                                                                       1
                                                                   ],
                                                        "destination":  [
                                                                            "obj-6",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-6",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-8",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-8",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-11",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-8",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-9",
                                                                            1
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-9",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-10",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-2",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-7",
                                                                            1
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-2",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-10",
                                                                            1
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-3",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-7",
                                                                            2
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-4",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-7",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-4",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-9",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-1",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-13",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-13",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-14",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-13",
                                                                       1
                                                                   ],
                                                        "destination":  [
                                                                            "obj-16",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-14",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-15",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-14",
                                                                       1
                                                                   ],
                                                        "destination":  [
                                                                            "obj-5",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-15",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-10",
                                                                            2
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-16",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-17",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-17",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-10",
                                                                            2
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-18",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-19",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-19",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-7",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-19",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-9",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-7",
                                                                       1
                                                                   ],
                                                        "destination":  [
                                                                            "obj-6",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-7",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-12",
                                                                            0
                                                                        ]
                                                    }
                                  }
                              ]
                }
}
