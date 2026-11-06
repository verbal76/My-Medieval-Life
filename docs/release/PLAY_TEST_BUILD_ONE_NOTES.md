# Play Test Build One — release notes (draft, not published)

Prepared for the owner's approval (B25R2-Q2, Q3). Release name exactly "Play Test Build One"; one Windows PC package.
Publishing needs the owner's explicit approval (completion directive 2026-11-06).

---

## Play Test Build One

**My Folklore** (working title; the game is still called My Medieval Life in its files and window) — a PC play test for
Windows, played with a controller.

### What is new since Build 34

- **Travelling by the map no longer gets stuck at rivers.** A journey planned across the region crosses rivers and lakes
  only by their bridges and fords, and never walks you into a riverbank. If the way ahead is blocked, the journey stops
  and tells you; your destination is kept, so you can Resume or Dismiss it.
- **Smoother long journeys.** The countryside ahead is prepared a little at a time as you walk, so long trips no longer
  stutter.
- **Resume and Dismiss with the controller.** When a journey is stopped and nothing nearby is waiting to be chosen, press Right or Left on the D-pad to reach the
  travel bar's buttons, A to choose, B to go back to play.
- **The whole game by controller.** Every window can be worked with the pad: the triggers step through a window's
  controls and the one in use is outlined. On the Region map, the View button reaches the map's own buttons; View
  again goes back to the map cursor, where A travels.
- **Bridges where they belong.** Roads now go round water where there is land to go round on, and cross it with a
  straight bridge where they must. No more roads that run out over a lake and back to the same shore.
- **Fixes:** saved games load back exactly as they were saved; a rare error in long games (a manor hand with no house) is
  gone; the Skills window no longer reports missing pictures.

### Saves

- Worlds started in Build 34 keep loading, drawn exactly as before. New worlds get the improved roads.

### Known

- Eight newer skills (carpentry, farming, healing, hunting, husbandry, law, masonry, tanning) have no picture in the
  Skills window yet.
- A short pause can still happen when a game starts and once a day at 5 pm in the game, while the village does its
  daily business.

### Download

`MyMedievalLife-B34-Windows.zip` (Windows 10 or 11, 64-bit). Unzip anywhere and run the game. A controller is
recommended; keyboard and mouse also work.

---

Internal: Build 25 Revision 2 (B25R2), code `832f711` (package from `7c1bac4`, which adds only the decision log), build
number 34 as directed. Evidence: `docs/release/B25R2_COMPLETION_CHECKLIST.md`.
