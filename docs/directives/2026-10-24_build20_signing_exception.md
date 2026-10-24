# MY MEDIEVAL LIFE — BUILD 20 SIGNING EXCEPTION

Owner directive, 2026-10-24, verbatim.

I am authorizing a one-time exception to the permanent Android signing policy for Build 20.
Use the existing disposable Android signing method that successfully produced Builds 1–19.
Do not require permanent signing secrets for this build. Do not ask me to generate keys, configure GitHub secrets, or perform any signing setup tonight.
This exception applies ONLY to Build 20. Preserve the permanent signing policy for subsequent builds. We will configure the permanent identity through Hot Attic Games Build & Signing Manager later.
Proceed with the existing three-platform build pipeline:

1. Android APK, signed with a disposable key.
2. Windows ZIP.
3. Linux ZIP.

All three must come from the same verified commit and carry the same build number.
Complete the required tests and existing release checks. Do not bypass gameplay, integrity, or platform validation.
If signing is the only remaining blocker, resolve it using this exception and push Build 20 as a private draft release.
If other blockers remain, identify them clearly and resolve them without requiring unnecessary owner decisions.
Do not publish publicly.
Do not wait for me to playtest before continuing the approved development schedule.
Get the three-platform Build 20 out tonight if it is otherwise ready. Permanent signing can wait until tomorrow.
