# Build 40 (Extra Life preview) — Windows hardware playtest checklist

Build 40 = commit `a5a0b7c` (branch `wip/b25-preview`), CI run 43362745451, artifact `pkg-full-windows`. An **incomplete private
preview**, not a Steam release. Allow about 60-90 minutes for the whole list; sections 1-9 are the stream's core (about 30 minutes).

## Before you start

1. Download `pkg-full-windows` from https://github.com/verbal76/My-Medieval-Life/actions/runs/43362745451 (Artifacts; signed in).
2. Unzip it, then unzip `MyMedievalLife-B40-Windows.zip` into its own folder, e.g. `C:\Games\MML-B40`.
3. Open **Task Manager** (Ctrl+Shift+Esc), Details tab, so you can watch `MyMedievalLife.exe`'s memory (section 16).
4. Know where the files are: saves and the game's log are in `%APPDATA%\Godot\app_userdata\My Medieval Life\` (type that into
   Explorer's address bar). The log is `logs\godot.log`: after a problem, copy it (it records script errors).

**Controls (keyboard):** move W A S D or arrows; Shift sprint; E or Enter interact (tap/use what is in front of you); T talk;
Space or J attack; I or Tab pack (inventory); L skills; B journal; M map; G gather mode; Q next target; C recenter view;
+/- zoom; Esc or P pause menu. Mouse: click a person, animal, tree or rock to walk to it and act. A gamepad also works
(not tested on hardware: try it in section 15 if you have one).

## How to mark each step

For every numbered check, write one of three marks:

- **W** — works (it does what it should)
- **B** — believable (it also looks and feels natural: movement, timing, animation)
- **X** — broken or needs improvement (write a short problem report, below)

A step can be **W** without **B** (works but looks wrong). Write **W+B** when both hold.

## The checklist

### 1. Launch and enter a world
1.1 Double-click `MyMedievalLife.exe` (SmartScreen: "More info", "Run anyway"). The title appears within about 20 s. Note the time it took.
1.2 New game: type a first name and a family name, Begin, read the origin story, Begin. You stand in the village, the journal's first
    message says where paid work is.
1.3 Note the frame rate feel (smooth / occasional stutter / choppy) and Task Manager memory (MB) now: ______

### 2. Walking and obstacles
2.1 Walk in all four directions with keys; sprint with Shift. Smooth, no jitter.
2.2 Walk into a house wall, a fence and a tree: you stop at them, you never pass through.
2.3 Click a spot across the village: the character walks round buildings to it.
2.4 Click a villager standing behind a field fence or across water: within about 3 s of standing still you should see
    "You can't reach ... from here." (new in Build 40). Before, you would stand there for ever.

### 3. Talking to villagers
3.1 Walk up to a villager and press T (or click them): a talk window opens.
3.2 Try each line offered (greeting, "Any work for me?", trade, news). Answers make sense; the window closes with Esc or the button.
3.3 Talk to three different villagers (a farmer, a shopkeeper, the reeve at the manor).

### 4. Trees and wood
4.1 Open the pack (I) and wield the axe (Wield).
4.2 Walk to a grown tree and interact (E or click). The felling takes a few seconds with swings; the tree falls; logs go into your pack.
4.3 Try a sapling or a stump: it says why nothing is cut.

### 5. Mining and gathering
5.1 Wield the pickaxe; mine a rock or a seam (E or click). Stone or ore goes into the pack.
5.2 Press G (gather mode) and tap a berry bush or flowers: they go into the pack.

### 6. Tools and the sword
6.1 In the pack, wield in turn the sword, the axe and the pickaxe. The character's held item changes on screen.
6.2 Note: the starting axe and pickaxe wear out after about 20 uses (by design); the smith sells new ones.

### 7-9. Hunting (the most visible stream moment)
Go to the woods outside the village (M for the map). Wield the sword.
7.1 **Deer:** approach and strike (Space). Expected: it flashes red, **turns to face you**, pauses briefly, then **runs away** in a
    zigzag, facing the way it runs. It must not back into you or slide sideways.
7.2 Chase and strike until it falls (a few blows; you are faster than a deer).
7.3 **Boar:** same; it startles and flees (in Build 40 a boar does not charge yet).
7.4 **Bear (careful: it hurts):** strike it. Expected: it turns angry, closes to biting distance and bites about every 3 s; it does not
    stand on top of you. Note how much health you lose: ______
8.1 For each animal, mark: faces you when struck? flees naturally? any bouncing, sliding, jitter, getting stuck in trees?
9.1 Interact with the carcass: meat, hide (and antler, tusk) go into the pack. The carcass disappears.

### 10. Crafting and the pack
10.1 At the sawhorse (carpenter's yard) make planks from logs; at an oven cook meat. A short wait if villagers are using it.
10.2 Open the pack: the new items are there; drop or move one; equipment slots show what you wear.

### 11. The reeve's job board
11.1 Go to the manor and talk to the reeve: "Any work for me?". Before 5 pm the board may be empty: the reeve says to ask again
    in the evening; farmers, miners or woodcutters may have work.
11.2 After 5 pm take a job (carry, quarry, mend), do it, and get paid. Note coins before ______ and after ______.

### 12. Buying, selling, eating, money
12.1 Sell logs or meat at a stall or shop; your coins go up by the price shown.
12.2 Buy food; eat it (pack, Eat). Hunger goes down.
12.3 Coins on screen always match what you paid or received.

### 13-14. Save, quit, restart, continue
13.1 Note: coins ____, a few pack items ____, what you wield ____, the day and time ____, where you stand.
13.2 Pause (Esc), "Save and quit to title". Then close the game window completely.
13.3 Start `MyMedievalLife.exe` again, Continue.
14.1 Everything in 13.1 is the same (coins, pack, equipment, day/time, place, journal, a job in progress).
14.2 Do this twice in the session at most (each Continue keeps some memory, see section 16).

### 15. Sound, look, speed
15.1 Music and sounds play (chopping, mining, blows, footsteps, village); volume settings work.
15.2 Text is readable at your screen size; nothing cut off; full screen / window both work.
15.3 Response: keys and clicks act at once; no input lag.
15.4 If you have a gamepad, walk, attack and open the pack with it.

### 16. Memory, pauses, crashes, errors
16.1 Every 15 minutes write Task Manager's memory for the game: ______ ______ ______ ______. Some growth is known (about +34 MB per
    Continue, and slow growth in play); report it if it passes about 3 GB or the game slows down.
16.2 A pause of up to about 1.5 s right after Continue is known. Report any other freeze longer than 1 s (what you were doing).
16.3 Any crash or error window: note the time, then copy `logs\godot.log` (see "Before you start").

## Reporting a problem (copy this block for each)

```
Build: 40 (a5a0b7c)        Checklist step: e.g. 7.1
What happened:
What I expected:
How to make it happen again (steps):
How often: every time / sometimes / once
Mark: X (broken) or W-not-B (works but looks wrong)
Screenshot or video: (Win+Shift+S for a screenshot; Win+G records video)
Time it happened (for the log):
```

Paste the blocks into a message (or a text file) and send them with `godot.log`. Each report is turned into a tracked defect with its
step and evidence.
