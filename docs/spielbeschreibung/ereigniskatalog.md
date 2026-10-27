# Ereigniskatalog

- **Worum es geht:** die Datei, in der alle Ereignisse und die Profile der Grade stehen: Aufbau,
  Felder, Schreibregeln und Prüfregeln.
- **Laden, wenn:** der Katalog gelesen, geschrieben oder geprüft wird, eine Prüfmeldung zu deuten
  ist oder das Format sich ändern soll.
- **Code:** `src/data/event_catalog.json`; `src/core/timeline/event_catalog.gd`,
  `catalog_validator.gd`, `catalog_issue.gd`, die Datenklassen `timeline_event.gd`,
  `event_category.gd`, `event_effect.gd`, `follow_up.gd`, `event_condition.gd`,
  `chance_modifier.gd`, `difficulty_profile.gd`
- **Herkunft:** `specs/002-zeitleisten-werkstatt/contracts/ereigniskatalog.md` und
  `data-model.md`, ergänzt durch dieselben Dateien in `specs/003-schwierigkeitsgrade/`
- **Stand:** Feature 003, 2026-10-27
- **Nachbarn:** was die Felder im Spiel bewirken in [zeitleiste.md](zeitleiste.md), Profile in
  [schwierigkeitsgrade.md](schwierigkeitsgrade.md), Pflege in [werkstatt.md](werkstatt.md)

## Die Datei

`src/data/event_catalog.json` beschreibt, was zwischen 1985 und 1999 passieren **kann**. Während
eines Spiels ändert er sich nie. Gepflegt wird er nur mit der Zeitleisten-Werkstatt, nicht im
Code und nicht von Hand. Lesen dürfen ihn Spiel, Werkstatt, Textausgabe und Tests; Tests nehmen
eigene Kataloge unter `src/test/fixtures/`.

Oberste Ebene:

| Schlüssel | Inhalt |
|---|---|
| `format` | immer `1`; eine andere Zahl macht die Datei unlesbar |
| `categories` | Liste der Kategorien; ihre Reihenfolge ist die der Zeilen im Zeitstrahl |
| `events` | Liste der Ereignisse, nach `id` sortiert |
| `profiles` | Objekt mit `"leicht"` und `"schwer"`, je eine Liste von Start-Modifikatoren; seit Feature 003, Dateien ohne den Abschnitt laden weiter |

Gekürztes Beispiel:

```json
{
	"categories": [
		{ "color": "nacht", "id": "kalender", "name": "Kalender" }
	],
	"events": [
		{
			"category": "kunde",
			"conditions": [],
			"description": "Eine Schule oder ein Büro fragt nach einer Sammelbestellung.",
			"duration_days": 0,
			"effects": [
				{ "delay_days": 7, "kind": "nachfrage", "magnitude": 0.3,
				  "note": "Sammelbestellung in Aussicht.", "scope": "once", "target": "komplett_pc" }
			],
			"follow_ups": [],
			"id": "grosskunde",
			"kind": "chance",
			"max_occurrences": 0,
			"min_gap_days": 120,
			"monthly_chance": 0.06,
			"title": "Großkunde meldet sich",
			"window": { "from": "1985-01-01", "to": "1999-12-31" }
		}
	],
	"format": 1,
	"profiles": {
		"leicht": [],
		"schwer": [
			{ "event_id": "grosskunde", "from_day": "1985-01-01", "id": "grosskunde",
			  "reason": "Test 1", "to_day": "1999-12-31", "value": 0.01 }
		]
	}
}
```

In der echten Datei steht jedes Element auf einer eigenen Zeile (siehe Schreibregeln).

## Felder

**Kategorie:** `id` (`[a-z0-9_]+`, entsteht aus dem Namen und bleibt fest), `name`, `color` (ein
Token aus `UiPalette.CATEGORY_TOKENS`, etwa `"petrol"`). Heute zehn Kategorien: Hardware,
Software, Tech, Wirtschaft, Lokal, Konkurrenz, Kunde, Reklamation, Lieferung, Kalender.

**Ereignis**, immer: `id` (`[a-z0-9_]+`, eindeutig, stabil), `title`, `description`, `category`,
`kind`, `effects`, `follow_ups`. Dazu je Art:

| `kind` | weitere Schlüssel |
|---|---|
| `"fixed"` | `date` (`"JJJJ-MM-TT"`), `duration_days` |
| `"yearly"` | `yearly` mit `from`, `to` (Jahre 1985–1999), `start` (`"MM-TT"`), `end` (`"MM-TT"`, `"MM-ende"` für Monatsende oder `""` für ohne Dauer) |
| `"preset"` | `window` mit `from`, `to`; `count_min`, `count_weights` (Prozent je Anzahl ab `count_min`, Summe 100), `min_gap_days`, `duration_days`, `conditions` |
| `"chance"` | `window`, `monthly_chance` (0 bis 1), `max_occurrences` (0 = unbegrenzt), `min_gap_days`, `duration_days`, `conditions` |
| `"follow_only"` | `duration_days`, `conditions` |

Beispiel für `count_weights`: `count_min` 0 und `[30, 70]` heißt zu 30 % keinmal, zu 70 % einmal.

**Wirkung:** `kind` (`"preis"`, `"nachfrage"`, `"reputation"`, `"kundenstrom"`, `"presse"`),
`target` (Warengruppe oder `"*"`), `magnitude` (−0.3 = −30 %; bei Presse 0), `delay_days`,
`scope` (`"once"` oder `"during"`), `note`.

**Folgeereignis:** `target`, `chance` (0 bis 1), `delay_min`, `delay_max`.

**Bedingung:** `event`, `occurred` (`true` = schon eingetreten, `false` = noch nicht).

**Start-Modifikator** im Profil: `id` (im Profil eindeutig), `event_id`, `value` (Anteil,
+0.05 = +5 Prozentpunkte), `reason`, `from_day`, `to_day` (beide `"JJJJ-MM-TT"`).

Fehlt beim Lesen ein Feld, gibt es eine Meldung V22 und den Vorgabewert. Dieselben Vorgaben
bekommt ein neues Ereignis in der Werkstatt: Texte und Listen leer, `fixed`, Datum 01.01.1985,
Zeitfenster über das ganze Spiel, genau einmal (`count_min` 1, `[100]`), Chance 0. Neue
Wirkungen: Presse, Ziel `*`, Stärke 0, `during` bei Ereignissen mit Dauer, sonst `once`.

## Schreibregeln

Gleicher Inhalt ergibt immer dieselbe Datei, und eine Feldänderung ändert genau eine Zeile:
1. `JSON.stringify(daten, "\t", true)` plus Zeilenumbruch am Ende: Schlüssel alphabetisch, Tabs.
2. `events` nach `id` sortiert. Kategorien, Wirkungen, Folgen, Bedingungen und Start-Modifikatoren
   behalten ihre Reihenfolge.
3. Anteile auf vier Nachkommastellen, Gewichte auf zwei. Ganze Zahlen als `int`, also `30` statt
   `30.0`; `JSON.parse` liest jede Zahl als `float`, der Katalog wandelt beim Lesen zurück.
4. Es werden genau die Schlüssel der Art geschrieben, auch leere Listen.
5. Unbekannte Schlüssel sind ein Fehler (V22) und gehen beim Speichern verloren. Die Werkstatt
   fragt deshalb vorher nach.

## Lesen

`EventCatalog.read_file(path, issues)` bzw. `from_json(text, issues)`:
- Ist der Text kein gültiges JSON, kein Objekt oder hat ein anderes `format`, gibt es `null` und
  eine Meldung V22, beim Parse-Fehler mit Zeile.
- Fehlende Schlüssel, falsche Typen, unbekannte Werte und Daten, die kein Kalendertag sind, werden
  zu V22. Das Ereignis bleibt mit Vorgabewerten im Katalog, damit die Werkstatt es zeigen und
  reparieren kann.
- Danach prüft `CatalogValidator.validate(catalog)` die Regeln unten.

## Prüfregeln

Jede Meldung ist ein `CatalogIssue` mit Stufe (`ERROR` oder `WARNING`), Regel, Ereignis, Feld
(benannt wie in der Datei, etwa `window.from`, `effects[1].delay_days`,
`profiles.schwer[2].reason`) und deutschem Text.

| Regel | Prüft | Stufe |
|---|---|---|
| V01–V03 | Kennung leer, doppelt, mit anderen Zeichen als `a–z`, `0–9`, `_` | Fehler |
| V04 | Titel leer | Fehler |
| V05 | Kategorie unbekannt | Fehler |
| V06 | Datum oder Zeitfenster außerhalb 01.01.1985–31.12.1999 | Fehler |
| V07 | Zeitfenster endet vor dem Beginn | Fehler |
| V08 | jährlich: Jahre außerhalb 1985–1999 oder von > bis | Fehler |
| V09 | jährlich: Beginn oder Ende kein gültiger Tag oder 29.02.; Beginn „Monatsende“ oder leer | Fehler |
| V10 | gesetzt: höchste Anzahl passt mit Mindestabstand nicht ins Fenster | Fehler |
| V11 | gesetzt: Gewichte negativ oder Summe nicht 100 (±0,01) | Fehler |
| V12 | Chance oder Wahrscheinlichkeit einer Folge außerhalb 0–1 | Fehler |
| V13 | Grundchance 0 | Warnung |
| V14 | Dauer, Verzögerung, Mindestabstand oder Höchstzahl negativ; `delay_min` > `delay_max` | Fehler |
| V15 | Folge oder Bedingung zeigt auf unbekannte Kennung; Bedingung auf sich selbst | Fehler |
| V16 | Folge zeigt auf fixes oder jährliches Ereignis | Fehler |
| V17 | Bedingung an fixem oder jährlichem Ereignis | Fehler |
| V18 | Kreis aus Folgen mit 100 % und Verzögerung 0 | Fehler |
| V19 | Wirkung „während“ mit Verzögerung ≥ Dauer | Fehler |
| V20 | Preis, Nachfrage, Ruf oder Kundenstrom mit Stärke 0 | Warnung |
| V21 | Kategorie: Kennung leer, falsch oder doppelt; Farbe kein erlaubtes Token | Fehler |
| V22 | Strukturfehler beim Lesen (siehe oben), auch ein Profil für Mittel oder einen unbekannten Grad | Fehler |
| V23 | Kreis aus Folgen mit 100 % und Verzögerung, der bis Spielende läuft | Warnung |
| V24 | gesetzt: Mindestabstand kürzer als die Dauer, Termine würden sich überlappen | Fehler |
| V25 | Start-Modifikator: Ereignis unbekannt oder leer | Fehler |
| V26 | Start-Modifikator auf ein Ereignis, das nicht über Wahrscheinlichkeit kommt | Fehler |
| V27 | Start-Modifikator endet vor dem Beginn | Fehler |
| V28 | Start-Modifikator: Beginn oder Ende außerhalb des Spielzeitraums | Fehler |
| V29 | Start-Modifikator: Grund leer | Fehler |
| V30 | Start-Modifikator: Kennung leer, falsch oder im Profil doppelt | Fehler |
| V31 | Start-Modifikator beginnt nicht am Monatsersten oder endet nicht am Monatsletzten; nennt die Würfelrunde, in der er wirklich wirkt | Warnung |

Reihenfolge der Meldungen: Ereignisse nach Kennung, dann Kategorien, dann Profile (Leicht vor
Schwer). Meldungen zu Profilen haben ein leeres `event_id`, damit sie nicht das Ereignis treffen,
auf das sie zeigen.

## Fehlerhaftes ausnehmen

Ein Katalog mit Fehlern bleibt benutzbar. `EventCatalog.without_faulty(issues)` gibt eine Kopie
ohne alles, wozu eine Meldung der Stufe `ERROR` gehört:
- Ereignisse mit Fehler fallen weg, Folgen auf sie mit.
- Bedingungen bleiben stehen: Ein ausgenommenes Ereignis tritt nie ein.
- Start-Modifikatoren mit Fehler fallen weg, ebenso die, deren Ereignis weggefallen ist.
  `skipped_start_modifiers(issues)` nennt sie.
- Fehler ohne Ereignis, etwa an einer Kategorie, nehmen nichts aus. Warnungen nehmen nie etwas aus.

Damit rechnen Spiel, Simulator, Statistik und Textausgabe. Das Spiel meldet jedes ausgenommene
Stück einmal mit `push_error()`.
