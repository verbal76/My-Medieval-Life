# Owner directive, 2026-10-23: game music and volume sliders

Verbatim:

> I added three releases all are songs all are long songs. We need to add them in as game music and we will need a volume slider in settings for music and sfx I will add those too

The three releases on the repository (tags `Songsmall`, `Songmed`, `Songbig`, published 2026-10-20):
- `Prosperous.Village.wav`, 39,105,040 bytes;
- `Sunrise.over.the.Village.wav`, 47,975,440 bytes;
- `misted.ancient.wav`, 86,337,040 bytes.

## Owner's answers to the clarifying questions (2026-10-23, verbatim choices)

- When should each song play? **"By time of day"**: the title screen and morning, Sunrise over the Village; daytime,
  Prosperous Village; evening and night (and caves), Misted Ancient; each fades into the next, with a short quiet gap
  between plays.
- Build: **"Yes, Build 18"**, before the candidate packages.
- Credits: **"They were made in suno"**.
- Format: **"Ogg for Android only"** (clarified from "Off for Android only"): Android carries compressed Ogg Vorbis;
  Windows and Linux ship the original WAVs.

## Sound effects (2026-10-23)

The owner supplied Cozy RPG SFX ambience loops (itch.io, aquumgifts.itch.io; author Spaceyyy; the pack's LICENSE.txt says
"Cozy RPG SFX by Bramble & Byte"): `cozy-rpg-sfx-ambience-1.zip` (dungeon drips, campfire) and
`cozy-rpg-sfx-ambience-2.zip` (cave wind, forest birds; sent twice, byte-identical). Terms: use in games allowed, no
royalties; the sounds themselves may not be redistributed as assets; credit appreciated ("Cozy RPG SFX by Spaceyyy").
Kept in `private-assets/` (git-ignored); only the imported game files are committed (CLAUDE.md section 3).

Owner, 2026-10-23 (verbatim): "Wav for Linux and exe unless ogg has no quality loss". Ogg Vorbis is lossy, so Windows
and Linux ship the original WAVs, as planned; Android carries Ogg.

The owner then sent the full set (2026-10-23, "This is supposed to be the three files"): `cozy-rpg-sfx-ambience-1.zip`,
`cozy-rpg-sfx-ambience-2.zip` (as before) and `cozy-rpg-sfx.zip` (48 sound effects: combat, magic, items, world,
jingles; sha256 8a17adcd…), all kept in `private-assets/`.
