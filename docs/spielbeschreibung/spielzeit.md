# Spielzeit

- **Worum es geht:** wie das Spiel Tage zählt und wie die Spieluhr die Zeit vorantreibt.
- **Laden, wenn:** etwas mit Datum, Tagen, Monaten, der Uhr oder dem Tempo zu tun hat.
- **Code:** `src/core/game_date.gd`, `src/core/game_clock.gd` (Autoload `GameClock`)
- **Herkunft:** `docs/features/01-01-spieluhr.md`, Feature 002 (negative Tage, Kalender-Ereignisse)
- **Stand:** Feature 003, 2026-10-27

## Spielzeitraum

Ein Spiel läuft vom 01.01.1985 bis zum 31.12.1999, 15 Jahre mit 5.478 Tagen. Alles im Spiel
rechnet in **Tagesindizes**:

| Tag | Index |
|---|---|
| 01.01.1985 | 0 |
| 31.12.1999 | 5477 (`TimelineRun.LAST_DAY`) |
| 31.12.1984 | −1 |
| 01.12.1984 | −31 |

Negative Indizes braucht nur die Zeitleiste: für jährliche Ereignisse, die vor Spielbeginn
anfangen, etwa den Winter 1984/85, und für den Tag −1, an dem ein Lauf vor dem ersten Spieltag
steht. Monate haben eigene Nummern, 0 (Januar 1985) bis 179 (Dezember 1999).

## GameDate

Ein Kalenderwert ohne Node (`RefCounted`) mit `year`, `month`, `day`. Intern rechnet alles über
den Tagesindex, das macht Vergleiche und Sprünge einfach. Schaltjahre stimmen.

- `to_day_index()` und `from_day_index()` rechnen in beide Richtungen, auch vor 1985.
- `from_iso("1993-03-22")` liest nur genau die Form `JJJJ-MM-TT` mit führenden Nullen, sonst
  `null`. So steht nach dem Speichern nie still ein anderes Format in einer Datei.
- `to_iso()` gibt `"1993-03-22"`, `str()` gibt `"22.03.1993"`, `to_label()` gibt `"März 1993"`.
- `is_valid(y, m, d)` prüft, ob es den Kalendertag gibt. Den 29.02.1989 gibt es nicht.

In Dateien stehen Tage immer als `"JJJJ-MM-TT"`, im Speicher als Index.

## GameClock

Autoload, das das aktuelle Datum hält und die Zeit vorantreibt. Andere Systeme messen keine Zeit
selbst, sie hängen sich an die Signale der Uhr.

| Signal | Wann |
|---|---|
| `day_passed(date)` | jeden neuen Tag |
| `month_passed(date)` | am Ersten eines Monats, nach `day_passed` |
| `year_passed(date)` | am 1. Januar, nach `month_passed` |
| `reached_end()` | wenn das Datum 1999 verlässt; die Uhr hält dann an |

- **Start:** 01.01.1985, pausiert (`paused = true`).
- **Laufen:** Ohne Pause zählt `_process()` mit `days_per_second` (Vorgabe 2,0) über einen
  Akkumulator hoch und ruft je vollem Tag `advance_day()` auf.
- **Schritte:** `advance_day()`, `advance_one_month()` (bis zum nächsten Monatsersten),
  `advance_one_year()` (bis zum nächsten 1. Januar). Jeder übersprungene Tag sendet seine Signale.
- **Pause:** `set_paused()`, `toggle_paused()`. `is_finished()` sagt, ob das Ende erreicht ist.

Die Zeitleiste hängt an `day_passed` (siehe [zeitleiste.md](zeitleiste.md)). Wer die Uhr im
Spiel startet und anhält, ist noch nicht gebaut; bisher pausiert die Uhr dauerhaft.

Jahreszeiten und Weihnachtsgeschäft kennt die Uhr nicht. Sie sind seit Feature 002 jährliche
Ereignisse im Katalog, das Signal `season_changed` gibt es nicht mehr.
