# Vertrag: Spielstand mit Laden und Konto

Erweiterung des Spielstands aus Feature 004
([spielstand.md](../../004-neues-spiel/contracts/spielstand.md)); dort Stehendes gilt weiter.
Entscheidungen in [research.md](../research.md) (R4, R5, R12), Felder in
[data-model.md](../data-model.md).

## Datei, Beispiel

```json
{
	"account": { "balance": 2568000, "rent_paid_through": "1985-01" },
	"catalog": { … },
	"created_at": "2026-10-29T19:12:40Z",
	"day": "1985-01-01",
	"difficulty": "schwer",
	"format": 1,
	"game_version": "0.1",
	"interventions": [],
	"last_played_at": "2026-10-29T19:12:40Z",
	"name": "Computer Klaus",
	"number": 7,
	"seed": 1804289383,
	"shop": {
		"address": "Lindenstraße 12",
		"area_m2": 90,
		"deposit": 432000,
		"id": "stadtteilzentrum",
		"lease_start": "1985-01-01",
		"parking": "mittel",
		"quarter": "wohngebiet",
		"rent": 144000,
		"title": "Ladenlokal Stadtteilzentrum",
		"visibility": "mittel",
		"walk_in": "mittel"
	}
}
```

## Regeln

- `shop` und `account` sind Pflicht; ohne sie ist der Spielstand beschädigt mit
  `SaveGame.REASON_FILE_PART`. Kein eigener Grund, keine Umwandlung, Formatversion bleibt 1.
- `rent_paid_through` liegt zwischen „1985-01“ und dem Monat des Spieldatums; ein Spielstand vom
  15.03.1985 hat „1985-03“, einer vom 31.01.1985 „1985-01“.
- Geschrieben wird kanonisch wie bisher; `SaveStore` prüft nach dem Schreiben Zeichen für Zeichen.
- `SaveGameFactory.new_game(opening_result, seed, number, now, version, catalog)` baut einen neuen
  Spielstand; `GameSession.start_new()` und der Fahrer des Selbsttests nutzen sie beide.

## Feste Größen

- Speichern und Lesen eines Spielstands ergibt Byte für Byte dieselbe Datei.
- Fortsetzen bucht keine Miete doppelt und keine zu wenig (SC-004).
- Die Fixtures der Spielstände unter `src/test/fixtures/spielstaende/` bekommen `shop` und
  `account`; eine Fixture ohne sie belegt „beschädigt“.
