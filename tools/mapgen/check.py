#!/usr/bin/env python3
"""Quick static check of a floor: the main route and which packs stand on it.

Run: python3 tools/mapgen/check.py [floor numbers...]   (default: all of levels/d01)
For every floor prints the main route length (start -> goal stops -> stairs, gates opened by the
route) and, for every pack, the distance to the route and whether it would aggro (aggro radius
with line of sight; bars let sight through). The bot test (tests/unit/test_bot_floors.gd) is the
real judge; this is for iterating on layouts without Godot.
"""
import json
import os
import sys
from collections import deque

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
LEVELS = os.path.join(ROOT, "levels", "d01")
MOBS = json.load(open(os.path.join(ROOT, "data", "mobs.json")))


def load(index):
    base = os.path.join(LEVELS, "floor_%02d" % index)
    grid = [line.rstrip("\n") for line in open(base + ".txt") if line.strip()]
    data = json.load(open(base + ".json")) if os.path.exists(base + ".json") else {}
    return grid, data


def find(grid, ch):
    return [(x, y) for y, row in enumerate(grid) for x, c in enumerate(row) if c == ch]


def walkable(grid, x, y, open_cells):
    if y < 0 or y >= len(grid) or x < 0 or x >= len(grid[y]):
        return False
    c = grid[y][x]
    if c in "#H|":
        return False
    if c in "D" and (x, y) not in open_cells:
        return False
    return True


def bfs(grid, a, b, open_cells):
    prev = {a: None}
    q = deque([a])
    while q:
        cur = q.popleft()
        if cur == b:
            break
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (cur[0] + dx, cur[1] + dy)
            if n not in prev and walkable(grid, n[0], n[1], open_cells):
                prev[n] = cur
                q.append(n)
    if b not in prev:
        return None
    path = []
    cur = b
    while cur is not None:
        path.append(cur)
        cur = prev[cur]
    return path[::-1]


def los(grid, a, b):
    (x0, y0), (x1, y1) = a, b
    n = max(abs(x1 - x0), abs(y1 - y0)) * 3 + 1
    for i in range(n + 1):
        t = i / n
        x = int(x0 + 0.5 + (x1 - x0) * t)
        y = int(y0 + 0.5 + (y1 - y0) * t)
        if grid[y][x] in "#H":
            return False
    return True


def route(grid, data):
    start = find(grid, "S")[0]
    stops = []
    goal = data.get("goal", {})
    open_cells = set()
    if goal.get("type") == "key_holder":
        stops.append(find(grid, goal["pack"])[0])
    if goal.get("type") == "seals":
        stops.extend(find(grid, "V"))
        open_cells.update(tuple(c) for c in data.get("seal_gates", []))
    exits = find(grid, "E")
    total = []
    cur = start
    # Visit stops greedily by path length.
    left = list(stops)
    while left:
        best = min(left, key=lambda s: len(bfs(grid, cur, s, set()) or [0] * 9999))
        p = bfs(grid, cur, best, set())
        if p is None:
            return None, "stop %s unreachable" % (best,)
        total += p
        cur = best
        left.remove(best)
    p = bfs(grid, cur, exits[0], open_cells)
    if p is None:
        # Maybe a lever opens a gate: try with all gates open (counts the lever detour).
        levers = find(grid, "L")
        gates = set(find(grid, "D"))
        for lv in levers:
            a = bfs(grid, cur, lv, set())
            b = bfs(grid, lv, exits[0], gates | open_cells)
            if a and b:
                total += a + b
                return total, "via lever %s" % (lv,)
        return None, "stairs unreachable"
    total += p
    return total, ""


def main():
    floors = [int(a) for a in sys.argv[1:]] or [i for i in range(1, 11)]
    for index in floors:
        grid, data = load(index)
        if data.get("goal", {}).get("type") == "boss":
            continue
        path, note = route(grid, data)
        print("floor %d: %s" % (index, "route %d m %s" % (len(path), note) if path else "BROKEN: " + note))
        if not path:
            continue
        cells = set(path)
        for letter, groups in sorted(data.get("packs", {}).items()):
            at = find(grid, letter)
            if not at:
                print("   pack %s: NOT ON MAP" % letter)
                continue
            p = at[0]
            radius = max(MOBS[g["mob"]].get("aggro_radius", 6) for g in groups)
            near = min(cells, key=lambda c: (c[0] - p[0]) ** 2 + (c[1] - p[1]) ** 2)
            d = ((near[0] - p[0]) ** 2 + (near[1] - p[1]) ** 2) ** 0.5
            seen = [c for c in cells if (c[0] - p[0]) ** 2 + (c[1] - p[1]) ** 2 <= radius ** 2 and los(grid, p, c)]
            mobs = "+".join("%d %s" % (g.get("count", 1), g["mob"]) for g in groups)
            print("   pack %s %-40s dist %4.1f %s" % (letter, mobs, d, "ON ROUTE (aggro)" if seen else "aside"))


if __name__ == "__main__":
    main()
