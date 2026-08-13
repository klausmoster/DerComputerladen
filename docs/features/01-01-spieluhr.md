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

Retrospektiv dokumentiert — das Feature war vor Einführung dieses Prozesses
bereits gebaut.

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

## + Offene Fragen

- **Toter Code:** `duplicate_date()`, `compare()`, `is_same_day()` und
  `advance_days()` sind definiert, werden aber nirgends aufgerufen. Entweder es
  gibt bald einen Nutzer dafür, oder sie sollten weg.
- **Kein anderer Spielstart als 1985-01-01 möglich.** `START_YEAR/MONTH/DAY` sind
  `const`. Gleichzeitig gibt es `Timeline.fast_forward_to()`, das genau dafür
  gedacht ist, den Markt auf einen späteren Stand zu bringen. Beides passt noch
  nicht zusammen — wenn ein späterer Spielstart gewollt ist, muss die Uhr auf
  ein Startdatum gesetzt werden können.
- **`season_changed` heißt irreführend.** Es gibt vier Jahreszeiten
  (`season()`), aber das Signal meldet nur den Wechsel des Weihnachtsgeschäfts.
  Entweder umbenennen (`holiday_season_changed`) oder auf echte Jahreszeiten
  erweitern.
- **`@export` auf einem Autoload** ist im Inspector nicht sinnvoll editierbar,
  weil Autoloads keine Szenendarstellung haben. Funktioniert, ist aber ein
  Geruch — als normale Variable mit Setter wäre es ehrlicher.
- **Kein Speichern/Laden** von `_day_index` → gehört zu 11-01.

## + Lernnotizen

Retrospektiv angelegt — keine Notizen aus der Bauzeit.
