# Spielstände

- **Worum es geht:** was ein Spielstand enthält, wie er als Datei aussieht, wie er sicher
  geschrieben, gelesen, geprüft und gelöscht wird.
- **Laden, wenn:** Speichern, Laden oder das Dateiformat betroffen sind, ein neues System
  mitgespeichert werden muss oder die Liste der Spielstände sich ändert.
- **Code:** `src/core/save/save_game.gd`, `save_slot.gd`, `save_store.gd`;
  `src/core/timeline/intervention_file.gd`; Tests `src/test/test_save_game.gd`,
  `test_save_store.gd`, `test_save_resume_run.gd`, `test_intervention_file.gd`, Fixtures
  `src/test/fixtures/spielstaende/`
- **Herkunft:** `specs/004-neues-spiel/` (`contracts/spielstand.md`, `data-model.md`, `research.md`
  R1 bis R5, R10); Zeitzone aus `specs/007-build-export-selbsttest/research.md` R7
- **Stand:** Feature 007, 2026-10-28
- **Nachbarn:** wer speichert und fortsetzt in [spielablauf.md](spielablauf.md), die Liste auf dem
  Titelbildschirm in [titel-und-hauptmenue.md](titel-und-hauptmenue.md)

## Idee

Ein Spielstand speichert nicht den ganzen Zustand, sondern das, woraus er wieder entsteht: **Seed,
Grad, Katalog und Eingriffsprotokoll** ergeben genau einen Fahrplan (siehe
[zeitleiste.md](zeitleiste.md)). Dazu kommen Spieldatum, Name, Nummer und Zeitpunkte. Beim
Fortsetzen baut die Zeitleiste den Fahrplan neu und spielt still bis zum Spieldatum.

Der Spielstand nimmt beim Anlegen eine **eigene Kopie des Katalogs** samt Profilen mit und läuft
damit weiter. Ändert Klaus danach den Katalog in der Werkstatt, gilt das erst ab dem nächsten neuen
Spiel. So kann sich die Vergangenheit eines laufenden Spiels nie verschieben.

## Klassen

| Klasse | Aufgabe |
|---|---|
| `SaveGame` | der Inhalt eines Spielstands; `to_json()` und `from_data()` |
| `SaveSlot` | ein Eintrag der Liste, auch wenn die Datei nicht lesbar ist: Zustand und Grund |
| `SaveStore` | der Ordner: auflisten, nächste Nummer, sicher schreiben, löschen |
| `InterventionFile` | Eingriffe in Dateien: Tage als `"JJJJ-MM-TT"`, Werte auf vier Stellen; teilen sich Spielstand und Probe der Werkstatt |

Alle ohne Node. Gespeichert und fortgesetzt wird nur über `GameSession`.

## Die Datei

Je Spielstand eine Datei `spiel_<N>.json` im Ordner `user://spielstaende/`. N ist eine Zahl ohne
führende Null von 1 bis 999.999.999. Andere Dateien im Ordner werden nie gelistet, gezählt oder
gelöscht.

```json
{
	"catalog": { "categories": [ … ], "events": [ … ], "format": 1, "profiles": { … } },
	"created_at": "2026-10-26T20:40:12Z",
	"day": "1985-01-01",
	"difficulty": "schwer",
	"format": 1,
	"game_version": "0.1",
	"interventions": [],
	"last_played_at": "2026-10-26T20:40:12Z",
	"name": "Spiel 2",
	"number": 2,
	"seed": 1804289383
}
```

| Schlüssel | Inhalt |
|---|---|
| `format` | Formatversion, heute 1 |
| `number`, `name` | Nummer (der Dateiname gilt) und Name, beim Anlegen „Spiel N“ |
| `difficulty` | `"leicht"`, `"mittel"` oder `"schwer"` |
| `seed` | 0 bis 2.147.483.647 |
| `day` | Spieldatum, 01.01.1985 bis 31.12.1999 |
| `created_at`, `last_played_at` | Zeitpunkte in UTC; angezeigt in Ortszeit |
| `game_version` | Version aus `project.godot`, die zuletzt geschrieben hat |
| `catalog` | die Kopie des Katalogs im Format von `event_catalog.json` |
| `interventions` | das Eingriffsprotokoll des Laufs |

**Ortszeit:** `SaveGame.time_text()` zeigt die Zeitpunkte mit dem Versatz aus der statischen
Stellschraube `SaveGame.time_zone_bias` (Minuten zu UTC). Vorgabe ist `SYSTEM_BIAS`, also wie der
Rechner; der Versatz gilt für heute, ein Zeitpunkt aus dem Sommer erscheint im Winter eine Stunde
früher. Nur der Selbsttest setzt ihn, auf 60 (UTC+1), damit die Liste auf jedem Rechner dieselbe
Uhrzeit zeigt und seine Fotos gleich bleiben (Feature 007, R7). Sie gilt für das ganze Programm;
wer sie in einem Test setzt, setzt sie danach zurück.

Alle Schlüssel sind Pflicht, ein leerer Name zählt als fehlend. Unbekannte Schlüssel stören nicht:
Spätere Features fügen ihre Daten hinzu. Geschrieben wird kanonisch wie der Katalog: Schlüssel
alphabetisch, Tabs, Zeilenumbruch am Ende. Ältere Formatversionen hebt `SaveGame._upgrade()`
später Schritt für Schritt an; mit Format 1 gibt es nichts umzuwandeln.

## Lesen und Zustand

`SaveSlot.read(path, number)` wirft nie und gibt nie `null`. Geprüft wird der Reihe nach, der erste
Treffer gilt:

| Prüfung | Zustand | Grund im Hinweis |
|---|---|---|
| kein gültiges JSON oder kein Objekt | beschädigt | „Lässt sich nicht lesen: Die Datei ist beschädigt.“ |
| `format` größer als 1 | neuere Version | „Mit einer neueren Version gespeichert.“ |
| `format` fehlt oder falsch, Pflichtfeld fehlt oder falscher Typ | beschädigt | „Lässt sich nicht lesen: Ein Teil der Datei stimmt nicht.“ |
| Grad unbekannt | beschädigt | „Der Schwierigkeitsgrad ist unbekannt.“ |
| Seed außerhalb | beschädigt | „Lässt sich nicht lesen: Ein Teil der Datei stimmt nicht.“ |
| Spieldatum außerhalb 1985–1999 | beschädigt | „Das Spieldatum ist kein Tag von 1985 bis 1999.“ |
| Zeitpunkt unlesbar, Eingriff mit falschem Datum oder nach dem Spieldatum, Katalog unlesbar | beschädigt | „Lässt sich nicht lesen: Ein Teil der Datei stimmt nicht.“ |
| sonst | fortsetzbar | — |

Im Code: `SaveSlot.State` `OK`, `DAMAGED`, `TOO_NEW`; `can_resume()` nur bei `OK`.

Die Gründe nennen nur, was der Spieler kennt, nie ein Feld, einen Wert aus der Datei oder Wörter
wie Seed oder Ereigniskatalog. Datei, Feld und Wert stehen nur im Protokoll (`push_warning()`).

Ein Katalog mit fehlerhaften Einträgen macht den Spielstand nicht kaputt. Er läuft ohne sie
weiter, wie das Spiel mit dem echten Katalog (siehe [ereigniskatalog.md](ereigniskatalog.md),
„Fehlerhaftes ausnehmen“).

## Sicher schreiben

`SaveStore.write(game, is_new)` schreibt in fünf Schritten, damit ein Abbruch an jeder Stelle,
auch zwei hintereinander, einen lesbaren Stand übrig lässt:

1. eine übrig gebliebene `.neu` abräumen und den neuen Text nach `spiel_N.json.neu` schreiben;
2. `.neu` wieder lesen; der Text muss Zeichen für Zeichen gleich sein;
3. eine übrig gebliebene `.alt` löschen, `spiel_N.json` in `.alt` umbenennen;
4. `.neu` in `spiel_N.json` umbenennen;
5. `.alt` löschen. Scheitert nur das, gilt das Speichern trotzdem.

Eine übrig gebliebene `.neu`, die der einzige lesbare Stand ist, wird in Schritt 1 zu `.alt` statt
gelöscht. Fehlt der Ordner, wird er angelegt. Mit `is_new` schreibt es nur, wenn es zur Nummer noch
keine Datei gibt, sonst `ERR_ALREADY_EXISTS`. Bei einem Fehler nennt `last_error` Datei und
Schritt fürs Protokoll; den Satz für den Spieler wählt `GameSession`.

**Welche Datei gilt** (`list_slots()`), je Nummer:
- `spiel_N.json`, wenn sie fortsetzbar oder von einer neueren Version ist. Eine neuere fällt nie
  auf eine ältere Zwischendatei zurück, sonst überschriebe das nächste Speichern sie;
- sonst die erste fortsetzbare von `.neu` und `.alt`;
- sonst der Zustand von `spiel_N.json`, ohne sie der von `.alt`.

Eine allein stehende `.neu`, die nicht fortsetzbar ist, ergibt keinen Spielstand: Dann ist schon
das erste Speichern gescheitert. Gilt eine Zwischendatei, meldet das nur das Protokoll.

Beschädigte und neuere Spielstände werden nie überschrieben: Fortsetzen lässt sich nur ein
fortsetzbarer, und ein neues Spiel nimmt nur eine Nummer ohne Dateien.

## Liste, Nummern, Löschen

- **Reihenfolge:** erst die fortsetzbaren nach „zuletzt gespielt“, der jüngste oben, bei
  Gleichstand die höhere Nummer; darunter die übrigen nach Nummer absteigend.
- **Nächste Nummer:** größte Nummer unter allen Dateien eines Spielstands plus 1, auch unter
  beschädigten und Zwischendateien; ohne Dateien 1. Nummern werden also nicht wiederverwendet,
  solange eine Datei dazu liegt.
- **Löschen** (`delete(N)`): `spiel_N.json`, `.neu` und `.alt` in dieser Reihenfolge, sonst nichts.
  Scheitert eine, hört es dort auf; der Spielstand bleibt lesbar. Fehlt alles,
  `ERR_FILE_NOT_FOUND`.

## Gemessen

Fortsetzen ergibt dasselbe Spiel wie ohne Pause: Für die Seeds 1, 4711 und 99999 in allen drei
Graden ist jede Zeile ab dem Tag nach dem Spieldatum gleich, auch mit Eingriffen vor und nach dem
Speichern (`test_save_resume_run.gd`). 20 Spielstände mit 500 Ereignissen liest die Liste in
höchstens 1 s.
