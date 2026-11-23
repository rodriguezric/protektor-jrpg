# Patch Notes

## 2026-11-23 08:21 EST — `feature_stargazing_window_scene` (v0.64.0)

Stargazing with Pala is now a proper scene: you go up to the observation deck's window together, then the view turns to the night sky and her constellations are drawn star by star as she describes them.

- You walk up to the glass; Pala comes in through the door and stands right beside you, both of you looking out.
- The view cuts to a full-screen night sky through the deck's window frame, with the two of you seen from behind, leaning on the sill. The sky pans from one constellation to the next.
- Her stars are already there in the sky; each line she says joins the ones she's describing: the Kitchen Chair (back, seat, legs, and it rocks on its short leg), the Cup My Brother Broke (rim, sides, handle, and the broken-off chip blinks), and a dog (head, back, tail, legs, and the tail wags). Each one's name lights up over it.
- Back on the deck, Pala tells you it's your turn to make one up next time, then leaves through the door.
- Code: `StoryWing._stargazing` rewritten; new `STAR_SHAPES`, `_sky_view`, `_strokes`/`_stroke`/`_draw_stroke` (drawn a pixel at a time: 1 px Line2D loses slanted runs to pixel snapping), `_tilted`/`_set_tilt`, `_star_trick` in scripts/story_wing.gd. New autotest scenario `PK_TEST=stargaze` in tools/autotest.gd.

## 2026-11-23 07:14 EST — `bugfix_door_entrances_and_exits` (v0.63.4)

People in scenes come and go through real doors, never through walls or out into the dark around a room, and every door is wide enough to walk through.

- Characters only faded in and out at doors in a room's top wall. Anywhere else they walked in a straight line until they were off camera: through the bottom wall of a room, into the black around small rooms, or through the Commons wall. Now every opening counts as an entrance and gets the fade: doors in a top wall, doorways in a bottom wall, and stairs. Walking off the edge of the screen is only for an open edge, like the plaza or the street. Inside a room, people head for the nearest door.
- Every door someone walks through is now two tiles wide, so a character fits through it: the hub building (Commons, Concourse, both decks, the dorm corridor), the pod wing and staging room at the Academy, the front doors at home and on Block 7, the three bedroom doors upstairs (now pairs of doors), and Midas' kitchen doorway.
- Rooms that people walked out of without a door now have one. The Orientation Hall and the Recovery Bay each have a doorway in the bottom wall, which the player can't use. The Commons' double doors back to the briefing halls are now an actual opening.
- Scene paths go around furniture. The recruits leaving the Orientation Hall step out of their bench row into the centre aisle, the badge officer leaves down the aisle, and the pilots leave the Commons along the open row below the archive console.
- The house standard has these rules now: godot-jrpg-style skill v1.4.0 and jrpg_art_style docs v1.3.0. `.standards.json` is re-stamped.
- Code: `scripts/world.gd` (entrance(), open_edge(), nearest_entrance(); map `solid_tiles`), `scripts/story.gd` (enter()/leave() through _way_in(); PK_TRACE=1 audit _trace()), `scripts/building.gd` (DD doors from DOORS, Commons south doorway, two props off the new sills), `scripts/maps.gd` (home, home_up, midas_home, block7, hall, corridor, waiting, recovery), `scripts/story_prologue.gd` (front-door exit), `scripts/story_academy.gd` (hall paths), `scripts/story_hub.gd` (pilots' walk-out path, exit door line).

## 2026-11-23 06:51 EST — `bugfix_emote_alignment` (v0.63.3)

Emote bubbles sit right on top of whoever is emoting.

- Bubbles used to pop at the same spot above everyone's feet, so they floated off to one side and sat at the wrong height on adults and on anyone sitting or lying down. Each bubble now points down at the middle of the character's head, two pixels above it, standing, sitting or lying and facing any way. It also stays attached through hops and when someone stands up or turns while it's showing.
- Code: `scripts/actor.gd` (head_top() reads the head from the frame on screen and caches it on the texture; _place_bubble(); EMOTE_GAP / EMOTE_TAIL; re-placed from refresh() and _set_lift()). New autotest `PK_TEST=emotecheck` (child and adults, stand/sit/lie, every facing, a mid-hop sample; worst gap error 0.1 px). The house standard now has this rule (godot-jrpg-style skill v1.3.0, jrpg_art_style docs v1.2.0), and `.standards.json` is re-stamped.

## 2026-11-23 06:46 EST — `bugfix_bedroom_console_in_bed` (v0.63.2)

Your bedroom at home is rearranged so nothing is squashed into anything else.

- The Starbox was jammed into the side of the bed. The room now has the bed in the corner (with its whole footprint blocked, since it's wider than one tile), the desk under the window, the wardrobe against the right wall, and the Starbox on the floor facing into the room, with the lamp beside it. The packed bag waits by the door and the toy sits in the open corner.
- The bedroom window moved over the desk, so you can look out of it now. It used to be behind the bed and the console.
- The bedtime scene matches: you're tucked into the bed in its new spot, and your mother comes to its side.
- Code: `scripts/maps.gd` (home_up() bedroom props and window), `scripts/story_prologue.gd` (_night() sleeper and quilt). New autotest `PK_TEST=homecheck` (every upstairs event reachable from the hallway, no two furniture sprites overlapping).

## 2026-11-23 06:43 EST — `bugfix_parade_mother_merges_with_crowd` (v0.63.1)

At the parade, your mother no longer walks into strangers or a look-alike.

- The crowd leaves your parents a patch of their own. Before, one woman in the crowd stood on your mother's own spot, dressed almost like her, so the two read as a copy of each other. Another stood exactly where your mother pushes to the barrier, so she walked into a stranger and back into her double.
- That crowd woman now has honey hair and a teal skirt, so she no longer reads as your mother.
- The guard who tells her to step back now walks along the open pavement in front of the barriers instead of on top of them.
- Code: `scripts/maps.gd` (parade() skips crowd slots around the family), `scripts/data.gd` (CROWD[1] colours), `scripts/story_scenes.gd` (barrier() guard path). New autotest `PK_TEST=paradecheck` (no two parade people stacked or side by side).

## 2026-11-23 06:32 EST — `feature_pilots_after_hours` (v0.63.0)

Once the interval's conversation is spent, the pilots leave the Commons and can be found around the building. Each pilot's room has a one-time scene.

- When the interval ends, Hiro, Pala and Midas walk out of the Commons. They stay out of it until the next interval, including after you reload a save. Before that they're in the Commons as always, so the main conversations are unchanged.
- Where to find them:
  - **Hiro:** in the training gym; in his room in front of his turn times once his sync climbs.
  - **Pala:** on the rec room floor watching channel four; later in her room or the archive.
  - **Midas:** in his room, writing home; lying on his bunk after the memory.
  - Talking to them there gives short, story-aware lines and never uses up the interval's conversation. You knock first, and they answer if they're in.
- New one-time scenes in the pilots' rooms:
  - **Hiro:** asleep sitting up in his flight gloves, still blocking in his sleep. You can take the gloves off for him.
  - **Pala:** she pulls you in, shuts the door, and shows you the pencil map she's drawing of every door without a nameplate.
  - **Midas:** he asks you to post a letter to his mother. If you post it at the Operations comm booth, a forwarded reply from his mother turns up on your desk after his death. If you let him keep it, you find it in his desk drawer afterwards and can still post it late.
- After Midas dies his room stays stripped and empty, except once: Pala sitting on the bare bunk frame.
- Code: `scripts/story_wing.gd` (away_spot(), scene_key(), build() places the pilots and dorm scene casts, _knock() for pilots who are in, their talk lines, post_letter(), _letter_at_desk(), midasdesk). `scripts/story_hub.gd` (_map() leaves the pilots out once the conversation is spent, _pilots_leave() in _close(), the comm booth posts a held letter first). `scripts/story_scenes.gd` (dorm room keys and casts; _hiro_asleep, _pala_map, _midas_letter, _pala_bunk; hiro_alone needs Hiro present). `tools/autotest.gd` (`PK_TEST=afterhours`: the walk-out, every pilot's spot, all four scenes, and every letter branch).

## 2026-11-23 05:26 EST — `feature_hub_building_layout` (v0.62.0)

The between-mission hub is now laid out like a real building, and the dormitories are open.

- The Pilot Commons is just the lounge now: couches, windows, the vending machine, the roster board and the people. Hiro, Pala, Midas and the recruits still hang out there, and that's still where you have your one conversation each interval.
- New Operations room, through the OPERATIONS door in the Commons: the deploy terminal, the comm booth for calls home, the sim pod, a planet hologram and the deployment log. The first time you use the terminal, the other pilots crowd in behind you.
- New Main Concourse, through the CONCOURSE door: a T-shaped hall with a building directory. Off it are the Engineering Bay (the workshop, parts shelves, diagnostics, and the sealed launch-cradle door), the Dormitories, stairs down to the Lower Deck and stairs up to the Upper Deck.
- Lower Deck: the rec room, mess hall and training gym. Upper Deck: the archive, observation deck, memorial hall and roof access. The rooms are no longer all one size: the mess hall is big, the archive narrow and deep, and the observation deck wide with a full window wall. The sealed doors and their unlock rules are unchanged.
- Dormitories: your room (your locker and its drawing moved here, plus your bunk and desk), Hiro's, Pala's and Midas' rooms, and a washroom. You knock before going into someone else's room. Each room shows who lives there and changes with the story: Hiro's doodles get torn down, Pala's binders disappear, and after Midas dies his room is stripped and his nameplate removed.
- Nameplates over every door and stairwell show where they lead. Each area flashes its name when you walk in. Once your conversation is spent, the marker points to the next step back toward the Operations terminal from wherever you are.
- Hiro, when he's far gone, now stands at the Commons window instead of the old sim pod.
- Code: new `scripts/building.gd` (Building: every hub map, PARENT/DOORS/ARRIVE links, arrival(), room sizes, room_door()/room_out()). `scripts/maps.gd`: commons() and wing_room() delegate to Building, and the old wing() corridor is gone. `scripts/world.gd`: _build_signs() for wall plaques. `scripts/story.gd`: routes commons/ops to StoryHub and the rest of the building to StoryWing. `scripts/story_wing.gd`: build(), go(), mark_route(), _knock(), first visits and _building_examine(); replaces enter_wing/_enter_room. `scripts/story_hub.gd`: terminal, comm and sim pod handled in Operations, mark_route() replaces the fixed marker, the pilots walk in for the first terminal visit, exit() and an examine fallthrough to StoryWing. `scripts/story_scenes.gd`: hiro_alone and room-scene positions and exit paths. `tools/autotest.gd`: `PK_TEST=building` (alias `wing`) tours every map through its doors; new `PK_TEST=buildcheck` checks that each map's arrivals are on open floor and that every exit, door, interactable and NPC can be reached. doorwalk, stuckcheck, hub and loop were updated for the new layout.

## 2026-11-19 21:08 EST — `bugfix_free_missions_no_powerups` (v0.61.5)

Free Missions are flown with no power-ups.

- Every Free Mission now deploys the bare Protektor: basic gun, no fire-rate or armor upgrades, no auto missile, no extended shield, whatever your profile has bought. Story missions still use your upgrades (or the bare kit on a stripped run).
- The ./run_mission dev tool keeps its --weapon / --upgrades flags.
- Code: `scripts/game.gd` (BASE_LOADOUT, loadout(free_mission), dev_loadout flag), `scripts/mission.gd` (setup() asks for the free-mission loadout in arcade mode), `scripts/main.gd` (run_mission sets dev_loadout). New autotest `PK_TEST=freeloadout`.

## 2026-11-19 15:08 EST — `bugfix_comms_message_start_scrolls_away` (v0.61.4)

Mission comms show every message in full: long transmissions page instead of scrolling their opening away.

- A message longer than the comms box is shown a box-full at a time. Each page types out, holds long enough to read with a blinking ">" for more, then clears for the next. Before, the box scrolled like a terminal and the first line was gone before you could read it ("Something huge is watching us" read as "huge is watching us").
- A queued message can still cut a hold short, but only after the last page has had a moment on screen (about half a second plus a beat per word), so closing lines aren't swallowed either.
- Code: `scripts/mission.gd` (_comms_pump types page by page via new _comms_pages(); _comms_show takes the end mark; minimum read time on the final hold). `tools/autotest.gd`: the comms test shoots the whole transmission and the hand-off to the next one.

## 2026-11-19 15:03 EST — `bugfix_cards_rank_glyph_clipped` (v0.61.3)

High-Low's card ranks sit fully on the card.

- The big rank letter in the card's corner used to poke two pixels above the card's top edge, which also cut the top off the A so an Ace looked like an H. It now sits three pixels inside the cream face.
- Code: `scripts/hub_game.gd` (_card_face places the rank from the font's ascent).

## 2026-11-19 15:02 EST — `bugfix_cards_banner_covers_card` (v0.61.2)

High-Low's banners no longer cover the card.

- READY?, WRONG and the result banner now sit in the felt strip under the card instead of across its face, so you can always see the card that just turned over. Ping-pong and the drill keep their banners where they were.
- Code: `scripts/hub_game.gd` (_big() picks the banner row per game).

## 2026-11-19 15:02 EST — `bugfix_brow_moods_per_type` (v0.61.1)

Every eyebrow is now one connected stroke in every mood, for both straight and arched brows.

- Arched brows no longer break apart when sad, crying or scared (the tail used to drop two rows below the raised inner end), and no longer kink into a V when angry.
- Angry brows are a clean slant down to the middle, the inner end sitting flush on the narrowed eye. Shock lifts the whole brow a row; arched brows keep their curve. Over glasses, the lifted shock brow stays level and clear of the frame.
- Code: `scripts/art_people.gd` (BROW_SHAPES table of [inner, outer, tail] rows per brow type and mood; _brow() reads it). `tools/autotest.gd`: `PK_TEST=brows PK_BROWS=types` renders both brow types side by side (two looks plus a face in glasses) in every mood, portrait and field, front and side.

## 2026-11-19 14:40 EST — `feature_character_brow_choice` (v0.61.0)

Choose your eyebrows when you register your pilot: straight or arched.

- Name entry has a new brows picker beside Look, labelled with the current choice ("< Straight >" / "< Arched >"). Left/Right or Z on it changes it with keys; tap either half to change it by touch. The portrait and walking preview update at once.
- The choice is saved with your slot and shows on your field sprite, dialog portraits and the save-slot portrait in every mood. Old saves start with straight brows.
- Everyone else's brows are unchanged: arched for feminine faces (a girl's or woman's voice, a skirt, or "fem"), straight otherwise.
- Code: `scripts/art_people.gd` (BROW_TYPES, _brow_type() replaces _feminine(), with a spec's "brows" winning), `scripts/game.gd` (Game.brows, in player_spec, save, load and slot info), `scripts/name_entry.gd` (brows picker, _change_brows()), `scripts/slot_screen.gd`, `tools/autotest.gd` (touch_screens taps the brows picker both ways).

## 2026-11-19 14:32 EST — `feature_brows_flush` (v0.60.0)

Eyebrows sit flush on the eyes and run a pixel longer, with an arched tail on feminine faces.

- Brows now sit in the row directly above the eyes (no gap) and have a third pixel running out past each eye's outer edge, so they read as a longer brow. Moods keep their shapes: inner ends up when sad or scared (the tail droops), inner ends down when angry, and the whole brow lifts a row in shock.
- Feminine faces drop that outer tail a pixel, an arched brow. That's anyone with a girl's or woman's voice, a skirt, or "fem": true in their look (now set on Nell and Sefa among the recruits).
- Code: `scripts/art_people.gd` (_brow() rewritten, new _feminine()), `scripts/data.gd` (fem on two EXTRAS).

## 2026-11-19 14:22 EST — `bugfix_mobile_standards` (v0.59.10)

Touch controls now meet the house mobile standard (jrpg_mobile_controls docs v1.0.1): minigame layouts, swipes, drag-scrolling lists and a setting for arrow games.

- Pilot Wing games each have their own touch layout. Ping-pong is played by tapping anywhere, side bars included. High-Low has big UP / DOWN buttons. The Sync-Reflex Drill follows the new "Arrow games" option: swipe anywhere, four arrow buttons, or both. The stick stays away, B quits, stray taps on the picture do nothing during play, and the help line switches to touch wording, centred clear of the corner buttons. On wide phones the buttons take over the whole side bars as big thumb zones that light while held.
- The Options screen has a new "Arrow games" row (Swipe / Buttons / Both, on touch devices), and tapping along a volume bar sets it directly.
- The Achievements wall is tapped directly: tap a tab to switch, tap a card to select it and again to look at it, and drag the grid to scroll. A flick keeps it gliding, and dragging never selects anything.
- The drill can be quit between arrows as well as during them (keys and touch).
- The house standard stamp is recorded in `.standards.json` (skills v1.1.0, docs v1.0.1).
- Code: `scripts/touch_controls.gd` (MINIGAME_LAYOUTS, swipe / zone / ud / arrows layouts, side-bar hit zones, drag-scroll + fling, _game_tap_allowed), `scripts/art_ui.gd` (arrow button art), `scripts/game.gd` (touch_arrows setting), `scripts/options_screen.gd`, `scripts/hub_game.gd` (TOUCH / TOUCH_KEYS, touch_layout / touch_running), `scripts/achievements_screen.gd` (tap(), scroll_by()). New autotest `PK_TEST=touch_mg` (every hub game by touch, achievements drag and flick, volume bar tap), passing at 1280x720 and 1560x720 along with the existing touch, touch_screens and console touch tests.

## 2026-11-19 14:10 EST — `bugfix_planet_difficulty_order` (v0.59.9)

Planets now sit in difficulty tiers: Terra Virex is the easiest, Ignara Prime and Glacien IX are harder, and Umbra Vacua, Viscera Nova, Mechanon Ascens and Tempestris are the hardest.

- Tier 2 (Ignara, Glacien): threats 5% faster than the level's ramp, 8% more far-side escorts, and quiets 0.1 s shorter. Tier 3 (Umbra, Viscera, Mechanon, Tempestris): 10% faster, 14% more escorts, and quiets 0.2 s shorter (Umbra keeps no escorts and gets faster, tighter silences instead). Level 1s get half of their tier, so they keep their designs but still rank in order.
- Glacien gets an extra nudge on every level (its slow freeze-and-thaw reads easier than its numbers), so it now sits clearly above Terra. Ignara 3 is eased a touch so it stays quite challenging without passing the top tier (in bot runs most of its damage comes in the Solar Crucible fight).
- Speed-weighted threat pressure per minute (L1 / L2 / L3): Terra 38 / 61 / 83, Glacien 38 / 66 / 90, Ignara 63 / 97 / 109, Viscera 43 / 72 / 91, Mechanon 48 / 69 / 95, Tempestris 76 / 109 / 159, Umbra 26 / 40 / 49 (few threats, but each punishes turning). Bot playthroughs at 2x: every level cleared except Umbra 02 (its turn sentries punish the bot's habit of always turning) and, in one of two runs, Ignara 03 (lost in the boss fight, then won with 4 hits).
- Code: `tools/build_levels.py` (TIERS, PLANET_TIER and NUDGE tables applied in Level.__init__ on top of RAMP), rebuilt `data/missions/*.json`.

## 2026-11-19 13:45 EST — `bugfix_level_difficulty_scaling` (v0.59.8)

Difficulty now ramps within each planet: level 1 is unchanged, level 2 is reasonably hard and level 3 is very hard.

- Level 1s are untouched; their rebuilt files are byte-for-byte the same.
- Level 2: threats move 12% faster, one arrival in five brings a drone from the far side (so there's always something to turn for), and quiet stretches cap at 1.8 s.
- Level 3: threats move 24% faster, one arrival in three brings a far-side drone, and quiet stretches cap at 1.5 s.
- Rocks, fast drones and chargers, which are already quick, get half the speed-up, so they stay readable. Escorts are basic drones. Umbra Vacua gets no escorts (its threats are few on purpose); its quiets shorten instead (3.2 / 2.8 / 2.4 s).
- Bot playthroughs (standard kit, no foresight): level 2s take 0-4 hits, level 3s 1-5 (some are bot losses, mostly in boss fights). Before, level 2 and 3 played much like level 1.
- Code: `tools/build_levels.py` (RAMP and SPARSE tables, _escorts() and _speed_up() passes in build(), per-level max_gap), rebuilt `data/missions/*_level_02.json` and `*_level_03.json`.

## 2026-11-19 13:23 EST — `bugfix_wave_pattern_variety` (v0.59.7)

Waves vary much more within a level: patterns come from fresh angles, in new shapes, and rarely repeat.

- Every pattern in a level is now turned to a new angle (and half the time mirrored), so a pattern that returns never comes from the same places. It's seeded per level, so each level still plays the same every run.
- New shared shapes that every planet mixes into its own vocabulary: pincers (two at once from split sides), fan sweeps (rocks walking across an arc), tight clusters (one block takes the knot), feints (a lane lights up but the threat comes from elsewhere), stutter rhythms (uneven beats you can't tap along to) and orbiters (circle-shooter drones that hold off and fire). Enemy types that were never used now appear: slow asteroids, random spirals and circle shooters.
- All 21 levels were rewritten so no pattern is used more than twice in a level, apart from each planet's signature (up to three times, each turned and tuned differently). Ignara's levels 1 and 2 no longer share the same mix. Level 1 intensity is unchanged, and every level stays within its target length.
- Mirror Twins: the front twin opens just after it fires and the back twin opens when you block its shot (then turn on it). Before, the back twin could stay behind you indefinitely.
- Code: `tools/build_levels.py` (pattern variation wrapper with a per-level seeded rng, new helpers pincer / fan_sweep / cluster / feint / stutter / orbiters, all planet scripts), rebuilt `data/missions/*.json`, `data/bosses.json` (mirror twin windows).

## 2026-11-19 12:58 EST — `bugfix_wave_dead_time` (v0.59.6)

Missions keep up the action: the long empty stretches between waves are gone, and the remaining pauses are deliberate.

- The level builder now closes up every quiet between arrivals longer than 2.2 s (3.2 s on Umbra Vacua, whose silences are part of its identity), pulling the rest of the level earlier, freeze release times included. In bot playthroughs the field-empty gaps of 2 s or more dropped from 3-21 per level to none outside the deliberate beats, and total empty time fell on every level (Viscera Nova 02: 52 s to 31 s).
- The one long pause left in a level is a breather placed right before its signature stretch on levels 2 and 3, so the quiet now means "brace yourself".
- Bosses arrive as soon as the arena is clear (the extra 2-3.5 s of waiting before each boss is gone).
- Level 1s got a little more of the same-intensity content to stay near 90 s after the gaps closed (their difficulty is unchanged).
- Code: `tools/build_levels.py` (Level.max_gap, breather(), _flow() compaction in build(), gate/boss waits removed, level 1 additions), all `data/missions/*.json` rebuilt. `tools/autotest.gd` levelcheck now prints idle time and every empty gap of 2 s or more; `tools/level_report.py` counts bosses that arrive together (Mirror Twins) as one fight.

## 2026-11-19 12:32 EST — `bugfix_glacien_frozen_cluster_size` (v0.59.5)

Glacien IX's frozen meteor clusters are about 30% smaller, so they can be blocked fairly.

- Every ice wall in the three Glacien levels has fewer rocks (3 to 2, 4 to 3, 5 to 4, 6 to 4) at the same spacing, so the wall is narrower rather than gappier. The drones behind each wall and all the timings are unchanged.
- The Frost Sentinel calls 2 frozen rocks instead of 3 (4 instead of 3 when hurt), and the Boreal Colossus's ice bursts fire 5-6 shards instead of 7-9, over a proportionally narrower arc.
- Bot playthroughs: Thin Ice, Crowding and Deep Freeze all cleared with 0-1 hits.
- Code: `tools/build_levels.py` (glacien_ix accumulation_wall calls), rebuilt `data/missions/glacien_ix_level_0*.json`, `data/bosses.json` (frost_sentinel adds, boreal_colossus arc_burst).

## 2026-11-19 12:28 EST — `bugfix_boss_vulnerability_windows` (v0.59.4)

Bosses are armored most of the time now and only take damage in short, signalled windows, so they can't be rolled over by holding fire.

- No boss phase is open all the time any more. Each boss opens after its signature attack has played out (Aegis Relay, Boreal Colossus, Cyclarch, Paragon and the Observer after their arc bursts, Solar Crucible and Storm Eye after their spinning streams, the Observer's middle phase after it calls adds, the Gestalt Heart's last phase after its burst), after you block one of its shots (Flare Carrier, Void Sentinel, Mirror Twins), or on short cycles that are shut longer than open (Pulse Node, Aegis Relay phase 1, Crucible and Cyclarch middle phases).
- Every window opens with a green ring, a flash and a chime, and closes with a clank. The HP bar is red only while shots land.
- A window takes at most 12% of a boss's HP (30% for a mini-boss) before it slams shut early, so dumping damage can't skip the fight's rhythm.
- Boss HP is lowered to match (Aegis 54, Colossus 66, Crucible 40, Cyclarch 50, Gestalt 66, Observer 54, Paragon 48, Mirror Twins 9 each). With a perfect-aim bot, bosses take 50-70 s and mini-bosses 15-35 s.
- Code: `scripts/boss.gd` (after_attack `on` filter with recovery wait _attack_len(), _window_edges() cues, per-window damage cap _window_cap() / window_cap in the def), `data/bosses.json` (open rules, HP, fight_sec). The autotest bot now also fires at whatever is in front while its back blocks rocks (as a player would).

## 2026-11-19 11:52 EST — `bugfix_boss_early_damage` (v0.59.3)

Bosses can no longer be shredded before their fight starts: they stay armored until their opening attacks have played.

- After a boss or mini-boss glides in it is shut (HP bar steel, shots spark off) until every one of its first-phase attacks has gone off once, plus a beat. When the armor drops it flashes, a green ring pulses out and a chime plays, and from then on its normal open/shut rules apply. Aegis Relay now first takes damage around 8.5 s in, the Observer around 10 s.
- Bosses can opt out with intro_armor: false in data/bosses.json, or set the length with intro_armor_sec.
- Code: `scripts/boss.gd` (_intro_armor_sec(), _intro_t in tick(), _expose_cue()). New autotest `PK_TEST=bosscheck PK_BOSS=<id>` fights one boss with the bot and logs, every second, whether it can take damage, and when damage first landed.

## 2026-11-19 11:49 EST — `bugfix_pingpong_look_and_feel` (v0.59.2)

Rec-room ping-pong redrawn and retimed so it looks and feels like the rest of the game.

- New scene: a lit rec room (banded wall, wood wainscot, tiled floor, pennants) with a hanging lamp pooling light on a proper table (top face with lines, apron, legs, net with posts and tape) and both players at 2x with red and blue paddles that cock back and sweep through a swing.
- The ball flies a real arc: over the net, one bounce on the receiver's half (with a tick), up to the paddle, with a shadow on the table or floor and a trail once the rally gets fast. On a miss it sails past and bounces on the floor.
- Timing is readable and fair: a ring closes on the sweet spot as the ball comes in and turns lemon when it's time to swing. The window is in seconds (not pixels), generous at the start and tightening over 25 hits, so fast rallies stay playable. A whiff locks the swing briefly, so mashing doesn't work.
- Juice: hit-stop and a little shake on PERFECT, sparks, a knock that climbs in pitch with the rally, a chime every 10, the rally count popping on a wall scoreboard, and your pilot smiles on a perfect and looks sad on a miss.
- Code: `scripts/hub_game.gd` (_pingpong rewritten with a time-based window, _flight_h ball arc, _draw_pong / _draw_rec_room / _draw_table / _draw_paddle). Best score and the Table Tennis Ace achievement are unchanged.

## 2026-11-19 11:44 EST — `bugfix_console_protektor_shield_side` (v0.59.1)

The Protektor cartridge's shield now guards your back instead of your front.

- On the Starbox's PROTEKTOR game the shield arc sits opposite where the robot faces: you shoot drones forward and turn your back to rocks and bolts to block them. The drawn arc and the block check use the same angle, so what you see is what blocks.
- Code: `scripts/cg_protektor.gd` (new _shield_dir(), used by _in_shield() and the arc in _draw(); the test bot now turns its back to incoming rocks).

## 2026-11-18 23:31 EST — `feature_character_eyebrows` (v0.59.0)

Everyone has eyebrows now, and they move with the mood.

- A two-pixel brow over each eye, on the field sprites and so on every dialog portrait, sitting in the row between the hairline and the eyes. They're coloured from the hair and darkened so even light hair (Hiro's) reads against skin.
- The brows act: level when calm or smiling, inner ends lifted when sad, crying or terrified (with a third pixel trailing out so the worry reads), inner ends pulled down when angry, both raised in shock, faint when hollow. The few one-off brow pixels some moods had before are folded in (the old angry brow was tilted the worried way round).
- People in glasses or sunglasses keep their frames as their brows (a brow over a frame doubled the line), except a startled lift in shock. Hiro's patched eye has none.
- Code: `scripts/art_people.gd` (_brow(), called from _face()), `tools/autotest.gd` (`PK_TEST=brows` saves a sheet of the cast in every mood, portrait and field, front and side).

## 2026-11-18 22:09 EST — `bugfix_stuck_after_door` (v0.58.5)

You can't get stuck after a door any more, and walking mode always comes back.

- The likely culprit: coming back from the Pilot Wing put you down inside the archive console's footprint in the Commons, where every step counts as blocked, so you were frozen right after the door. You now arrive in front of the door.
- Safety nets, so it can't happen anywhere else: if you're ever standing inside a wall or a piece of furniture while you have control, you're moved to the nearest open tile (cutscenes that seat people on benches are left alone). And if the field stays locked with nothing going on (no conversation or scene running, no dialog, fade, menu or cutscene picture, nobody walking a scripted path) for a few seconds, control is handed back; an interaction that hangs and goes quiet for 10 seconds is released too.
- Tested by walking every door and exit (the home stairs, the front door, Block 7, the Commons, the Pilot Wing and all seven rooms) twice over, back to back with keys held, checking walking mode and an open direction after each: 40 of 40 clean, plus a deliberately stuck lock that released itself in about 5 seconds.
- Code: `scripts/maps.gd` (the Commons arrival tile from the wing), `scripts/world.gd` (blocked_by_map(), _unstick_player(), _safety_net()), `scripts/story.gd` (active / last_activity / touch() so the field can tell a running scene from a dead lock), `tools/autotest.gd` (`PK_TEST=doorwalk`, `PK_REPS`).

## 2026-11-18 21:41 EST — `bugfix_characters_pop_in_and_out` (v0.58.4)

Nobody pops into or out of view any more: people in field scenes walk in and out through doors or from off-screen, per the house JRPG rule.

- New staging helpers, ported from the house standard: enter() brings someone through a door (they fade in inside the dark opening and step down onto the floor) or walks them in from beyond the camera's view; leave() walks them back out the same way (fading out in a doorway) and only removes them once they're out of sight.
- Fixed scenes: the Instructor who comes for Kit, the medic who asks Sefa her name, and the parade guard now walk in and out instead of appearing and vanishing; Nell, Dov, Kit and the maintenance unit walk to their places instead of teleporting; Midas in the mess hall, Hiro and Pala on the rooftop, Pala at the memorial and Midas with his tomatoes are in the room as it fades in, and leave through the door; Pala arrives at the observation deck through the door behind you and leaves the same way.
- Older scenes: the badge-hall officer walks back out instead of vanishing; recruits file out of the orientation hall and step into the lift doors and fade instead of blinking out; the staging-room Instructor comes in through the door; the recovery-ward Instructor walks in, and you walk over rather than being moved; the recruits boarding the parade shuttle fade into its door.
- Code: `scripts/story.gd` (enter(), leave()), `scripts/world.gd` (view_rect(), door_sill(), offstage(), char_at()), `scripts/story_scenes.gd` (room_cast()/room_key(), all scenes), `scripts/story_wing.gd` (room casts before the fade, Pala, Midas), `scripts/story_academy.gd`, `scripts/story_prologue.gd`, `tools/autotest.gd`.

## 2026-11-18 20:33 EST — `bugfix_field_cutscene_player_stuck` (v0.58.3)

You can no longer get stuck after talking to someone who starts a field cutscene.

- Pinned by people: walking is blocked near anyone standing close, and a cutscene could leave people right beside you (Tomas and Juno after the bracelet scene ended up close enough on both sides to block every direction). Now a person overlapping you can never pin you (any step that doesn't go further into them is allowed), and Tomas and Juno stop a step further away.
- Scenes that change maps: when an interaction moved you to a new map partway through (entering Pilot Wing rooms, the street door, coming back to the Commons, Midas' memory), the new map started unlocked while the scene was still playing, so you could walk off, open the menu or start a second conversation on top of it. Now control stays locked until the interaction finishes and is then handed back on whichever map you ended up on.
- Code: `scripts/world.gd` (blocked() lets you step out of an overlap), `scripts/main.gd` (load_map() keeps a busy world's lock on the new map), `scripts/story.gd` (talk/examine/trigger/exit release the new map when the interaction ends), `scripts/story_prologue.gd` (_friends_gift spacing), `tools/autotest.gd` (`PK_TEST=stuckcheck`).

## 2026-11-18 17:58 EST — `bugfix_rooftop_tomato_not_wilted_on_return` (v0.58.2)

Midas' rooftop planter now stays wilted after he's gone until you water it, instead of springing back to ripe tomatoes on the next visit.

- While Midas is alive his planter has tomatoes; once he's dead it is wilted on every visit until you water it, and then it stays watered-green.
- Code: `scripts/maps.gd` (wing_room('rooftop') picks the planter's look from the story), `tools/autotest.gd` (`PK_TEST=tomato`).

## 2026-11-18 17:58 EST — `bugfix_departure_walks_backward` (v0.58.1)

The dawn send-off in Block 7 walks steadily down the street instead of stepping back a tile to reach Tomas.

- The stops now run in order along the sidewalk: Mr. Hale, Benno, Tomas, Juno, Pip and Mrs. Okafor (Tomas used to come after Juno, one tile behind her).
- Code: `scripts/story_prologue.gd` (_departure() stop order).

## 2026-11-18 17:42 EST — `feature_field_story_scenes_expansion` (v0.58.0)

Nine new staged moments in the field, each played once when the story is ready for it.

- The Commons, when you come back from a deployment (at most one per return): Nell's secret ration-candle birthday behind the couch (sing along or keep watch); Pala copying files at the archive console as the maintenance unit polishes its way toward her (distract it, or stay out of it); Hiro alone at the sim pod in the dim light, blocking things that aren't there and counting ('You made me lose count.'); the Instructor walking in to 'transfer' Kit, who looks back from the door while nobody looks at Kit (Kit is gone from the Commons after); a medic asking Sefa her name ('...Pilot.').
- The Pilot Wing: Midas pocketing a bread roll in the mess hall 'for later, in case' (while he's alive); Hiro and Pala arguing on the rooftop ('I'm the fastest thing in this building.' 'That's what scares me.'); Pala leaving Midas' mother's tomato recipe by his name on the memorial wall (after he's gone).
- The parade: your mother pushes through to the barrier, waving both arms, until a guard steps in front of her.
- Each scene is staged with actors walking in and out, emotes, pans and a choice or two, and is remembered so it never repeats.
- Code: new `scripts/story_scenes.gd` (StoryScenes), `scripts/story.gd` (scenes), `scripts/story_hub.gd` (Commons moment on return; Kit's transfer), `scripts/story_wing.gd` (room moments), `scripts/story_prologue.gd` (the barrier), `tools/autotest.gd` (`PK_TEST=scenes`, `PK_SCENE`).

## 2026-11-18 17:38 EST — `feature_npc_conversation_expansion` (v0.57.0)

Everyone you can walk up to has more to say, it changes with the story, and they move on a line each time you come back.

- Home (the evening before): your mother and father each have a run of lines that reacts to what you said about the letter, whether you went out into Block 7, and Juno's bracelet ('Keep it on. Don't let them take it off you.').
- The parade: Hiro, Pala, Midas, the announcer and your parents in the crowd now talk before you line up, and the crowd and the other recruits have a wider spread of lines ('Which one's yours, sweetheart? Oh, you don't get to pick?').
- The academy corridor: the Instructor, Hiro, Pala, Midas and the recruits each have more than one line ('There are more pods than recruits.').
- The Commons: the background recruits are now people with names and portraits (Nell, who counts the chairs at dinner; Dov, who wants a ping-pong rematch; Sefa, who can't hear her sister's voice any more; Kit, who watches the leaderboard; Bram, who tells the same joke). What they say follows the story: how many deployments you've flown, a win or a loss last time, your sync level, calls home, your rally record, Hiro's state, and Midas' death ('Midas laughed at all my jokes. Even the bad ones.'). As the intake 'transfers', fewer of them are left. The maintenance unit gets a paper smile, then a name.
- The escape: Pala has a few lines in the launch wing.
- Lines never repeat twice in a row; once someone's lines are used up, their last few cycle.
- Code: new `scripts/npc_talk.gd` (NpcTalk: conditions, rotation) and `data/npc_talk.json` (built by `tools/build_npc_talk.py`), `scripts/data.gd` (RECRUITS), `scripts/game.gd` (recruits in cast()), `scripts/story_prologue.gd`, `scripts/story_academy.gd`, `scripts/story_hub.gd` (named recruits; last_result), `scripts/story_endings.gd`, `tools/autotest.gd` (`PK_TEST=npctalk` prints every person's lines under three story states; `PK_TEST=commonstalk`).

## 2026-11-18 17:32 EST — `feature_protektor_propaganda_lore` (v0.56.0)

How they sell us: 13 pieces of Protektor propaganda to find and file, a FILES page to read them, and two scenes where the truth breaks through.

- Helion sells the Protektor as a chrome robot that never sleeps; the program is children in chairs. The pieces: the Block 7 noticeboard poster, the recruitment flyer in the bin, your plastic Protektor, Pip's cardboard costume (from Helion's printed pattern), the Starbox PROTEKTOR cartridge, Helion News's 'brave machines' (watch channel 1 a few seconds), the ROBO-PROTEKTOR! cartoon (channel 2), the hollow display Protektor at the parade (examine it before you line up), the Commons vending machine's robot sticker, PROTEKTOR CRUNCH cereal in the mess hall, and two archive files: 'a deliberate simplification', and the new MARKETING BRIEF 7-C (after four deployments): 'The public must never picture a child.'
- Each find files with a toast (FILED n / 13). The field menu has a new Files page: found pieces with where they were and what they say; missing ones show where to look.
- Reveal 1: reading Marketing Brief 7-C the first time cuts through every robot you grew up with (the poster, the parade machine, the toy, the cartridge) to 'There was never a robot. There was always a child in a chair.'
- Reveal 2: after six deployments, Helion News on the rec room TV runs a special bulletin over your last planet: a robot painted over a defense, the shield swinging wide before each block the way you swing it. Afterwards: 'They painted a robot over me,' and the recruit on the couch: 'Wasn't that robot AMAZING? I want to be just like it.'
- Achievement: Read Between the Lines (file all 13). Finds are kept in the profile.
- Code: new `scripts/propaganda.gd` (Propaganda), `scripts/propaganda_screen.gd` (FILES), `scripts/pilot_status.gd` (Files entry), `scripts/story_prologue.gd`, `scripts/story_hub.gd`, `scripts/story_wing.gd` (finds, brief entry, both reveals), `scripts/tv_shows.gd` (the special bulletin), `scripts/tv_screen.gd`, `scripts/console_screen.gd`, `scripts/maps.gd` (parade mech and cereal events), `scripts/main.gd` (toast headers), `scripts/achievements.gd`, `scripts/art_achieve.gd`, `tools/autotest.gd` (`PK_TEST=propaganda`).

## 2026-11-18 17:27 EST — `feature_hub_room_minigames` (v0.55.0)

Three little games in the Pilot Wing, each under a minute, with best scores, achievements and a few credits for a good result.

- Rec Room ping-pong (the table): a rally against a recruit. Press Z (tap) as the ball reaches your paddle; PERFECT / GOOD / EARLY / WHIFF / MISS calls, the ball speeds up each return, and the rally ends on your first miss.
- Rec Room high-low (the card table): Up if the next card is higher, Down if lower (ties win); cards flip with a little animation. Score: your streak.
- Training Gym sync-reflex drill (the console): ten arrows light up one at a time; press that direction as fast as you can. Score: average reaction in ms (a wrong press costs 250 ms). Beat 300 ms and the system says 'well done' for the first time, and it doesn't feel like praise.
- Each game has a short intro and reacts to how you did; a decent result pays 5 credits, once per game per interval. Best scores are kept in the profile. Achievements (GAMES): Table Tennis Ace (20-hit rally), Card Shark (7 in a row), Too Fast to Feel (drill under 300 ms).
- The games don't change relationships: Midas' fate is tied to his relationship level, so a game with him can't be allowed to move it.
- Touch: the games are arrow screens (the stick steers, a tap is Z, B leaves).
- Code: new `scripts/hub_game.gd` (HubGame), `scripts/story.gd` (hub_minigame(): intros, reactions, credits), `scripts/main.gd` (hub_game()), `scripts/achievements.gd` (hub_result(), three achievements; the Starbox 'played' count now only counts Starbox games), `scripts/art_achieve.gd`, `scripts/touch_controls.gd`, `tools/autotest.gd` (`PK_TEST=hubgame`, `PK_HG`).

## 2026-11-18 17:22 EST — `feature_hub_extra_rooms` (v0.54.0)

The Pilot Wing: seven rooms off the Commons to wander between missions, with lore, games and a few quiet moments. None of it uses up the interval's one conversation.

- A new door in the Commons' top wall (left of the dorm) opens onto the Pilot Wing corridor; each room has a door there (face it and press Z), and you leave a room by walking out of its doorway. Rooms open with seniority: Rec Room, Mess Hall and Training Gym from the start, the Archive after two deployments, the Observation Deck after three, the Memorial Hall after four (or once Midas is gone), the Rooftop Garden after five. Sealed doors say when they'll open.
- Rec Room: the same TV as home (all six channels), a Starbox bolted to the shelf (HIRO WAS HERE), a ping-pong table, a card table, and a recruit glued to the couch who is obsessed with Hearts of the Shield Grid and reacts to whichever episode you've reached. Mess Hall: Nutri-Loaf (three ways, all sliced), water (blue), the calorie allowance by sync tier, and two gossiping recruits. Archive: two lore terminals with six entries that unlock over time (Helion's history, the Initiative, the planet roster, and pilot records for LISE HALE and A. DELACROIX, the children Block 7 lost), the locked transfer-records cabinet, and Pala's hidden printouts. Training Gym: sim pods (training), treadmill, a punching bag that swings, the turn-time board (Hiro, Hiro, Hiro, Hiro), and a reflex-drill station. Observation Deck: a wall of window and a telescope. Memorial Hall: a wall of names that grows with the roster (Lise Hale and Delacroix are on it; Midas, with a tin rocket tucked beside his name), ration candles you can light, and a secret guestbook. Rooftop Garden: hydroponic planters under the open night sky.
- Staged scenes: the first night on the Observation Deck, Pala comes in and shows you the constellations she made up (The Kitchen Chair, The Cup My Brother Broke, and a dog), drawn in light across the window. The first visit to the Rooftop finds Midas tending tomatoes like his mother's, or, once he's gone, his labelled planter going dry, which you can water.
- Art: new props (ping-pong table, telescope, hydroponic planters, candles, punching bag, treadmill).
- Code: new `scripts/story_wing.gd` (StoryWing: unlocks, doors, first-visit scenes, room talk/examines, lore), `scripts/maps.gd` (wing(), wing_room(id); Commons door), `scripts/story.gd` (routing; hub_minigame() stubs for the games), `scripts/story_hub.gd` (the door), `scripts/art_props.gd`, `tools/autotest.gd` (`PK_TEST=wing`, `PK_ROOM`, `PK_DEAD`).

## 2026-11-18 17:10 EST — `feature_neighborhood_opening_area` (v0.53.0)

Block 7: the street outside your front door, with the neighbours and friends you're leaving, and a dawn send-off on the way to the parade.

- In the evening the front door now opens onto Block 7 (step through it; the same door brings you home): tenement fronts with lit windows, your door and Mrs. Okafor's, flickering street lamps and a lazy block cat on the sidewalk, a road, the ration kiosk with its striped awning, the noticeboard papered with a chrome-robot Helion poster (STEEL THAT NEVER SLEEPS), a bench, and a scrap of park with swings and a slide. Everything has something to say when examined (your initials on the swing, the dark Delacroix window, the smoothed-out recruitment flyer in the bin...).
- Neighbours, each with a run of lines that moves on each time you return: Mrs. Okafor (on her chair; they took the Delacroix boy twelve years ago, and the camera pans to his family's dark window), Mr. Hale (his daughter went up six years ago; a form letter every spring), Benno at the kiosk (the free tea tin), childhood friends Tomas (not picked: relieved or jealous?) and Juno, and the little ones Pip (in a cardboard Robo-Protektor costume) and Wren.
- Animated scenes: walk into the park and Pip and Wren are playing Robo-Protektor versus the Slime Lord (KA-POW!, Wren goes down), then Pip runs over: 'Are you gonna be a ROBOT now?!' Talk to Tomas or Juno and they come over from the bench with a bracelet braided from blue parade ribbon.
- Dawn: after the night scene the whole block lines the sidewalk and you walk its length with your parents a step behind; each neighbour sees you off (Hale, Benno's 'free' gift, Juno's 'Wear it!' if you have the bracelet, Tomas, Pip's BEEP BOOP salute, Mrs. Okafor), then on to the parade. The street is optional in the evening; the send-off always plays.
- Art: a new 'block' tile theme (soot brick fronts, lit curtained windows, wooden doors), new props (kiosk, noticeboard, swings, slide, cat, bin, street lamp) and a cardboard-robot costume look for characters.
- Code: `scripts/maps.gd` (block7(time)), `scripts/story_prologue.gd` (front-door exit, BLOCK7_TALK, _neighbour(), _friends_gift(), _kids_game(), _departure(), new examines), `scripts/story.gd` (block7 routed to the prologue), `scripts/data.gd` (the Block 7 cast), `scripts/art_tiles.gd`, `scripts/art_props.gd`, `scripts/art_people.gd` (boxbot), `tools/autotest.gd` (`PK_TEST=block7`).

## 2026-11-18 17:02 EST — `feature_tv_serial_cheesy_drama` (v0.52.0)

HEARTS OF THE SHIELD GRID: channel 4's six-episode soap opera, acted with total commitment and no restraint.

- One new episode each time it airs (with 'Previously on HEARTS OF THE SHIELD GRID...' first), and the place is kept in the profile, so it carries across playthroughs; after the finale it reruns from the top, marked RERUN.
- The cast: Captain Brick Steele (sunglasses, epaulettes, a sash), Lady Veronica (auburn, floral, pink), the villainous Dr. Noir (moustache), Nurse Pearl, a priest, and Brick's evil twin Brack (dark coat, moustache). Episodes: 1 A Love in Orbit (Brick slowly removes his sunglasses... 'Not so fast!'), 2 The Slap Heard Round the Grid (SLAP!, 'How could you not tell me you had a TWIN?' '...I don't.'), 3 Who Is Brick Steele? (amnesia: '...Brick? What a ridiculous name.'), 4 Two Bricks, One Heart (the evil twin arrives; Veronica faints), 5 I Object! (the wedding, both twins burst in), 6 Hearts Forever? ('I am your FATHER.' 'NOOOOO!' ...it was all a dream? 'Or... WAS it?' He takes off his sunglasses: another pair underneath. THE END?).
- Dramatic zooms on every gasp, freeze frames in sepia with TO BE CONTINUED, music stings. Watching the whole run earns Must-See TV (GAMES).
- Art: a new `shades` look (sunglasses) for characters.
- Code: `scripts/tv_serial.gd` (TvSerial: episodes, recaps, cast, progress), `scripts/tv_sets.gd` (observation deck, parlor, hospital, chapel, bedroom sets), `scripts/tv_stage.gd` (freeze_frame), `scripts/art_people.gd` (shades), `scripts/achievements.gd` + `scripts/art_achieve.gd` (Must-See TV, tv icon), `tools/autotest.gd` (`PK_EP`).

## 2026-11-18 16:52 EST — `feature_home_tv_channels` (v0.51.0)

The home TV works: flip through six channels of short animated shows on the family set.

- Examine the TV in the living room (after the first look at the silent parade loop) and choose Watch: the set fills the screen, a wood-cabinet CRT with its picture under scanlines. Up/Right and Down/Left flip channels through a burst of static with a green CH number; X (B) switches it off. Each show is staged with real field actors, props and backdrops inside the picture, with a one-line caption band, and loops with a test-card ident between runs.
- CH1 HELION NEWS: anchor Corvin Vale at his desk, a scrolling red ticker ('SHIELD GRID AT 100% * RATIONS UNCHANGED...'), footage of a Protektor over Terra Virex, proud families cheering 'the brave machines', and 'the Protektor never sleeps... so you can.' CH2 ROBO-PROTEKTOR!: the robot cartoon (the Space Slime Lord, KA-POW!, 'eat your rations... and ENLIST!'). CH3 RATION KITCHEN: Chef Dilly's Nutri-Loaf three ways ('...also sliced.', laugh track). CH4 is held for the serial (stand-by card for now). CH5 PLANET OF THE WEEK: Sunny Rollins' forecast for a planet that changes by the day. CH6: snow... and every so often, for a blink, REMAIN CALM.
- In the evening your parents react to whatever you left it on (your father on the news, your mother on the cartoon you used to punch the air to, and so on). The TV remembers its channel.
- Touch: the TV is an arrow screen (the stick flips, B switches off).
- Code: new `scripts/tv_screen.gd` (TvScreen: set, channel flipping, show runner and safe cancelling), `scripts/tv_stage.gd` (TvStage: actors, props, captions, zoom, flash, shake, stings, ticker), `scripts/tv_shows.gd` (the shows), `scripts/tv_sets.gd` (backdrops and foreground pieces), `scripts/tv_serial.gd` (channel 4 placeholder); `scripts/main.gd` (tv()), `scripts/story_prologue.gd` (_tv(), TV_REACTIONS), `scripts/touch_controls.gd`, `tools/autotest.gd` (`PK_TEST=tv`, `PK_CH`, `PK_EVERY`, `PK_FLIP`).

## 2026-11-18 16:43 EST — `feature_console_sword_story_mini` (v0.50.0)

SWORD STORY, the third Starbox cartridge: a one-screen action RPG on a meadow, wave after wave.

- The hero moves in eight directions (arrows / stick), Z (A) slashes in a short arc in front with knockback, X (B) rolls (a quick dash you can't be hit during). Five hearts; beaten foes sometimes drop a heart.
- Foes: slimes hop at you, bats swoop, knights block from the front (hit them from the side or behind), archers back off and shoot (a slash can knock an arrow away). Every fifth wave is the SLIME KING: it quivers and flashes before charging across the meadow and spits out slimes, with its health bar over its crown.
- Scoring: each foe's value times the combo (+10% per hit while hits keep coming within 1.5 s, shown as 'N HIT'), plus a bonus per wave cleared. WAVE / WAVE CLEAR / KING DEFEATED! / THE END banners and a little fanfare on the title card.
- Achievements (GAMES): Squire (clear wave 5), Knight of the Meadow (wave 10), Hero of the Story (wave 20), Flawless Blade (beat the Slime King untouched), Blade Dancer (30-hit combo).
- Code: new `scripts/cg_sword.gd`; `scripts/achievements.gd` (GAME_ACH sword), `tools/autotest.gd` (`PK_WAVE` to start the console scenario at a later wave).

## 2026-11-18 16:38 EST — `feature_console_duel_striders_mini` (v0.49.0)

DUEL STRIDERS, the second Starbox cartridge: a pocket grid duel against an endless ladder of CPU striders.

- A 6x3 grid, your three blue columns against the CPU's red ones. Step between your panels with the arrows / stick (held stick repeats), Z (A) fires your buster down the row, X (B) plays the card in hand: WIDE SWORD (hits the enemy's whole front column), BOMB (lands three panels ahead) or GUARD (blocks the next hit). Each card reloads on its own timer (bars on the hand at the bottom right) and the hand moves on to the next ready card.
- Opponents (SPARK, BOLT, HEX, VOLT...) come one after another, each with more health, more speed and more moves: shots, then ground waves, column strikes and bombs. Every strike flashes its panels yellow first. VS / FIGHT! / K.O.! banners; your five hearts carry over and heal one per win.
- Scoring: 10 per hit, and per win 1000 + 200 per heart left + a speed bonus.
- Achievements (GAMES): Rookie Strider (3 wins), Grid Champion (10), Legend of the Grid (25), Not a Scratch (win a round untouched), Buster Purist (win a round with the buster alone).
- Code: new `scripts/cg_duel.gd`; `scripts/achievements.gd` (GAME_ACH duel).

## 2026-11-18 16:35 EST — `feature_console_protektor_mini` (v0.48.0)

PROTEKTOR, the first Starbox cartridge: the toy version of the real thing, starring a cartoon tin robot.

- Title card (PROTEKTOR / STEEL THAT NEVER SLEEPS, the robot bobbing over its planet), then an endless run: turn with the arrows / stick, the shield arc in front blocks rocks and enemy bolts, Z (A) fires along the same line at drones, X (B) sets off an Overdrive that clears the screen (three charges, one more every 2000 points). Three hearts; spawns and speed ramp up over about two and a half minutes, and after 30 seconds drones park and shoot.
- Scoring: drone 100, block 50 times a chain multiplier (x2 to x5 for blocks in a row, shown next to the score), bolt block 25, Overdrive kills 50. The robot's face cheers on kills and winces when the planet is hit; at zero hearts it blows up.
- Achievements (GAMES): Rookie Robot (1,000), Ace Robot (5,000), Robot Legend (20,000), Three-Minute Hero (survive 3 minutes), Unbreakable Bot (50-block chain), with cartridge icons.
- Console fix: while a game runs the console leaves the tap-target group, so on touch the stick works and the corner button is MENU (pause), not B.
- Code: new `scripts/cg_protektor.gd`; `scripts/achievements.gd` (GAME_ACH protektor), `scripts/console_screen.gd`, `tools/autotest.gd` (console scenario: the cartridge's bot via `auto`, `PK_SECS`, `PK_TOUCH` stick/A checks).

## 2026-11-18 16:31 EST — `feature_bedroom_game_console` (v0.47.0)

The Starbox: a home game console in the protagonist's room (and on the title screen), with a cartridge shelf, high scores and a GAMES achievements tab.

- Your room now has a little CRT and the Starbox on a cabinet, its attract loop blinking. Examine it to play (first look: the worn A button, the robot-grin PROTEKTOR label, 'Every kid on the block had one. Helion made sure of it.'). The title screen has a new Starbox entry so the games are playable outside the story.
- The console fills the screen as a CRT set: its picture is a low-res 144x80 screen at 2x under scanlines, a roll bar and a curved-tube falloff. It warms up from a bright line, the STARBOX logo bounces in to a jingle ('Helion Toys (c) Licensed Protektor product'), then the cartridge shelf: three slots (Protektor, Duel Striders, Sword Story) with each game's best score. Pause (P / Esc / MENU) in a game; game over shows the top-5 table with your new entry flashing, then Z for another go or X back to the shelf. The tube collapses to a line when you power off.
- High scores (top 5 per game) live in the profile, so they survive new playthroughs.
- Achievements: a new GAMES tab with Player One, Cartridge Collector (play all three) and Name on Every Board (a high score in each), plus room for each game's own.
- Touch: a new console layout: while a game runs the stick steers, A and B sit bottom right and MENU pauses; stray taps on the picture are ignored. The shelf is tapped directly.
- Code: new `scripts/console_screen.gd` (ConsoleScreen: shell, CRT shader, shelf, pause, scores), `scripts/console_game.gd` (ConsoleGame base for cartridges), `scripts/touch_controls.gd` (console layout), `scripts/game.gd` (touch_layout, touch_running), `scripts/main.gd` (console(), new `pause` action), `scripts/achievements.gd` (GAMES category, console stats, console_result()), `scripts/art_achieve.gd`, `scripts/art_props.gd` (starbox prop), `scripts/maps.gd`, `scripts/story_prologue.gd` (_starbox()), `scripts/title_screen.gd` (Starbox entry; menu nudged up to fit), `tools/autotest.gd` (`PK_TEST=console`, `PK_GAME`).

## 2026-11-18 14:59 EST — `feature_codec_transmission_filter` (v0.46.0)

Incoming pilot calls now look like transmissions: a scanline codec filter over the caller's face.

- While Hiro, Pala or Midas is on the codec, their portrait gets dark scanlines on every other row, a bright band rolling down the frame, a tint toward their colour, darkened edges, flicker and the odd row tearing a pixel sideways, plus a channel tag (CH1 Hiro, CH2 Pala, CH3 Midas) and a blinking red REC dot. Your own face stays clean, so incoming vs. local reads at a glance.
- In Midas' breakdown the filter frays as he talks: more and wider tears, faster flicker, the tag stuttering, all the way into SIGNAL LOST.
- Code: `scripts/mission.gd` (`CODEC_SHADER` screen-texture shader on whole pixels, `codec_fx`/`codec_label`/`codec_dot` over the portrait box, `_codec_show()` from `_portrait_swap()`, `_update_codec()`, `_codec_harsh` driven by `_midas_breakdown()`).

## 2026-11-18 14:55 EST — `feature_midas_dies_in_breakdown` (v0.45.0)

Midas' breakdown on the codec is now the moment he dies, instead of a warning he survives.

- Hearing his memory in the Commons no longer kills him off-screen: he stays in the Commons (he only says he's okay if you try to talk again). The first story mission after that plays his breakdown about a fifth of the way in. His last words ('Mom, I c-') cut off, static swallows his face over a flatline tone, the arena reads SIGNAL LOST, then your face returns in shock, play resumes, and SYSTEM logs 'Pilot channel 3 offline. Continue engagement.' The Commons announcement of his death follows that mission as before.
- If that mission ends before the call comes through (a loss or retreat), he is marked dead anyway. The breakdown no longer plays after the first talk.
- Code: `scripts/game.gd` (relationship 2 no longer sets `midas_dead`; `midas_dead()` reads the flag; new `midas_doomed()`), `scripts/mission.gd` (`_arm_breakdown()` keyed on `midas_doomed()`, death ending in `_midas_breakdown()`, `_keep_face`, `_finish` fallback), `scripts/sfx.gd` (`flatline`), `scripts/story_hub.gd` (`_midas()` at relationship 2), `tools/autotest.gd` (`PK_TEST=breakdown`).

## 2026-11-18 14:49 EST — `feature_midas_breakdown_transmission` (v0.44.0)

Once you've talked with Midas, a priority transmission stops the next story mission: Midas, terrified, breaking down on the codec.

- Fires once per story save, in the first story mission after Midas' first Commons talk (relationship 1) while he's alive, about a third of the way into the level. Never in Free Missions or training, never during a boss, never once he's dead. It replaces his ordinary lines for that mission.
- The fight freezes (threats, shots, the level clock and your controls), the arena darkens under a flashing PRIORITY SIGNAL, the music drops out under static, and Midas' face blinks in with a new terrified look (wide eyes, pinprick pupils, sweat, clenched mouth), shaking with stabs of static while he stutters 'I... I c-can't...' / 'It's in my head. It won't stop.' / 'I.. I can't control it.. I can't...'. Then your face blinks back in shock, the music returns and play resumes.
- Code: `scripts/mission.gd` (`_arm_breakdown()`, `_midas_breakdown()`, `_breakdown_ready()`, `_cutin` freeze), `scripts/art_people.gd` + `scripts/art_portraits.gd` (`terrified` mood), `scripts/game.gd` (`story.midas_breakdown_seen`), `tools/autotest.gd` (`PK_TEST=breakdown`).

## 2026-11-18 14:45 EST — `feature_pilot_planet_transmissions` (v0.43.0)

Hiro, Pala and Midas now have their own lines on every story level, and what they say follows how close you've grown to them.

- Each of the 21 story levels has two scripted codec calls (early, middle or late), and every pilot is heard on every planet. Lines change with the pilot's relationship: Hiro goes from cocky to cold to hollow over four tiers, Pala from nervous to trusting to openly suspicious of Helion, and Midas from scared to homesick.
- Once Midas is dead he never transmits again; his slots go to Hiro or Pala remarking on his absence (or stay silent). If Pala has left, she is silent too. Calls wait out boss intros and never start while a boss is on the field. Free Missions and training stay quiet.
- The old random chatter is off on levels with scripted calls.
- Code: `data/pilot_comms.json` (built by `tools/build_pilot_comms.py`), `scripts/mission.gd` (`pilot_comms_data()`, `pilot_line()`, `_build_pilot_script()`, `_pilot_tick()`), `tools/autotest.gd` (`PK_TEST=pilotcomms` prints every level's lines under three story states).

## 2026-11-18 14:39 EST — `feature_mission_codec_portraits` (v0.42.0)

Pilots now call you mid-mission codec-style: their face blinks into your portrait panel while they talk, then blinks back to you.

- When Hiro, Pala or Midas sends a message, the portrait panel cuts to static, their face flickers in with their name under it in their colour, and their mouth moves while the text types. Back-to-back lines from the same pilot keep the face up; when the calls end (or a SYSTEM message comes in) the panel blinks back to the protagonist, with any mood they picked up in the meantime (a hit flinch can't cover the pilot's face).
- The random in-mission chatter uses the new calls. Midas never calls once he is dead.
- Code: `scripts/mission.gd` (`pilot_call()`, `_portrait_swap()`, `_static_tex()`, pilot-aware `_comms`/`_comms_pump`, `_set_mood` held while a pilot is on, new `pilot_comms` mission event: `{type, pilot, text, mood, type_speed_cps, hold_sec}`), `tools/autotest.gd` (`PK_TEST=codec`).

## 2026-11-18 13:20 EST — `feature_midas_toy_memory_field_scene` (v0.41.0)

Midas' memory of his mother and the hidden toys now plays out in his kitchen, in field graphics, instead of over a still painting.

- When Midas tells the memory (Commons, after your first talk with him), the screen fades into a flashback of his mother's kitchen: counters, stove, the table with the chipped blue cup, a warm haze at the edges. Each line of his story has its beat: young Midas alone at the table the evening after his birthday; the next morning Mom steps through the doorway with a toy and hands it over, and he lights up; two more mornings, two more toys lining up on the table; Midas creeping to the dresser and finding the rest; Mom leaning in the doorway with her hair tied up and flour on her cheek; her answer, and hearts. The cut-off last line, the static and "Interaction window closed." still snap you back to the Commons, where you were standing.
- New art: Midas' mother (his hair in a bun, apron, flour smudge), young Midas in home clothes, three more toys (tin rocket, robot dog, patched bear), and a `flour` face detail for people.
- Code: scripts/story_hub.gd `_midas_memory()`, `_next_morning()`, `_mom_brings()`, `_stash_peek()`, `_midas_specs()` (the Commons is rebuilt afterwards and control handed back when the talk ends); scripts/maps.gd `midas_home()`; scripts/art_props.gd `toy(v)`; scripts/art_people.gd `flour`.

## 2026-11-18 12:50 EST — `bugfix_no_system_eye_portrait` (v0.40.3)

The one-eyed machine portrait is gone from dialogue: System lines show only their name and text.

- Academy and hub System announcements no longer show the single-eye machine in the portrait frame, matching the Protektor's own lines.
- scripts/story.gd `speaker()`: `system` joins `system_far` / `system_close` with no portrait; scripts/dialog.gd `_set_portrait()` treats a "system" portrait as none, so it can't come back from anywhere else.

## 2026-11-18 11:56 EST — `bugfix_level_clear_names_outdated` (v0.40.2)

Each redesigned level now ends with its own name instead of the old level's.

- The clear message was still the old level's ("Viscera Nova 01 clear: Meteor Pulse", "Umbra Vacua 02 clear: Rotating Convergence"...). It now names the level as built: Glacien IX Thin Ice / Crowding / Deep Freeze, Ignara Prime Kindling / Flashpoint / Crucible, Tempestris Squall Line / Eyewall / Cyclone Season, Viscera Nova First Contact / Reflex Arc / The Heart, Umbra Vacua Stillness / Commitment / The Observer, Mechanon Ascens Calibration / Disruption / Paragon (Terra Virex unchanged).
- tools/build_levels.py: `TITLES`; `write()` sets each level's `title`, its completion message and `completion.message_text`. All 21 missions rebuilt (only those texts changed).

## 2026-11-18 11:55 EST — `bugfix_touch_pause_button_covers_mission_hud` (v0.40.1)

On 16:9 touch screens the pause button no longer covers the planet name and level in a deployment.

- With no side bars, the deployment's pause button now sits in the empty right half of the SCORE box instead of over "TERRA VIREX / LEVEL 01". Wider phones (button in the side bar) are unchanged. The "Esc pause" hint is hidden while playing by touch.
- scripts/touch_controls.gd `relayout()` + `MISSION_SLOT`; scripts/mission.gd `pause_hint` hidden when `Game.touch_active`.
- A very long block streak label ("BLOCK x12") can still pass under the button for a moment.

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
