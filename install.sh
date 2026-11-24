#!/bin/sh
# Installs Ink Diary for Claude on a reMarkable Paper Pro. Run on the tablet, as root,
# from the unpacked package folder (see docs/paper-pro/STAGE1.md).
#
# Everything goes under /home/root; the read-only system area is never touched, and
# nothing starts by itself after a restart. Undo: sh uninstall.sh (and see the guide).
set -eu
cd -- "$(dirname -- "$0")"
[ "$(id -u)" = 0 ] || { echo 'Run this on the tablet as root'; exit 1; }

machine=$(tr -d '\0' < /sys/devices/soc0/machine 2>/dev/null || true)
if [ "$(uname -m)" != aarch64 ] || ! printf '%s' "$machine" | grep -qi -e ferrari -e 'paper pro'; then
    echo "This package is for the reMarkable Paper Pro only (found: ${machine:-unknown}, $(uname -m))."
    exit 1
fi

# The software version this build was made and checked for. Another version may have
# renamed the notebook app's parts, so refuse unless told otherwise.
expected=3.29.1.0
firmware=$(sed -n 's/^IMG_VERSION=//p' /etc/os-release 2>/dev/null | tr -d '"')
[ -n "$firmware" ] || firmware=$(sed -n 's/^REMARKABLE_RELEASE_VERSION=//p' /usr/share/remarkable/update.conf 2>/dev/null)
if [ "$firmware" != "$expected" ] && [ "${INK_DIARY_ANY_VERSION:-}" != 1 ]; then
    echo "This build is for Paper Pro software $expected; this tablet has ${firmware:-an unknown version}."
    echo "Nothing was installed. It needs a build for your version."
    exit 1
fi

[ -f bin/ink-diary.so ] || { echo 'bin/ink-diary.so is missing: use the package from the cloud build'; exit 1; }
if [ -f SHA256SUMS ] && ! sha256sum -c SHA256SUMS > /dev/null 2>&1; then
    echo 'Some files in this folder are damaged or changed (SHA256SUMS does not match). Copy the folder again.'
    exit 1
fi

[ -x /home/root/.vellum/bin/vellum ] || { echo 'Install Vellum first (guide, part 2)'; exit 1; }
/home/root/.vellum/bin/vellum add xovi qt-resource-rebuilder xovi-message-broker framebuffer-spy 'rm-shot>=1.2.0'

if [ ! -s /home/root/xovi/exthome/qt-resource-rebuilder/hashtab ]; then
    echo 'The name map is missing. Run this first, then install again:'
    echo '  bash /home/root/xovi/rebuild_hashtable'
    exit 1
fi

base=/home/root/.config/ink-diary
mkdir -p "$base"
chmod 700 "$base"
cp icons/claude.svg "$base/claude.svg"
chmod 644 "$base/claude.svg"
cp fonts/DejaVuSansMono.ttf "$base/DejaVuSansMono.ttf"
chmod 644 "$base/DejaVuSansMono.ttf"
cp fonts/Caveat.ttf "$base/Caveat.ttf"
chmod 644 "$base/Caveat.ttf"
cp bin/config-model "$base/config-model"
chmod 700 "$base/config-model"
cp configure.sh "$base/configure.sh"
chmod 700 "$base/configure.sh"
cp bin/ink-diary.so /home/root/xovi/extensions.d/ink-diary.so.new
chmod 755 /home/root/xovi/extensions.d/ink-diary.so.new
mv /home/root/xovi/extensions.d/ink-diary.so.new /home/root/xovi/extensions.d/ink-diary.so
cp inkDiary.qmd /home/root/xovi/exthome/qt-resource-rebuilder/inkDiary.qmd
chmod 644 /home/root/xovi/exthome/qt-resource-rebuilder/inkDiary.qmd

if [ -f STAGE1 ]; then
    printf 'Installed the Stage 1 TEST build (button + screenshots only; no Claude requests).\n'
else
    printf 'Installed. Configure with: sh /home/root/.config/ink-diary/configure.sh\n'
fi
printf 'Start it with: bash /home/root/xovi/start\n'
