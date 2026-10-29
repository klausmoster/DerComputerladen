# Quickstart: Ladeneröffnung prüfen

Prüfanleitung für die Abnahmen und die Gesamtabnahme. Verträge unter [contracts/](contracts/),
Zahlen in [data-model.md](data-model.md). Befehle laufen vom Repo-Root.

## Vorbereitung

- Godot 4.7.2 unter `/Applications/Godot.app`, GUT 9.7.1 im Projekt.
- Die game_bible ist importiert, ohne offene Änderung:

```bash
python3 -I tools/bible/importiere.py --pruefen
```

- Alte Spielstände aus der Zeit vor 010 dürfen liegen bleiben; sie erscheinen als beschädigt.

## Automatische Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle grün, zweimal hintereinander dieselbe Zahl der Prüfungen. Darunter:
- `test_shop_rules.gd`, `test_daten_laeden.gd`: Tabelle „bezahlbar je Grad“ (SC-002).
- `test_shop_account.gd`, `test_game_session.gd`: 179 Mieten bis 31.12.1999, Kontostand auf den
  Pfennig; Fortsetzen an drei Tagen ohne Unterschied (SC-003, SC-004).
- `test_fahrplan_laden.gd`: Fahrplan bytegleich für Seeds 1, 4711, 99999, alle Grade, alle Läden
  (SC-005).
- `test_broker_office.gd`: kein Spielstand vor der Anmeldung, an jeder Stelle (SC-007).

## Startprobe

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --quit-after 120 -d
```

Erwartet: Exit 0, keine Ausgabe.

## Von Hand, im Fenster

Spiel starten:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src
```

1. **Gradwahl → Büro:** „Neues Spiel“, „Schwer“. Der Communicator fährt hinaus, das Büro erscheint
   mit dem Stadtplan; der Makler sagt seinen Satz. Im Ordner der Spielstände ist nichts neu.
2. **Grau auf Schwer:** Die Fußgängerzone ist grau. Ihr Exposé zeigt den Vermerk mit 43.200,00 DM
   Nachweis und 30.000,00 DM Kapital, ohne „Diesen Laden mieten“.
3. **Blättern:** Im Exposé mit den Knöpfen oder Pfeiltasten durch alle vier Läden; Esc zurück zum
   Plan; Esc noch einmal zurück zur Gradwahl, „Schwer“ vorgewählt.
4. **Mieten:** Stadtteilzentrum, „Diesen Laden mieten“, Mietvertrag mit 1.440,00 DM Miete,
   4.320,00 DM Kaution, Mietbeginn 01.01.1985. „Unterschreiben“.
5. **Name:** Leeres Feld: „Anmelden“ gesperrt, Grund steht da. Ein Zeichen wie „@“ lässt sich nicht
   tippen. „Computer Klaus“ eintippen, „Anmelden“.
6. **Laden:** Spielbildschirm mit Ladenbild (Platzhalter bis zur Phase „Bilder“), Name, in der
   Leuchtanzeige DI 01.01.1985 und 25.680,00 DM. Die Uhr steht.
7. **Miete:** Uhr laufen lassen bis 01.02.1985: Kontostand 24.240,00 DM. Tempo wechseln, anhalten.
8. **Speichern:** „Zum Hauptmenü“. „Weiterspielen“ zeigt „Weiter mit Computer Klaus, Schwer, am …“.
   Fortsetzen: gleicher Laden, gleicher Kontostand, Uhr steht.
9. **Gleicher Name:** Ein zweites Spiel „Computer Klaus“ auf Leicht anlegen. „Spiel laden“ zeigt
   beide, unterscheidbar an Grad und Datum; die Rückfrage beim Löschen nennt Grad und Datum.
10. **Alter Spielstand:** Ein Spielstand von vor 010 steht als beschädigt in der Liste und lässt
    sich löschen.
11. **Fenster schließen im Büro:** Im Büro Cmd+Q: Die App endet, kein neuer Spielstand.
12. **Minus:** Im Spielbildschirm laufen lassen, bis der Kontostand unter null fällt: Minus und „SOLL“ in der
    Leuchtanzeige.

## Aufräumen

- Probe-Spielstände liegen unter
  `~/Library/Application Support/Godot/app_userdata/Der Computerladen/spielstaende/`; im Spiel über
  „Spiel laden“ → „Löschen …“ entfernen.
- Erzeugte Daten zurücksetzen, falls von Hand geändert: `git restore src/data/`.
