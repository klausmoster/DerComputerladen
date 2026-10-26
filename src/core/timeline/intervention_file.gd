class_name InterventionFile
extends RefCounted

## Einträge des Eingriffsprotokolls in Dateien (Feature 004, research.md, R5): Spielstand und
## Was-wäre-wenn-Probe schreiben Eingriffe gleich, deshalb steht die Regel hier, an einer Stelle.
## Bisher stand sie in WhatIfProbe; die liegt aber unter tools/ und fehlt im exportierten Spiel.
##
## Im Speicher sind alle Tage Tagesindizes wie im Lauf (TimelineRun.interventions); in der Datei
## stehen sie lesbar als „JJJJ-MM-TT“ wie im Katalog, −1 also als „1984-12-31“. Umgerechnet wird
## nur beim Schreiben mit to_file() und beim Lesen mit from_file(). Vor from_file() prüft
## wrong_date(), ob jedes Datum stimmt; was dann noch fehlt oder nicht passt, lehnt
## TimelineRun.apply_intervention() ab.
##
## Nur statische Funktionen: Die Klasse hat keinen Zustand, sie wird nie mit new() angelegt.

## Die Schlüssel im Eingriffsprotokoll, die Tage sind, auch im Modifikator darin; bisher
## WhatIfProbe.DATE_KEYS.
const DATE_KEYS := ["at_day", "day", "new_day", "from_day", "to_day"]


## Kopie eines Eintrags für die Datei: Tage als „JJJJ-MM-TT“, auch vor 1985 (−1 ist der
## 31.12.1984). Der Wert eines Modifikators ist ein Anteil und wird wie die Anteile im Katalog auf
## vier Nachkommastellen gerundet (ereigniskatalog.md, Schreibregel 3); +5 Prozentpunkte stehen
## als 0.05 darin. Bisher WhatIfProbe._to_file().
static func to_file(record: Dictionary) -> Dictionary:
	var result := {}
	for key: Variant in record:
		var value: Variant = record[key]
		if typeof(value) == TYPE_DICTIONARY:
			value = to_file(value)
		elif DATE_KEYS.has(key) and is_whole_number(value):
			value = GameDate.from_day_index(int(value)).to_iso()
		elif key == "value" and (typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT):
			value = roundf(float(value) * 10000.0) / 10000.0
		result[key] = value
	return result


## Kopie eines Eintrags aus der Datei mit Tagesindizes statt „JJJJ-MM-TT“, auch im Modifikator
## darin. Nur für Einträge, die wrong_date() durchgelassen hat. Bisher WhatIfProbe._from_file().
static func from_file(record: Dictionary) -> Dictionary:
	var result := {}
	for key: Variant in record:
		var value: Variant = record[key]
		if typeof(value) == TYPE_DICTIONARY:
			value = from_file(value)
		elif DATE_KEYS.has(key):
			value = GameDate.from_iso(value).to_day_index()
		result[key] = value
	return result


## Warum ein Eintrag aus der Datei kein gültiges Datum hat, als Satz, etwa „Bei „day“ steht
## „1992-02-30“, kein gültiges Datum JJJJ-MM-TT.“; leer, wenn jeder Tag darin, auch im
## Modifikator, ein Kalendertag „JJJJ-MM-TT“ ist. Ein fehlender Tag ist hier kein Fehler; über den
## entscheidet apply_intervention(), wie bei jedem anderen fehlenden Feld. Bisher
## WhatIfProbe._wrong_date().
static func wrong_date(record: Dictionary) -> String:
	for key: Variant in record:
		var value: Variant = record[key]
		if typeof(value) == TYPE_DICTIONARY:
			var inner := wrong_date(value)
			if not inner.is_empty():
				return inner
		elif DATE_KEYS.has(key) and not is_date(value):
			return "Bei „%s“ steht %s, kein gültiges Datum JJJJ-MM-TT." % [key, shown(value)]
	return ""


## Ob [param value] ein Kalendertag „JJJJ-MM-TT“ ist, wie die Daten im Katalog.
static func is_date(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and GameDate.from_iso(value) != null


## Ob [param value] eine ganze Zahl ist, als int oder als float ohne Nachkommastellen. Aus JSON
## kommt jede Zahl als float, 2556 also als 2556.0. Bisher WhatIfProbe._is_whole_number().
static func is_whole_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and value == floorf(value) and absf(value) < 1e15


## Ein Wert aus der Datei für Meldungen: Text in „…“, eine ganze Zahl ohne Nachkomma. Bisher
## WhatIfProbe._shown().
static func shown(value: Variant) -> String:
	if typeof(value) == TYPE_STRING:
		return "„%s“" % value
	if is_whole_number(value):
		return str(int(value))
	return str(value)
