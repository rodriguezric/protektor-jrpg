# Patch Notes

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
