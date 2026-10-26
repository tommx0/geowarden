#!/bin/bash
# Baut dist/geowarden_<version>_all.deb. Version: erste Zeile von debian/changelog.
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(sed -n '1s/.*(\(.*\)).*/\1/p' debian/changelog)
B=$(mktemp -d)
trap 'rm -rf "$B"' EXIT

install -D -m 755 src/geowarden          "$B/usr/sbin/geowarden"
install -D -m 755 src/geowarden-apply    "$B/usr/sbin/geowarden-apply"
install -D -m 644 src/geowarden.conf     "$B/usr/share/geowarden/geowarden.conf"
install -D -m 644 src/geowarden.service  "$B/usr/lib/systemd/system/geowarden.service"
install -D -m 644 src/geowarden.timer    "$B/usr/lib/systemd/system/geowarden.timer"
install -D -m 644 src/README            "$B/usr/share/doc/geowarden/README"
install -D -m 644 debian/copyright      "$B/usr/share/doc/geowarden/copyright"
gzip -9n < debian/changelog > "$B/usr/share/doc/geowarden/changelog.gz"
chmod 644 "$B/usr/share/doc/geowarden/changelog.gz"

chmod 755 "$B"
mkdir -p "$B/DEBIAN"
SIZE=$(du -sk --exclude=DEBIAN "$B" | cut -f1)
sed -e "s/@VERSION@/$VERSION/" -e "s/@SIZE@/$SIZE/" debian/control > "$B/DEBIAN/control"
install -m 755 debian/postinst debian/prerm debian/postrm "$B/DEBIAN/"
(cd "$B" && find usr -type f -exec md5sum {} + | sort -k2) > "$B/DEBIAN/md5sums"

mkdir -p dist
dpkg-deb --root-owner-group -Zxz --build "$B" "dist/geowarden_${VERSION}_all.deb"
