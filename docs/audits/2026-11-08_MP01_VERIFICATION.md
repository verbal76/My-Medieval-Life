# MP-01 — guest-owned pitches count as open for host customers and credit guest XP

**Audited original source:** `fe7d8f88bf5df77ce7e6ea601d6abc62eed13122` (2026-11-08). Branch `audit/mp01-guest-stall-attendance-20261108`.

## Evidence
- First original game run [#42507064870](https://github.com/verbal76/My-Medieval-Life/actions/runs/42507064870): **8 checks, 3 failures**; host's business.attended and seller-distance checks ignored a present guest seller.
- Extended original-code test [#42507246263](https://github.com/verbal76/My-Medieval-Life/actions/runs/42507246263): **11 checks, 4 failures**; also proves a real host-processed NPC purchase credited no trading XP to the guest seller.
- Fix SHA `6f612787e233b919b7ffda75f277c63fd3ef1487`: centralized actual owner identification for guest/host pitch and shop, attendance checks reference the owner and own premises, and the trading XP earned on a directly attended NPC sale credits the selling player rather than the host.
- GREEN run [#42507374909](https://github.com/verbal76/My-Medieval-Life/actions/runs/42507374909): **11 checks, 0 failures** on the fix commit. Tests guest pitch renting/stocking, host attendance detection, actual NPC sale/XP attribution and the reverse case (host nearby but guest absent).

Regression `game/tests/mp01_guest_stall_attendance_test.gd`; `.github/workflows/tests.yml` registration; minimum 11 checks. One runner per focused run; temporary workflow removed from final PR.

**Limitations:** focused test covers a guest rental pitch, not a full remote host+guest session, guest shop, or UI signal delivery. No simulation baseline change. **DRAFT PR, NOT MERGED/CLOSED**; verify existing business, multiplayer, controller/remote and simulation gates on exact integration SHA before closing.
