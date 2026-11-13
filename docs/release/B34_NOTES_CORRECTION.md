# Build 34 release notes correction (ND-22, owner decision 2026-11-12)

The lead's edit of release `build-34` was refused by the session (HTTP 403: "Creating, editing, or deleting releases is not permitted for this session type"); not bypassed. To apply: on GitHub, Releases, build-34, Edit, replace the Linux line with the one below and save.

**Replace:**

```
- Linux: `MyMedievalLife-B34-Linux.zip`.
```

**With:**

```
- Linux (full game): **not included in this release.** The full-game Linux package failed to build (one test failed in its build job, run 42144510422), so no `MyMedievalLife-B34-Linux.zip` is attached. Linux players: use a newer verified build instead, Build 39 (`b3c9eb5`, 2026-11-12; its Linux package starts and quits cleanly), available privately from the developer. The Linux demo below is unaffected. (Correction made 2026-11-12, owner decision ND-22.)
- Android: `MyMedievalLife-B34-Android.apk`, signed with the permanent release key ... (the rest of the original line unchanged)
```

The full corrected body is `docs/release/B34_NOTES_CORRECTED_BODY.md`.
