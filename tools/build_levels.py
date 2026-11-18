#!/usr/bin/env python3
"""Builds data/missions/<planet>_level_0N.json from authored level plans.

    python3 tools/build_levels.py              # rebuild every planet defined here
    python3 tools/build_levels.py terra_virex  # one planet

Each planet is a function that returns its three levels as lists of phases.
A phase is a name plus events made with the pattern helpers below, laid out
on a clock. The builder keeps each level's existing header (music, texture,
name) and its completion triggers (end message, story handoff), writes a
`phases` summary for design review, and replaces `events`.

Design sources: the original Protektor docs (Protektor_Arcade_Mode_Planetary_
Design.txt, data/planet_types.json, pattern_primitives.json). Level rules:
beatable with the standard kit; L1 ~90 s, L2 ~120 s (ends on a mini-boss),
L3 ~150 s (ends on the planet boss); check with tools/level_report.py and the
levelcheck autotest.

Angles are compass degrees: 0 top, 90 right, 180 bottom, 270 left.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class Level:
    """A clock plus the events laid on it."""

    def __init__(self, planet: str, index: int):
        self.planet = planet
        self.index = index
        self.t = 0.0
        self.events = []
        self.phases = []
        self._n = 0

    # -- clock ---------------------------------------------------------------
    def phase(self, phase_id: str, message: str = ""):
        self.phases.append({"phase_id": phase_id, "start_sec": round(self.t, 2)})
        if message:
            self.msg(message)
        return self

    def wait(self, sec: float):
        self.t += sec
        return self

    def _ev(self, e: dict, at: float = None):
        self._n += 1
        e["id"] = "%s_level_%02d_%03d" % (self.planet, self.index, self._n)
        e["time"] = round(self.t if at is None else at, 2)
        self.events.append(e)

    # -- primitives ----------------------------------------------------------
    def spawn(self, kind: str, deg: float, dt: float = 0.0, **extra):
        e = {"type": "spawn_enemy", "enemy_type": kind, "spawn_side": "degrees", "degrees": int(deg) % 360}
        e.update(extra)
        self._ev(e, self.t + dt)
        return self

    def msg(self, text: str, hold: float = 1.4):
        self._ev({"type": "fx_async_message", "text": text, "type_speed_cps": 24, "hold_sec": hold})
        return self

    def gate(self):
        """Hold the timeline until the arena is empty."""
        self._ev({"type": "wait_until_clear"})
        self.t += 0.5
        return self

    def boss(self, boss_id: str, deg: float = 0, mini: bool = False):
        self._ev({"type": "spawn_miniboss" if mini else "spawn_boss", "boss_id": boss_id, "degrees": int(deg) % 360})
        self.t += 0.5
        return self

    # -- patterns (pattern_primitives vocabulary) ----------------------------
    def single_lane_block(self, deg: float, n: int, gap: float, kind: str = "asteroid"):
        """Rocks down one lane: turn your back to it and hold."""
        for i in range(n):
            self.spawn(kind, deg, i * gap)
        self.t += n * gap
        return self

    def drone_cleanup(self, degs: list, gap: float, kind: str = "drone_basic"):
        """Drones one at a time from the given angles: face and shoot."""
        for i, d in enumerate(degs):
            self.spawn(kind, d, i * gap)
        self.t += len(degs) * gap
        return self

    def block_then_shoot(self, degs: list, gap: float, lag: float = 0.6, drone: str = "drone_basic", rock: str = "asteroid"):
        """A rock from each angle with a drone from the opposite side just after:
        block the rock, then turn and shoot the drone."""
        for i, d in enumerate(degs):
            self.spawn(rock, d, i * gap)
            self.spawn(drone, d + 180, i * gap + lag)
        self.t += len(degs) * gap
        return self

    def alternating_lanes(self, degs: list, n: int, gap: float, kinds: list):
        """Threats alternate between lanes, cycling the kinds."""
        for i in range(n):
            self.spawn(kinds[i % len(kinds)], degs[i % len(degs)], i * gap)
        self.t += n * gap
        return self

    def build(self) -> dict:
        return {"events": sorted(self.events, key=lambda e: e["time"]), "phases": self.phases,
                "timeline_sec": round(max([e["time"] for e in self.events] or [0]), 1)}


# ============================================================ Terra Virex ===
# Earth-descendant baseline defense. Core skill: block_then_shoot.
# Pool: asteroid, drone_basic, charger_drone, drone_sine.
# Rhythm: L1 teach_cleanly, L2 steady_layering, L3 compressed_but_readable.
# Signature: block_then_shoot. Mini-boss: Relay Sentinel (opens after you
# block its shot). Boss: The Aegis Relay.

def terra_virex():
    out = []
    # ---- L1: First Watch (~90 s), teach cleanly ----
    L = Level("terra_virex", 1)
    L.phase("intro_teach", "Pattern initialization in progress.").wait(2.0)
    L.single_lane_block(0, 4, 2.4).wait(1.5)
    L.single_lane_block(90, 3, 2.4).wait(1.5)
    L.drone_cleanup([180, 270, 0, 90], 2.8).wait(1.5)
    L.phase("development", "Threat complexity rising.")
    L.block_then_shoot([0, 90, 180, 270, 45], 3.4, lag=0.8).wait(1.0)
    L.phase("signature", "Opposing vectors detected.")
    L.block_then_shoot([135, 315, 45, 225, 0, 180], 3.0, lag=0.7)
    L.spawn("charger_drone", 270).wait(3.0)
    L.spawn("charger_drone", 90).wait(3.5)
    L.phase("final_clear", "Final contact sweep.")
    L.drone_cleanup([0, 120, 240, 60, 180, 300], 1.8)
    out.append(L)

    # ---- L2: Crossfire Watch (~120 s), steady layering, mini-boss ----
    L = Level("terra_virex", 2)
    L.phase("intro_teach", "Pattern initialization in progress.").wait(2.0)
    L.alternating_lanes([0, 180], 6, 1.8, ["asteroid"]).wait(1.0)
    L.alternating_lanes([90, 270], 6, 2.2, ["drone_basic"]).wait(1.5)
    L.phase("development", "Threat complexity rising.")
    L.block_then_shoot([0, 90, 180, 270], 3.4, lag=0.7)
    for d in (45, 225, 135):
        L.spawn("drone_sine", d).wait(2.2)
    L.block_then_shoot([315, 135, 45, 225], 3.0, lag=0.6).wait(1.0)
    L.phase("compression", "Pressure increasing.")
    L.alternating_lanes([0, 90, 180, 270], 10, 1.4, ["asteroid", "asteroid", "drone_basic"]).wait(1.0)
    L.spawn("charger_drone", 45).wait(2.5)
    L.spawn("drone_sine", 225).wait(2.0)
    L.phase("signature", "Opposing vectors detected.")
    L.block_then_shoot([0, 180, 90, 270, 45, 225], 2.7, lag=0.6)
    L.wait(2.0).gate()
    L.phase("mini_boss", "Relay signal hardening. Block to expose its core.")
    L.wait(1.5).boss("relay_sentinel", 0, mini=True)
    L.gate()
    out.append(L)

    # ---- L3: Aegis Drill (~150 s), compressed but readable, boss ----
    L = Level("terra_virex", 3)
    L.phase("intro_teach", "Pattern initialization in progress.").wait(2.0)
    L.single_lane_block(180, 3, 1.6).wait(0.5)
    L.block_then_shoot([0, 90, 180, 270], 3.0, lag=0.6).wait(1.0)
    L.phase("development", "Threat complexity rising.")
    L.alternating_lanes([45, 225, 135, 315], 6, 1.5, ["asteroid", "drone_basic"]).wait(1.0)
    L.spawn("charger_drone", 0).wait(2.0)
    L.spawn("charger_drone", 180).wait(2.5)
    L.block_then_shoot([90, 270, 0, 180], 2.8, lag=0.6, drone="drone_sine").wait(1.0)
    L.phase("compression", "Pressure increasing.")
    L.alternating_lanes([0, 90, 180, 270], 10, 1.25, ["asteroid", "asteroid", "drone_basic", "asteroid", "drone_sine"]).wait(1.0)
    L.spawn("charger_drone", 135).wait(1.5)
    L.spawn("charger_drone", 315).wait(2.5)
    L.phase("signature", "Opposing vectors detected.")
    L.block_then_shoot([0, 180, 45, 225, 90, 270], 2.5, lag=0.55)
    L.wait(2.0).gate()
    L.phase("boss", "")
    L.wait(0.5).boss("aegis_relay", 0)
    L.gate()
    out.append(L)
    return out


PLANETS = {"terra_virex": terra_virex}


def write(level: Level) -> str:
    path = os.path.join(ROOT, "data", "missions", "%s_level_%02d.json" % (level.planet, level.index))
    old = json.load(open(path)) if os.path.exists(path) else {}
    built = level.build()
    keep = [e for e in old.get("events", []) if "trigger" in e]
    data = {
        "format_version": old.get("format_version", 1),
        "level_id": "%s_level_%02d" % (level.planet, level.index),
        "planet_type": level.planet,
        "level_index": level.index,
        "target_duration_sec": {1: 90, 2: 120, 3: 150}[level.index],
        "completion": old.get("completion", {}),
        "header": old.get("header", {}),
        "phases": built["phases"],
        "authoring": {"built_by": "tools/build_levels.py", "timeline_sec": built["timeline_sec"]},
        "events": built["events"] + keep,
    }
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    return "%s: %d events, timeline %.1fs" % (os.path.basename(path), len(built["events"]), built["timeline_sec"])


def main():
    want = sys.argv[1:] or list(PLANETS)
    for p in want:
        for level in PLANETS[p]():
            print(write(level))


if __name__ == "__main__":
    main()
