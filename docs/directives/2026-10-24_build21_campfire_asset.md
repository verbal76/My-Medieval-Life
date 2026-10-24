Owner directive, 2026-10-24, verbatim.

The release name campfire is in there that has the full Sprite sheet 

Build 21 — Owner-approved campfire asset implementation

I am attaching the animated campfire sprite sheet and screenshots of its original itch.io listing and licensing information.

This is my final asset selection for the game's campfire. Use this exact artwork. Do not search for, generate, substitute, or compare alternative campfire sprites.

Asset: Animated Pixel Campfire (FREE)
Creator: SMStudios
Source: https://simon-develop.itch.io/
License: Creative Commons Attribution 4.0 International (CC BY 4.0)

Implementation

1. Import the supplied original sprite sheet into the existing Godot asset pipeline. Do not use the screenshots as the production artwork.

2. Inspect the sheet to establish the correct frame dimensions, frame count, spacing, transparency, and animation timing. Do not assume these values.

3. Create a properly looping animated campfire using the original sprite frames. Preserve the original pixel-art appearance, colors, proportions, and ember animation.

4. Use nearest-neighbor filtering and appropriate integer scaling where practical. Do not introduce smoothing, blurry textures, stretched frames, or unnecessary interpolation.

5. Position the campfire naturally on the ground within the bandit camp. Anchor the base of the logs to the ground, with flames rising above them. Correct the draw order so characters can move in front of or behind it naturally.

6. Size it consistently with the game's existing characters, buildings, and isometric environment. Do not distort the artwork to force a perspective change.

7. Replace the incorrect market-stall-like placeholder artwork currently appearing in the bandit camp. The camp should visibly read as a bandit campsite.

8. Use the existing rendering and animation systems. Do not create a new rendering architecture or unrelated visual-effects system.

9. Ensure the animation works on both Windows and Android without unnecessary per-frame allocations or performance overhead.

10. Verify that the animation plays, loops, remains grounded, and renders correctly. Use focused checks rather than a comprehensive test campaign.

Attribution and creator recognition

The owner explicitly approves CC BY 4.0 assets.

Add SMStudios to the game's existing credits system and asset attribution register.

Include:

- Creator: SMStudios
- Asset: Animated Pixel Campfire
- Original asset-page link, taken from the supplied listing
- License: CC BY 4.0
- Link: https://creativecommons.org/licenses/by/4.0/
- An indication of modifications if the artwork is changed

Retain any additional attribution notices provided with the downloaded asset.

Where supported, make the creator's name or portfolio link clickable in the credits.

Hot Attic Games' policy is to publicly recognize creators who contribute to our projects, even when attribution is not legally required.

Scope and execution

This asset is approved for Build 21 and supersedes previous instructions to search for a suitable campfire.

Continue the existing Build 21 implementation. Do not restart, interrupt the active agent, or expand this into an asset-selection exercise.

If the supplied sprite sheet cannot be read or imported, report the specific technical problem rather than substituting another asset.

Implement the campfire and continue with the remaining approved Build 21 work.
