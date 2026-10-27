MY MEDIEVAL LIFE — OWNER GAMEPLAY VISUAL REQUIREMENT

VISIBLE EQUIPPED WEAPONS AND SWORD ATTACK ANIMATIONS

Claude, I want to correct an inconsistency in My Medieval Life's weapon presentation.

When my character uses an axe, pickaxe, or hammer, I can visibly see the tool being used.

However, when attacking with a sword, the actual sword is not visibly represented in the same way.

THIS NEEDS TO BE CORRECTED.

OWNER REQUIREMENTS

1. When a sword is equipped and drawn, the character must visibly hold that sword.

2. During an attack, the actual sword sprite must visibly swing with the character's movement.

3. The animation must correctly account for character facing direction, including appropriate foreground/background layering.

4. The sword must visually remain connected to the character's hand throughout the animation.

5. Sword appearance should correspond to the equipped item wherever the existing equipment and asset systems support distinct weapon types.

6. Combat hit detection and damage timing should correspond to the visible attack animation.

7. Do not replace the sword with a generic slash effect. The player must actually see the weapon being swung. Additional effects are optional, but never a substitute for the visible weapon.

8. The visual presentation should remain consistent with MML's existing pixel-art style.

IMPLEMENTATION APPROACH

First, inspect how the existing axe, pickaxe, and hammer animations render their equipped tools.

Determine why swords do not receive equivalent visual treatment.

Reuse or extend existing equipment-rendering and directional-animation systems wherever practical.

Do not build a separate combat-rendering architecture unnecessarily.

Ensure the correction works for the player and applicable weapon-equipped NPCs.

Preserve existing combat damage, timing, reach, stamina, and gameplay balance unless a verified defect requires correction.

ACCEPTANCE CRITERIA

A character wielding a sword must visibly:

- Hold the sword.
- Move with the equipped sword.
- Swing the sword when attacking.
- Display the correct weapon orientation throughout the attack.
- Return to the appropriate weapon-holding pose afterward.

Verify the relevant facing directions and weapon types.

Provide actual in-game visual evidence, not a disconnected mockup.

Use targeted tests and visual checks rather than another comprehensive audit.

PRIORITY

Add this to the current authorized gameplay-presentation work for Expansion 20.

Do not delay foundational Living Economy implementation to perform a large unrelated combat overhaul.

OWNER DESIGN PRINCIPLE: IF MY CHARACTER IS USING A WEAPON, I WANT TO SEE THE ACTUAL WEAPON BEING USED.
