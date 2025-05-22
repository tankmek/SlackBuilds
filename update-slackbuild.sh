 #!/bin/sh
set -eu

# --- Parse Arguments ---
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 <package-name> <new-version> [--dry-run]" >&2
    exit 1
fi

PKG="$1"
VERSION="$2"
DRY_RUN="${3:-}"

CONF_JSON="pkgdefs/$PKG.json"
PKGDIR="./$PKG"
INFO_FILE="$PKGDIR/${PKG}.info"
BUILD_FILE="$PKGDIR/${PKG}.SlackBuild"

# --- Validate files ---
[ -f "$CONF_JSON" ] || { echo "Missing: $CONF_JSON" >&2; exit 1; }
[ -f "$INFO_FILE" ] || { echo "Missing: $INFO_FILE" >&2; exit 1; }
[ -f "$BUILD_FILE" ] || { echo "Missing: $BUILD_FILE" >&2; exit 1; }

# --- Load shared functions ---
. ./utils.sh

# --- Extract current version and short-circuit if same ---
CURRENT_VERSION=$(grep '^VERSION=' "$INFO_FILE" | cut -d= -f2 | tr -d '"')
if [ "$CURRENT_VERSION" = "$VERSION" ]; then
    log "No update needed: current version already $VERSION."
    [ "$DRY_RUN" = "--dry-run" ] && exit 0
fi

# --- Load template URL and generate download target ---
DOWNLOAD_FMT=$(jq -r .download_fmt "$CONF_JSON")
URL=$(printf "%s" "$DOWNLOAD_FMT" | sed "s/%v/$VERSION/g")

# --- Download and hash tarball ---
RESULT=$(download_and_verify "$URL")
WORKDIR=$(echo "$RESULT" | awk '{print $1}')
MD5=$(echo "$RESULT" | awk '{print $2}')

# --- Copy working files ---
cp -r "$PKGDIR"/* "$WORKDIR/"

# --- Apply updates ---
update_info_file "$WORKDIR/${PKG}.info" "$VERSION" "$URL" "$MD5"
update_build_file "$WORKDIR/${PKG}.SlackBuild" "$VERSION"

# --- Dry-run: show proposed changes without modifying files ---
if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "=== DRY RUN: Showing proposed changes for $PKG $VERSION ==="

    if command -v delta >/dev/null 2>&1; then
        DIFF="delta --paging=always --syntax-theme=Dracula"
    else
        DIFF="cat"
    fi

    echo "--- .info diff ---"
    diff -u "$PKGDIR/${PKG}.info" "$WORKDIR/${PKG}.info" | $DIFF || true

    echo "--- .SlackBuild diff ---"
    diff -u "$PKGDIR/${PKG}.SlackBuild" "$WORKDIR/${PKG}.SlackBuild" | $DIFF || true

    echo "Dry run complete. No files modified."
    rm -rf "$WORKDIR"
    exit 0
fi

# --- Final archive ---
create_archive "$PKG" "$WORKDIR"

# --- Cleanup ---
rm -rf "$WORKDIR"
