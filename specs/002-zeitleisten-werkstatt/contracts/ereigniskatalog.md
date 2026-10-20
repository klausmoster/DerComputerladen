# Vertrag: Dateiformat des Ereigniskatalogs

Gehört zu [spec.md](../spec.md) und [data-model.md](../data-model.md), Entscheidungen in
[research.md](../research.md) (R3, R4, R19). Die Datei liegt unter `src/data/event_catalog.json`
(Verfassung 2.1.0, Grundsatz V, Ausnahme Ereigniskatalog) und wird nur von der Werkstatt
geschrieben. Lesen dürfen sie Spiel, Werkstatt, Textausgabe und Tests.

## Aufbau

```json
{
	"categories": [
		{
			"color": "anzeige",
			"id": "hardware",
			"name": "Hardware"
		},
		{
			"color": "signalgelb",
			"id": "kalender",
			"name": "Kalender"
		}
	],
	"events": [
		{
			"category": "hardware",
			"date": "1993-03-22",
			"description": "Superskalare P5-Architektur, 64-Bit-Bus. Das neue High-End – teuer und heiß.",
			"duration_days": 0,
			"effects": [
				{
					"delay_days": 0,
					"kind": "preis",
					"magnitude": -0.3,
					"note": "486 wird zur Mittelklasse.",
					"scope": "once",
					"target": "cpu_486"
				},
				{
					"delay_days": 14,
					"kind": "nachfrage",
					"magnitude": 0.2,
					"note": "Pentium-Systeme wollen Speicher.",
					"scope": "once",
					"target": "ram"
				}
			],
			"follow_ups": [],
			"id": "intel_pentium",
			"kind": "fixed",
			"title": "Intel Pentium erscheint"
		},
		{
			"category": "lokal",
			"conditions": [],
			"count_min": 0,
			"count_weights": [30, 70],
			"description": "Ein neues Wohngebiet entsteht – mehr potenzielle Laufkundschaft.",
			"duration_days": 0,
			"effects": [],
			"follow_ups": [],
			"id": "neubaugebiet_stadtrand",
			"kind": "preset",
			"min_gap_days": 1095,
			"title": "Neubaugebiet am Stadtrand",
			"window": {
				"from": "1987-01-01",
				"to": "1996-12-31"
			}
		},
		{
			"category": "reklamation",
			"conditions": [],
			"description": "Mehrere Kunden kommen gleichzeitig mit defekter Ware zurück.",
			"duration_days": 0,
			"effects": [],
			"follow_ups": [
				{
					"chance": 0.5,
					"delay_max": 21,
					"delay_min": 7,
					"target": "zeitungsartikel_reklamation"
				}
			],
			"id": "reklamationswelle",
			"kind": "chance",
			"max_occurrences": 0,
			"min_gap_days": 90,
			"monthly_chance": 0.03,
			"title": "Reklamationswelle",
			"window": {
				"from": "1985-01-01",
				"to": "1999-12-31"
			}
		},
		{
			"category": "kalender",
			"description": "Hauptumsatzzeit des Jahres.",
			"effects": [
				{
					"delay_days": 0,
					"kind": "kundenstrom",
					"magnitude": 0.3,
					"note": "Startwert.",
					"scope": "during",
					"target": "*"
				}
			],
			"follow_ups": [],
			"id": "weihnachtsgeschaeft",
			"kind": "yearly",
			"title": "Weihnachtsgeschäft",
			"yearly": {
				"end": "12-ende",
				"from": 1985,
				"start": "11-01",
				"to": 1999
			}
		},
		{
			"category": "reklamation",
			"conditions": [],
			"description": "Die Lokalzeitung berichtet über Ärger im Computerladen.",
			"duration_days": 0,
			"effects": [],
			"follow_ups": [],
			"id": "zeitungsartikel_reklamation",
			"kind": "follow_only",
			"title": "Zeitungsartikel über Reklamationen"
		}
	],
	"format": 1
}
```

Das Beispiel zeigt jede Art einmal, gekürzt auf zwei Kategorien. „Neubaugebiet am Stadtrand“ und
der Zeitungsartikel sind Beispiele für das Format, kein Teil der Übernahme.

## Felder

Oberste Ebene:

| Schlüssel | Typ | Regel |
|---|---|---|
| `format` | Zahl | immer `1`; eine andere Zahl lehnt der Katalog mit V22 ab |
| `categories` | Liste | Reihenfolge = Zeilen im Zeitstrahl |
| `events` | Liste | nach `id` sortiert |

Kategorie: `id`, `name`, `color` (Token aus `UiPalette`, etwa `"petrol"`, `"gehaeuse-hell"`).

Ereignis, immer vorhanden: `id`, `title`, `description`, `category`, `kind`, `effects`,
`follow_ups`.

| `kind` | weitere Schlüssel |
|---|---|
| `"fixed"` | `date`, `duration_days` |
| `"yearly"` | `yearly` mit `from`, `to` (Jahre), `start` (`"MM-TT"`), `end` (`"MM-TT"`, `"MM-ende"` oder `""` für ohne Dauer) |
| `"preset"` | `window` mit `from`, `to` (`"JJJJ-MM-TT"`), `count_min`, `count_weights` (Liste von Zahlen), `min_gap_days`, `duration_days`, `conditions` |
| `"chance"` | `window`, `monthly_chance` (0 bis 1), `max_occurrences`, `min_gap_days`, `duration_days`, `conditions` |
| `"follow_only"` | `duration_days`, `conditions` |

Wirkung: `kind` (`"preis"`, `"nachfrage"`, `"reputation"`, `"kundenstrom"`, `"presse"`),
`target`, `magnitude`, `delay_days`, `scope` (`"once"` oder `"during"`), `note`.

Folgeereignis: `target`, `chance` (0 bis 1), `delay_min`, `delay_max`.

Bedingung: `event`, `occurred` (`true` = schon eingetreten, `false` = noch nicht eingetreten).

## Schreibregeln

Damit gleicher Inhalt immer dieselbe Datei ergibt und eine Feldänderung genau eine Zeile ändert
(FR-035):

1. Geschrieben wird mit `JSON.stringify(daten, "\t", true)` und einem abschließenden Zeilenumbruch.
   Schlüssel stehen damit alphabetisch, eingerückt wird mit Tabs.
2. `events` wird vor dem Schreiben nach `id` sortiert. `categories`, `effects`, `follow_ups` und
   `conditions` bleiben in ihrer Reihenfolge.
3. Ganzzahlige Felder werden als `int` geschrieben, auch Gewichte ohne Nachkommastellen (`30`
   statt `30.0`). `JSON.parse` liest jede Zahl als `float`; beim Lesen wandelt der Katalog sie
   zurück (research.md, R3).
4. Es werden genau die Schlüssel geschrieben, die zur Art gehören, auch leere Listen. Schlüssel
   einer anderen Art fallen weg.
5. Unbekannte Schlüssel sind ein Fehler (V22) und werden nicht stillschweigend verworfen; so geht
   beim Speichern nichts verloren, was jemand von Hand eingetragen hat.

## Lesen

- Die Datei wird als Text gelesen und mit einer `JSON`-Instanz geparst. Bei einem Parse-Fehler
  gibt es keinen Katalog, sondern eine Meldung mit Zeile und Grund (research.md, R4).
- Fehlende Schlüssel, falsche Typen und unbekannte Werte werden zu Prüfmeldungen V22. Das
  Ereignis bleibt mit Vorgabewerten im Katalog, damit die Werkstatt es zeigen und reparieren kann.
- Im Spiel nimmt die Zeitleiste jedes Ereignis mit einer Fehlermeldung (Stufe `ERROR`) aus dem
  Lauf und meldet es mit Kennung und Grund über `push_error()` (FR-049).

## Übernahme aus `EventDatabase`

| Bisher (`event_database.gd`) | Neu |
|---|---|
| `is_fixed = true`, `year`/`month`/`day` | `"kind": "fixed"`, `"date": "JJJJ-MM-TT"`, `"duration_days": 0` |
| `is_fixed = false` | `"kind": "chance"` |
| `monthly_chance` | `monthly_chance` |
| `earliest_year`, `latest_year` | `"window": {"from": "JJJJ-01-01", "to": "JJJJ-12-31"}` |
| `max_occurrences` | `max_occurrences` |
| `cooldown_days` | `min_gap_days` |
| `category` (Enum, etwa `HARDWARE`) | `category` (Kennung, etwa `"hardware"`) |
| `EventEffect.kind` (Enum, etwa `PREIS`) | `"kind": "preis"` |
| `delay_days`, `target`, `magnitude`, `note` | unverändert |
| – | `"scope": "once"` für alle übernommenen Wirkungen |
| – | `"follow_ups": []`, `"conditions": []` |
