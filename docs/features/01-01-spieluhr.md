---
feature_id: "01-01"
feature_name: "Spieluhr"
feature_system: "01 Zeitleiste"
feature_status: "fertig"
feature_phase: "tasks"
godot_knoten:
- "GameClock (Autoload, Node)"
godot_dateien:
- "src/core/game_date.gd"
- "src/core/game_clock.gd"
godot_signale_raus:
- "day_passed(date: GameDate)"
- "month_passed(date: GameDate)"
- "year_passed(date: GameDate)"
- "season_changed(is_holiday_season: bool)"
- "reached_end()"
godot_signale_rein: []
lernen_ziele:
- "Autoload/Singleton in Godot"
- "Signale als Entkopplung statt direkter Aufrufe"
- "_process(delta) und Akkumulator-Muster"
lernen_neue_konzepte:
- "class_name vs. Autoload"
- "RefCounted als leichtgewichtiger Wertetyp"
bezug_haengt_ab_von: []
bezug_blockiert:
- "01-02"
- "03-01"
- "11-01"
tags:
- feature
---
# 01-01 Spieluhr

## + Problem

Eine Wirtschaftssimulation über fünfzehn Jahre braucht eine Zeitachse, an der
alles andere hängt: Preise fallen über Monate, das Weihnachtsgeschäft kommt
jährlich, Hardware erscheint an festen Daten. Ohne eine zentrale Uhr würde jedes
System seine eigene Zeit mitzählen — und sie würden auseinanderlaufen.

Dazu kommt: Zeit muss **springen** können. Der Spieler will einen Monat
überspringen, wenn nichts los ist, und Tag für Tag gehen, wenn es spannend wird.

## + Lösung

Eine einzige Uhr für das ganze Spiel, die von 1985-01-01 bis 1999-12-31 läuft.
Sie kann automatisch ticken (mit einstellbarem Tempo) oder schrittweise
weitergeschaltet werden — einen Tag, einen Monat, ein Jahr.

Andere Systeme messen keine Zeit selbst, sie hören zu: „sag mir Bescheid, wenn
ein Tag vorbei ist". Damit gibt es genau eine Wahrheit über das Datum.

## + Technischer Vertrag

**`src/core/game_date.gd`** — `class_name GameDate extends RefCounted`

Kalender-Wert, kein Node. Rechnet intern über einen absoluten Tagesindex
(1985-01-01 = 0), damit Vergleiche und Sprünge trivial sind.

```gdscript
const EPOCH_YEAR := 1985

func _init(p_year := EPOCH_YEAR, p_month := 1, p_day := 1) -> void
static func is_leap_year(y: int) -> bool
static func days_in_month(y: int, m: int) -> int
static func from_day_index(index: int) -> GameDate
func to_day_index() -> int
func duplicate_date() -> GameDate
func compare(other: GameDate) -> int     # <0 vorher, 0 gleich, >0 nachher
func is_same_day(other: GameDate) -> bool
func is_holiday_season() -> bool         # November oder Dezember
func season() -> String                  # "Winter" | "Frühling" | "Sommer" | "Herbst"
func _to_string() -> String              # "01.03.1993"
func to_label() -> String                # "März 1993"
```

**`src/core/game_clock.gd`** — Autoload `GameClock`, `extends Node`

Registriert in `src/project.godot` unter `[autoload]` als
`GameClock="*res://core/game_clock.gd"`.

```gdscript
signal day_passed(date: GameDate)
signal month_passed(date: GameDate)
signal year_passed(date: GameDate)
signal season_changed(is_holiday_season: bool)
signal reached_end()

const START_YEAR := 1985
const START_MONTH := 1
const START_DAY := 1
const END_YEAR := 1999

@export var days_per_second: float = 2.0
var paused: bool = true
var date: GameDate

func advance_day() -> void
func advance_days(count: int) -> void
func advance_one_month() -> void    # bis zum Ersten des Folgemonats
func advance_one_year() -> void     # bis zum 1. Januar des Folgejahres
func set_paused(value: bool) -> void
func toggle_paused() -> void
func is_finished() -> bool
```

Reihenfolge beim Tageswechsel ist verbindlich: erst `day_passed`, dann bei
Monats-/Jahreswechsel `month_passed`/`year_passed`, dann `season_changed` — und
nur, wenn sich `is_holiday_season()` gegenüber dem Vortag geändert hat.

**Nicht dazu gehört:** Uhrzeit innerhalb eines Tages, Feiertagskalender,
Speichern/Laden des Datums (→ 11-01), Zeitzonen.

## + Schritte

Gebaut wurde das Feature vor Einführung dieses Prozesses; die Dokumentation
entstand retrospektiv. Offen ist eine Aufräumrunde aus den Punkten 1, 3 und 4
der offenen Fragen — **erledigt am 13.08.2026**:

1. `[K]` `duplicate_date()`, `compare()`, `is_same_day()` aus `game_date.gd`
   entfernen.
2. `[K]` Headless laufen lassen — muss weiterhin sauber durchgehen.
3. `[K]` `advance_days()` aus `game_clock.gd` entfernen.
4. `[K]` `@export` bei `days_per_second` entfernen (Autoloads haben keine Szene,
   in der sich die Property vorbelegen ließe — das Attribut verspricht etwas,
   das es nicht gibt).
5. `[K]` Headless laufen lassen.
6. `[C]` Review gegen die Akzeptanzkriterien, Entscheidungen und Lernnotizen
   ins Dokument schreiben.

**Entfallen:** Das Signal `season_changed` sollte ursprünglich in
`holiday_season_changed` umbenannt werden. Stattdessen fällt es später ganz weg —
Jahreszeiten und Weihnachtsgeschäft werden zu Ereignissen in der Timeline
(→ 01-06). Deshalb hier nicht anfassen.

Aufteilung ist ein Vorschlag — Schritte wandern im Gespräch.

## + Akzeptanzkriterien

- `GameDate.from_day_index(d.to_day_index())` liefert wieder `d` — für jedes
  Datum im Zeitraum.
- Schaltjahre stimmen: 1988, 1992, 1996 haben 366 Tage; 1900-Regel greift im
  Zeitraum nicht.
- `advance_one_month()` vom 15.03. landet auf dem 01.04., nicht auf dem 15.04.
- Die Uhr stoppt nach dem 31.12.1999: `is_finished()` wird `true`, `paused` wird
  gesetzt, `reached_end` feuert genau einmal.
- `season_changed` feuert nur an zwei Tagen im Jahr — am 01.11. (`true`) und am
  01.01. (`false`).
- Projekt startet fehlerfrei:
  `Godot --headless --path src res://scenes/timeline_demo.tscn --quit-after 60`
  → keine Ausgabe, Exit 0. (Geprüft mit Godot 4.6.3.)
- Die Testsuite läuft durch:
  `Godot --headless --path src -s res://addons/gut/gut_cmdln.gd`
  → alle Tests grün. Achtung: Diese Tests decken bisher die Ereignis-Datenbank
  ab, nicht den Kalender selbst — siehe Offene Fragen.

## + Entscheidungen

**Absoluter Tagesindex statt Y/M/D-Arithmetik.** Alternative wäre gewesen, direkt
auf Jahr/Monat/Tag zu rechnen. Über einen Index sind Vergleich, Differenz und
„in 14 Tagen" triviale Ganzzahl-Operationen — und die Timeline kann Ereignisse in
einem Dictionary nach Tagesindex ablegen. Der Preis ist die Umrechnung in
`from_day_index()`, die über die Jahre schleift.

**`RefCounted` statt `Resource` für `GameDate`.** Ein Datum ist ein Wert, keine
speicherbare Ressource. `RefCounted` ist leichter und wird nicht versehentlich
in eine `.tres` serialisiert.

**Uhr als Autoload statt als Node in der Szene.** Jedes System braucht die Zeit;
ein Autoload ist von überall erreichbar, ohne dass Szenen sich gegenseitig
kennen müssen. Nachteil siehe Offene Fragen.

**Akkumulator statt Timer-Node.** `_process(delta)` mit Akkumulator macht das
Tempo stufenlos einstellbar und entkoppelt die Spielzeit von der Framerate.

**Ungenutzte Methoden gelöscht statt aufgehoben** (Aufräumrunde 08/2026).
`duplicate_date()`, `compare()`, `is_same_day()` und `advance_days()` wurden
nirgends aufgerufen. Alternative wäre gewesen, sie „für später" stehen zu lassen.
Dagegen sprach: Ungenutzter Code wird nie ausgeführt und damit nie geprüft — er
ist Behauptung, nicht Wahrheit. `compare()` war dafür das Beispiel: Der Name
verspricht einen Vergleich (−1/0/1), zurück kam die Tagesdifferenz. Wiederholen
lässt sich das über `git log -S` in Minuten.

**`@export` bei `days_per_second` entfernt.** `@export` blendet eine Property im
Inspector ein — für einen Node in einer Szene. `GameClock` wird als Autoload
direkt aus dem Skript erzeugt (`GameClock="*res://core/game_clock.gd"`), hat also
keine Szene, in der sich ein Wert vorbelegen ließe. Das Attribut versprach eine
Einstellmöglichkeit, die es nicht gab. Wäre der Wert wirklich zur Entwurfszeit
einstellbar gewesen, hätte man das Autoload als `.tscn` registrieren müssen —
Aufwand ohne Ertrag für einen Wert, den die UI zur Laufzeit setzt.

## + Offene Fragen

- **Kein anderer Spielstart als 1985-01-01 möglich.** `START_YEAR/MONTH/DAY` sind
  `const`. Gleichzeitig gibt es `Timeline.fast_forward_to()`, das genau dafür
  gedacht ist, den Markt auf einen späteren Stand zu bringen. Beides passt noch
  nicht zusammen — wenn ein späterer Spielstart gewollt ist, muss die Uhr auf
  ein Startdatum gesetzt werden können.
- **`season_changed` heißt irreführend.** Es gibt vier Jahreszeiten
  (`season()`), aber das Signal meldet nur den Wechsel des Weihnachtsgeschäfts.
  Wird sich mit 01-06 erledigen: Dann fällt das Signal ganz weg, weil
  Jahreszeiten und Weihnachtsgeschäft zu Ereignissen in der Timeline werden.
- **Kein Speichern/Laden** von `_day_index` → gehört zu 11-01.
- **Für `GameDate` gibt es noch keine Tests.** Die Testabdeckung liegt bisher auf
  der Ereignis-Datenbank. Schaltjahre, `from_day_index()`/`to_day_index()` im
  Kreis und die Monatsgrenzen bei `advance_one_month()` sind alle prüfbar und
  bisher ungeprüft — die Akzeptanzkriterien oben stehen als Behauptung da, nicht
  als Test.

## + Lernnotizen

Aus der Aufräumrunde (erste eigene Godot-Sitzung):

- **Der Godot-Projektordner ist `src/`**, nicht das Repo-Root. Im Project Manager
  über *Import* die Datei `src/project.godot` öffnen.
- **`F5` startet das Projekt** (oder der ▶-Knopf oben rechts). Fehler landen
  unten im Panel *Ausgabe*.
- **„Headless"** heißt: dasselbe Programm ohne Fenster, vom Terminal gestartet.
  Braucht man für automatische Prüfungen, im Alltag reicht `F5`.
- **Autoloads stehen in `project.godot`** unter `[autoload]`. Der Stern in
  `GameClock="*res://core/game_clock.gd"` heißt „aktiviert".
- **`@export` wirkt nur bei Nodes in einer Szene.** Bei einem Autoload, das direkt
  aus einem Skript erzeugt wird, bewirkt es nichts.
- **Ein Addon muss aktiviert werden**, nicht nur heruntergeladen:
  Projekt → Projekteinstellungen → Reiter *Plugins*. Vorher taucht kein Panel auf.
- **GUT hat zwei getrennte Konfigurationen.** Das Panel im Editor führt seine
  eigene (außerhalb des Projekts, in Godots Benutzerdaten), der
  Kommandozeilen-Lauf liest `res://.gutconfig.json`. Was man im Panel einträgt,
  gilt nicht fürs Terminal und umgekehrt.
- **Testordner im Panel:** Abschnitt *Test Directories*, erstes Feld `res://test`.
