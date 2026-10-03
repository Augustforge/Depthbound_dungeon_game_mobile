#!/usr/bin/env python3
"""Floor layouts of dungeon 1 (GDD 16.3), written as code so they are easy to edit.

Run: python3 tools/mapgen/floors.py  -> writes levels/d01/floor_XX.txt/.json for the floors below.
Legend (GDD 19.5): # wall . floor ~ deco water S start E stairs a-z packs C/G/R chests
^ spikes T bear trap H harpoon wall L lever D gate V valve W flood valve F spring N note
B lock-gate bars | prison bars (blocks, see-through)
"""
import json
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "levels", "d01")


class Floor:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [["#"] * w for _ in range(h)]
        self.data = {}

    def room(self, x, y, w, h):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.g[yy][xx] = "."
        return self

    def hline(self, x0, x1, y, width=2):
        for yy in range(y, y + width):
            for xx in range(min(x0, x1), max(x0, x1) + 1):
                self.g[yy][xx] = "."

    def vline(self, x, y0, y1, width=2):
        for yy in range(min(y0, y1), max(y0, y1) + 1):
            for xx in range(x, x + width):
                self.g[yy][xx] = "."

    def put(self, x, y, ch):
        cur = self.g[y][x]
        assert cur in ".~|" or ch in "#|", "(%d,%d) is '%s', cannot put '%s'" % (x, y, cur, ch)
        self.g[y][x] = ch

    def cell_block(self, x, y, w, h, door_x, door_side="S"):
        """A prison cell: walls with bars on one side and a door gap (bars elsewhere)."""
        self.room(x, y, w, h)
        bar_y = y + h if door_side == "S" else y - 1
        for xx in range(x, x + w):
            self.g[bar_y][xx] = "|"
        self.g[bar_y][door_x] = "."

    def water(self, cells):
        for x, y in cells:
            self.put(x, y, "~")

    def write(self, index):
        text = "\n".join("".join(r) for r in self.g) + "\n"
        with open(os.path.join(ROOT, "floor_%02d.txt" % index), "w") as f:
            f.write(text)
        with open(os.path.join(ROOT, "floor_%02d.json" % index), "w") as f:
            json.dump(self.data, f, ensure_ascii=False, indent="\t")
            f.write("\n")
        return text


def floor_02():
    """Block A: a long prison corridor with cells on both sides, a guard hall and a side wing."""
    f = Floor(40, 26)
    f.room(1, 10, 6, 6)                      # start
    f.hline(7, 33, 12, 3)                    # main corridor
    for i, x in enumerate(range(9, 31, 5)):  # cells north and south of the corridor
        f.cell_block(x, 6, 4, 5, x + 1 + i % 2, "S")
        f.cell_block(x, 16, 4, 5, x + 2 - i % 2, "N")
    f.room(34, 3, 5, 20)                     # exit hall
    f.room(14, 1, 12, 4)                     # guard room (north)
    f.vline(19, 5, 5, 2)
    f.g[5][19] = "."
    f.g[5][20] = "."
    f.room(14, 22, 14, 3)                    # south store
    f.vline(25, 21, 21, 2)
    f.g[21][25] = "."
    f.g[21][26] = "."
    f.put(3, 12, "S"); f.put(36, 20, "E")
    f.put(20, 2, "a"); f.put(18, 3, "b"); f.put(32, 13, "c"); f.put(20, 23, "d"); f.put(36, 4, "e")
    f.put(16, 2, "C"); f.put(24, 2, "C"); f.put(15, 23, "G")
    for x, y in [(22, 13), (27, 12), (17, 14)]:
        f.put(x, y, "T")
    for x, y in [(29, 12), (29, 13), (30, 12), (30, 13), (35, 15), (36, 15), (35, 16), (36, 16)]:
        f.put(x, y, "^")
    f.data = {"id": "d01_f02", "name_key": "FLOOR_D01_02", "time_limit": 150, "goal": {"type": "breakthrough"},
              "zone": "cells", "accent": "cells",
              "packs": {"a": [{"mob": "rat", "count": 4}], "b": [{"mob": "prisoner", "count": 3}],
                        "c": [{"mob": "jailer", "count": 1}, {"mob": "prisoner", "count": 2}],
                        "d": [{"mob": "rat", "count": 5}],
                        "e": [{"mob": "jailer", "count": 1}, {"mob": "prisoner", "count": 2}]},
              "locks": {"c": [[33, 12], [33, 13], [33, 14]]}}
    f.put(33, 12, "B"); f.put(33, 13, "B"); f.put(33, 14, "B")
    return f


def floor_03():
    """Guard post: start -> courtyard around the guard tower -> passage (c) -> exit wing; the key is
    on the senior jailer in the armoury above the exit wing. Barracks, west wing, south yard: optional."""
    f = Floor(42, 28)
    f.room(1, 11, 7, 7)                      # start (west)
    f.hline(8, 9, 14, 2)
    f.room(10, 10, 22, 10)                   # courtyard
    for x in range(18, 24):                  # guard tower block in the middle
        for y in range(13, 17):
            f.g[y][x] = "#"
    f.room(13, 1, 16, 8)                     # barracks (north, optional)
    f.vline(14, 9, 9, 2)
    f.room(33, 2, 8, 7)                      # armoury with the key holder
    f.vline(36, 9, 11, 2)
    f.hline(32, 34, 16, 2)                   # passage to the exit wing (pack c)
    f.room(35, 12, 6, 15)                    # exit wing
    f.room(1, 20, 8, 7)                      # west wing (iron chest)
    f.vline(3, 18, 19, 2)
    f.room(14, 21, 14, 6)                    # south yard
    f.vline(20, 20, 20, 2)
    f.put(3, 13, "S"); f.put(38, 25, "E")
    f.put(20, 4, "a"); f.put(25, 6, "b"); f.put(33, 16, "c"); f.put(5, 23, "d"); f.put(20, 24, "e"); f.put(37, 5, "f")
    f.put(15, 2, "C"); f.put(27, 24, "C"); f.put(2, 25, "G")
    f.put(16, 11, "F"); f.put(5, 12, "N")
    # Harpoon walls: one covers the courtyard (with a lever), one the south yard.
    f.g[9][26] = "H"; f.put(28, 18, "L")
    f.g[27][23] = "H"
    f.put(15, 18, "T"); f.put(36, 14, "T")
    f.data = {"id": "d01_f03", "name_key": "FLOOR_D01_03", "time_limit": 145,
              "goal": {"type": "key_holder", "pack": "f"}, "zone": "cells", "accent": "guard_post",
              "packs": {"a": [{"mob": "prisoner", "count": 2}, {"mob": "crossbowman", "count": 1}],
                        "b": [{"mob": "rat", "count": 4}],
                        "c": [{"mob": "jailer", "count": 1}, {"mob": "crossbowman", "count": 2}],
                        "d": [{"mob": "prisoner", "count": 3}], "e": [{"mob": "rat", "count": 5}],
                        "f": [{"mob": "jailer", "count": 1}, {"mob": "prisoner", "count": 2}]},
              "links": [{"lever_at": [28, 18], "harpoon_at": [26, 9]}],
              "harpoons": {"26,9": [0, 1], "23,27": [0, -1]},
              "notes": {"N": "NOTE_D01_02"}}
    return f


def floor_04():
    """Flooded yard: the short way is barred by a gate whose lever is in a side wing; the long way loops
    north. A flooded pen south of the yard holds two packs; a chain brute guards the reliquary."""
    f = Floor(44, 30)
    f.room(1, 12, 6, 6)                      # start
    f.hline(7, 12, 14, 2)
    f.room(13, 9, 16, 7)                     # yard
    f.water([(15, 10), (16, 10), (15, 11), (26, 10), (26, 11)])
    f.hline(29, 31, 14, 2)                   # short way east...
    f.put(30, 14, "D"); f.put(30, 15, "D")   # ...blocked by a gate
    f.room(32, 10, 11, 10)                   # exit hall
    f.room(14, 1, 10, 6)                     # north-west wing with the lever (dead end)
    f.vline(18, 7, 8, 2)
    f.vline(27, 5, 8, 2)                     # long way: up from the yard...
    f.hline(27, 30, 3, 2)                    # ...along the north corridor
    f.room(31, 1, 8, 6)
    f.vline(34, 7, 9, 2)
    f.room(13, 17, 16, 4)                    # flooded pen (optional), door in its north-east corner
    f.g[16][27] = "."; f.g[16][28] = "."
    f.water([(15, 18), (16, 18), (20, 19), (21, 19), (22, 19), (25, 18)])
    f.room(13, 23, 14, 6)                    # south wing (chest + rats)
    f.vline(19, 21, 22, 2)
    f.room(30, 23, 13, 6)                    # relic room
    f.hline(27, 29, 25, 2)
    f.put(3, 14, "S"); f.put(40, 18, "E")
    f.put(20, 18, "a")
    f.put(16, 19, "b"); f.put(29, 3, "c"); f.put(17, 3, "d"); f.put(20, 26, "e"); f.put(34, 8, "f")
    f.put(36, 26, "g")
    f.put(15, 1, "L"); f.put(14, 27, "C"); f.put(25, 27, "G"); f.put(41, 27, "R")
    f.put(21, 12, "F")
    for x, y in [(10, 14), (11, 14), (10, 15), (11, 15), (34, 12), (35, 12), (34, 13), (35, 13)]:
        f.put(x, y, "^")
    f.g[2][29] = "H"; f.g[22][24] = "H"
    f.put(19, 21, "T"); f.put(33, 14, "T")
    f.data = {"id": "d01_f04", "name_key": "FLOOR_D01_04", "time_limit": 165, "goal": {"type": "breakthrough"},
              "zone": "cells", "accent": "flooded_yard",
              "packs": {"a": [{"mob": "prisoner", "count": 3}],
                        "b": [{"mob": "crossbowman", "count": 2}, {"mob": "jailer", "count": 1}],
                        "c": [{"mob": "jailer", "count": 2}],
                        "d": [{"mob": "rat", "count": 4}, {"mob": "prisoner", "count": 1}],
                        "e": [{"mob": "rat", "count": 6}],
                        "f": [{"mob": "prisoner", "count": 3}, {"mob": "crossbowman", "count": 1}],
                        "g": [{"mob": "chain_brute", "count": 1}]},
              "links": [{"lever_at": [15, 1], "gate_at": [30, 14]}, {"lever_at": [15, 1], "gate_at": [30, 15]}],
              "harpoons": {"29,2": [0, 1], "24,22": [0, 1]}}
    return f


def floor_06():
    """Lower cells: a valve in each wing (seals 2) opens the sluice gate to the stairs. The side halls
    off the start room (cell hall west, flooded store east) are optional."""
    f = Floor(46, 30)
    f.room(19, 22, 8, 7)                     # start (south centre)
    f.vline(22, 15, 21, 2)
    f.room(14, 10, 18, 5)                    # central gallery
    f.hline(4, 13, 11, 2)                    # west corridor
    f.room(1, 3, 10, 8)                      # west wing (valve 1)
    for x in range(2, 10, 3):                # empty cells under the west corridor
        f.cell_block(x, 14, 2, 4, x, "N")
    f.hline(32, 41, 11, 2)                   # east corridor
    f.room(35, 3, 10, 8)                     # east wing (valve 2)
    f.vline(22, 5, 9, 2)                     # sluice to the stairs, gate opens with both seals
    f.room(18, 1, 10, 4)
    f.room(1, 20, 12, 8)                     # south-west cell hall (optional)
    f.hline(13, 18, 24, 2)
    f.room(34, 15, 10, 11)                   # east store (optional, flooded corner)
    f.hline(27, 33, 25, 2)
    f.put(22, 26, "S"); f.put(23, 2, "E")
    f.put(41, 17, "a"); f.put(6, 22, "b"); f.put(4, 6, "c"); f.put(41, 6, "d"); f.put(37, 22, "e")
    f.put(24, 11, "f"); f.put(3, 26, "g")
    f.put(2, 4, "V"); f.put(43, 4, "V")
    f.put(42, 24, "G"); f.put(2, 21, "C"); f.put(25, 27, "N")
    for x, y in [(9, 11), (35, 12), (22, 18)]:
        f.put(x, y, "T")
    for x, y in [(30, 11), (31, 11), (30, 12), (31, 12), (12, 24), (12, 25)]:
        f.put(x, y, "^")
    f.water([(15, 13), (16, 13), (29, 10), (40, 15), (41, 15), (42, 15), (43, 16)])
    f.put(22, 8, "D"); f.put(23, 8, "D")
    f.data = {"id": "d01_f06", "name_key": "FLOOR_D01_06", "time_limit": 180,
              "goal": {"type": "seals", "count": 2}, "zone": "casemates", "accent": "lower_cells",
              "packs": {"a": [{"mob": "drowned", "count": 2}],
                        "b": [{"mob": "prisoner", "count": 3}, {"mob": "crossbowman", "count": 1}],
                        "c": [{"mob": "jailer", "count": 1}, {"mob": "drowned", "count": 1}],
                        "d": [{"mob": "drowned", "count": 2}, {"mob": "rat", "count": 2}],
                        "e": [{"mob": "prisoner", "count": 4}],
                        "f": [{"mob": "jailer", "count": 1}, {"mob": "crossbowman", "count": 2}],
                        "g": [{"mob": "rat", "count": 5}]},
              "seal_gates": [[22, 8], [23, 8]],
              "notes": {"N": "NOTE_D01_03"}}
    return f


def floor_07():
    """Torture chamber: two spike halls on the way; lure packs through the spikes."""
    f = Floor(46, 32)
    f.room(1, 1, 7, 6)                       # start
    f.hline(8, 11, 3, 2)
    f.room(12, 1, 14, 9)                     # spike hall 1
    for x in range(14, 24, 2):
        for y in (3, 4, 6, 7):
            f.put(x, y, "^")
    f.vline(24, 10, 13, 2)                   # passage a (south)
    f.room(18, 14, 14, 6)                    # rack room
    f.hline(32, 35, 16, 2)
    f.room(36, 10, 9, 10)                    # interrogation (chest)
    f.room(4, 12, 10, 9)                     # west cells
    f.hline(14, 17, 16, 2)
    f.vline(25, 20, 22, 2)
    f.room(12, 23, 22, 6)                    # spike hall 2
    for x in range(15, 31, 3):
        for y in (24, 25, 27):
            f.put(x, y, "^")
    f.hline(34, 37, 25, 2)                   # passage e (harpoons)
    f.room(38, 22, 7, 9)                     # exit
    f.put(3, 3, "S"); f.put(41, 29, "E")
    f.put(24, 11, "a"); f.put(42, 17, "b"); f.put(9, 18, "c"); f.put(40, 12, "d"); f.put(35, 25, "e"); f.put(6, 13, "f")
    f.put(6, 19, "C"); f.put(30, 18, "C"); f.put(43, 11, "G")
    f.put(16, 16, "F")
    f.g[24][35] = "H"; f.g[27][36] = "H"; f.g[21][40] = "H"
    f.data = {"id": "d01_f07", "name_key": "FLOOR_D01_07", "time_limit": 110, "goal": {"type": "breakthrough"},
              "zone": "casemates", "accent": "torture",
              "packs": {"a": [{"mob": "prisoner", "count": 6}],
                        "b": [{"mob": "jailer", "count": 2}, {"mob": "crossbowman", "count": 1}],
                        "c": [{"mob": "drowned", "count": 3}],
                        "d": [{"mob": "jailer", "count": 2}, {"mob": "prisoner", "count": 2}],
                        "e": [{"mob": "prisoner", "count": 4}, {"mob": "crossbowman", "count": 2}],
                        "f": [{"mob": "rat", "count": 6}]},
              "harpoons": {"35,24": [0, 1], "36,27": [0, -1], "40,21": [0, 1]}}
    return f


def floor_08():
    """Sluice: the short way crosses the central hall with a pack of 8 and a flood valve;
    the long corridor goes around."""
    f = Floor(48, 32)
    f.room(1, 13, 7, 6)                      # start
    f.hline(8, 13, 15, 2)
    f.room(14, 10, 16, 12)                   # central hall (flood zone)
    f.hline(30, 35, 15, 2)
    f.room(36, 12, 11, 8)                    # stairs hall
    f.room(10, 1, 8, 6)                      # north room (flood valve)
    f.vline(10, 7, 14, 2)                    # from the start corridor up to it
    f.hline(18, 44, 3, 2)                    # long corridor north
    f.vline(43, 5, 11, 2)
    f.room(20, 25, 14, 6)                    # south room (chest)
    f.vline(25, 22, 24, 2)
    f.room(2, 22, 8, 8)                      # rat den
    f.vline(4, 19, 21, 2)
    f.put(3, 15, "S"); f.put(44, 18, "E")
    f.put(12, 3, "a"); f.put(22, 15, "b"); f.put(27, 27, "c"); f.put(30, 3, "d"); f.put(5, 25, "e"); f.put(38, 15, "f")
    f.put(15, 2, "W")
    f.put(32, 28, "G"); f.put(3, 28, "C")
    for x, y in [(9, 15), (40, 16)]:
        f.put(x, y, "T")
    for x, y in [(20, 3), (21, 3), (20, 4), (21, 4), (31, 15), (32, 15), (31, 16), (32, 16)]:
        f.put(x, y, "^")
    f.g[2][36] = "H"
    f.data = {"id": "d01_f08", "name_key": "FLOOR_D01_08", "time_limit": 140, "goal": {"type": "breakthrough"},
              "zone": "casemates", "accent": "sluice",
              "packs": {"a": [{"mob": "prisoner", "count": 3}],
                        "b": [{"mob": "jailer", "count": 2}, {"mob": "drowned", "count": 3}, {"mob": "prisoner", "count": 3}],
                        "c": [{"mob": "crossbowman", "count": 2}, {"mob": "jailer", "count": 1}],
                        "d": [{"mob": "drowned", "count": 4}], "e": [{"mob": "rat", "count": 5}],
                        "f": [{"mob": "jailer", "count": 1}, {"mob": "drowned", "count": 2}]},
              "floods": [{"valve_at": [15, 2], "rect": [14, 10, 16, 12]}],
              "harpoons": {"36,2": [0, 1]}}
    return f


def floor_09():
    """Death row: a long row of condemned cells; the key is on a chain brute; a second brute guards
    a reliquary."""
    f = Floor(50, 34)
    f.room(1, 15, 6, 6)                      # start
    f.hline(7, 44, 17, 3)                    # death row
    for i, x in enumerate(range(9, 41, 5)):
        f.cell_block(x, 12, 4, 4, x + 1 + i % 3, "S")
        f.cell_block(x, 21, 4, 4, x + 2 - i % 2, "N")
    f.room(10, 1, 14, 9)                     # guard barracks (north-west)
    f.vline(16, 10, 11, 2)
    f.room(28, 1, 14, 9)                     # brute room with the key (north-east)
    f.vline(34, 10, 11, 2)
    f.room(45, 12, 4, 21)                    # exit wing
    f.room(10, 26, 16, 7)                    # south hall
    f.vline(17, 25, 25, 2)
    f.room(30, 26, 14, 7)                    # reliquary
    f.vline(35, 25, 25, 2)
    f.put(3, 17, "S"); f.put(46, 31, "E")
    f.put(15, 5, "a"); f.put(21, 27, "b"); f.put(44, 18, "c"); f.put(21, 4, "d"); f.put(14, 30, "e"); f.put(34, 4, "f")
    f.put(37, 29, "g")
    f.put(11, 2, "C"); f.put(12, 31, "G"); f.put(42, 31, "R")
    f.put(35, 13, "F"); f.put(4, 19, "N")
    for x, y in [(12, 18), (30, 17), (35, 19)]:
        f.put(x, y, "T")
    for x, y in [(40, 17), (41, 17), (40, 18), (41, 18), (24, 28), (25, 28), (24, 29), (25, 29)]:
        f.put(x, y, "^")
    f.g[11][22] = "H"                        # shoots through a cell and its bars across death row
    f.g[33][47] = "H"
    f.data = {"id": "d01_f09", "name_key": "FLOOR_D01_09", "time_limit": 195,
              "goal": {"type": "key_holder", "pack": "f"}, "zone": "casemates", "accent": "death_row",
              "packs": {"a": [{"mob": "prisoner", "count": 4}, {"mob": "crossbowman", "count": 1}],
                        "b": [{"mob": "drowned", "count": 3}, {"mob": "jailer", "count": 1}],
                        "c": [{"mob": "jailer", "count": 2}, {"mob": "crossbowman", "count": 2}],
                        "d": [{"mob": "rat", "count": 6}], "e": [{"mob": "drowned", "count": 3}],
                        "f": [{"mob": "chain_brute", "count": 1}, {"mob": "prisoner", "count": 2}],
                        "g": [{"mob": "chain_brute", "count": 1}]},
              "harpoons": {"22,11": [0, 1], "47,33": [0, -1]},
              "notes": {"N": "NOTE_D01_04"}}
    return f


if __name__ == "__main__":
    for idx, fn in [(2, floor_02), (3, floor_03), (4, floor_04), (6, floor_06), (7, floor_07), (8, floor_08),
                    (9, floor_09)]:
        print("floor %d\n%s" % (idx, fn().write(idx)))
