Owner directive, 2026-10-24, verbatim (sent with the archive craftpix-net-218281-free-pixel-art-dungeon-objects-asset-pack.zip and licence screenshots; the owner asked to hold before acting).

MY MEDIEVAL LIFE — BUILD 21: CRAFTPIX MARKET STALL IMPLEMENTATION

Owner directive

I am attaching the original Craftpix Free Pixel Art Dungeon Objects Asset Pack ZIP and screenshots of its licensing terms.

This is an approved addition to the existing Build 21 work. Do not restart completed work, create a separate development campaign, or substitute different market stall artwork.

1. Exact sprite identification

Use the original archive:

"craftpix-net-218281-free-pixel-art-dungeon-objects-asset-pack.zip"

Inside it, locate:

"PNG/supplies_objects.png"

The source sheet is 208 × 592 pixels.

The two approved market stall sprites are:

- Sprite A: The completely empty wooden shelving unit in the first row, far-left position, at the very top of "supplies_objects.png".
- Sprite B: The completely empty wooden shelving unit in the second row, far-left position, directly below Sprite A.

Both are brown wooden shelves with two horizontal display levels. The other shelves in those rows already contain goods. Do not confuse those stocked versions with the two empty units.

Use the two empty units as the standard market stall furniture. Do not use the awning-style market stalls from the previously discussed itch.io pack.

Inspect the original PNG and PSD source to determine exact sprite boundaries and transparent padding. Record the extraction coordinates in the implementation notes. Do not guess coordinates from screenshots.

2. Licensing verification — mandatory

Read the included "License.txt" and the attached Craftpix licensing screenshots.

The supplied terms indicate:

- Commercial and noncommercial game use is permitted.
- Modifying the graphics for use in the game is permitted.
- Selling a game containing these assets is permitted.
- Reselling or separately redistributing the original or modified artwork is prohibited.
- The license restricts using assets for training, fine-tuning, developing, testing, validating, or improving AI systems.
- Attribution is not required under the shown Craftpix terms, but the owner explicitly wants contributor credits.

Verify the applicable license before implementation. Do not claim these assets are CC0. They are Craftpix-licensed assets, not public-domain artwork.

Normal, authorized game integration should use deterministic sprite extraction, ordinary pixel editing, and engine rendering. Do not submit these assets to image-generation services, use them as AI training data, or create generative-AI derivatives. If the license creates a genuine uncertainty about the proposed workflow, identify the exact restriction and ask before proceeding.

Do not redistribute the standalone asset pack as a separate downloadable product.

Add an appropriate credit in the game's existing credits system:

Craftpix.net — Free Pixel Art Dungeon Objects Asset Pack — Market stall and environmental artwork

Include the source website or asset-pack page if the existing credits system supports links.

3. Market stall appearance

Replace the current market stall presentation with these wooden shelving units.

Requirements:

- Preserve the original pixel-art identity, palette, outlines, and pixel sharpness.
- Use nearest-neighbor rendering. No smoothing, blurry scaling, or AI-generated restyling.
- Make the shelves modular so they can accommodate ten distinct merchandise displays without items hanging in midair.
- Extend the middle shelf sections using appropriate pixel-art construction rather than horizontally stretching the entire sprite.
- Maintain believable support posts, shelves, and dimensions.
- Verify the result in the actual isometric game camera.
- Ensure players can approach and interact with the stalls normally.
- Do not introduce collision, pathfinding, or building-placement regressions.

4. Ten visible merchandise listings

A market stall must support and visibly represent ten different product listings.

This is not a request to draw every physical unit of inventory.

For example, 70 wheat offered for sale may appear as one appropriate wheat display. Ten different listed goods should be represented by ten distinguishable displays.

Use appropriate existing item artwork and compatible props from the Craftpix pack where useful.

Arrange the goods naturally across both shelves. No floating merchandise, clipping, or items extending beyond the usable furniture.

If the inventory contains fewer than ten listings, display only those listings. If the inventory changes, update the visible goods.

Preserve existing inventory quantities, prices, ownership, trading, and economy rules.

5. Player and NPC market stalls

This feature must apply to every market stall, not only the player's.

NPC-owned stalls currently fail to show what their merchants are selling until the player opens the interaction interface.

Correct that.

- Player stalls show the player's actual listed merchandise.
- NPC stalls show each NPC merchant's actual listed merchandise.
- Empty stalls appear empty.
- Goods are removed or changed visually when listings change.
- Displays must be based on actual market inventory, not random decorative merchandise.
- The existing interaction interface remains available for exact prices, quantities, buying, and selling.

The objective is to make the market visibly alive. A player should be able to walk through the market and get a useful impression of what merchants offer without opening every stall.

6. Multiplayer compatibility

This must work with Build 21 multiplayer.

- Stall ownership and merchandise listings remain authoritative game data.
- Clients render the same listings from synchronized state.
- Visual displays do not create additional inventory or duplicate goods.
- Joining players see existing merchandise.
- Updates to listings are reflected for connected players.

Reuse the existing multiplayer architecture. Do not create a separate synchronization system just for shelf decorations.

7. Additional Craftpix objects

The pack contains other potentially useful objects, including stocked shelves, barrels, sacks, crates, and weapon displays.

You may use appropriate objects where they directly support the approved Build 21 work.

Do not begin a broad village-decoration redesign or introduce unrelated dungeon assets.

Record other potentially useful objects as future opportunities without expanding scope.

8. Integration with current Build 21 work

This directive supplements the previously approved Build 21 work, including multiplayer menus, Android network permissions, animal synchronization, gameplay corrections, and the flight-recorder checks.

Coordinate with the existing agent. Do not have two workers simultaneously edit conflicting game files.

Preserve the previously approved backlog decisions and follow-up package. Do not silently omit approved items.

Use focused tests to confirm that shelf rendering, inventory representation, interactions, and multiplayer state work. Reuse passing test evidence where applicable. Avoid redundant full simulation campaigns.

9. Completion report

When complete, report:

1. Exact source file and sprite extraction coordinates for both shelves.
2. Applicable license and any unresolved restrictions.
3. How modular shelf expansion works.
4. How ten listings are displayed.
5. Confirmation that both player and NPC stalls use the system.
6. Confirmation that multiplayer clients receive consistent displays.
7. Tests performed and actual results.
8. Remaining blockers, if any.
9. Screenshots from the actual game camera showing an empty stall, a partially stocked stall, and a ten-listing stall.

Do not present isolated sprite renders as proof of in-game appearance.

Do not publish Build 21 without owner approval.

Owner's design intent: The market should visibly reflect the economy. I want to see what people are selling, not just interact with anonymous counters. Use the exact two empty Craftpix shelf sprites identified above and make the merchandise displays a natural part of the village.
