# Vertrag: Stadt, Läden und Figuren in der game_bible, Importer

Wie Stadt, Läden und Figuren in der game_bible stehen und wie der Importer daraus Daten fürs Spiel
macht. Entscheidungen in [research.md](../research.md) (R6, R9, R16, R17), Felder im Spiel in
[data-model.md](../data-model.md). Es gelten die Datenkonventionen der game_bible aus `CLAUDE.md`:
strukturierte Daten nur im Frontmatter, Skalare als `kategorie_feld`, Preise als Range mit `von`
und `bis` in DM, Freitext nur unter `## +…`, `Templates/TEMPLATE_*.md` als alleinige Autorität.

## Dateien

```text
docs/game_bible/
├── Templates/
│   ├── TEMPLATE_Laden.md     # neu
│   ├── TEMPLATE_Stadt.md     # neu
│   └── TEMPLATE_Figur.md     # neu
├── Stadt/<Name>.md           # neu, eine Notiz
├── Läden/                    # neu, vier Notizen
├── Läden.md                  # neu: Übersicht, erzeugt von regenerate_tables.py
├── Figuren/
│   ├── Ladenbesitzer.md      # neu
│   └── Makler.md             # neu
└── Figuren.md                # neu: Übersicht aller Figuren (FR-001c)
tools/bible/
├── importiere.py             # neu: game_bible → src/data/
└── test_importiere.py        # neu: Beispielnotizen → erwartete .tres, bytegleich
```

## TEMPLATE_Laden.md (Frontmatter)

```yaml
grunddaten_titel: ""            # „Ladenlokal Fußgängerzone“
grunddaten_reihenfolge: 0
grunddaten_anschrift: ""
grunddaten_viertel: ""          # innenstadt | wohngebiet | gewerbegebiet
flaeche_qm: 0
lage_laufkundschaft: ""         # niedrig | mittel | hoch
lage_sichtbarkeit: ""
lage_parkplaetze: ""
preise_miete:
- datum: "1985-01"
  von: 0
  bis: 0
text_beschreibung: ""
text_kleingedrucktes: ""
quelle_miete: ""                # Verweis auf recherche-geld.md oder eine Quelle
```

Darunter nur geschützte Abschnitte `## +Hintergrund` und `## +Notizen`.

## TEMPLATE_Figur.md (Frontmatter)

```yaml
grunddaten_name: ""             # „Herr Brandt“
grunddaten_rolle: ""            # „Makler“
grunddaten_alter: 0
grunddaten_vorkommen: []        # Features und Orte, etwa „010 Büro des Maklers“
optik_kurz: ""                  # ein Satz für die Übersicht; das ganze Aussehen steht im Bildkatalog
art_sprechweise: ""             # siezt, trocken, Lieblingswörter
art_charakter: ""
bild_katalog: ""                # Kennung und Abschnitt im Bildkatalog, etwa „F-02, #makler“
bild_szene: ""                  # Bild im Spiel, res://assets/images/buero/makler.png
saetze:
- anlass: ""
  text: ""
```

Darunter `## +Hintergrund` für alles, was eine Figur lebendig macht und die KI beim Schreiben
neuer Sätze braucht. `Figuren.md` listet alle Figuren mit Name, Rolle, Alter, Optik in einem
Satz, Vorkommen und Verweis auf den Bildkatalog.

**Aussehen nur an einer Stelle:** Wie eine Figur aussieht, ihr fester Prompt-Baustein, das
Figurenblatt als Referenzbild und die Bilder mit ihr stehen im Bildkatalog
(`docs/art/bildkatalog.md`, Abschnitt „Figuren“), den `dcl-grafik` pflegt; maßgeblich bleibt der
Style-Guide (`docs/style-guide/README.md`, „Szenen und Figuren“). Die game_bible sagt, wer die Figur
ist, wie sie redet und was sie sagt, und verweist für das Aussehen auf den Katalog. So gibt es für
das Aussehen eine Quelle statt zwei.

## TEMPLATE_Stadt.md (Frontmatter)

```yaml
grunddaten_name: ""
grunddaten_einwohner: 0
grunddaten_land: ""             # Bundesland, erfunden ist erlaubt
viertel: []                     # [innenstadt, wohngebiet, gewerbegebiet]
```

## Importer `tools/bible/importiere.py`

- Aufruf ohne Argumente vom Repo-Root: `python3 -I tools/bible/importiere.py`; liest
  `docs/game_bible/Stadt/`, `Läden/`, `Figuren/`, schreibt `src/data/stadt.tres`,
  `src/data/laeden/<id>.tres`, `src/data/figuren/<id>.tres`.
- `--pruefen`: schreibt nichts, meldet nur Fehler und ob eine Datei sich ändern würde (für Tests und
  vor dem Commit).
- Fehler mit Datei und Feld, Abbruch ohne zu schreiben: fehlendes Pflichtfeld, unbekanntes Viertel
  oder unbekannte Stufe, kein Eintrag `preise_miete` mit `datum: "1985-01"`, `von` ≠ `bis`, Fläche
  oder Miete nicht größer 0, doppelte Reihenfolge, fehlender Anlass des Maklers (data-model.md).
- IDs aus dem Dateinamen: klein, Umlaute als ae, oe, ue, ss, Leerzeichen als `_`.
- Ausgabe kanonisch: gleiche Notizen, gleiche Dateien, Byte für Byte; Kopfkommentar „Erzeugt von
  tools/bible/importiere.py aus docs/game_bible/…; nicht von Hand ändern.“
- Beträge in Pfennig, mit Ganzzahlen gerechnet; ein Betrag, der keine ganzen Pfennige ergibt, ist
  ein Fehler (CHK047). Die Bildpfade folgen der ID über `ShopOffer.image_path()` (data-model.md).
- Ein Werkzeug außerhalb von `src/`: Der Kopf nennt die Stellen in Godot, deren Format oder Werte
  es ein zweites Mal kennt: die Klassen `ShopOffer`, `CityData`, `FigureData`, die Anlässe
  `FigureData.OCCASIONS`, die Stufen `ShopOffer.Level` und `ShopOffer.image_path()` (Leitfaden,
  „Werkzeuge“; CHK041).
- Gleichschritt (CHK015): `tools/build/baue_alles.sh` ruft vor dem Bau `importiere.py --pruefen` und
  bricht bei einem Unterschied ab. Ändert Klaus die game_bible, lässt Claude den Importer laufen.

## Feste Größen

- `python3 -I tools/bible/importiere.py --pruefen` meldet nach dem Import keine Änderung.
- `test_daten_laeden.gd` liest die erzeugten Dateien und prüft die Tabelle in data-model.md
  („bezahlbar je Grad“).
