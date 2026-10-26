# geowarden

Länder-Allowlist für Linux-Server: Neue Verbindungen auf den öffentlichen
Netzwerk-Interfaces werden nur aus ausgewählten Ländern angenommen, alles andere
wird per nftables verworfen. Bedienung über ein Menü im Terminal.

- Länder nach Kontinent ein- und ausschalten, die Sperre als Ganzes an/aus
- Länderzuordnung per Geolokation ([DB-IP Lite](https://db-ip.com/db/lite.php)),
  automatisch beim Start und täglich aktualisiert
- Bestehende Verbindungen, VPN-Interfaces (z. B. Tailscale, WireGuard),
  Docker-interner Verkehr und frei wählbare Ports bleiben ungefiltert
- Filtert vor Docker-DNAT, gilt also auch für veröffentlichte Container-Ports
- Fehlgeschlagene Downloads oder kaputte Daten lassen die bisherigen Regeln stehen

Getestet auf Debian 12/13 und Ubuntu 22.04/24.04.

## Installation

Paket bauen und installieren:

```bash
./build.sh
apt install ./dist/geowarden_1.0.0_all.deb
```

Nach der Installation ist die Sperre **aus**, damit du dich nicht versehentlich
aussperrst. Einschalten und Länder wählen:

```bash
geowarden
```

Vorbelegt sind Europa (ohne Russland und Belarus) und die USA.

## Bedienung

| Was | Wie |
|---|---|
| Menü (als root) | `geowarden` |
| Konfiguration | `/etc/geowarden.conf` |
| Regeln neu laden | `systemctl start geowarden.service` |
| Notaus bis zum nächsten Timer-Lauf | `nft delete table inet geowarden` |
| Letzte Läufe | `journalctl -u geowarden.service` |

### Konfiguration

| Variable | Bedeutung | Vorgabe |
|---|---|---|
| `ENABLED` | Sperre an (`yes`) oder aus (`no`) | `no` |
| `COUNTRIES` | Erlaubte Länder, ISO-Codes klein geschrieben | Europa ohne RU/BY, USA |
| `WAN_IF` | Gefilterte Interfaces; leer = Interfaces der Default-Routen | leer |
| `OPEN_TCP` | Weltweit offene TCP-Ports | `80` (Let's-Encrypt-HTTP-01) |
| `OPEN_UDP` | Weltweit offene UDP-Ports | `41641` (Tailscale) |

## Funktionsweise

`geowarden.timer` startet `geowarden-apply` eine Minute nach dem Systemstart und
einmal täglich. Das Skript

1. nimmt die DB-IP-Datei des aktuellen Monats aus `/var/cache/geowarden` oder
   lädt sie herunter (sonst die des Vormonats),
2. filtert die IP-Bereiche der erlaubten Länder heraus,
3. ersetzt die nftables-Tabelle `inet geowarden` in einer einzigen Transaktion.

Die Regeln hängen im `prerouting`-Hook mit Priorität -150: nach Connection
Tracking, vor DNAT. Andere Firewalls (Docker, CrowdSec, ufw) bleiben unberührt.

## Hinweise

- Geolokation ist nie perfekt. Bei Cloud-, Hosting- und VPN-Adressen kann die
  Zuordnung vom tatsächlichen Standort abweichen.
- Prüfe vor dem Einschalten, dass du aus einem erlaubten Land oder über ein
  ungefiltertes Interface (VPN) zugreifst. Bestehende SSH-Verbindungen bleiben
  erhalten, neue aus gesperrten Ländern nicht.
- Wer in der EU Waren oder Dienstleistungen anbietet, sollte die
  Geoblocking-Verordnung (EU) 2018/302 beachten: Kunden aus anderen EU-Ländern
  dürfen nicht ohne sachlichen Grund ausgesperrt werden.

## Lizenz

MIT, siehe [LICENSE](LICENSE).

Die Geodaten werden zur Laufzeit geladen und sind nicht Teil dieses Projekts:
[IP Geolocation by DB-IP](https://db-ip.com), lizenziert unter
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
