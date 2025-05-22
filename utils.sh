#!/bin/sh

# Print informational messages to stderr
log() {
    printf '[INFO] %s\n' "$*" >&2
}

# Download a file and return "<workdir> <md5sum>" via stdout
download_and_verify() {
    URL="$1"
    TMPDIR="${TMPDIR:-/tmp}"
    WORKDIR="$(mktemp -d "$TMPDIR/pkgbuild_XXXXXX")"
    TARBALL_NAME=$(basename "$URL")

    log "Downloading: $URL"
    if ! curl -fsSL -A "SlackBuildBot/1.0" -o "$WORKDIR/$TARBALL_NAME" "$URL"; then
        log "Download failed. No files were changed."
        rm -rf "$WORKDIR"
        exit 1
    fi

    log "Calculating MD5..."
    if ! MD5=$(md5sum "$WORKDIR/$TARBALL_NAME" | awk '{print $1}'); then
        log "MD5 calculation failed."
        rm -rf "$WORKDIR"
        exit 1
    fi

    # Return structured data
    echo "$WORKDIR $MD5"
}

# Update .info file with new VERSION, DOWNLOAD, and MD5SUM
update_info_file() {
    INFO_FILE="$1"
    VERSION="$2"
    URL="$3"
    MD5="$4"

    sed -i '' \
        -e "s/^VERSION=.*/VERSION=\"$VERSION\"/" \
        -e "s|^DOWNLOAD=.*|DOWNLOAD=\"$URL\"|" \
        -e "s/^MD5SUM=.*/MD5SUM=\"$MD5\"/" \
        "$INFO_FILE"
}

# Update the fallback VERSION line in the SlackBuild
update_build_file() {
    BUILD_FILE="$1"
    VERSION="$2"
    sed -i '' "s/^VERSION=.*/VERSION=\${VERSION:-$VERSION}/" "$BUILD_FILE"
}

# Create <pkg>.tar.gz from the working directory, including all contents
create_archive() {
    PKG="$1"
    WORKDIR="$2"
    OUTFILE="${PKG}.tar.gz"

    tar -czf "$OUTFILE" -C "$WORKDIR" .

    log "Created metadata archive: $OUTFILE"
}
