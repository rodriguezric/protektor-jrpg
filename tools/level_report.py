#!/usr/bin/env python3
"""Static report on every mission in data/missions/ against the level rules.

    python3 tools/level_report.py            # table of all levels
    python3 tools/level_report.py terra      # only levels whose id contains "terra"

Per level: the timeline length (last timed event), an estimated play time
(timeline + a clear-out tail for the last threats to arrive), spawns by type,
the busiest 10 s window, the music track, and any boss / mini-boss events.

Level rules (the level-redesign study): beatable with the standard kit, and a
play time near the level's target - L1 about 90 s, L2 about 120 s, L3 about
150 s - always inside 90-150 s, earlier levels of a planet shorter. A level is
flagged SHORT / LONG when its estimate is more than TOLERANCE seconds from
its target (or outside the 90-150 s window).

Whether a level is actually beatable is checked by playing it:
    PK_TEST=levelcheck PK_LEVEL=all PK_SPEED=3 godot --path .   (tools/autotest.gd)
The bot there has instant aim but no foresight (it turns to the nearest
threat), so a LOSE means "too dense for a simple player", not "impossible";
a WIN with few hits is the real signal that a level is fair. Results were the
same at PK_SPEED=1 and 3 on Terra Virex.
"""
import collections
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = {1: 90.0, 2: 120.0, 3: 150.0}
WINDOW = (90.0, 150.0)
TOLERANCE = 20.0
## Seconds after the last spawn for its threat to cross the arena and die.
CLEAR_TAIL = 8.0
BOSS_TYPES = ("spawn_boss", "spawn_miniboss")


def level_index(level_id: str, data: dict) -> int:
    if "level_index" in data:
        return int(data["level_index"])
    tail = level_id.rsplit("_", 1)[-1]
    return int(tail) if tail.isdigit() else 1


def report(path: str) -> dict:
    data = json.load(open(path))
    level_id = os.path.basename(path)[:-5]
    events = data.get("events", [])
    timed = [e for e in events if "time" in e]
    spawns = [e for e in timed if e.get("type") == "spawn_enemy"]
    last = max((float(e["time"]) for e in timed), default=0.0)
    kinds = collections.Counter(e.get("enemy_type", "?") for e in spawns)
    # busiest 10 s window of spawns
    times = sorted(float(e["time"]) for e in spawns)
    peak = 0
    j = 0
    for i, t in enumerate(times):
        while times[j] < t - 10.0:
            j += 1
        peak = max(peak, i - j + 1)
    bosses = [e.get("boss_id", e.get("id", "?")) + ("*" if e.get("type") == "spawn_miniboss" else "")
              for e in events if e.get("type") in BOSS_TYPES]
    lv = level_index(level_id, data)
    est = last + CLEAR_TAIL
    target = TARGET.get(lv, 120.0)
    flag = "ok"
    if est < max(WINDOW[0], target - TOLERANCE):
        flag = "SHORT"
    elif est > min(WINDOW[1], target + TOLERANCE) and not bosses:
        # a boss fight's length is decided in play, not by the timeline
        flag = "LONG"
    music = os.path.basename(str(data.get("header", {}).get("music", {}).get("file_path", "")))
    return {"id": level_id, "lv": lv, "last": last, "est": est, "target": target, "flag": flag,
            "spawns": len(spawns), "peak": peak, "kinds": kinds, "music": music, "bosses": bosses}


def main() -> None:
    needle = sys.argv[1] if len(sys.argv) > 1 else ""
    rows = [report(p) for p in sorted(glob.glob(os.path.join(ROOT, "data", "missions", "*.json")))
            if needle in os.path.basename(p)]
    print("%-26s %2s %6s %6s %6s %-5s %6s %5s  %-22s %s" % ("level", "L", "time", "est", "target", "flag",
          "spawns", "/10s", "music", "bosses / mix"))
    for r in rows:
        mix = ", ".join("%s %d" % (k, n) for k, n in r["kinds"].most_common())
        boss = ("BOSS " + " ".join(r["bosses"]) + " | ") if r["bosses"] else ""
        print("%-26s %2d %5.0fs %5.0fs %5.0fs %-5s %6d %5d  %-22s %s%s" % (r["id"], r["lv"], r["last"], r["est"],
              r["target"], r["flag"], r["spawns"], r["peak"], r["music"], boss, mix))
    bad = [r for r in rows if r["flag"] != "ok"]
    print("\n%d levels, %d outside their target time (target +/- %.0f s inside %.0f-%.0f s)." % (
        len(rows), len(bad), TOLERANCE, WINDOW[0], WINDOW[1]))


if __name__ == "__main__":
    main()
