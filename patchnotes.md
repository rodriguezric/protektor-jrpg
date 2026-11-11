# Patch Notes

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
