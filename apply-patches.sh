#!/bin/bash
# apply-patches.sh — apply all frameworks-side patches for the
# GT-I8150 (ancora) LineageOS 15.1 (Oreo) port onto an existing
# LineageOS 15.1 source tree.
#
# It looks up the build root itself, so any of these work:
#
#     ~/TWRP/device/samsung/ancora/apply-patches.sh          # after copying it here
#     /path/to/audio-tree-still/device/samsung/ancora/apply-patches.sh ~/TWRP
#     cd ~/TWRP && ./device/samsung/ancora/apply-patches.sh
#
# Or export ANCORA_BUILD_ROOT=/path/to/root and run it from anywhere.
# Add --force-prelink to also apply the optional bionic prelink patch.
#
# Patch table (patch->repo):
#   frameworks-av-15.1-camera-params-extra.patch   -> frameworks/av   (mandatory)
#   system-core-15.1-vectorimpl-reserved.patch     -> system/core     (mandatory)
#   bionic-15.1-prelink-optional.patch             -> bionic          (optional)
set -u

FORCE_PRELINK=0
BUILD_ROOT=""
for arg in "$@"; do
  case "$arg" in
    --force-prelink) FORCE_PRELINK=1 ;;
    *)               BUILD_ROOT="$arg" ;;
  esac
done
[ -z "$BUILD_ROOT" ] && [ -n "${ANCORA_BUILD_ROOT:-}" ] && BUILD_ROOT="$ANCORA_BUILD_ROOT"
[ -z "$BUILD_ROOT" ] && [ -d "$HOME/TWRP/system/core" ] && BUILD_ROOT="$HOME/TWRP"

# --- locate the device dir: the directory this script lives in -------------
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d "$script_dir/patches" ]; then
  echo "cannot find patches/ next to $0" >&2; exit 1
fi
DEV_DIR="$script_dir"

# --- sanity: find the build root (walk up from the device dir, then fallback)
if [ -z "$BUILD_ROOT" ]; then
  probe="$DEV_DIR"
  for _ in 1 2 3 4 5; do
    if [ -d "$probe/system/core/libutils" ] && [ -d "$probe/bionic/linker" ]; then
      BUILD_ROOT="$probe"; break
    fi
    probe="$(dirname "$probe")"
  done
fi
if [ -z "$BUILD_ROOT" ] || [ ! -d "$BUILD_ROOT/system/core/libutils" ]; then
  echo "usage: $(basename "$0") [BUILD_ROOT] [--force-prelink]" >&2
  echo "  BUILD_ROOT: LineageOS 15.1 tree root (contains system/core, bionic, frameworks/av)" >&2
  echo "  e.g.        $(basename "$0") ~/TWRP" >&2
  exit 1
fi
echo "build root : $BUILD_ROOT"

# --- git apply wrapper: skips already-applied patches -----------------------
apply() { # $1 repo-relative dir, $2 patch file, $3 label
  local rel="$1"
  local patch="$2"
  local label="$3"
  local repo="$BUILD_ROOT/$rel"
  if [ ! -d "$repo" ]; then
    echo "  [SKIP] $label — '$rel' not present in this tree" >&2
    return 0
  fi
  echo "applying $label -> $rel"
  (
    cd "$repo" || exit 1
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if git apply --check --reverse --ignore-whitespace "$patch" 2>/dev/null; then
        echo "  [SKIP] already applied"; exit 0
      fi
      if git apply --check --ignore-whitespace "$patch" 2>/dev/null; then
        git apply --ignore-whitespace "$patch" || exit 1
        echo "  [OK] applied"; exit 0
      fi
      echo "  [FAIL] does not apply (already modified? tree version differs?) — run 'git diff $rel' to inspect" >&2
      exit 1
    else
      if patch -p1 -R --dry-run -i "$patch" >/dev/null 2>&1; then
        echo "  [SKIP] already applied"; exit 0
      fi
      if patch -p1 -i "$patch"; then
        echo "  [OK] applied (patch tool, not a git work tree)"; exit 0
      fi
      echo "  [FAIL] patch -p1 failed" >&2
      exit 1
    fi
  ) || FAILED=1
  return 0
}

FAILED=0
wish_to_apply(){
  if [ "$FORCE_PRELINK" = 1 ]; then return 0; fi
  [ -t 0 ] || return 1
  printf "apply optional %s? [y/N] " "$1"; read -r ans; [ "$ans" = y ] || [ "$ans" = Y ]
}

# ---- mandatory set ----------------------------------------------------------
apply frameworks/av   "$DEV_DIR/patches/frameworks-av-15.1-camera-params-extra.patch" "CameraParameters EXTRA hook"
apply system/core     "$DEV_DIR/patches/system-core-15.1-vectorimpl-reserved.patch"  "VectorImpl reserved slots"

# ---- optional set -----------------------------------------------------------
wish_to_apply "bionic prelink support" && \
    apply bionic "$DEV_DIR/patches/bionic-15.1-prelink-optional.patch" "bionic prelink (OPTIONAL)"

# ----------------------------------------------------------------------------
echo
if [ "$FAILED" = 0 ]; then
  echo "all requested patches are now in the tree."
else
  echo "SOME patches failed — inspect the failures above before building." >&2
fi
cat <<'EOT'
post-build sanity (Stage 0 of BRINGUP.md):
  nm -D out/target/product/ancora/system/lib/libutils.so | grep reservedVectorImpl
  → needs reservedVectorImpl1..8 + the SortedVectorImpl eight
remember: commit the applied patches inside each repo (or keep them out of
upstream branches but reproducible via this script).
EOT
exit "$FAILED"
