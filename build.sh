#!/bin/bash
# Builds dist/geowarden_<version>_all.deb. Version: first line of debian/changelog.
# Needs dpkg-deb and GNU coreutils (du --exclude, sed -i), so run it on Debian/Ubuntu.
set -euo pipefail
cd "$(dirname "$0")"

# First line looks like "geowarden (1.4.0) stable; urgency=medium": take what's in ( )
VERSION=$(sed -n '1s/.*(\(.*\)).*/\1/p' debian/changelog)
# Year of the release: from the date in the first trailer line " -- Name  Sat, 07 Nov 2026 ..."
YEAR=$(awk '/^ -- /{print $(NF-2); exit}' debian/changelog)
# Staging directory that mirrors the target file system; removed on exit
B=$(mktemp -d)
trap 'rm -rf "$B"' EXIT

# Programs and data, with the version and year filled into the menu
install -D -m 755 src/geowarden          "$B/usr/sbin/geowarden"
sed -i -e "s/@VERSION@/$VERSION/" -e "s/@YEAR@/$YEAR/" "$B/usr/sbin/geowarden"
install -D -m 755 src/geowarden-apply    "$B/usr/sbin/geowarden-apply"
# Template only: postinst copies it to /etc on first install
install -D -m 644 src/geowarden.conf     "$B/usr/share/geowarden/geowarden.conf"
install -D -m 644 src/worldmap.txt       "$B/usr/share/geowarden/worldmap.txt"
install -D -m 644 src/geowarden.service  "$B/usr/lib/systemd/system/geowarden.service"
install -D -m 644 src/geowarden.timer    "$B/usr/lib/systemd/system/geowarden.timer"
# Documentation as Debian policy expects it (changelog gzipped, -n: no timestamp)
install -D -m 644 src/README            "$B/usr/share/doc/geowarden/README"
install -D -m 644 debian/copyright      "$B/usr/share/doc/geowarden/copyright"
gzip -9n < debian/changelog > "$B/usr/share/doc/geowarden/changelog.gz"
chmod 644 "$B/usr/share/doc/geowarden/changelog.gz"

# Package metadata: control with version and installed size (in KiB),
# the maintainer scripts and the checksums of all installed files
chmod 755 "$B"
mkdir -p "$B/DEBIAN"
SIZE=$(du -sk --exclude=DEBIAN "$B" | cut -f1)
sed -e "s/@VERSION@/$VERSION/" -e "s/@SIZE@/$SIZE/" debian/control > "$B/DEBIAN/control"
install -m 755 debian/postinst debian/prerm debian/postrm "$B/DEBIAN/"
(cd "$B" && find usr -type f -exec md5sum {} + | sort -k2) > "$B/DEBIAN/md5sums"

# --root-owner-group: files owned by root without building as root; -Zxz: xz compression
mkdir -p dist
dpkg-deb --root-owner-group -Zxz --build "$B" "dist/geowarden_${VERSION}_all.deb"
