#!/usr/bin/env bash
# Makes the folder that is copied to the tablet, from a build in bin/<target>.
#
#   tools/paper-pro/package.sh ferrari-stage1   # -> dist/ink-diary-stage1-test/
#   tools/paper-pro/package.sh ferrari          # -> dist/ink-diary-paper-pro/
#
# The folder holds the installer, the plugin, the notebook patch, fonts, icon and a
# SHA256SUMS file that install.sh checks before installing anything.
set -euo pipefail
cd -- "$(dirname -- "$0")/../.."
target=${1:?Usage: tools/paper-pro/package.sh ferrari|ferrari-stage1}
case "$target" in
    ferrari)        name=ink-diary-paper-pro ;;
    ferrari-stage1) name=ink-diary-stage1-test ;;
    *) echo "Unknown target $target" >&2; exit 2 ;;
esac
[ -s "bin/$target/ink-diary.so" ] && [ -s "bin/$target/config-model" ] || { echo "Build bin/$target first (./build.sh $target)" >&2; exit 1; }
out=dist/$name
rm -rf "$out"
mkdir -p "$out/bin" "$out/icons" "$out/fonts"
cp install.sh uninstall.sh configure.sh inkDiary.qmd LICENSE THIRD_PARTY.md "$out/"
cp "bin/$target/ink-diary.so" "bin/$target/config-model" "$out/bin/"
[ -f "bin/$target/BUILD-INFO.txt" ] && cp "bin/$target/BUILD-INFO.txt" "$out/"
cp icons/claude.svg "$out/icons/"
cp fonts/Caveat.ttf fonts/DejaVuSansMono.ttf fonts/OFL.txt fonts/DejaVu-LICENSE.txt "$out/fonts/"
if [ "$target" = ferrari-stage1 ]; then
    printf 'Stage 1 test build: shows the Claude button and saves two screenshots.\nNo Claude requests, no API key, nothing added to your notebooks.\n' > "$out/STAGE1"
fi
chmod 755 "$out/install.sh" "$out/uninstall.sh" "$out/configure.sh" "$out/bin/config-model"
(cd "$out" && find . -type f ! -name SHA256SUMS -print | LC_ALL=C sort | sed 's|^\./||' | xargs sha256sum > SHA256SUMS)
echo "Packaged $out"
