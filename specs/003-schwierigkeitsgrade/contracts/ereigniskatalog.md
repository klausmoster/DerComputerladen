# Vertrag: Abschnitt „profiles“ im Ereigniskatalog

Gehört zu [spec.md](../spec.md) (FR-002 bis FR-005, FR-012) und
[data-model.md](../data-model.md); die Entscheidungen stehen in [research.md](../research.md),
R2 bis R4 und R8. Der Vertrag ergänzt
[ereigniskatalog.md von Feature 002](../../002-zeitleisten-werkstatt/contracts/ereigniskatalog.md).
Was dort steht, gilt weiter, auch für die Datei `src/data/event_catalog.json` und dafür, wer sie
schreibt. Gepflegt wird der Abschnitt mit der Werkstatt, im Reiter „Schwierigkeitsgrade“.

## Aufbau

Der Abschnitt steht auf oberster Ebene neben `categories`, `events` und `format`. Weil die
Schlüssel alphabetisch stehen, kommt er am Ende der Datei, hinter `"format": 1`:

```json
{
	"categories": [ … ],
	"events": [ … ],
	"format": 1,
	"profiles": {
		"leicht": [
			{
				"event_id": "reklamationswelle",
				"from_day": "1985-01-01",
				"id": "reklamationswelle",
				"reason": "Nachsichtige Kunden",
				"to_day": "1999-12-31",
				"value": -0.02
			}
		],
		"schwer": [
			{
				"event_id": "reklamationswelle",
				"from_day": "1985-01-01",
				"id": "reklamationswelle",
				"reason": "Anspruchsvolle Kunden",
				"to_day": "1999-12-31",
				"value": 0.05
			},
			{
				"event_id": "konkurrent_eroeffnet",
				"from_day": "1995-01-01",
				"id": "konkurrent_eroeffnet",
				"reason": "Die Ketten kommen",
				"to_day": "1999-12-31",
				"value": 0.03
			}
		]
	}
}
```

Das Beispiel zeigt die Szenarien aus der Spec: „Leicht −2“ und „Schwer +5“ auf die
Reklamationswelle (US2, Szenario 6) und „Schwer +3 auf Konkurrent eröffnet ab 01.01.1995“ (US2,
Szenario 7). Es sind Beispiele für das Format, keine Startwerte; die schlägt research.md, R18 vor.

Ein Katalog ohne Profile, wie jeder Katalog aus Feature 002 nach dem ersten Speichern:

```json
	"format": 1,
	"profiles": {
		"leicht": [],
		"schwer": []
	}
}
```

## Felder

| Schlüssel | Typ | Regel |
|---|---|---|
| `profiles` | Objekt | freiwillig beim Lesen, immer geschrieben |
| `profiles.leicht`, `profiles.schwer` | Liste | Start-Modifikatoren des Grads in ihrer Reihenfolge; ein fehlender Grad heißt leer; andere Schlüssel sind V22 (R4) |

Start-Modifikator, alle Schlüssel Pflicht:

| Schlüssel | Typ in der Datei | Bedeutung |
|---|---|---|
| `event_id` | Text | Kennung eines Ereignisses über Wahrscheinlichkeit |
| `from_day` | `"JJJJ-MM-TT"` | erster Tag, an dem er gilt |
| `id` | Text | Kennung, `[a-z0-9_]+`, im Profil eindeutig |
| `reason` | Text | lesbarer Grund |
| `to_day` | `"JJJJ-MM-TT"` | letzter Tag, an dem er gilt; „unbegrenzt“ heißt `"1999-12-31"` |
| `value` | Zahl | Prozentpunkte als Anteil: `0.05` heißt +5, `-0.02` heißt −2 |

Die Schlüssel sind dieselben wie bei einem Modifikator in einer Was-wäre-wenn-Probe (R2).

## Schreibregeln

Die Schreibregeln 1 bis 5 von Feature 002 gelten auch hier. Für den Abschnitt heißt das:

1. **Form:** Geschrieben wird mit `JSON.stringify(daten, "\t", true)`. Jeder Schlüssel steht auf
   einer eigenen Zeile. Ändert Klaus einen einzelnen Wert, ändert sich genau eine Zeile (FR-005,
   SC-006). Das gilt auch für die Kennung, denn sortiert wird nicht.
2. **Reihenfolge:** Die Listen behalten ihre Reihenfolge. Neue Start-Modifikatoren kommen ans
   Ende, ein Duplikat direkt hinter sein Original.
3. **Zahlen:** `value` wird auf vier Nachkommastellen gerundet. Tage stehen als Datum.
4. **Vollständig:** `profiles`, `leicht` und `schwer` werden immer geschrieben, leere Listen als
   `[]`. Bei einem Katalog aus Feature 002 bekommt beim ersten Speichern die Zeile `"format": 1`
   ein Komma, und vier Zeilen kommen dazu (R3).
5. **Unbekanntes:** Ein unbekannter Schlüssel ist ein Fehler (V22), im Abschnitt genauso wie in
   einem Start-Modifikator. Der Katalog behält ihn nicht; die Werkstatt fragt vor dem Speichern
   nach.

`"format"` bleibt `1` (R3).

## Lesen

- **Fehlt etwas:** Fehlt `profiles`, sind beide Profile leer, ohne Meldung. Fehlt darin `leicht`
  oder `schwer`, ist dieses Profil leer, ebenfalls ohne Meldung.
- **Strukturfehler (V22):**
  - `profiles` ist kein Objekt, oder ein Profil ist keine Liste: Meldung, das Profil ist leer.
  - Ein Eintrag ist kein Objekt: Meldung. An seiner Stelle steht ein Start-Modifikator mit den
    Vorgaben. So passen die Stellen im Profil zu den Feldern der Meldungen, und Klaus kann ihn in
    der Werkstatt löschen.
  - Ein Schlüssel fehlt, hat den falschen Typ oder ein Datum ist kein Kalendertag: Meldung, der
    Start-Modifikator bleibt mit der Vorgabe für dieses Feld im Profil (data-model.md), damit die
    Werkstatt ihn zeigen und reparieren kann.
  - `"mittel"`: „Für „Mittel“ gibt es kein Profil: Mittel ist der Katalog ohne
    Start-Modifikatoren.“
  - Ein anderer Grad, etwa `"extrem"`: „Den Schwierigkeitsgrad „extrem“ gibt es nicht; Profile
    gibt es nur für „leicht“ und „schwer“.“
- **Felder der Meldungen:** `profiles`, `profiles.mittel`, `profiles.extrem`, `profiles.schwer[2]`
  oder `profiles.schwer[2].value`, `event_id` leer. Der Text nennt den Ort und das volle Feld
  (data-model.md, „Prüfmeldungen zu Profilen“).
- **Weitere Regeln:** Was sich lesen lässt, prüft danach `CatalogValidator` mit V25 bis V31;
  V31 ist eine Warnung für einen Beginn oder ein Ende mitten im Monat.
- **Im Spiel:** Spiel, Simulator, Statistik und Textausgabe rechnen nur mit Start-Modifikatoren,
  die die Prüfung bestehen (`without_faulty()`, data-model.md).

## Dateien aus Feature 002

- Jeder Katalog aus Feature 002 lässt sich lesen. Beide Profile sind dann leer (Edge Case
  „Ältere Katalogdatei“).
- Speichert die Werkstatt ihn, bekommt die Zeile `"format": 1` ein Komma, und der leere
  Abschnitt kommt mit vier Zeilen dazu. Sonst ändert sich nichts.
- Die eingefrorene Übernahme `src/test/fixtures/event_catalog_uebernahme.json` bleibt Byte für
  Byte, wie sie ist. Ihre Rundreise ergibt sie selbst mit diesen fünf Zeilen, und eine zweite
  Rundreise ändert nichts mehr. Andere Fixtures, an denen Tests Zeichen für Zeichen vergleichen,
  bekommen den Abschnitt eingetragen (research.md, R17).
- Der echte Katalog bekommt den Abschnitt zur Abnahme von Phase 1: Klaus öffnet ihn in der
  Werkstatt und speichert einmal, Claude committet ihn mit der Phase (R3). Danach gilt auch am
  echten Katalog wieder „eine Änderung, eine Zeile“.
