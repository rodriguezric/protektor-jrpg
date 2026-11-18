#!/usr/bin/env python3
"""Builds data/pilot_comms.json: what Hiro, Pala and Midas say over the codec
on each story level.

    python3 tools/build_pilot_comms.py

Shape: planet -> level ("1".."3") -> list of calls. A call is
    {"pilot", "at": start|mid|late, "lines": {tier: [text, mood]}, "dead": {...}}
The tier is the pilot's relationship level; mission.gd uses the highest tier
key not above it. Midas calls carry a "dead" call (another pilot, usually
about his absence) that replaces his once Game.midas_dead() is true; with no
"dead" call his slot stays silent. Moods are portrait moods: "", smile, sad,
angry, shock, hollow.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def L(*tiers):
    return {str(i): list(t) for i, t in enumerate(tiers) if t is not None}


def call(pilot, at, lines, dead=None):
    c = {"pilot": pilot, "at": at, "lines": lines}
    if dead:
        c["dead"] = dead
    return c


COMMS = {
    "terra_virex": {
        "1": [
            call("hiro", "start", L(("First real drop! Bet I clear my side before you clear yours.", "smile"),
                                    ("Feel that hum when the link takes? Don't hesitate. Just turn.", "smile"),
                                    ("Terra again. I could fly this one asleep. Maybe I do.", ""),
                                    ("Terra Virex. Baseline. Nothing here requires thought.", "hollow"))),
            call("midas", "mid", L(("Is that a colony down there? Are people watching us?", "sad"),
                                   ("Did you call home yet? Tell me you called home.", "smile")),
                 dead={"pilot": "pala", "lines": L(("Midas used to watch the colony lights from up here. ...Keep going.", "sad"),
                                                   None,
                                                   ("They took Midas off the roster like he was never on it.", "angry"))}),
        ],
        "2": [
            call("pala", "start", L(("Shots from both sides on this one. Don't chase. Turn with it.", "sad"),
                                    ("Crossfire. Breathe between volleys. I'm right here.", "smile"),
                                    ("They log every turn we make. Make yours look ordinary.", "angry"))),
            call("hiro", "late", L(("Relay sentinel coming up. First one to tag it buys dinner.", "smile"),
                                   ("The sentinel pulses before it fires. Stop thinking and you'll feel it.", "smile"),
                                   ("Don't talk. Turn.", ""),
                                   ("Sentinel inbound. Its pattern is already in me.", "hollow"))),
        ],
        "3": [
            call("midas", "start", L(("The Aegis Relay is so big. I'll be listening, okay?", "sad"),
                                     ("Mom says big things are only small things standing close together.", "smile")),
                 dead={"pilot": "pala", "lines": L(("Midas would have said something kind right about now. So: you've got this.", "sad"),
                                                   None,
                                                   ("Midas didn't transfer. I'm going to prove it.", "angry"))}),
            call("pala", "late", L(("Almost through. When we land, let's sit somewhere quiet.", "smile"),
                                   ("Watch the relay's shield. It opens when it breathes. So do you.", "smile"),
                                   ("If anything happens after this drill, my notes are in my locker.", "sad"))),
        ],
    },
    "glacien_ix": {
        "1": [
            call("pala", "start", L(("It's so quiet out here. Quiet makes me count my heartbeats.", "sad"),
                                    ("Ice holds things still until it doesn't. Watch the frozen ones.", ""),
                                    ("The cold scrambles their channel. We can talk a little more freely.", "angry"))),
            call("hiro", "mid", L(("They just hang there! Hit the frozen ones before they wake!", "smile"),
                                  ("Stillness is a lie. Everything here waits for you to blink.", "smile"),
                                  ("Frozen targets. Free points. Faster.", ""),
                                  ("Stillness. Release. Impact. Predictable.", "hollow"))),
        ],
        "2": [
            call("midas", "start", L(("It's so cold I can feel it through the link. Can you?", "sad"),
                                     ("It snowed at home once. Mom made me wear three scarves.", "smile")),
                 dead={"pilot": "hiro", "lines": L(("Midas' channel is still on my display. Somebody should clear it.", ""),
                                                   None,
                                                   ("Midas' channel is dead weight. Ignore it.", ""),
                                                   ("One fewer signal. Less noise.", "hollow"))}),
            call("pala", "late", L(("They're crowding in. Don't let them make you panic.", "sad"),
                                   ("Frost Sentinel ahead. I've seen you do harder. Go.", "smile"),
                                   ("Another pilot dropped off the roster this morning. Stay sharp.", "angry"))),
        ],
        "3": [
            call("hiro", "start", L(("Colossus run! Loser does the other's sim drills for a week.", "smile"),
                                    ("When the Colossus moves the whole planet groans. I love it.", "smile"),
                                    ("The Colossus is slow. I'm not.", ""),
                                    ("Large target. Low threat. Proceed.", "hollow"))),
            call("midas", "late", L(("I'm scared of the big one. But I'm glad it's you down there.", "sad"),
                                    ("If I don't make it back, call my mom for me? ...Joking. Mostly.", "sad")),
                 dead={"pilot": "pala", "lines": L(("I keep waiting for Midas to check in. The quiet is worse than the cold.", "sad"),
                                                   None,
                                                   ("Midas' last log stops mid-sentence. Same as the others.", "angry"))}),
        ],
    },
    "ignara_prime": {
        "1": [
            call("hiro", "start", L(("Ignara! Finally something with some heat. Keep up.", "smile"),
                                    ("The heat sharpens everything. I see the shots before they fire.", "smile"),
                                    ("Hot. Fast. Good.", ""),
                                    ("Thermal load irrelevant. Continue.", "hollow"))),
            call("pala", "mid", L(("The heat warnings are screaming. Turn early, not hard.", "sad"),
                                  ("Your sync spiked just now. Breathe. Come back to yourself.", ""),
                                  ("The heat masks our telemetry. They hear less of us down here.", "angry"))),
        ],
        "2": [
            call("midas", "start", L(("Everything's on fire. Is it supposed to look like this?", "shock"),
                                     ("This heat smells like Mom's oven. Is that weird? It's weird.", "smile")),
                 dead={"pilot": "hiro", "lines": L(("Midas would've freaked out at all this fire. ...Let's just go.", ""),
                                                   None,
                                                   ("Empty channel. Fine.", ""),
                                                   ("Midas is a closed channel.", "hollow"))}),
            call("hiro", "late", L(("Flare Carrier! Don't let it out-turn you!", "smile"),
                                   ("Watch the flares. Or don't. I stopped watching.", "smile"),
                                   ("The carrier's mine.", ""),
                                   ("Flare pattern known.", "hollow"))),
        ],
        "3": [
            call("pala", "start", L(("The Crucible burns hot enough to melt a relay. Stay calm in there.", "sad"),
                                    ("Whatever happens in the Crucible, you come back. Promise me.", "sad"),
                                    ("After this, we talk. Somewhere they can't record.", "angry"))),
            call("midas", "late", L(("I'm on your channel. You're doing it. You're really doing it!", "smile"),
                                    ("I-I'm here. I'm okay. My hands just won't stop shaking.", "sad")),
                 dead={"pilot": "pala", "lines": L(("Midas used to talk us through the Crucible. I'll try. ...Stay with me.", "sad"),
                                                   None,
                                                   ("Midas' sync logs are sealed now. So were the others'.", "angry"))}),
        ],
    },
    "tempestris": {
        "1": [
            call("pala", "start", L(("Storm static on every channel. If I cut out, keep turning.", "sad"),
                                    ("There's a rhythm under the storm. Find it, then trust it.", ""),
                                    ("The storm blinds their monitors. Talk to me while it lasts.", "angry"))),
            call("hiro", "mid", L(("The wind throws them everywhere! Best drop yet!", "smile"),
                                  ("Chaos is a pattern you haven't finished feeling.", "smile"),
                                  ("Stop fighting the wind.", ""),
                                  ("There is no chaos. Only latency.", "hollow"))),
        ],
        "2": [
            call("midas", "start", L(("The lightning keeps lighting up your shield. It's kind of pretty.", "smile"),
                                     ("When storms came at home, Mom told stories until they passed.", "sad")),
                 dead={"pilot": "hiro", "lines": L(("Storm's loud enough. Nobody needs to fill the quiet. ...Right?", ""),
                                                   None,
                                                   ("No one checking in. Good. Less static.", ""),
                                                   ("Silence on channel three. Optimal.", "hollow"))}),
            call("pala", "late", L(("Storm Eye ahead. It's calm in the middle. Don't trust it.", "sad"),
                                   ("Eye of the storm. Stay in it with me.", "smile"),
                                   ("I mapped a way out. When this storm passes, I'll show you.", "angry"))),
        ],
        "3": [
            call("hiro", "start", L(("Cyclarch! Bet it spins faster than you can turn.", "smile"),
                                    ("I dreamed about this fight. I already know how it ends.", "smile"),
                                    ("Stay out of my lane.", ""),
                                    ("The Cyclarch is a rotation. So am I.", "hollow"))),
            call("midas", "late", L(("Hang on! You're almost through the storm!", "smile"),
                                    ("Something's humming in my head. It's fine. Keep going.", "sad")),
                 dead={"pilot": "pala", "lines": L(("Midas always cheered right about here. So, for him: go!", "smile"),
                                                   None,
                                                   ("I won't let them erase him like the others.", "angry"))}),
        ],
    },
    "viscera_nova": {
        "1": [
            call("hiro", "start", L(("It's alive! The whole planet's alive! Can you feel it looking?", "smile"),
                                    ("It reacts to us. Like it wants to be faster too.", "smile"),
                                    ("It's alive. Doesn't matter.", ""),
                                    ("Organic interference. It will learn to yield.", "hollow"))),
            call("pala", "mid", L(("It flinches when we fire. Is that... pain?", "shock"),
                                  ("It reacts to fear. Ours. Stay calm and it calms.", ""),
                                  ("It feels like the sync room. Something listening back.", "angry"))),
        ],
        "2": [
            call("midas", "start", L(("The ground is breathing. I want to go home.", "sad"),
                                     ("It's like it's dreaming. I hope it's dreaming something nice.", "sad")),
                 dead={"pilot": "hiro", "lines": L(("It keeps pinging Midas' old channel. Creepy.", ""),
                                                   None,
                                                   ("It keeps calling an empty channel. So did I, once.", ""),
                                                   ("It searches for a dead signal. Inefficient.", "hollow"))}),
            call("hiro", "late", L(("Pulse Node! Hit it between beats!", "smile"),
                                   ("Feel its heartbeat. Get inside it.", "smile"),
                                   ("Between beats. Now.", ""),
                                   ("Synchronizing with the node.", "hollow"))),
        ],
        "3": [
            call("pala", "start", L(("The Heart is at the center. Whatever it wants, don't let it in.", "sad"),
                                    ("Honestly? I'm scared. I'm glad it's you beside me.", "sad"),
                                    ("They sent us here to see how far sync can go. Don't give them that.", "angry"))),
            call("midas", "late", L(("You can do this! I believe in you. Really!", "smile"),
                                    ("It sounds like a heartbeat... it sounds like mine.", "shock")),
                 dead={"pilot": "pala", "lines": L(("Midas said it sounded like a heartbeat. I didn't listen enough.", "sad"),
                                                   None,
                                                   ("Midas heard it first. Then they took him off the roster.", "angry"))}),
        ],
    },
    "umbra_vacua": {
        "1": [
            call("hiro", "start", L(("Umbra! I found this route myself. Don't embarrass me.", "smile"),
                                    ("No noise out here. Just us and the link. This is where I belong.", "smile"),
                                    ("Quiet. Finally.", ""),
                                    ("The void and I agree.", "hollow"))),
            call("pala", "mid", L(("Don't fire at shadows. Out here, panic is what gets you hit.", "sad"),
                                  ("Slow down. The void punishes rushing. So do I.", "smile"),
                                  ("Hiro found this route on his own? Command knew. They wanted him to.", "angry"))),
        ],
        "2": [
            call("midas", "start", L(("It's so dark. I can't see the stars from here.", "sad"),
                                     ("There were so many stars at home. I can't find any of them.", "sad")),
                 dead={"pilot": "hiro", "lines": L(("Midas hated the dark. He'd have hated this.", ""),
                                                   None,
                                                   ("Midas would have hated the dark. I don't, anymore.", ""),
                                                   ("Darkness. Absence. Equivalent.", "hollow"))}),
            call("pala", "late", L(("Void Sentinel ahead. Commit to a turn, then hold it.", "sad"),
                                   ("Pick a side and keep it. I'll watch the other.", "smile"),
                                   ("Whatever's watching out here, it isn't the only one.", "angry"))),
        ],
        "3": [
            call("hiro", "start", L(("Something huge is watching us. Let's give it a show!", "smile"),
                                    ("It sees every turn before you make it. So do I, now.", "smile"),
                                    ("Don't look away from it.", ""),
                                    ("It observes. I am observed. We are the same.", "hollow"))),
            call("midas", "late", L(("Don't look back! Don't look back at it!", "shock"),
                                    ("It's looking at me. Why is it looking at me?", "shock")),
                 dead={"pilot": "pala", "lines": L(("If Midas were here he'd tell you not to look back. So don't.", "sad"),
                                                   None,
                                                   ("He was watched like this too, wasn't he? Right to the end.", "angry"))}),
        ],
    },
    "mechanon_ascens": {
        "1": [
            call("pala", "start", L(("A machine world. Everything here runs on a schedule.", "sad"),
                                    ("Machines don't hesitate. That's why you can beat them. Break the rhythm.", ""),
                                    ("Helion built this place. Look at the patterns. They're ours.", "angry"))),
            call("hiro", "mid", L(("Perfect timing, perfect lanes. Finally a fair fight!", "smile"),
                                  ("Everything here is synchronized. It's beautiful.", "smile"),
                                  ("This is what we're meant to be.", ""),
                                  ("Perfection recognized. Joining rhythm.", "hollow"))),
        ],
        "2": [
            call("midas", "start", L(("Everything moves in perfect lines. It's making me dizzy.", "sad"),
                                     ("It's so clean here. Nothing like a kitchen at all.", "sad")),
                 dead={"pilot": "pala", "lines": L(("This was Midas' last route. Let's not lose what he protected.", "sad"),
                                                   None,
                                                   ("Midas' final sync rate matches the missing pilots'. Exactly.", "angry"))}),
            call("hiro", "late", L(("Mirror twins! Two of them, two of us. Fair.", "smile"),
                                   ("They copy you. Be faster than your copy.", "smile"),
                                   ("Mirrors. Beneath us.", ""),
                                   ("Twin signal. Single mind.", "hollow"))),
        ],
        "3": [
            call("pala", "start", L(("The Paragon is a Protektor with no pilot. Or... with something else.", "shock"),
                                    ("That machine is what they want us to become. Don't let it be you.", "sad"),
                                    ("That's the end of the sync program. A pilot with nothing left. Fight it.", "angry"))),
            call("hiro", "late", L(("A Protektor with no pilot? Nothing beats a real one. Prove it!", "smile"),
                                   ("Paragon. Perfect sync. ...I want to know how it feels.", "smile"),
                                   ("It's what I'm becoming. It's beautiful.", ""),
                                   ("It's calling me. I hear it.", "hollow"))),
        ],
    },
}


def main() -> None:
    out = os.path.join(ROOT, "data", "pilot_comms.json")
    with open(out, "w") as f:
        json.dump(COMMS, f, indent=1)
        f.write("\n")
    n = sum(len(lv) for p in COMMS.values() for lv in p.values())
    print("wrote %s: %d calls" % (out, n))


if __name__ == "__main__":
    main()
