---
feature_id: "01-02"
feature_name: "Ereignis-Engine"
feature_system: "01 Zeitleiste"
feature_status: "fertig"
feature_phase: "tasks"
godot_knoten:
- "Timeline (Autoload, Node)"
godot_dateien:
- "src/core/timeline.gd"
- "src/core/timeline_event.gd"
- "src/core/event_effect.gd"
- "src/data/event_database.gd"
godot_signale_raus:
- "event_fired(event: TimelineEvent, date: GameDate)"
- "effect_applied(effect: EventEffect, source: TimelineEvent, date: GameDate)"
godot_signale_rein:
- "GameClock.day_passed"
- "GameClock.month_passed"
lernen_ziele:
- "Custom Resource als Datencontainer"
- "@export_group und @export_range im Inspector"
- "enum in GDScript und Category.keys()"
- "Signale weiterreichen statt Logik verdrahten"
lernen_neue_konzepte:
- "Resource vs. RefCounted"
- "typisierte Arrays (Array[EventEffect])"
- "RandomNumberGenerator statt randf()"
bezug_haengt_ab_von:
- "01-01"
bezug_blockiert:
- "03-01"
- "03-02"
- "08-01"
tags:
- feature
---
# 01-02 Ereignis-Engine

## + Problem

Das Spiel lebt davon, dass die Welt sich ohne Zutun des Spielers verändert: Der
Pentium erscheint und macht den 486 über Nacht zur Mittelklasse. Windows 95 kommt
und plötzlich braucht jeder eine Maus und mehr RAM. Nebenan eröffnet ein
Konkurrent.

Zwei Sorten von Ereignissen, die sich grundlegend unterscheiden: **historische**
liegen fest und sind für jedes Spiel gleich — sie bilden die echte PC-Geschichte
ab. **Zufällige** hängen von Glück und Spielstand ab und machen jeden Durchlauf
anders.

Und beide müssen **Kettenreaktionen** auslösen können, sonst bleibt es bei
Meldungen ohne Folgen.

## + Lösung

Eine Engine, die an der Spieluhr hängt und beides abwickelt: Historische
Ereignisse feuern an ihrem Datum, zufällige werden monatlich ausgewürfelt — mit
Wahrscheinlichkeit, Zeitfenster, Höchstzahl und Mindestabstand.

Jedes Ereignis trägt eine Liste von Auswirkungen. Entscheidend: **die Engine
wendet sie nicht an.** Sie meldet sie per Signal und überlässt es Wirtschaft,
Nachfrage und Reputation, darauf zu reagieren. Damit kann die Zeitleiste fertig
sein, bevor es die Systeme gibt, die sie beeinflusst.

Auswirkungen können verzögert eintreten („RAM-Nachfrage steigt, aber erst zwei
Wochen später") und ein Ereignis kann ein weiteres auslösen.

## + Technischer Vertrag

**`src/core/event_effect.gd`** — `class_name EventEffect extends Resource`

```gdscript
enum Kind { PREIS, NACHFRAGE, REPUTATION, KUNDENSTROM, PRESSE, SPAWN }

@export var kind: Kind = Kind.PRESSE
@export var target: String = ""      # "cpu_486", "ram", "modem", "*"
@export var magnitude: float = 0.0   # relativ: -0.30 = -30 %
@export var delay_days: int = 0
@export_multiline var note: String = ""

func kind_label() -> String
func describe() -> String
```

Bei `Kind.SPAWN` ist `target` keine Warengruppe, sondern die `id` eines anderen
registrierten Ereignisses.

**`src/core/timeline_event.gd`** — `class_name TimelineEvent extends Resource`

```gdscript
enum Category { HARDWARE, SOFTWARE, TECH, WIRTSCHAFT, LOKAL,
                KONKURRENZ, KUNDE, REKLAMATION, LIEFERUNG }

@export var id: String
@export var title: String
@export_multiline var description: String
@export var category: Category
@export var is_fixed: bool = true

@export_group("Fixes Datum")
@export var year: int; @export var month: int; @export var day: int

@export_group("Variabel")
@export_range(0.0, 1.0, 0.01) var monthly_chance: float
@export var earliest_year: int; @export var latest_year: int
@export var max_occurrences: int   # 0 = unbegrenzt
@export var cooldown_days: int

@export_group("Wirkung")
@export var effects: Array[EventEffect]

func trigger_day_index() -> int
func can_occur(date: GameDate, occurrences: int,
               last_fired_day: int, current_day: int) -> bool
func category_label() -> String
```

**`src/core/timeline.gd`** — Autoload `Timeline`, `extends Node`

```gdscript
signal event_fired(event: TimelineEvent, date: GameDate)
signal effect_applied(effect: EventEffect, source: TimelineEvent, date: GameDate)

var fixed_events: Array[TimelineEvent]
var variable_events: Array[TimelineEvent]
var history: Array[Dictionary]   # { event: TimelineEvent, day_index: int }

func register_event(event: TimelineEvent) -> void
func fast_forward_to(date: GameDate) -> void
```

Ablauf: `_ready()` lädt aus `EventDatabase` und verbindet sich mit
`GameClock.day_passed` (fixe Ereignisse + fällige verzögerte Effekte) und
`GameClock.month_passed` (Würfelrunde für variable Ereignisse). Fixe Ereignisse
liegen in `_fixed_by_day: Dictionary` (Tagesindex → Array), damit pro Tag nur
ein Lookup nötig ist.

**`src/data/event_database.gd`** — `class_name EventDatabase extends RefCounted`

```gdscript
static func build_fixed_events() -> Array[TimelineEvent]     # 19 Ereignisse
static func build_variable_events() -> Array[TimelineEvent]  #  6 Ereignisse
```

**Nicht dazu gehört:** das Anwenden der Effekte (Abnehmer bauen 03-01, 03-02,
08-01), das Speichern der Historie (→ 11-01), eine Ereignis-Anzeige im Spiel
(→ 10-xx). Die Demo-UI loggt nur.

## + Schritte

Retrospektiv dokumentiert — das Feature war vor Einführung dieses Prozesses
bereits gebaut.

## + Akzeptanzkriterien

- Beim Start sind 19 fixe und 6 variable Ereignisse registriert.
- Am 22.03.1993 feuert `intel_pentium` und meldet sofort `PREIS cpu_486 -30 %`.
- Der verzögerte Effekt desselben Ereignisses (`NACHFRAGE ram +20 %`,
  `delay_days: 14`) wird am 05.04.1993 gemeldet, nicht vorher.
- Der `KUNDENSTROM`-Effekt der Wiedervereinigung (03.10.1990, `delay_days: 60`)
  erscheint am 02.12.1990.
- Ein variables Ereignis mit `cooldown_days: 365` feuert im Folgemonat nicht
  erneut, auch wenn der Würfel es zulassen würde.
- Projekt startet fehlerfrei:
  `Godot --headless --path src res://scenes/timeline_demo.tscn --quit-after 60`
  → keine Ausgabe, Exit 0. (Geprüft mit Godot 4.6.3.)

## + Entscheidungen

**Signal statt direkter Anwendung.** Die Engine könnte Preise selbst ändern.
Dann müsste sie aber Preise, Nachfrage, Reputation und Kundenstrom kennen — und
wäre erst baubar, wenn all das existiert. Über `effect_applied` ist die
Zeitleiste fertig, bevor es einen einzigen Abnehmer gibt. Genau das war hier der
Fall.

**`target` als freier String statt Enum.** Ein Enum wäre typsicher, müsste aber
bei jeder neuen Warengruppe erweitert werden — und die Warengruppen stehen noch
nicht fest, weil sie aus der game_bible kommen. Bewusst in Kauf genommene
Unschärfe; Preis siehe Offene Fragen.

**Fixe Ereignisse in einem Dictionary nach Tagesindex.** Alternative wäre, jeden
Tag über alle Ereignisse zu laufen. Bei 19 Ereignissen egal, aber die Datenbank
soll wachsen, und `GameClock` kann bis 60 Tage/Sekunde ticken.

**Ereignisse in GDScript statt in `.tres`-Dateien.** `TimelineEvent` ist eine
`Resource`, könnte also im Inspector angelegt werden. In Code sind 25 Ereignisse
in einer Datei überblickbar, diffbar und ohne Editor änderbar. Bei mehreren
hundert kippt das — dann wird es ein Fall für 02-01.

## + Offene Fragen

- **`fast_forward_to()` läuft nicht garantiert chronologisch.** Es iteriert
  `_fixed_by_day.keys()` in Einfügereihenfolge, nicht nach Tagesindex sortiert.
  Heute stimmt die Reihenfolge nur, weil `EventDatabase` die Ereignisse zufällig
  chronologisch anlegt. Sortieren, bevor jemand ein Ereignis an der falschen
  Stelle einfügt.
- **`fast_forward_to()` staut verzögerte Effekte auf.** Es reiht sie mit einem
  `apply_day` in der Vergangenheit ein; sie feuern dann alle gebündelt am ersten
  echten Spieltag. Vermutlich sollten sie beim Vorspulen entweder sofort oder
  gar nicht gemeldet werden.
- **SPAWN hat keinen Zyklenschutz.** Ereignis A spawnt B, B spawnt A → endlose
  Rekursion in `_dispatch_effect()`. Aktuell nutzt kein Ereignis `SPAWN`, das
  Problem ist also latent, nicht akut.
- **`_find_event()` konkateniert bei jedem Aufruf** `fixed_events + variable_events`
  und sucht linear. Ein `Dictionary` id→Event beim Registrieren wäre die
  naheliegende Korrektur — vor allem, weil `id` ohnehin schon als Schlüssel für
  `_occurrences` und `_last_fired_day` dient.
- **Keine Validierung der `target`-Strings.** Ein Tippfehler (`"cpu_468"`) fällt
  nirgends auf — der Effekt feuert, kein Abnehmer reagiert, niemand merkt es.
  Spätestens wenn 03-01 existiert, braucht es eine Liste gültiger Ziele oder
  eine Warnung bei unbekanntem `target`.
- **Im Januar 1985 findet keine Würfelrunde statt**, weil variable Ereignisse an
  `month_passed` hängen und das erst beim Wechsel auf Februar feuert.
- **`history` wächst unbegrenzt** und wird nirgends gelesen. Gedacht für Rückblick
  und Speicherstand (→ 11-01).
- **`can_occur()` kennt nur den Kalender, nicht den Spielzustand.** Übergeben
  werden Datum, bisherige Auslösungen, letzter Auslösetag und der heutige Tag —
  mehr nicht. Damit trifft eine Reklamationswelle mit 3 % pro Monat, egal ob der
  Spieler Markenware oder Schrott vom windigen Händler verkauft hat, und der
  Großkunde meldet sich unabhängig vom Ruf des Ladens. Zufall ohne Ursache.
  Damit sich das Spiel ursächlich anfühlt, müssen variable Ereignisse den
  Spielzustand sehen können — Reputation, Warenqualität, Standort. Wird spätestens
  bei 08-02 (Reklamationen) gebraucht, wo genau diese Rückkopplung den Kern des
  Features ausmacht.
- **Die Wahrscheinlichkeit lässt sich zur Laufzeit zwar ändern, aber nicht
  sauber.** `monthly_chance` ist eine gewöhnliche Variable auf einem lebenden
  Objekt, und `_roll_variable_events()` liest sie bei jeder Würfelrunde neu —
  ein Zuweisen wirkt also sofort. Was fehlt, ist alles drumherum:
  - **Kein Zugriff von außen.** `_find_event()` ist privat; es gibt kein
    öffentliches `Timeline.get_event(id)`. Wer die Chance ändern will, müsste
    selbst durch `Timeline.variable_events` suchen.
  - **Kein Weg zurück.** Wer den Grundwert überschreibt, verliert ihn. Es gibt
    keinen Begriff von „Zuschlag mit Ursache und Dauer", also auch keine
    Möglichkeit, eine Erhöhung wieder zurückzunehmen oder dem Spieler zu
    erklären, warum etwas gerade wahrscheinlicher ist.
  - **Wird nicht gespeichert.** Die Ereignisse werden bei jedem Start frisch aus
    `EventDatabase` gebaut. Ein geänderter Wert fällt beim Laden still auf den
    Ausgangswert zurück (→ 11-01).

  Naheliegende Lösung: Grundwert unangetastet lassen und die wirksame Chance aus
  Grundwert plus benannten Zuschlägen berechnen. Dann ist nachvollziehbar,
  woher eine Änderung kommt, und sie lässt sich einzeln wieder entfernen.

## + Lernnotizen

Retrospektiv angelegt — keine Notizen aus der Bauzeit.
