#!/usr/bin/env python3
"""Builds data/npc_talk.json: what the people you can walk up to say.

    python3 tools/build_npc_talk.py

Shape: key ("<place>.<who>") -> {"speaker": cast id or "" (narrator, the line
quoted), "groups": [{"when": [conditions], "lines": [[text, mood], ...]}]}.
Every group whose conditions all hold contributes its lines, in order, and
each talk moves one line on (NpcTalk); once they're used up the last few
lines cycle, and the same line never plays twice in a row.

Conditions (NpcTalk._holds): evening, block7, bracelet, letter:<doubt|resolve|
silent>, midas_dead, midas_alive, pala_gone, hiro>=N, pala>=N, midas>=N,
done>=N, done<N, won, lost, sync>=N, home>=N, pong>=N.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def g(when, *lines):
    return {"when": list(when), "lines": [list(l) for l in lines]}


TALK = {
    # ---- home, the evening before -------------------------------------
    "home.mother": {"speaker": "mother", "groups": [
        g([], ("Did you eat? You should eat something.", "tired"),
          ("...I keep reading it. As if the words will change if I look long enough.", "tired")),
        g(["letter:resolve"], ("You said you could do it. You always said that. Even about the slide.", "smile")),
        g(["letter:doubt"], ("You asked if you had to go. I've been asking myself the same thing all evening.", "sad")),
        g(["block7"], ("You went outside? Did Mrs. Okafor say something? ...She always says something.", "smile")),
        g(["bracelet"], ("Is that from Juno? Keep it on. Don't let them take it off you.", "smile")),
        g([], ("I ironed your shirt three times. It didn't need it. I needed it.", "sad"),
          ("When you were small you were afraid of the dark. Tonight I think it's my turn.", "sad")),
    ]},
    "home.father": {"speaker": "father", "groups": [
        g([], ("The shield's breathing slower tonight. They say that's normal.", ""),
          ("Get some sleep. I'll check the heater.", "")),
        g(["letter:silent"], ("You didn't say much at the table. Neither did I. We're alike that way.", "sad")),
        g(["block7"], ("Benno gave your mother the good tea for free. The whole block knows, then.", "")),
        g([], ("I fixed that heater the week you were born. It still stutters. Some things just stay the way they are.", ""),
          ("They'll give you a uniform. Don't let it give you a new name.", "stern")),
    ]},
    # ---- the parade ----------------------------------------------------
    "parade.hiro": {"speaker": "hiro", "groups": [g([],
        ("Look at those things. Bet they hit harder than anything on this planet.", "still_smiling"),
        ("I'm going to be the best pilot this intake has ever had. Watch.", "smile"),
        ("Nervous? I'm not nervous. I'm ready. It feels the same, that's all.", "smile"))]},
    "parade.pala": {"speaker": "pala", "groups": [g([],
        ("Their joints don't flex like armor. They flex like... something grown.", "anxious"),
        ("Have you noticed none of them has a face?", "anxious"),
        ("My brother says the parade's the last time they let you choose where to look.", ""))]},
    "parade.midas": {"speaker": "midas", "groups": [g([],
        ("My mom's out there somewhere. I can't find her face.", "uneasy"),
        ("I'm Midas. Sorry. I talk when I'm scared. I'm talking a lot.", "sad"),
        ("If they ask you later, tell them I was brave, okay?", "sad"))]},
    "parade.announcer": {"speaker": "announcer", "groups": [g([],
        ("Recruits will hold formation until called!", ""),
        ("Smile for the families, recruits! This is the proudest day of their lives!", ""),
        ("...Please step back into the line.", ""))]},
    "parade.mother": {"speaker": "mother", "groups": [g([],
        ("We're right here. We'll stay right here.", "sad"),
        ("Go on. Stand with them. We can see you from here.", "smile"))]},
    "parade.father": {"speaker": "father", "groups": [g([],
        ("Stand up straight. Not for them. For you.", ""),
        ("Whatever they call you up there, you know your name.", "stern"))]},
    "parade.crowd": {"speaker": "", "groups": [g([],
        ("We're so proud of you!", ""), ("Helion keeps us safe!", ""), ("Wave! Wave to us!", ""),
        ("My boy went up last spring. He writes every month. Well. The letters come every month.", ""),
        ("Look at the machines! Aren't they beautiful?", ""), ("Which one's yours, sweetheart? Oh, you don't get to pick?", ""),
        ("Don't cry. They're watching the cameras.", ""), ("A hero in the family! Full rations for life!", ""))]},
    "parade.rec": {"speaker": "", "groups": [g([],
        ("Don't step out of line. They're watching.", ""), ("My uniform's too big too.", ""),
        ("I heard you get your own Protektor.", ""), ("My mom told me to be brave. I said okay. I don't know how.", ""),
        ("...", ""), ("Do you think they'll let us write home?", ""))]},
    # ---- the academy corridor ------------------------------------------
    "corridor.instructor": {"speaker": "instructor", "groups": [g([],
        ("Proceed to your pod, recruit. Do not delay.", ""),
        ("Hesitation is a habit. Habits can be removed.", ""),
        ("Your pod is calibrated to you. It already knows your name.", ""))]},
    "corridor.hiro": {"speaker": "hiro", "groups": [g([],
        ("Hurry up! I want to know what mine sounds like.", "still_smiling"),
        ("Race you to the pods. Loser has to... I don't know. Lose.", "smile"))]},
    "corridor.pala": {"speaker": "pala", "groups": [g([],
        ("Group of four. Four pods. And no one asked us which one we wanted.", "anxious"),
        ("Count the doors. There are more pods than recruits.", "anxious"))]},
    "corridor.midas": {"speaker": "midas", "groups": [g([],
        ("If I close my eyes, it's almost like the lift at home.", "uneasy"),
        ("Do you think it hurts? Don't answer. Actually, answer.", "sad"))]},
    "corridor.rec": {"speaker": "", "groups": [g([],
        ("Keep moving. They're timing us.", ""), ("Which pod's yours? Mine has a scratch on the glass.", ""),
        ("Somebody said the pods are warm. Why are they warm?", ""))]},
    # ---- the Commons: five recruits and the bot -------------------------
    "commons.nell": {"speaker": "nell", "groups": [
        g(["done<3"], ("I counted the chairs at dinner. Thirty-one. Yesterday there were thirty-two.", "worried"),
          ("I count things when I'm nervous. Stairs. Chairs. Us.", "")),
        g(["done>=3"], ("Twenty-six chairs tonight. I've stopped telling anyone the number.", "sad"),
          ("Nobody's chair has a name on it. That's on purpose, isn't it?", "worried")),
        g(["midas_dead"], ("They take the empty chair away before dinner now. So the gap doesn't show.", "sad")),
        g(["done>=6"], ("I don't count anymore. It's easier. Is that bad? It feels bad.", "flat")),
    ]},
    "commons.dov": {"speaker": "dov", "groups": [
        g([], ("You play ping-pong? Rec room, through the wing. I'll go easy on you.", "smile"),
          ("I had a table at home. Well. A door on two crates. Same thing.", "smile")),
        g(["pong>=10"], ("You're the one with the rally! The whole wing's talking about it.", "smile")),
        g(["won"], ("Clean deployment? You're grinning. Don't let them see you grin.", "smile")),
        g(["done>=5"], ("I don't really want to play anymore. My hands keep turning to block.", "flat")),
    ]},
    "commons.sefa": {"speaker": "sefa", "groups": [
        g([], ("I don't remember my sister's voice anymore. I mean, I do. I just can't hear it.", "sad"),
          ("Do you write letters? I write them and keep them. It's cheaper than sending.", "")),
        g(["home>=1"], ("You called home? What did it sound like? ...No. Don't tell me.", "sad")),
        g(["sync>=55"], ("I dreamed about home last night and it was all planets. Just planets.", "flat")),
        g(["done>=4"], ("They asked if I wanted my letters forwarded to my new posting. I'm not going anywhere. Am I?", "worried")),
    ]},
    "commons.kit": {"speaker": "kit", "groups": [
        g([], ("Did you see the leaderboard? Nobody's beaten Hiro's turn speed.", "smile"),
          ("I'm eleventh. Eleventh's fine. Eleventh's basically tenth.", "smile")),
        g(["lost"], ("Rough one? It happens. They write it down, though. Everything gets written down.", "")),
        g(["won"], ("Nice deployment. You're climbing the board.", "smile")),
        g(["hiro>=3"], ("Hiro doesn't even look at the board anymore. He's just... what the board measures.", "flat")),
    ]},
    "commons.bram": {"speaker": "bram", "groups": [
        g([], ("Why did the Protektor cross the galaxy? Because it was told to. ...That's the whole joke.", "smile"),
          ("Knock knock. Who's there? Synchronization. Synchronization wh- Synchronization.", "smile")),
        g(["midas_dead"], ("Midas laughed at all my jokes. Even the bad ones. Especially the bad ones.", "sad")),
        g(["done>=4"], ("I ran out of jokes. I'm recycling. Why did the Protektor cross the galaxy?", "flat")),
    ]},
    "commons.bot": {"speaker": "", "groups": [
        g([], ("A maintenance unit polishes the same panel of floor. It has been polishing it since you arrived.", ""),
          ("The unit stops, turns its sensor toward you, considers you, and resumes polishing.", "")),
        g(["done>=3"], ("Someone has taped a paper smile to the maintenance unit.", "")),
        g(["done>=6"], ("The maintenance unit has a name now, on a strip of tape: PROTEKTOR. Someone thought that was funny.", "")),
    ]},
    # ---- the escape ------------------------------------------------------
    "launch_wing.pala": {"speaker": "pala", "groups": [g([],
        ("Not now. Keep moving.", "anxious"), ("Stay low. The cameras pan every eight seconds.", ""),
        ("If anyone asks, we're inventory.", "smile"))]},
}


def main() -> None:
    out = os.path.join(ROOT, "data", "npc_talk.json")
    with open(out, "w") as f:
        json.dump(TALK, f, indent=1)
        f.write("\n")
    print("wrote %s: %d people" % (out, len(TALK)))


if __name__ == "__main__":
    main()
