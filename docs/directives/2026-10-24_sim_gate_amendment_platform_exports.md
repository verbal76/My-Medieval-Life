Owner directive, 2026-10-24, verbatim (amendment to SIM-GATE-01).

SIM-GATE-01 — OWNER AMENDMENT: PLATFORM-SPECIFIC FLIGHT RECORDER EXPORTS
This amendment is permanent and supersedes any earlier requirement to attach Excel workbooks to every My Medieval Life release.
Automated pre-build simulation:

* Continue running mandatory simulations and analyzing recorder data before every build.
* Generate and retain internal analysis workbooks as CI artifacts.
* Use the findings to identify and correct defects before packaging.
* Do not require the owner to download or review these workbooks for every build.
* Provide a concise simulation result summary with each build.

Windows and Linux gameplay:

* Support optional live gameplay recording through the existing flight recorder.
* Allow the player/developer to export recorded gameplay data directly to the local computer.
* Support XLSX analysis exports with meaningful charts and event records.
* Recording must remain disabled by default.
* Use bounded memory and incremental disk writes.
* Preserve determinism and simulation performance.

Android gameplay:

* Do not include Excel generation libraries or workbook export functionality in the APK.
* Do not include unnecessary desktop recording/export dependencies.
* Keep Android memory usage and APK size protected.
* Retain only lightweight instrumentation necessary for gameplay correctness and debugging.
* Do not compromise Android gameplay to accommodate desktop reporting.

Architecture:

* Maintain one consistent simulation event schema.
* Keep simulation logic separate from recorder storage and spreadsheet generation.
* Use platform-specific recording/export implementations where necessary.
* Do not duplicate simulation systems.
* Do not allow recorder activity to change gameplay decisions or RNG.

Release requirements:

* All three platforms remain subject to the permanent automated pre-build quality gate.
* Excel files are generated internally by CI.
* Live gameplay XLSX exports are supported only on Windows and Linux.
* No routine owner-facing workbook attachment is required for private releases.

Register this as an amendment to `SIM-GATE-01`, preserve the existing implementation branch, and continue the ongoing work without restarting completed tasks.
