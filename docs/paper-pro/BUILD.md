# Paper Pro build environment

Status as of 2026-11-24. Target: reMarkable Paper Pro ("ferrari", 64-bit ARM), software **3.29.1.0**.

## Cloud build

`.github/workflows/paper-pro-build.yml` builds the plugin on GitHub's free Ubuntu runners on every pull request, every push to `main`, and on demand (Actions tab → "Paper Pro build" → "Run workflow").

What it does:

1. Downloads reMarkable's official SDK for 3.29.1.0, ferrari, x86_64 host (409 MB, cached between runs) and checks its SHA-256.
2. Fetches xovi at a pinned commit, for `util/xovigen.py`.
3. Runs `./build.sh ferrari`, which also checks that both outputs really are 64-bit ARM files.
4. Uploads `bin/ferrari/` (`ink-diary.so`, `config-model`, `BUILD-INFO.txt` with checksums and the Qt version) as the run's download, kept for 30 days.

| Input | Value |
|---|---|
| SDK | `https://storage.googleapis.com/remarkable-codex-toolchain/3.29.1.0/remarkable-production-image-6.0.112-ferrari-public-x86_64-toolchain.sh` |
| SDK SHA-256 | `e517362f102f77e0b140c0ed53a74bea8a3e6fe4048199ea44df7d9af2683ebb` (Google Storage MD5 `y9aKNrbQC0RbOmMGXZbwtQ==` matched) |
| SDK environment file | `environment-setup-cortexa53-crypto-remarkable-linux` |
| xovi | `asivery/xovi` @ `2b99649f5e4fd6288be7792a8570bd16418adb70` |

To move to another software version, change `RM_SOFTWARE`, `SDK_URL` and `SDK_SHA256` in the workflow. The URL list is at https://developer.remarkable.com/links .

**The build is not installable yet.** It compiles the current code, which still requires the reMarkable 2 screen (1404 × 1872) and places the button for the rM2 toolbar, so on a Paper Pro it would load and then refuse to start. Stages 1 and 2 of the port plan change that.

## Local build

The same SDK runs on any x86_64 Linux machine (an aarch64 host variant is also published):

```sh
sh remarkable-production-image-6.0.112-ferrari-public-x86_64-toolchain.sh -y -d ~/sdk-ferrari-3.29.1.0
git clone https://github.com/asivery/xovi ~/xovi
SDK_ENV=~/sdk-ferrari-3.29.1.0/environment-setup-cortexa53-crypto-remarkable-linux XOVI_REPO=~/xovi ./build.sh ferrari
```

`./build.sh rm2` still builds the old reMarkable 2 target with an rM2 SDK.

## Does the plugin loader support 3.29.1.0?

Yes, as far as can be checked without the tablet. The evidence, from the Vellum package index (`vellum-dev/vellum`, `packages/*/VELBUILD`, read 2026-11-24):

- **xovi 0.3.3** ships an aarch64 build and has no software-version limit.
- **xovi-extensions 19.0.1** (qt-resource-rebuilder, xovi-message-broker, framebuffer-spy, qt-command-executor) ships aarch64 and requires only `remarkable-os>=3.20`, no upper limit.
- **rm-shot 1.2.0** (screenshots) ships aarch64 and has no software-version limit.
- About 40 Vellum UI mods that work through qt-resource-rebuilder declare `remarkable-os>=3.29`. Some are Paper Pro family only, for example `hide-dev-mode-icon` (`!rm1 !rm2 ... remarkable-os>=3.29 remarkable-os<3.30`) and `bluetooth-settings`. So the loader and the QML patcher are in use on Paper Pro 3.29.

Not yet proven: that rm-shot captures correctly on a full-size Paper Pro on 3.29 (it worked on the Paper Pro Move, and one person reports it working on the Paper Pro on 3.28). Stage 1 checks it on Gilad's tablet.

## The notebook app's name map ("hashtab")

The button patch (`inkDiary.qmd`) refers to parts of the notebook app by hashed names such as `[[1224665461898798997]]`. qt-resource-rebuilder needs a "hashtab" file, built on the tablet for its exact software version, to translate them. It also tells us which names exist in 3.29.1.0, so we can check and rewrite the patch.

It can only be built after xovi and qt-resource-rebuilder are installed (Stage 1). The command, on the tablet:

```sh
bash /home/root/xovi/rebuild_hashtable
```

It writes `/home/root/xovi/exthome/qt-resource-rebuilder/hashtab`. Copy it to a computer with:

```sh
scp root@10.11.99.1:/home/root/xovi/exthome/qt-resource-rebuilder/hashtab ~/Desktop/hashtab-ferrari-3.29.1.0
```

The hashtab is derived from reMarkable's own software, so it stays out of this repository (the Paper Pro port this borrows from keeps it private too).

## Read-only device check

`tools/paper-pro/device-info.sh` prints the facts the build depends on (model, processor, software version, Qt library, whether xovi is installed, the notebook app's checksum). It reads files only and changes nothing. The plain-language steps are in [YOUR-STEPS.md](YOUR-STEPS.md).
