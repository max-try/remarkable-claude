#!/usr/bin/env bash
# Build the plugin with an official reMarkable SDK (toolkit).
#
#   ./build.sh            # Paper Pro ("ferrari"), the default target
#   ./build.sh ferrari    # same
#   ./build.sh rm2        # reMarkable 2 (legacy)
#
# Needs SDK_ENV (the SDK's environment-setup-* file, from the SDK that matches
# the tablet's software version and target) and XOVI_REPO (a checkout of
# https://github.com/asivery/xovi). CI does all of this in
# .github/workflows/paper-pro-build.yml.
#
# Output: bin/<target>/ink-diary.so and bin/<target>/config-model. The legacy
# rm2 target also refreshes bin/ink-diary.so and bin/config-model.
set -euo pipefail
cd -- "$(dirname -- "$0")"
target=${1:-ferrari}
case "$target" in
    ferrari) xovi_arch=aarch64 elf_class=2 elf_machine=183 ;;  # ELFCLASS64, EM_AARCH64
    rm2)     xovi_arch=arm32   elf_class=1 elf_machine=40  ;;  # ELFCLASS32, EM_ARM
    *) echo 'Usage: ./build.sh [ferrari|rm2]' >&2; exit 2 ;;
esac
: "${SDK_ENV:?Set SDK_ENV to the environment-setup file of the official SDK for this target and OS version}"
: "${XOVI_REPO:?Set XOVI_REPO to the xovi source checkout}"
SDK_ENV=$(realpath "$SDK_ENV")
XOVI_REPO=$(realpath "$XOVI_REPO")
set +u
# shellcheck disable=SC1090
source "$SDK_ENV"
set -u
: "${CXX:?SDK did not set CXX}"
: "${STRIP:?SDK did not set STRIP}"

# Refuse an SDK for the wrong processor before spending time compiling.
compiler_arch=$($CXX -dumpmachine)
case "$target:$compiler_arch" in
    ferrari:aarch64*|rm2:arm*) ;;
    *) echo "The SDK compiler ($compiler_arch) does not match target $target" >&2; exit 1 ;;
esac

repo=$PWD
build_dir="$repo/build/$target"
out_dir="$repo/bin/$target"
mkdir -p "$build_dir" "$out_dir"

python3 "$XOVI_REPO/util/xovigen.py" -a "$xovi_arch" -o xovi.cpp -H xovi.h ink-diary.xovi
test -s xovi.cpp && test -s xovi.h

(
    cd "$build_dir"
    qmake "$repo/ink-diary.pro" CONFIG+=release
    make -j"${JOBS:-4}"
)
cp "$build_dir/ink-diary.so" "$out_dir/ink-diary.so"
$STRIP --strip-unneeded "$out_dir/ink-diary.so"

$CXX -std=c++17 -fPIC -ffile-prefix-map="$HOME"=/build-home src/config-model.cpp -o "$out_dir/config-model" $(pkg-config --cflags --libs Qt6Core)
$STRIP --strip-unneeded "$out_dir/config-model"

# qmake can pick a different compiler than CXX, so check the real output.
for name in ink-diary.so config-model; do
    python3 - "$out_dir/$name" "$elf_class" "$elf_machine" <<'PY'
import sys
path, cls, machine = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
h = open(path, 'rb').read(20)
if len(h) < 20 or h[:4] != b'\x7fELF' or h[4] != cls or int.from_bytes(h[18:20], 'little') != machine:
    sys.exit(f'{path} was not built for the expected processor')
PY
done

if [ "$target" = rm2 ]; then
    cp "$out_dir/ink-diary.so" "$out_dir/config-model" bin/
fi

qt=$(pkg-config --modversion Qt6Core)
printf 'Built %s (%s, Qt %s) in bin/%s\n' "$target" "$compiler_arch" "$qt" "$target"
