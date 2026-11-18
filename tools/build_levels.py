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
import random
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

    def slow_encircle(self, start: float, step: float, n: int, gap: float, kinds: list):
        """One threat at a time, each a step further round the circle."""
        for i in range(n):
            self.spawn(kinds[i % len(kinds)], start + i * step, i * gap)
        self.t += n * gap
        return self

    def staggered_lane_freeze(self, degs: list, gap: float, hold: float, dist: float = 150, kind: str = "asteroid"):
        """Each threat stops at dist for `hold` seconds, then comes on: wait
        for the thaw, then block."""
        for i, d in enumerate(degs):
            self.spawn(kind, d, i * gap, hold_dist=dist, hold_sec=hold)
        self.t += len(degs) * gap
        return self

    def accumulation_wall(self, centre: float, width: float, n: int, release_after: float, rock: str = "asteroid",
                          drones: int = 0, drone: str = "drone_basic", dist: float = 150, gap: float = 0.35):
        """n rocks fan across an arc and freeze at dist, then all thaw at
        once `release_after` seconds after the first appears. `drones` frozen
        drones sit on the far side: shoot them in the quiet window, then turn
        your back on the wall before it thaws."""
        release = round(self.t + release_after, 2)
        for i in range(n):
            frac = 0.5 if n == 1 else i / (n - 1)
            self.spawn(rock, centre - width / 2 + width * frac, i * gap, hold_dist=dist, release_at=release)
        for i in range(drones):
            frac = 0.5 if drones == 1 else i / (drones - 1)
            self.spawn(drone, centre + 180 - 40 + 80 * frac, n * gap + i * gap, hold_dist=dist + 20, release_at=release + 1.2)
        self.t += release_after + 1.0
        return self

    def lane(self, deg: float, dt: float = 0.0, dur: float = 0.6):
        """A lane ignites (telegraph streak) without spawning anything."""
        self._ev({"type": "fx_lane", "degrees": int(deg) % 360, "duration_sec": dur}, self.t + dt)
        return self

    def chain_ignition(self, start: float, step: float, n: int, gap: float, kinds: list, warn: float = 0.6):
        """Lanes ignite one after another round the planet; each fires a
        fast threat `warn` seconds after its streak. Rotate with it."""
        for i in range(n):
            d = start + i * step
            self.lane(d, i * gap, warn)
            self.spawn(kinds[i % len(kinds)], d, i * gap + warn)
        self.t += n * gap + warn
        return self

    def double_lane_rush(self, deg: float, n: int, gap: float, rock: str = "asteroid", drone: str = "drone_fast"):
        """Rocks down one lane while fast drones come down the opposite one:
        your back takes the rocks while your front shoots the drones."""
        for i in range(n):
            self.spawn(rock, deg, i * gap)
            self.spawn(drone, deg + 180, i * gap + gap * 0.5)
        self.t += n * gap
        return self

    def rapid_burst(self, deg: float, n: int, gap: float, spread: float = 30, kind: str = "asteroid"):
        """A quick salvo from one side, fanned a little: one block holds it."""
        for i in range(n):
            self.spawn(kind, deg + (i % 3 - 1) * spread / 2, i * gap)
        self.t += n * gap
        return self

    def alternating_sides(self, degs: list, n: int, gap: float, kind: str = "drone_fast"):
        """Fast threats flipping between sides: turn, shoot, turn back."""
        for i in range(n):
            self.spawn(kind, degs[i % len(degs)], i * gap)
        self.t += n * gap
        return self

    def flash(self, dt: float = 0.0, alpha: float = 0.35, dur: float = 0.15, color: str = "white"):
        self._ev({"type": "fx_flash", "color": color, "duration_sec": dur, "alpha": alpha}, self.t + dt)
        return self

    def storm_front(self, centre: float, beats: int, beat: float, step: float, per_beat: int, spread: float = 40,
                    drones: list = None, seed: int = 1):
        """A storm of rocks from one quadrant, scattered and jittered so it
        looks random; the quadrant steps round by `step` every `beat`
        seconds (lightning on each step). A drone comes from the opposite
        side each beat. Read the beat and you can turn before the front does."""
        rng = random.Random(seed)
        drones = drones or ["drone_basic"]
        for b in range(beats):
            c = centre + b * step
            self.flash(b * beat)
            for k in range(per_beat):
                self.spawn("asteroid", c + rng.uniform(-spread, spread), b * beat + 0.6 + rng.uniform(0, beat - 1.0))
            self.spawn(drones[b % len(drones)], c + 180 + rng.uniform(-20, 20), b * beat + 0.4)
        self.t += beats * beat
        return self

    def false_scramble(self, n: int, window: float, kinds: list, seed: int = 2):
        """A burst from all over that looks like chaos, then a clean gap."""
        rng = random.Random(seed)
        for i in range(n):
            self.spawn(kinds[i % len(kinds)], rng.choice([0, 45, 90, 135, 180, 225, 270, 315]) + rng.uniform(-10, 10),
                       rng.uniform(0, window))
        self.t += window + 3.0
        return self

    def mirrored_arcs(self, deg: float, n: int, gap: float):
        """Spiral drones in mirrored pairs from opposite sides."""
        for i in range(n):
            d = deg + i * 30
            self.spawn("spiral_drone_clock", d, i * gap)
            self.spawn("spiral_drone_counter", d + 180, i * gap)
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


# ============================================================= Glacien IX ===
# Frozen silence and delayed danger. Core skill: calm_under_accumulation.
# Pool: asteroid, drone_basic, drone_tank, drone_sine.
# Rhythm: L1 slow_and_readable, L2 crowding_build, L3 oppressive_accumulation.
# Signature: accumulation_wall / delayed_release_window (threats freeze round
# the planet and thaw together). Mini-boss: Frost Sentinel. Boss: Boreal
# Colossus (long dormant spells, sudden bursts).

def glacien_ix():
    out = []
    # ---- L1: Thin Ice (~90 s), slow and readable ----
    L = Level("glacien_ix", 1)
    L.phase("intro_teach", "Cold front holding. Hold your nerve.").wait(2.0)
    L.slow_encircle(0, 45, 8, 2.6, ["drone_basic", "drone_sine"]).wait(1.5)
    L.phase("development", "Signals stalling in orbit.")
    L.staggered_lane_freeze([0, 90, 180, 270], 3.4, 1.6).wait(1.0)
    L.staggered_lane_freeze([45, 225, 135, 315], 3.0, 2.0).wait(1.0)
    L.phase("signature", "Ice wall forming. Thin it before the thaw.")
    L.accumulation_wall(180, 70, 3, 5.0, drones=2).wait(1.0)
    L.accumulation_wall(90, 70, 4, 5.0, drones=2).wait(1.0)
    L.accumulation_wall(315, 80, 4, 5.0, drones=2).wait(1.0)
    L.phase("final_clear", "Final contact sweep.")
    L.spawn("drone_tank", 0).wait(4.0)
    L.spawn("drone_tank", 180).wait(4.0)
    L.slow_encircle(90, 90, 4, 1.8, ["drone_sine"])
    out.append(L)

    # ---- L2: Crowding (~120 s), crowding build, mini-boss ----
    L = Level("glacien_ix", 2)
    L.phase("intro_teach", "Cold front holding. Hold your nerve.").wait(2.0)
    L.slow_encircle(0, 60, 6, 2.2, ["drone_basic", "drone_sine", "drone_basic"]).wait(1.0)
    L.staggered_lane_freeze([90, 270, 0, 180], 2.6, 2.2).wait(1.0)
    L.phase("development", "Signals stalling in orbit.")
    L.accumulation_wall(0, 80, 4, 5.0, drones=2).wait(0.5)
    L.spawn("drone_tank", 90).wait(3.0)
    L.accumulation_wall(225, 90, 5, 5.0, drones=3).wait(0.5)
    L.phase("compression", "Pressure accumulating.")
    L.staggered_lane_freeze([0, 120, 240, 60, 180, 300], 1.9, 2.4).wait(0.5)
    L.spawn("drone_tank", 270).spawn("drone_tank", 90, 2.0).wait(5.0)
    L.slow_encircle(45, 90, 4, 1.8, ["drone_sine"]).wait(1.0)
    L.phase("signature", "Ice wall forming. Thin it before the thaw.")
    L.accumulation_wall(135, 90, 5, 4.6, drones=3).wait(0.5)
    L.accumulation_wall(315, 90, 5, 4.6, drones=3)
    L.wait(2.0).gate()
    L.phase("mini_boss", "Frost sentinel inbound. Shoot it while it rebuilds.")
    L.wait(1.5).boss("frost_sentinel", 0, mini=True)
    L.gate()
    out.append(L)

    # ---- L3: Deep Freeze (~150 s), oppressive accumulation, boss ----
    L = Level("glacien_ix", 3)
    L.phase("intro_teach", "Cold front holding. Hold your nerve.").wait(2.0)
    L.staggered_lane_freeze([0, 180, 90, 270], 2.2, 2.0).wait(1.0)
    L.phase("development", "Signals stalling in orbit.")
    L.accumulation_wall(90, 90, 5, 4.6, drones=2).wait(0.5)
    L.slow_encircle(0, 45, 6, 1.6, ["drone_sine", "drone_basic"]).wait(0.5)
    L.accumulation_wall(270, 90, 5, 4.4, drones=3).wait(0.5)
    L.phase("compression", "Pressure accumulating.")
    L.spawn("drone_tank", 45).spawn("drone_tank", 225, 1.5).wait(3.0)
    L.staggered_lane_freeze([0, 90, 180, 270, 45, 135, 225, 315], 1.5, 2.6).wait(0.5)
    L.accumulation_wall(45, 100, 6, 4.4, drones=3).wait(0.5)
    L.spawn("drone_tank", 135).spawn("drone_tank", 315, 1.2).wait(3.5)
    L.phase("signature", "The ice is listening.")
    L.accumulation_wall(0, 100, 6, 4.4, drones=3).wait(0.5)
    L.accumulation_wall(180, 100, 6, 4.4, drones=3)
    L.wait(2.0).gate()
    L.phase("boss", "")
    L.wait(0.5).boss("boreal_colossus", 0)
    L.gate()
    out.append(L)
    return out


# =========================================================== Ignara Prime ===
# Heat, aggression, overload. Core skill: rapid_defensive_rotation.
# Pool: asteroid, drone_fast, drone_basic.
# Rhythm: L1 burst_with_breathers, L2 reduced_recovery, L3 relentless_pressure.
# Signature: chain_lane_ignition (lanes light up in sequence round the planet).
# Mini-boss: Flare Carrier (dashes between lanes). Boss: Solar Crucible.

def ignara_prime():
    out = []
    # ---- L1: Kindling (~90 s), bursts with breathers ----
    L = Level("ignara_prime", 1)
    L.phase("intro_teach", "Thermal spikes detected. Turn fast.").wait(2.0)
    L.rapid_burst(0, 4, 0.7).wait(3.0)
    L.alternating_sides([90, 270], 6, 1.6).wait(3.0)
    L.rapid_burst(180, 4, 0.7).wait(3.0)
    L.phase("development", "Heat rising.")
    L.double_lane_rush(270, 5, 1.6).wait(3.0)
    L.double_lane_rush(0, 5, 1.6).wait(3.5)
    L.phase("signature", "Lanes igniting. Follow the fire.")
    L.chain_ignition(0, 90, 8, 1.6, ["drone_fast", "asteroid"]).wait(3.0)
    L.chain_ignition(180, -45, 8, 1.4, ["drone_fast", "asteroid"]).wait(3.0)
    L.phase("final_clear", "Final contact sweep.")
    L.alternating_sides([0, 180, 90, 270], 8, 1.1)
    out.append(L)

    # ---- L2: Flashpoint (~120 s), reduced recovery, mini-boss ----
    L = Level("ignara_prime", 2)
    L.phase("intro_teach", "Thermal spikes detected. Turn fast.").wait(2.0)
    L.rapid_burst(90, 5, 0.6).wait(2.0)
    L.alternating_sides([0, 180], 8, 1.2).wait(2.0)
    L.phase("development", "Heat rising.")
    L.double_lane_rush(45, 6, 1.4).wait(2.0)
    L.chain_ignition(90, 90, 8, 1.3, ["drone_fast", "asteroid", "drone_fast"]).wait(2.0)
    L.double_lane_rush(180, 6, 1.3).wait(2.0)
    L.rapid_burst(270, 5, 0.6).wait(1.5)
    L.alternating_sides([45, 225], 6, 1.1, "drone_basic").wait(2.0)
    L.phase("compression", "Thermal overload building.")
    L.alternating_sides([0, 90, 180, 270], 12, 0.95).wait(1.5)
    L.rapid_burst(315, 6, 0.55).wait(2.0)
    L.phase("signature", "Lanes igniting. Follow the fire.")
    L.chain_ignition(0, 45, 12, 1.15, ["drone_fast", "asteroid"])
    L.wait(2.0).gate()
    L.phase("mini_boss", "Flare carrier on approach. Track it.")
    L.wait(1.5).boss("flare_carrier", 90, mini=True)
    L.gate()
    out.append(L)

    # ---- L3: Crucible (~150 s), relentless pressure, boss ----
    L = Level("ignara_prime", 3)
    L.phase("intro_teach", "Thermal spikes detected. Turn fast.").wait(2.0)
    L.alternating_sides([0, 180, 90, 270], 8, 1.0).wait(1.5)
    L.phase("development", "Heat rising.")
    L.double_lane_rush(90, 6, 1.25).wait(1.5)
    L.chain_ignition(0, 90, 8, 1.15, ["drone_fast", "asteroid"]).wait(1.5)
    L.double_lane_rush(225, 6, 1.2).wait(1.5)
    L.phase("compression", "Thermal overload building.")
    L.alternating_sides([45, 225, 135, 315], 12, 0.9).wait(1.0)
    L.rapid_burst(0, 6, 0.5).rapid_burst(180, 6, 0.5).wait(1.5)
    L.phase("signature", "Every lane is burning.")
    L.chain_ignition(0, 45, 10, 1.05, ["drone_fast", "asteroid"]).wait(0.5)
    L.chain_ignition(180, -90, 8, 1.0, ["asteroid", "drone_fast"])
    L.wait(2.0).gate()
    L.phase("boss", "")
    L.wait(0.5).boss("solar_crucible", 0)
    L.gate()
    out.append(L)
    return out


# ============================================================= Tempestris ===
# Storm chaos with hidden structure. Core skill: implicit_pattern_recognition.
# Pool: asteroid, drone_basic, drone_fast, drone_sine, charger_drone, spirals.
# Rhythm: L1 structured_noise, L2 obscured_cycle, L3 intuitive_safe_zone_reading.
# Signature: rotating_safe_quadrants (storm_front: the rock storm steps round
# on a beat, so the safe facing rotates with it). Mini-boss: Storm Eye.
# Boss: The Cyclarch.

def tempestris():
    out = []
    # ---- L1: Squall Line (~90 s), structured noise ----
    L = Level("tempestris", 1)
    L.phase("intro_teach", "Storm cells forming. Look for the pattern.").wait(2.0)
    L.storm_front(0, 4, 4.5, 0, 3, 35, ["drone_basic"], seed=11).wait(1.5)
    L.false_scramble(6, 5.0, ["drone_basic", "drone_sine"], seed=12)
    L.phase("development", "The storm is turning.")
    L.storm_front(90, 5, 4.5, 90, 3, 35, ["drone_basic", "drone_sine"], seed=13).wait(1.5)
    L.mirrored_arcs(0, 3, 3.0).wait(2.0)
    L.phase("signature", "Find the calm. It moves.")
    L.storm_front(0, 6, 4.0, 90, 4, 40, ["drone_sine", "drone_basic"], seed=14).wait(1.5)
    L.phase("final_clear", "Final contact sweep.")
    L.false_scramble(6, 4.0, ["drone_basic", "drone_fast"], seed=15)
    out.append(L)

    # ---- L2: Eyewall (~120 s), obscured cycle, mini-boss ----
    L = Level("tempestris", 2)
    L.phase("intro_teach", "Storm cells forming. Look for the pattern.").wait(2.0)
    L.storm_front(180, 4, 4.0, -90, 3, 40, ["drone_basic", "drone_sine"], seed=21).wait(1.0)
    L.false_scramble(8, 5.0, ["drone_basic", "drone_sine", "drone_fast"], seed=22)
    L.phase("development", "The storm is turning.")
    L.mirrored_arcs(45, 4, 2.6).wait(1.0)
    L.storm_front(45, 5, 3.8, 90, 4, 40, ["drone_sine", "charger_drone"], seed=23).wait(1.0)
    L.phase("compression", "Pressure dropping. Brace.")
    L.false_scramble(10, 6.0, ["drone_basic", "drone_fast", "drone_sine"], seed=24)
    L.phase("signature", "Find the calm. It moves.")
    L.storm_front(270, 7, 3.5, 90, 4, 45, ["drone_basic", "drone_fast", "drone_sine"], seed=25)
    L.wait(2.0).gate()
    L.phase("mini_boss", "Storm eye closing in. Keep turning.")
    L.wait(1.5).boss("storm_eye", 0, mini=True)
    L.gate()
    out.append(L)

    # ---- L3: Cyclone Season (~150 s), safe-zone reading, boss ----
    L = Level("tempestris", 3)
    L.phase("intro_teach", "Storm cells forming. Look for the pattern.").wait(2.0)
    L.storm_front(90, 4, 3.6, 90, 3, 40, ["drone_basic", "drone_sine"], seed=31).wait(1.0)
    L.phase("development", "The storm is turning.")
    L.mirrored_arcs(0, 4, 2.4).wait(1.0)
    L.false_scramble(10, 6.0, ["drone_fast", "drone_sine", "charger_drone"], seed=32)
    L.storm_front(0, 5, 3.4, -90, 4, 45, ["drone_sine", "drone_fast"], seed=33).wait(1.0)
    L.phase("compression", "Pressure dropping. Brace.")
    L.storm_front(180, 3, 3.2, 90, 4, 45, ["drone_basic", "charger_drone", "drone_fast"], seed=34).wait(1.0)
    L.phase("signature", "Find the calm. It moves.")
    L.storm_front(45, 5, 3.2, 90, 5, 45, ["drone_fast", "drone_sine"], seed=35)
    L.wait(2.0).gate()
    L.phase("boss", "")
    L.wait(0.5).boss("cyclarch", 0)
    L.gate()
    out.append(L)
    return out


PLANETS = {"terra_virex": terra_virex, "glacien_ix": glacien_ix, "ignara_prime": ignara_prime, "tempestris": tempestris}


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
