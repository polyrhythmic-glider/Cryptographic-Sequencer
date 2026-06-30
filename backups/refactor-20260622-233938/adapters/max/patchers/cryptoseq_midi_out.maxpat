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
                                 430.0,
                                 200.0
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
                                                  "numoutlets":  1,
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        30.0,
                                                                        30.0,
                                                                        30.0
                                                                    ],
                                                  "comment":  "event list"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-2",
                                                  "maxclass":  "inlet",
                                                  "numoutlets":  1,
                                                  "patching_rect":  [
                                                                        165.0,
                                                                        30.0,
                                                                        30.0,
                                                                        30.0
                                                                    ],
                                                  "comment":  "interval message"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-3",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  1,
                                                  "numoutlets":  3,
                                                  "outlettype":  [
                                                                     "int",
                                                                     "int",
                                                                     "int"
                                                                 ],
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        80.0,
                                                                        150.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "js cryptoseq_midi.js"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-4",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  3,
                                                  "numoutlets":  2,
                                                  "outlettype":  [
                                                                     "int",
                                                                     "int"
                                                                 ],
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        120.0,
                                                                        125.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "makenote 100 250"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-5",
                                                  "maxclass":  "newobj",
                                                  "numinlets":  3,
                                                  "numoutlets":  0,
                                                  "patching_rect":  [
                                                                        30.0,
                                                                        160.0,
                                                                        70.0,
                                                                        22.0
                                                                    ],
                                                  "text":  "noteout"
                                              }
                                  },
                                  {
                                      "box":  {
                                                  "id":  "obj-6",
                                                  "maxclass":  "inlet",
                                                  "numoutlets":  1,
                                                  "patching_rect":  [
                                                                        300,
                                                                        30,
                                                                        30,
                                                                        30
                                                                    ],
                                                  "comment":  "control messages"
                                              }
                                  }
                              ],
                    "lines":  [
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-1",
                                                                       0
                                                                   ],
                                                        "destination":  [
                                                                            "obj-3",
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
                                                                            "obj-3",
                                                                            0
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
                                                                            "obj-4",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-3",
                                                                       1
                                                                   ],
                                                        "destination":  [
                                                                            "obj-4",
                                                                            1
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-3",
                                                                       2
                                                                   ],
                                                        "destination":  [
                                                                            "obj-4",
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
                                                                            "obj-5",
                                                                            0
                                                                        ]
                                                    }
                                  },
                                  {
                                      "patchline":  {
                                                        "source":  [
                                                                       "obj-4",
                                                                       1
                                                                   ],
                                                        "destination":  [
                                                                            "obj-5",
                                                                            1
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
                                                                            "obj-3",
                                                                            0
                                                                        ]
                                                    }
                                  }
                              ]
                }
}
