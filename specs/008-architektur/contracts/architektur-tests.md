# Vertrag: Architektur-Tests

Datei: `src/test/test_architektur.gd`, `extends GutTest` (research.md, R6, R7). Baut der Godot-Agent
`[A]` in Phase 4. FR-008, SC-004.

Die Listen stehen seit dem Bestandsbericht fest (Klaus, 2026-10-28, T028): `BIS_BEHEBUNG` und
`VORGEMERKT` sind leer, weil keine der Abweichungen aus Phase 3 eine gemessene Regel betrifft; die
Stelle in `werkstatt.gd` ist eine begründete Ausnahme. Liefert eine Prüffunktion beim Bau weitere
Treffer, hält der Agent an und meldet sie, statt sie in eine Liste zu schreiben.

Welche Regeln messbar sind, hat Klaus mit dem Leitfaden festgelegt (2026-10-28): AR-01, AR-02 und
AR-03 wie geplant, dazu „kein globaler Zufall in Kernen“ (AR-08) und „Spiel kennt Werkzeuge nicht“
(AR-14). Die Probe „speichern, laden, vergleichen“ entfällt (Klaus, 2026-10-28).

## Konstanten

```gdscript
## Kerne außerhalb von core/timeline/ und core/save/, je mit Grund (AR-01).
const KERNE: Array[String] = [
	"res://core/game_date.gd",
	"res://scenes/title/key_sequence.gd",
	"res://scenes/title/menu_paper.gd",
	"res://scenes/title/title_texts.gd",
	"res://scenes/title/invaders/invaders_game.gd",
	"res://scenes/title/invaders/invaders_sprites.gd",
	"res://ui/ui_palette.gd",
	"res://tools/werkstatt/catalog_editor.gd",
	"res://tools/werkstatt/what_if_probe.gd",
	"res://tools/werkstatt/zebra.gd",
	"res://tools/selbsttest/selbsttest_ablage.gd",
	"res://tools/selbsttest/selbsttest_lauf.gd",
	"res://tools/selbsttest/selbsttest_protokoll.gd",
	"res://tools/selbsttest/selbsttest_texte.gd",
]

## Die Autoloads in dieser Reihenfolge, wie im Leitfaden (AR-03).
const AUTOLOADS: Array[String] = ["GameClock", "Timeline", "GameWindow", "GameSession"]

## Erlaubte Stellen je Prüfung: {"datei": …, "regel": "AR-NN", "grund": …}. Nur begründete
## Ausnahmen aus der Tabelle im Leitfaden.
const ERLAUBT_NACH_OBEN: Array[Dictionary] = [
	{"datei": "res://tools/werkstatt/werkstatt.gd", "regel": "AR-02",
		"grund": "GameWindow über /root/ anhalten; mit -s kennt GDScript den Namen nicht"},
]

## Abweichungen, die Phase 5 behebt. Wird mit Phase 5 leer.
const BIS_BEHEBUNG: Array[Dictionary] = [
	{"datei": "res://tools/selbsttest/selbsttest_ergebnis.gd", "regel": "AR-02",
		"grund": "B1: GameWindow über /root/; Naht kommt in T036a"},
]

## Abweichungen, die Klaus als eigenes Feature vorgemerkt hat: {"datei": …, "regel": "AR-NN",
## "feature": Eintrag in Feature_Ideas.md}. Leert sich mit dem Feature, das sie behebt.
const VORGEMERKT: Array[Dictionary] = []
```

## Prüffunktionen

Jede nimmt einen Pfad oder Text, damit die Fehlerprobe dieselben Funktionen an Kopien außerhalb des
Repos aufruft (wie `test_bilder.gd`):

| Funktion | Gibt zurück | Regel |
|---|---|---|
| `kern_verstoesse(quelltext: String) -> Array[String]` | Gründe, warum der Text kein Kern ist: erbt nicht von `RefCounted` oder `Resource`, nennt ein Autoload, ruft `get_tree()` oder `Engine.get_main_loop()`, ruft globalen Zufall nach AR-08: `randi()`, `randf()`, `randi_range()`, `randf_range()`, `randfn()`, `randomize()` ohne Objekt davor, oder `.shuffle()` und `.pick_random()` auf einem Array. Aufrufe auf einem eigenen Würfel wie `dice.randf()` oder `_rng.randi_range(…)` sind erlaubt | AR-01, AR-08 |
| `autoloads_aus(project_godot: String) -> Array[String]` | Namen der Autoloads in Reihenfolge | AR-03 |
| `wege_nach_oben(quelltext: String) -> Array[int]` | Zeilen mit `../` in einem Knotenpfad oder `/root/` | AR-02 |
| `verweise_auf_werkzeuge(quelltext: String) -> Array[int]` | Zeilen mit `res://tools/` | AR-14 |

Kommentare und Zeichenketten in Doku-Kommentaren zählen nicht als Treffer; der kleine Leser aus
`test_texte.gd` trennt Code, Zeichenkette und Kommentar und wird wiederverwendet oder nachgebaut.

## Tests

| Test | prüft |
|---|---|
| `test_kerne_ohne_node` | jedes Skript in `core/timeline/`, `core/save/` und `KERNE`: `kern_verstoesse` leer |
| `test_genau_diese_autoloads` | `autoloads_aus(project.godot) == AUTOLOADS` |
| `test_kein_weg_nach_oben` | alle Skripte und Szenen unter `src/` ohne `addons/` und `test/`: Treffer nur an Stellen in `ERLAUBT_NACH_OBEN`, `BIS_BEHEBUNG` oder `VORGEMERKT` |
| `test_spiel_kennt_werkzeuge_nicht` | alle Skripte und Szenen unter `src/` außer `tools/`, `addons/` und `test/`: `verweise_auf_werkzeuge` leer |
| `test_listen_ohne_leichen` | jeder Eintrag in `KERNE`, `ERLAUBT_NACH_OBEN`, `BIS_BEHEBUNG` und `VORGEMERKT` zeigt auf eine Datei und Stelle, die es gibt und die noch trifft |
| `test_ausnahmen_wie_im_leitfaden` | jeder Eintrag in `ERLAUBT_NACH_OBEN` steht in der Tabelle „Ausnahmen“ von `docs/architektur-leitfaden.md`; der Test liest die Datei über `ProjectSettings.globalize_path("res://")` und `..` |

Testnamen und Meldungen deutsch; jede Meldung nennt Datei, Zeile und AR-Nummer.

## Auslegungen beim Bau (T031, Claude, 2026-10-28)

Vom Godot-Agent gemeldet, von Claude geprüft und übernommen:
- Ein Eintrag in einer Liste erlaubt genau eine Stelle; die Einträge haben keine Zeile. Ein zweites
  `/root/` in `werkstatt.gd` würde rot, ein Eintrag ohne Stelle meldet der Test gegen Leichen.
- Nur `test_kein_weg_nach_oben` liest die Listen. Ein Eintrag mit einer anderen Regel als AR-02 ist
  deshalb ein Fehler der Liste.
- Eine Zeichenkette mit `://` ist ein Dateipfad, nie ein Knotenpfad.
- Gezählt werden wörtlich `../` und `/root/`; `get_node("..")` und `"/root"` ohne Schrägstrich
  nicht. Heute gibt es keine solche Stelle; erweitert wird erst, wenn eine auftaucht.
- Nach der Nachprüfung von 007 (T035; Klaus, 2026-10-28): In Skripten zählt `../` nur in einem
  Knotenpfad, also in `^"…"`, `$…`, `NodePath(…)` und als Text in `get_node()`,
  `get_node_or_null()`, `has_node()`; `"../Resources"` in `path_join()` ist ein Dateipfad im
  App-Paket und wurde vorher fälschlich gemeldet. `/root/` zählt weiter überall, in Szenen beides wie
  bisher. `KERNE` bekommt die vier Kerne des Selbsttests; `selbsttest_system.gd` (Dienste der Engine)
  und `selbsttest_logger.gd` (erbt von `Logger`) nicht (Leitfaden, AR-01).
- Ein Kern erbt wörtlich von `RefCounted` oder `Resource` oder hat kein `extends`; eine eigene
  Resource-Klasse als Basis würde gemeldet.
- `.shuffle()` und `.pick_random()` zählen auf jedem Objekt; `rng.randomize()` auf einem eigenen
  Würfel prüft der Prüfer, nicht der Test.
- Geprüft werden `.gd` und `.tscn`, keine `.tres`.
- Meldungen: Einzahl bei 1, AR-Nummer einmal (Phasenprüfung T033).

## Fehlerprobe

Der Agent zeigt für jede Prüffunktion an einer Kopie außerhalb des Repos (`OS.get_cache_dir()` oder
`user://test_architektur/`), dass ein eingebauter Verstoß gefunden wird und eine erlaubte Stelle
daneben nicht: ein Kern mit `extends Node`, ein Kern mit `GameSession.`, ein Kern mit `randf()` (und
daneben erlaubt `_rng.randf()` auf einem eigenen Würfel), ein fünftes Autoload, ein
`get_node("../Kasse")`, ein `load("res://tools/werkstatt/zebra.gd")` im Spiel. Das Ergebnis steht in der Lernnotiz.
