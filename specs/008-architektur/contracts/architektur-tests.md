# Vertrag: Architektur-Tests

Datei: `src/test/test_architektur.gd`, `extends GutTest` (research.md, R6, R7). Baut der Godot-Agent
`[A]` in Phase 4. FR-008, SC-004.

Welche Regeln messbar sind, hat Klaus mit dem Leitfaden festgelegt (2026-10-28): AR-01, AR-02 und
AR-03 wie geplant, dazu „kein globaler Zufall in Kernen“ (AR-08) und „Spiel kennt Werkzeuge nicht“
(AR-14). Die Probe „speichern, laden, vergleichen“ entfällt (Klaus, 2026-10-28).

## Konstanten

```gdscript
## Kerne außerhalb von core/timeline/ und core/save/, je mit Grund (AR-01).
const KERNE: Array[String] = [
	"res://core/game_date.gd",
	"res://scenes/title/key_sequence.gd",
	"res://scenes/title/invaders/invaders_game.gd",
	# … endgültige Liste nach dem Bestandsbericht
]

## Die Autoloads in dieser Reihenfolge, wie im Leitfaden (AR-03).
const AUTOLOADS: Array[String] = ["GameClock", "Timeline", "GameWindow", "GameSession"]

## Erlaubte Stellen je Prüfung: {"datei": …, "regel": "AR-NN", "grund": …}. Nur begründete
## Ausnahmen aus der Tabelle im Leitfaden.
const ERLAUBT_NACH_OBEN: Array[Dictionary] = []

## Abweichungen, die Phase 5 behebt. Wird mit Phase 5 leer.
const BIS_BEHEBUNG: Array[Dictionary] = []

## Abweichungen, die Klaus als eigenes Feature vorgemerkt hat: {"datei": …, "regel": "AR-NN",
## "feature": Eintrag in Feature_Ideas.md}. Leert sich mit dem Feature, das sie behebt.
const VORGEMERKT: Array[Dictionary] = []
```

## Prüffunktionen

Jede nimmt einen Pfad oder Text, damit die Fehlerprobe dieselben Funktionen an Kopien außerhalb des
Repos aufruft (wie `test_bilder.gd`):

| Funktion | Gibt zurück | Regel |
|---|---|---|
| `kern_verstoesse(quelltext: String) -> Array[String]` | Gründe, warum der Text kein Kern ist: erbt nicht von `RefCounted` oder `Resource`, nennt ein Autoload, ruft `get_tree()` oder `Engine.get_main_loop()`, ruft `randi()`, `randf()`, `randi_range()`, `randf_range()` oder `randomize()` ohne eigenen `RandomNumberGenerator` | AR-01, AR-08 |
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

## Fehlerprobe

Der Agent zeigt für jede Prüffunktion an einer Kopie außerhalb des Repos (`OS.get_cache_dir()` oder
`user://test_architektur/`), dass ein eingebauter Verstoß gefunden wird und eine erlaubte Stelle
daneben nicht: ein Kern mit `extends Node`, ein Kern mit `GameSession.`, ein Kern mit `randf()` (und
daneben erlaubt `_rng.randf()` auf einem eigenen Würfel), ein fünftes Autoload, ein
`get_node("../Kasse")`, ein `load("res://tools/werkstatt/zebra.gd")` im Spiel. Das Ergebnis steht in der Lernnotiz.
