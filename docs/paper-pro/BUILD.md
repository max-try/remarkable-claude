# Paper Pro build environment

Status as of 2026-11-24 (Stage 1 prepared). Target: reMarkable Paper Pro ("ferrari", 64-bit ARM), software **3.29.1.0**.

## Cloud build

`.github/workflows/paper-pro-build.yml` builds the plugin on GitHub's free Ubuntu runners on every pull request, every push to `main`, and on demand (Actions tab → "Paper Pro build" → "Run workflow").

What it does:

1. Downloads reMarkable's official SDK for 3.29.1.0, ferrari, x86_64 host (409 MB, cached between runs) and checks its SHA-256.
2. Fetches xovi at a pinned commit, for `util/xovigen.py`.
3. Runs `./build.sh ferrari` (the full plugin) and `./build.sh ferrari-stage1` (the Stage 1 test), which also check that the outputs really are 64-bit ARM files.
4. Packages each with `tools/paper-pro/package.sh` into a folder that is copied to the tablet as it is: installer, plugin, notebook patch, fonts, icon, `BUILD-INFO.txt` and a `SHA256SUMS` that `install.sh` checks first.
5. Uploads them as the run's two downloads, kept for 90 days: **`ink-diary-stage1-test`** and **`ink-diary-paper-pro-untested`**.

A second job, `host-tests`, runs `./test.sh` (layout, button position and toolbar hiding in a stand-in notebook screen, rendering, placement maths, settings) and the name-map checker's test.

| Input | Value |
|---|---|
| SDK | `https://storage.googleapis.com/remarkable-codex-toolchain/3.29.1.0/remarkable-production-image-6.0.112-ferrari-public-x86_64-toolchain.sh` |
| SDK SHA-256 | `e517362f102f77e0b140c0ed53a74bea8a3e6fe4048199ea44df7d9af2683ebb` (Google Storage MD5 `y9aKNrbQC0RbOmMGXZbwtQ==` matched) |
| SDK environment file | `environment-setup-cortexa53-crypto-remarkable-linux` |
| xovi | `asivery/xovi` @ `2b99649f5e4fd6288be7792a8570bd16418adb70` |

To move to another software version, change `RM_SOFTWARE`, `SDK_URL` and `SDK_SHA256` in the workflow. The URL list is at https://developer.remarkable.com/links .

**What's installable:** the Stage 1 test build, following [STAGE1.md](STAGE1.md). The full plugin builds and passes the host tests, but stays untested on a tablet until Stage 2.

## What only the tablet can confirm

Everything below is written in the code from the 3.28 Paper Pro port and the Paper Pro's published screen size, and marked `TO CONFIRM` there. The Stage 1 test measures each one (`report.json` plus two screenshots):

| Assumption | Where | How Stage 1 checks it |
|---|---|---|
| Screen and screenshot are 1620 × 2160, window scale 1 | `src/layout.h` | `screenshot1`, `windowSize`, `devicePixelRatio`, `canvas` |
| The patch's names (DocumentView.qml, `FocusScope#root`, `toolbar`, `zoomButton`) exist on 3.29.1.0 | `inkDiary.qmd` | `tools/paper-pro/check-hashtab.py` on the name map; `toolbarFound`, `zoomButtonFound` |
| The button lands at 1524, 1928 (72 × 72), clear of the notebook's own controls | `inkDiary.qmd`, `src/layout.h` masks | `buttonRect`, `buttonParentRect`, screenshot 1 |
| Hiding the toolbar leaves nothing else on screen, and it comes back | `inkDiary.qmd` Bindings | screenshot 2, `toolbarHidden.toolbarVisible`, `after.toolbarVisible` |
| Answers keep the rM2's size: 1174 px wide, centred | `src/layout.h` | Stage 2 (first real answer) |
| The scene-units-per-pixel measurement works, to size answers | `src/inserter.inc` `screenToSceneScale` | `sceneUnitsPerPixel` (the 3.28 port measured about 0.86 on the Move) |
| Native image insertion still exists | `src/inserter.inc` | `nativeImageInsert`, `screenMapping` |

Landscape and zoomed pages are not supported yet: the plugin reads a portrait page at normal zoom.

## Local build

The same SDK runs on any x86_64 Linux machine (an aarch64 host variant is also published):

```sh
sh remarkable-production-image-6.0.112-ferrari-public-x86_64-toolchain.sh -y -d ~/sdk-ferrari-3.29.1.0
git clone https://github.com/asivery/xovi ~/xovi
SDK_ENV=~/sdk-ferrari-3.29.1.0/environment-setup-cortexa53-crypto-remarkable-linux XOVI_REPO=~/xovi ./build.sh ferrari
```

`./build.sh ferrari-stage1` builds the Stage 1 test, and `tools/paper-pro/package.sh <target>` makes the folder for the tablet. The reMarkable 2 target was removed: the port is Paper Pro only.

## Does the plugin loader support 3.29.1.0?

Yes, as far as can be checked without the tablet. The evidence, from the Vellum package index (`vellum-dev/vellum`, `packages/*/VELBUILD`, read 2026-11-24):

- **xovi 0.3.3** ships an aarch64 build and has no software-version limit.
- **xovi-extensions 19.0.1** (qt-resource-rebuilder, xovi-message-broker, framebuffer-spy, qt-command-executor) ships aarch64 and requires only `remarkable-os>=3.20`, no upper limit.
- **rm-shot 1.2.0** (screenshots) ships aarch64 and has no software-version limit.
- About 40 Vellum UI mods that work through qt-resource-rebuilder declare `remarkable-os>=3.29`. Some are Paper Pro family only, for example `hide-dev-mode-icon` (`!rm1 !rm2 ... remarkable-os>=3.29 remarkable-os<3.30`) and `bluetooth-settings`. So the loader and the QML patcher are in use on Paper Pro 3.29.

Not yet proven: that rm-shot captures correctly on a full-size Paper Pro on 3.29 (its README lists the Paper Pro as supported, it worked on the Paper Pro Move, and one person reports it working on the Paper Pro on 3.28). Stage 1 checks it on Gilad's tablet.

Two cautions from the xovi and Vellum scripts, built into the guide: `rebuild_hashtable` leaves the notebook app stopped (start it with `systemctl start xochitl`), and the tablet reboots itself if the notebook app restarts 4 times in 10 minutes, so the guide runs `systemctl reset-failed xochitl` before `xovi/start` (Vellum's own uninstaller does the same).

## The notebook app's name map ("hashtab")

The button patch (`inkDiary.qmd`) refers to parts of the notebook app by hashed names such as `[[1224665461898798997]]`. qt-resource-rebuilder needs a "hashtab" file, built on the tablet for its exact software version, to translate them. It also tells us which names exist in 3.29.1.0, so we can check and rewrite the patch.

It can only be built after xovi and qt-resource-rebuilder are installed (Stage 1). The command, on the tablet:

```sh
bash /home/root/xovi/rebuild_hashtable
```

It writes `/home/root/xovi/exthome/qt-resource-rebuilder/hashtab` and leaves the notebook app stopped; `systemctl start xochitl` brings it back. Copy it to a computer with (Windows PowerShell; on macOS/Linux use `~/Downloads/...`):

```powershell
scp root@10.11.99.1:/home/root/xovi/exthome/qt-resource-rebuilder/hashtab "$HOME\Downloads\hashtab-ferrari-3.29.1.0"
```

Then check it:

```sh
python3 tools/paper-pro/check-hashtab.py hashtab-ferrari-3.29.1.0
```

The patch's hashes are qmldiff's hashes of `/qml/device/view/documentview/DocumentView.qml`, `FocusScope` and `root` (`tests/check-hashtab.py` checks this), the same place the 3.28 Paper Pro port patches.

The hashtab is derived from reMarkable's own software, so it stays out of this repository (the Paper Pro port this borrows from keeps it private too).

## Read-only device check

`tools/paper-pro/device-info.sh` prints the facts the build depends on (model, processor, software version, Qt library, whether xovi is installed, the notebook app's checksum). It reads files only and changes nothing. The plain-language steps, written for Windows (Gilad's computer), are in [YOUR-STEPS.md](YOUR-STEPS.md).
