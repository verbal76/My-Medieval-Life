# Building My Medieval Life

All three platforms are built by `.github/workflows/release.yml`, started by hand on an approved
commit (never on a push; CLAUDE.md section 5). One run builds Linux, Windows and Android from the
same commit with the same build number (the run number) and publishes them together as a GitHub
Release (a pre-release unless built from `main`), with `SHA256SUMS.txt` and release notes that name
the commit and include `docs/release/TESTING_CHECKLIST.md`.

## Build dependencies

| Dependency | Version | What for | Where it comes from |
|---|---|---|---|
| Godot | 4.7.2 stable, with its export templates | the game and all three exports | godotengine/godot GitHub release (installed by the workflow) |
| Java (Temurin) | 17 | Android export | `actions/setup-java` |
| Android SDK | the runner's preinstalled SDK | Android export | GitHub's ubuntu runner |
| Android release key | the owner's permanent keystore in the secrets `ANDROID_RELEASE_KEYSTORE_BASE64`, `ANDROID_RELEASE_KEYSTORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD` (no fallback key: a missing secret stops the build) | signing the APK with `apksigner` so builds from Build 21 update each other (`ANDROID_SIGNING.md`) | the owner (secrets) |
| Python | 3.12 | the Windows icon check | `actions/setup-python` |
| Pillow | 10.4.0 | the Windows icon check (decodes the icon images) | PyPI |

**The Windows icon needs no extra tool.** Godot 4.7 writes the icon into the `.exe` itself when the
Windows preset has `application/modify_resources=true` and `application/icon` set; it no longer needs
rcedit or Wine. The icon is `game/assets/icon/icon.ico` (16 to 256 px), made by
`tools/import_game_assets.py` from the owner's `My_Medieval_Life_Icon_Pack.zip`.

**Every Windows build is checked:** `tools/check_exe_icon.py` reads the icon resources out of the
exported `.exe` and compares each image, pixel by pixel, with the approved artwork; the build fails
on a mismatch (Godot's default icon differs by about 80 out of 255 per channel; the right icon by 0).

## Building locally (no release)

    cd game
    godot --headless --path . --import
    godot --headless --path . --export-release "Linux" ../out/pc/linux/MyMedievalLife.x86_64
    godot --headless --path . --export-release "Windows Desktop" ../out/pc/windows/MyMedievalLife.exe
    python3 ../tools/check_exe_icon.py ../out/pc/windows/MyMedievalLife.exe
    godot --headless --path . --export-debug "Android" ../out/mymedievallife-dev.apk   # needs the Android SDK and a keystore in the editor settings
