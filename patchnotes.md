# Patch Notes

## 2026-11-18 11:31 EST — `feature_boss_achievements` (v0.40.0)

Achievements for every planetary boss, and one for beating them all, on a new BOSSES tab.

- Relay Silenced (The Aegis Relay), Thaw (Boreal Colossus), Heat Death (Solar Crucible), Eye of the Storm (The Cyclarch), Still Heart (The Gestalt Heart), Unobserved (The Observer), Imperfect (Paragon Protektor), and Every Shield Broken for all seven (with a 0/7 progress count). Each card shows the boss itself.
- They unlock the moment the boss dies, in story or Free Missions (retreating afterwards doesn't take it back). Mini-bosses and training don't count; test runs never unlock anything.
- Code: scripts/achievements.gd `BOSSES`, the `bosses` category, `boss_defeated()` and the `bosses_defeated` stat; scripts/mission.gd calls it from `on_boss_died`; scripts/art_achieve.gd `boss` / `all_bosses` emblems.

## 2026-11-18 11:29 EST — `feature_mechanon_ascens_level_redesign` (v0.39.0)

Mechanon Ascens rebuilt around breaking your own rhythm: symmetry that breaks, threats that echo where you faced. Mirror Twins mini-boss, Paragon Protektor boss.

- Mirrored rock/drone pairs; steady a-b rhythms whose last beat comes from somewhere else; echo waves that arrive where you were facing a moment ago (drones in front of it, rocks behind it), so a fixed rhythm lines them up and a changed one doesn't; fast pressure waves round all the lanes; lane shifters.
- Level 1 "Calibration" (~90 s), Level 2 "Disruption" (~120 s) ending on the MIRROR TWINS (two units that sit where you faced a second ago, one in front and one behind), Level 3 "Paragon" (~150 s) ending on the PARAGON PROTEKTOR: it drifts in behind wherever you faced, on a delay that shortens each phase, and fires bursts at your front, so turn to it (shield to the bursts) and shoot in the gap before it slides behind you again.
- Standard kit: the levelcheck bot clears all three (98 s, 108 s, 144 s; 1 hit on the boss).
- Fix: a boss's mirror movement used the level clock, which stands still during boss fights; bosses now keep their own clock.
- Code: scripts/mission.gd spawn_side "echo" (facing log); scripts/boss.gd `_clock`; tools/build_levels.py `echo`, `echo_wave`, `symmetric_pairs`, `symmetry_break`, `pressure_wave` and the Mechanon plans; data/bosses.json `mirror_twin_a`, `mirror_twin_b`, `paragon_protektor`.

## 2026-11-18 11:21 EST — `feature_umbra_vacua_level_redesign` (v0.38.0)

Umbra Vacua rebuilt around restraint: long silences, few but lethal threats, and enemies that punish turning. Void Sentinel mini-boss, The Observer boss.

- The old Umbra was dense spiral spam; now it's sparse. New: turn sentries hold position and fire every time you turn; turn-watchers lunge when you turn. Hold still, shoot what's in front, block what's behind.
- Level 1 "Stillness" (~90 s), Level 2 "Commitment" (~120 s) ending on the VOID SENTINEL (it lunges at the planet when you turn), Level 3 (~150 s) ending on THE OBSERVER: it only acts when you do. Every turn sends shots at your back as you now face, so turn once and hold, and the shield takes them; keep turning and they land. It hops quadrants in phase 2-3 and calls turn sentries.
- Standard kit: the levelcheck bot clears all three with no hits (91 s, 110 s, 110 s). The Observer's real length depends on how still you can stay; the bot is a fast, twitchy player.
- Code: scripts/threat.gd `fire_on_turn`; scripts/boss.gd on_rotate `lunge: true` and `from: "behind"`; tools/build_levels.py `turn_sentries`, `void` and the Umbra plans; data/bosses.json `void_sentinel`, `observer`.

## 2026-11-18 11:08 EST — `feature_viscera_nova_level_redesign` (v0.37.0)

Viscera Nova rebuilt around reading intent: enemies that answer fire, wake on a block or lunge when you turn. Pulse Node mini-boss, The Gestalt Heart boss.

- New behaviours: retaliators (pink) fire back 0.45 s after a hit that doesn't kill them, so finish them in one burst; watchers hover, pulsing, and lunge the moment you block anything, or the moment you turn; chargers still flash before they lunge.
- Level 1 "First Contact" (~90 s) teaches each one on its own with a comms line, then mixes them. Level 2 "Reflex Arc" (~120 s) mixes them up, then the PULSE NODE: it opens and shuts on a beat and fires back if you hit it while it's shut. Level 3 "The Heart" (~150 s) ends on THE GESTALT HEART: it is ringed by node drones and stays shut until they're dead; it fires whenever you turn (it mirrors your rhythm), re-grows watcher nodes in phase 2 and sends chargers in phase 3.
- Standard kit: the levelcheck bot clears all three (95 s, 107 s, 121 s; 1 hit on the boss).
- Code: scripts/threat.gd `retaliate`, `hold_style` "watch", `wake_on` block / turn, `lunge_mult`; scripts/mission.gd `block_count`, spawn events take the new keys; scripts/boss.gd open `when_clear`, `punish_shut`, adds pass the intent keys. tools/build_levels.py `chargers`, `retaliators`, `watchers` and the Viscera plans; data/bosses.json `pulse_node`, `gestalt_heart`.

## 2026-11-18 10:51 EST — `feature_tempestris_level_redesign` (v0.36.0)

Tempestris rebuilt as a storm with hidden structure: the rock storm steps round the planet on a beat. Storm Eye mini-boss, The Cyclarch boss.

- Signature, the moving calm: rocks pour from one quadrant, scattered so it looks random, while a drone comes from the opposite side; on a steady beat (with a lightning flash) the storm steps 90 degrees round. Read the beat and turn before it does: shoot forward, let the shield take the storm.
- Level 1 "Squall Line" (~90 s), Level 2 "Eyewall" (~120 s) with false scrambles (a burst from everywhere, then a clean gap) and mirrored spiral pairs, ending on the STORM EYE (an orbiting mini-boss sweeping arcs of fire), Level 3 "Cyclone Season" (~150 s) ending on THE CYCLARCH: orbiting arcs of fire from behind that widen and speed up across three phases, with spiral and sine escorts.
- Standard kit: the levelcheck bot clears all three with no hits (99 s, 112 s, 133 s); the old Tempestris 3 was the one level it couldn't clear.
- Code: tools/build_levels.py `storm_front`, `false_scramble`, `mirrored_arcs`, `flash` (seeded, so every run is the same) and the Tempestris plans; `fx_flash` takes an `alpha`; data/bosses.json `storm_eye`, `cyclarch`.

## 2026-11-18 10:44 EST — `feature_ignara_prime_level_redesign` (v0.35.0)

Ignara Prime rebuilt around fast rotation: lanes ignite in sequence round the planet. Flare Carrier mini-boss, Solar Crucible boss.

- New telegraph: a lane "ignites" with a pulsing heat streak just before something fast comes down it.
- Level 1 "Kindling" (~90 s): rock salvos with breathers, fast drones flipping sides, rocks down one lane while fast drones rush the opposite one, then two chains of igniting lanes to follow round the planet.
- Level 2 "Flashpoint" (~120 s): shorter breathers, a 12-lane chain, then the FLARE CARRIER: a mini-boss that hops between quadrants every couple of seconds firing paired shots.
- Level 3 "Crucible" (~150 s): relentless chains and rushes, then the SOLAR CRUCIBLE: continuous rings of fire sweeping from behind you while its aimed shots force you to turn: shoot, block, shoot. Counter-rotating rings in phase 2, quadrant hops and fast escorts in phase 3.
- Standard kit: the levelcheck bot clears all three (91 s, 114 s, 146 s, 3 hits on the boss).
- Code: mission event `fx_lane` (scripts/mission.gd `_lane_fx`); tools/build_levels.py `lane`, `chain_ignition`, `double_lane_rush`, `rapid_burst`, `alternating_sides` and the Ignara plans; data/bosses.json `flare_carrier`, `solar_crucible`.

## 2026-11-18 10:32 EST — `feature_glacien_ix_level_redesign` (v0.34.0)

Glacien IX rebuilt around patience: threats freeze around the planet and thaw together. Frost Sentinel mini-boss, Boreal Colossus boss.

- New threat behaviour: frozen threats. They stop at a set distance, frost over (they can be shot), shake and flash for 0.8 s, then carry on together.
- Level 1 "Thin Ice" (~90 s): a slow circle of drones, single lanes that pause before coming in, then three small ice walls: rocks freeze in an arc behind you while drones wait in front; shoot the drones in the quiet, turn your back on the wall before it thaws.
- Level 2 "Crowding" (~120 s): bigger walls, tanks, staggered freezes, then the FROST SENTINEL: it calls frozen rock walls behind you and opens for a few seconds after each call.
- Level 3 "Deep Freeze" (~150 s): oppressive walls on opposite sides, then the BOREAL COLOSSUS: long dormant spells broken by sudden 7-9 shot bursts from behind (long red tell), later hopping between quadrants and calling frozen rocks.
- Standard kit: the levelcheck bot clears all three (89 s, 124 s, 124 s). Terra Virex still clears with no hits.
- Code: scripts/threat.gd `hold_dist` / `hold_sec` / `release_at` with a thaw countdown that keeps running behind wait_until_clear gates; spawn events and boss `adds` accept them. tools/build_levels.py: `slow_encircle`, `staggered_lane_freeze`, `accumulation_wall`, Glacien plans. data/bosses.json: `frost_sentinel`, `boreal_colossus`. Test bot blocks toward the centre of all nearby rocks and shots.

## 2026-11-18 10:17 EST — `feature_terra_virex_level_redesign` (v0.33.0)

Terra Virex rebuilt to its design: block-then-shoot teaching, a Relay Sentinel mini-boss and the Aegis Relay boss.

- Level 1 "First Watch" (~90 s): single-lane blocks, then a rock from one side and a drone from the other (block, then turn and shoot), a faster diagonal version, chargers, a drone clean-up.
- Level 2 "Crossfire Watch" (~120 s): alternating lanes, layered block-then-shoot with sine drones, a compression stretch, then the Relay Sentinel mini-boss: it only opens for ~3 s after you block one of its shots.
- Level 3 "Aegis Drill" (~150 s): compressed but readable waves, then THE AEGIS RELAY: an orbiting satellite array whose weak point rotates open and shut; its bursts come from behind you (face it and your shield takes them), aimed volleys force you to turn; three phases ending in hops between quadrants and drone escorts.
- Boss and mini-boss name cards now sit in the upper arena, clear of the planet.
- Standard kit: the levelcheck bot clears all three with no hits (90 s, 116 s, 130 s).
- tools/build_levels.py (new): builds mission JSON from pattern helpers (single_lane_block, block_then_shoot, alternating_lanes, drone_cleanup, gate, boss), keeping each level's header and completion/story-handoff triggers. data/bosses.json: `relay_sentinel`, `aegis_relay` (with `fight_sec`, used by tools/level_report.py for boss-level estimates).
- Test bot fix: it switched to mouse aim to shoot and never back, so the mission kept snapping its facing to the cursor and its blocks failed. With the fix, the old levels' baseline is 20 of 21 cleared (only Tempestris 3 lost), not the 6 reported in v0.29.0. levelcheck gains PK_VERBOSE=1 (logs each hit and what was nearest).

## 2026-11-18 09:57 EST — `feature_ignara_prime_music` (v0.32.0)

Every Ignara Prime level now plays the Ignara Prime track; the boss theme is kept for bosses.

- Ignara Prime level 1 used to open with boss_theme.mp3; it now uses ignara_prime.mp3 like levels 2 and 3. boss_theme is only played by the boss intro.
- data/missions/ignara_prime_level_01.json header.music.

## 2026-11-18 09:56 EST — `feature_boss_intro_staging` (v0.31.0)

Bosses now make an entrance: silence, a WARNING build-up, a flash and the boss theme; and they die in a chain of explosions.

- Boss intro: the arena empties, the level music fades out, a beat of silence, then six WARNING pulses (red screen, alarms, rising shake, the HUD and planet glitching, the pilot's portrait in shock), the boss glides in, a white flash with hit-stop, boss_theme starts and its name card ("<NAME> / PLANETARY THREAT") pops up. Flashes stay at two a second.
- Boss death: hit-stop, six blasts across its body, a white-out, the shatter, music stops, then the normal victory.
- Mini-bosses: a short version over ducked level music (one red flash, "! WARNING !", name card "ELITE THREAT"), music restored when it dies.
- Boss hits now give a quick half-flash so a stream of bolts doesn't keep the boss white.
- scripts/mission.gd: `_boss_entrance`, `_boss_intro`, `_mini_intro`, `_name_card`, `_boss_death`, `_dissolve_threats`, `_staged_wait` (pause-aware); the timeline and the level end hold while staging (`_hold`). Event option `intro: false` skips it; boss defs may set `music`, `warning`, `subtitle`. data/bosses.json gains a `test_mini` placeholder.

## 2026-11-18 09:48 EST — `feature_boss_encounter_runtime` (v0.30.0)

Engine support for bosses and mini-bosses: big multi-phase enemies with an HP bar, plus new mission events.

- Missions can now field bosses: they glide in, hold position around the planet, attack on timers, change behaviour at HP thresholds, and can be shut (hits spark off) until they open. A boss HP bar with its name runs along the top of the arena. No shipped level uses one yet; the planet redesigns will.
- scripts/boss.gd (new `Boss`, a `Threat` subclass so bolts, beam and missiles hit it): movement hold / orbit / hop / mirror / lunge; open always / cycle / after_attack / after_block; attacks volley, arc_burst, spin_stream, adds, on_rotate, each with an optional tell. data/bosses.json holds definitions (a `test_boss` placeholder for now).
- scripts/mission.gd: events `spawn_boss` / `spawn_miniboss`, `music` (play / fade_out / duck / restore), `wait_until_clear` (holds the timeline until the arena is empty), `fx_flash`, `fx_shake`; `boss_spawned` / `boss_defeated` signals; results carry `bosses`; boss shots are drawn red and tell the boss when blocked.
- scripts/art_mission.gd `boss()` + Art.boss(): data-driven boss sprite (shapes orb, relay, colossus, crucible, cyclone, heart, eye, mirror; nodes, spikes; lidded eye while shut).

## 2026-11-18 09:46 EST — `feature_level_test_harness` (v0.29.0)

Tools for checking levels against the redesign rules: a timeline report and a standard-kit play test.

- No player-facing change.
- tools/level_report.py: per mission, timeline length, estimated play time, spawns by type, busiest 10 s, music, bosses; flags levels away from their target (L1 90 s, L2 120 s, L3 150 s, +/-20 s inside 90-150 s). Today all 21 are SHORT.
- tools/autotest.gd `levelcheck` scenario (PK_LEVEL=all|id|substring, PK_SPEED, PK_LIMIT): plays each level with the basic kit and prints WIN/LOSE/TIMEOUT, game time, hits and hp. First run: 6 wins, 15 losses (Terra Virex 2-3 and all of Ignara Prime, Tempestris, Viscera Nova among them).
- The autotest bot now confirms the defeat screen too, so failed runs no longer stall.

## 2026-11-12 20:13 EST — `feature_options_menu` (v0.28.0)

New Options screen: music volume, sound volume, text speed and vibration.

- Options is on the title menu (between Achievements and Quit) and in the X field menu (Close / Save / Options / Controls / Title). Left/Right change a row, Z (or a second tap) cycles it, X or Back leaves. Changes apply immediately (the blip previews the sound level) and are remembered across launches, shared by all save slots.
- Music and Sound: 0-10, 0 mutes. Text speed: Slow / Normal (the old 48 cps) / Fast / Instant. Vibration On/Off appears when playing by touch.
- scripts/options_screen.gd (new `OptionsScreen`); scripts/game.gd `settings`, `load_settings()`, `save_settings()`, `text_cps()` (file user://protektor_settings.json, test-isolated via `_p()`); scripts/sfx.gd creates Music/SFX buses and `apply_volumes()`; mission.gd routes the zoom loop and shield-up players to those buses; dialog.gd types at `Game.text_cps()`; `Game.buzz()` honours the vibration setting; touch_controls.gd lists OptionsScreen as an arrow screen; title menu moved up 6 px to fit the extra row.

## 2026-11-12 20:00 EST — `feature_free_missions_quick_retry` (v0.27.0)

Free Missions results now offer Retry / Next / Star map, so you can go again without the star map.

- Win screen: Retry, Next (the next level of the same world, when unlocked; cursor starts here) and Star map. Defeat screen: Retry and Star map. Retry skips the warp intro; Next plays it. Star map (or X) returns to the map with the same world selected. Story deployments and training are unchanged.
- scripts/mission.gd: new `_arcade_menu()` (one-row Menu, keys and touch) replaces the "Press Z" prompt in arcade mode on victory and defeat; `_result` carries `next`.
- scripts/main.gd `arcade()`: inner loop replays or advances on `next`.

## 2026-11-12 19:40 EST — `feature_dont_show_protektor_portrait` (v0.26.0)

The Protektor speaks without a portrait: a voice with no face.

- When the Protektor talks through the badge (first badge touch, the sync pod link and its follow-up line), the dialog box shows only its name tag and text. Academy System announcements keep their eye portrait.
- scripts/story.gd `speaker()`: `system_far` / `system_close` no longer pass a portrait; plain `system` is unchanged.

## 2026-11-11 16:15 EST — `bugfix_free_missions_overwrites_story_slot` (v0.25.5)

Playing Free Missions no longer wipes your story save.

- Clearing a Free Mission used to overwrite the last-used save slot with an empty prologue, so Continue started a new game. Story slots are now untouched; Free Missions progress is still saved.
- scripts/game.gd: new `in_story` flag (true after `new_game()`, false after `load_meta_only()`); `save()` only writes the profile when no playthrough is live; `mark_completed(..., arcade_mode=true)` calls `save_profile()` instead of `save()`.

## 2026-11-11 16:11 EST — `bugfix_autotest_writes_real_saves` (v0.25.4)

Running the autotest scenarios no longer overwrites the player's real save slots, profile or achievements.

- No player-facing change; normal play still saves to user:// exactly as before.
- scripts/game.gd: new `save_dir` + `_init_save_dir()` / `_p()`. When PK_TEST is set, slots, profile, legacy save and achievements go to user://autotest/ (wiped at launch); PK_SAVE_DIR overrides the folder. PK_ACH still wins for achievements.
- tools/autotest.gd `slotlogic`: only appends the missile special if it isn't already owned (it was duplicating it in the profile).
- Note: `slots`/`slotlogic` used to read whatever was in the real save folder; they now start from an empty one.

## 2026-11-11 16:09 EST — `bugfix_press_z_prompt_on_touch` (v0.25.3)

Mission results and the ending card say "Tap ..." instead of "Press Z" when you're playing by touch.

- Victory and defeat screens show "Tap to continue" on touch; the end card shows "Tap to return to the title". Keyboard/gamepad still read "Press Z ...".
- scripts/art.gd: new `press_prompt(rest)` helper keyed on `Game.touch_active`; used in scripts/mission.gd (`_begin_victory`, defeat screen) and scripts/story_endings.gd (`_end_card`), with labels centred on the chosen text's width.

## 2026-11-11 16:07 EST — `bugfix_recruit_mentions_dead_midas` (v0.25.2)

Recruits in the Commons no longer talk about Midas as if he were alive after his death.

- After Midas dies, the recruit who used to say "You're from the same intake as Midas, right? He's nice." now says "They took Midas's name off the board this morning. Nobody said anything."
- scripts/story_hub.gd `talk()`: the generic recruit line set 2 branches on `Game.midas_dead()`.

## 2026-11-11 16:06 EST — `bugfix_training_info_reward_mismatch` (v0.25.1)

The Training Modules screen now shows the first-clear double reward, matching the tier menu.

- The info box under the module picker showed the next uncleared tier at its base price (e.g. "[III 24c]") while the tier menu and the actual payout were double; it now reads "[III 24c x2]".
- scripts/training.gd `_update_info()`: tag for `k == done` uses "%dc x2".
