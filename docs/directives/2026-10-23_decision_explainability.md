# Owner directive, 2026-10-23: Decision Explainability and Player Understanding (cross-expansion requirement)

Saved verbatim.

---

MY MEDIEVAL LIFE — CROSS-EXPANSION DESIGN REQUIREMENT

Decision Explainability and Player Understanding

Applies to Expansions 19, 20, 21, and future simulation systems.

Add a shared Decision Explainability capability to the architectural planning and requirements registers.

Every significant NPC decision should be capable of producing a lightweight, deterministic explanation record identifying:

- The decision made.
- The principal factors that influenced it.
- Relevant needs, obligations, resources, beliefs, and relationships.
- The information available to the NPC when deciding.
- The selected outcome and meaningful alternatives, where applicable.
- References to relevant simulation events.

Explanations must reflect actual decision inputs and outcomes. Do not generate fabricated justifications after the fact.

Design three presentation layers:

1. In-world: Natural NPC dialogue, rumors, notices, and observable behavior.
2. Player inspection: Optional contextual explanations and historical information limited to what the player's character knows or can discover.
3. Developer diagnostics: Complete decision traces for debugging, testing, calibration, and deterministic replay.

Preserve the distinction between objective world truth, individual NPC beliefs, NPC statements, and player knowledge.

Do not expose secret motivations, private relationships, undiscovered crimes, or hidden information through ordinary player-facing interfaces.

Keep the implementation efficient. Do not permanently store verbose traces for every trivial action. Prioritize consequential decisions and use compact reason codes and references where practical.

During the current development phases:

- Audit existing decision tracing and UI capabilities.
- Identify reusable interfaces across Expansions 19, 20, and 21.
- Include explainability requirements in their capability matrices.
- Identify gaps and recommend a shared architecture.
- Do not build a separate explanation engine for each expansion.
- Do not activate or implement additional features without owner authorization.

Design principle: Complexity should create meaningful player choices, not invisible calculations.
