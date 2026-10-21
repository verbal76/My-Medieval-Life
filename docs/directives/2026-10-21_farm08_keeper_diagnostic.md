# Owner directive, 2026-10-21: FARM-08 cattle keeper diagnostic (summary with the owner's words for the rules)

"Approve one focused diagnostic run before making the FARM-08 decision." "Do not change farming yields, prices, animal
behavior, or economic rules yet. Keep both experimental farming switches disabled in the release configuration."

1. One targeted keeper trace on an existing failing seed/configuration ("Prefer a case where the keeper ran out of money
   despite substantial wheat remaining in the village"): starting and ending coins; income from milk, livestock and
   other sales; milk produced, held, sold and unsold; feed purchases (quantities, prices, sellers); failed purchases and
   their reasons; wheat available and whether the keeper could actually buy it; other expenses or transfers; herd size,
   breeding animals, culling, starvation and deaths. "Identify the point where the keeper becomes unable to sustain the
   herd." "Do not assume that wheat existing somewhere in the village means the keeper can afford or access it."
2. Verify the season calendar ("seasons may change approximately every two simulated days"): intended, an accelerated
   test configuration, a reporting error, or a defect. "Do not change season duration without owner approval."
3. Classify findings as: legitimate economic consequence; economic balance concern; implementation defect; unresolved.
   "Do not automatically classify herd extinction as a bug. Do not automatically dismiss it as acceptable simply because
   conservation checks passed."
4. SIM-01: one representative failing seed, minimum trace, stop once the mechanism is established; no multi-seed
   campaign; do not disturb Build 17. "No implementation changes are authorized by this directive."
5. Report: seed, configuration, commit; cause of the falling balance; where the money went; why products did or did not
   earn enough; whether feed was physically available, affordable and accessible; the sequence to extinction; the
   seasons; the classification with evidence; the smallest corrective options. Update the FARM-08 record, facts apart
   from hypotheses. "The purpose of this diagnostic is to understand the failure, not to make the village artificially
   successful." "A VILLAGE IS ALLOWED TO FAIL. THE SIMULATION IS NOT."
