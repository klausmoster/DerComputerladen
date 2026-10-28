# Vertrag: Architektur-Leitfaden

Datei: `docs/architektur-leitfaden.md` (research.md, R1). Schreibt Claude `[C]`, entscheidet Klaus
`[K]` (R2). FR-001 bis FR-009.

## Gliederung

```text
# Architektur-Leitfaden
Kopf: Zweck, Geltung, Stand, Verweis auf Verfassung und Quellen
## So liest man eine Regel          # Teile einer Regel, Stände, Nummern, Schwere der Befunde
## Godot-Prinzipien                 # AR-01 bis AR-05, je eine Regel, ggf. Unterregeln
## Muster                           # je Muster aus Nystrom, das das Spiel nutzt oder braucht
## Schichten                        # Kern, Oberfläche, Adventure, Wirtschaft, Werkzeuge
## Was bisher woanders stand        # Grundsätze aus architektur.md und Verfassung, je mit Verweis (FR-006)
## Ausnahmen                        # Tabelle der begründeten Ausnahmen (R3)
## Geschichte                       # gestrichene und geänderte Regeln mit altem Wortlaut (FR-007)
```

Die fünf Godot-Prinzipien bekommen die ersten Nummern, in dieser Reihenfolge:
AR-01 Kern ohne Node, AR-02 Signal nach oben, Aufruf nach unten, AR-03 Autoloads sparsam,
AR-04 Daten als Resources, AR-05 Szenen-Komposition. Danach zählt die Nummer weiter, egal in welchem
Abschnitt die Regel steht. Eine Nummer wird nie neu vergeben, auch nicht nach einer Streichung.

## Eine Regel

```markdown
### AR-02 Signal nach oben, Aufruf nach unten

- **Aussage:** Ein Baustein kennt den, der ihn einsetzt, nicht. Er meldet nach oben per Signal;
  wer ihn einsetzt, ruft ihn direkt auf.
- **Grund:** …
- **Beispiel:** `Communicator` meldet `case_key_pressed`; der Titel hört zu (`src/ui/communicator/communicator.gd`).
- **Gegenbeispiel:** Ein Regal im Laden ruft `get_parent().kasse_aktualisieren()`.
- **Quelle:** Godot-Doku, „Scene organization“; Nystrom, „Observer“.
- **Schicht:** alle
- **Prüfweise:** Prüfer
- **Stand:** gilt seit 2026-…, Klaus
```

| Teil | Pflicht | Inhalt |
|---|---|---|
| Aussage | ja | ein bis drei Sätze, an einer Stelle im Code als eingehalten oder verletzt erkennbar |
| Grund | ja | warum, für dieses Spiel; kein allgemeiner Lehrsatz |
| Beispiel | ja | Stelle im eigenen Code mit Pfad; gibt es keine, ein ausgedachtes Beispiel aus dem Spiel, als solches gekennzeichnet |
| Gegenbeispiel | ja | wie ein Verstoß aussähe, möglichst aus dem Spiel |
| Quelle | ja | Abschnitt aus `docs/recherche/architektur-quellen.md`, aus der Verfassung oder „Klaus, Datum“ |
| Schicht | ja | alle, Kern, Oberfläche, Adventure, Wirtschaft oder Werkzeuge; mehrere möglich |
| Prüfweise | ja | „Prüfer“ oder „Test: `test_architektur.gd`, <Funktion>“ |
| Stand | ja | „Vorschlag“ (nur im Entwurf), „gilt seit JJJJ-MM-TT, Klaus“ oder „gilt ab dem ersten Feature der Schicht <Name>“ |

Eine Regel mit dem Stand „Vorschlag“ ist nicht gültig; nach Phase 1 gibt es keine mehr (SC-001).
Ist eine Regel für eine Schicht gedacht, die es noch nicht gibt, prüft der Prüfer sie bis dahin
nicht (Spec, Edge Cases).

## Muster

Je Muster ein Abschnitt mit: Name deutsch und englisch, Kern in einem Satz, Godot-Entsprechung, wo es
im Spiel gilt oder gelten wird, und die Regeln, die daraus folgen (mit AR-Nummer). Muster ohne Bezug
zum Spiel stehen nicht drin (FR-003); welche das sind, steht in research.md, R12.

## Schichten

Je Schicht: Vorbild (für Kern und Oberfläche: die Godot-Prinzipien), was übernommen wird, was nicht
und warum, die Regeln der Schicht (mit AR-Nummer). Werkzeuge sind keine eigene Schicht mit Vorbild;
der Abschnitt nennt nur, welche Regeln dort anders gelten.

## Ausnahmen

| Ort | Regel | Grund | Freigabe |
|---|---|---|---|
| `src/…:Zeile` | AR-NN | … | Klaus, JJJJ-MM-TT |

Dazu an der Stelle im Code: `# Ausnahme AR-NN: <Grund> (Klaus, JJJJ-MM-TT)` (R3). In einer Szene
(`.tscn`) steht der Kommentar im Skript des Knotens, der die Ausnahme braucht. Hat die Stelle kein
Skript, etwa ein Knoten ohne Skript oder eine Resource, reicht die Zeile in der Tabelle mit Datei und
Knoten (CHK010).

## Schwere

Der Abschnitt „So liest man eine Regel“ übernimmt die Tabelle „Schwere“ aus dem Vertrag
[architektur-pruefer.md](architektur-pruefer.md), damit Klaus und der Prüfer dieselbe sehen (CHK015).

## Geschichte

Je gestrichener oder geänderter Regel: Nummer, alter Wortlaut, was sich änderte, Grund, Datum, wer.
Form wie „bis 2026-10-20: im Vollbild“ (ki_dev, „Dokumentation und Entscheidungen“).

## Grenzen

- Der Leitfaden widerspricht der Verfassung nicht; wo er etwas aus ihr übernimmt, verweist er auf
  den Grundsatz (FR-006).
- Er regelt den Aufbau des Codes, nicht Stil, Texte oder Spielinhalt. Typisierung, Namen und
  Kommentare stehen weiter in `docs/spielbeschreibung/architektur.md`, „Code-Stil“, und gehören
  nicht zum Maßstab des Prüfers.
