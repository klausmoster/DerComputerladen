class_name FieldHelpers
extends RefCounted

## Gemeinsame Hilfen der Panels der Werkstatt für ihre Eingabefelder (Feature 008, T036b, L16;
## AR-02): Eingaben lesen und Werte zeigen, die rote Kontur eines Felds mit Fehler, der Grund einer
## Prüfmeldung ohne Ort davor und der Name einer Kategorie in einer Auswahl.
##
## Bis Feature 008 standen sie in EventForm und EventList, und DifficultyPanel, SimulatorPanel,
## TimelineView und InterventionDialog riefen sie dort, zum Teil als private Funktionen fremder
## Klassen. Geschwister kennen einander nicht; was mehrere brauchen, liegt hier, und jedes Panel
## ruft es hier.
##
## Nur statische Funktionen ohne Zustand; niemand legt ein FieldHelpers an. Die Klasse erbt von
## RefCounted, weil ein Skript mit class_name eine Basis braucht, nicht weil es Objekte gibt.
##
## Jede Lesefunktion gibt [true, Wert] oder [false, Grund] zurück. Der Grund steht dann als Hinweis
## am Feld.

static var _whole_pattern := RegEx.create_from_string("^[+-]?\\d{1,9}$")
static var _number_pattern := RegEx.create_from_string("^[+-]?(\\d{1,9}([.]\\d*)?|[.]\\d+)$")
static var _date_pattern := RegEx.create_from_string("^(\\d{1,2})\\.(\\d{1,2})\\.(\\d{4})$")
static var _day_pattern := RegEx.create_from_string("^(\\d{1,2})\\.(\\d{1,2})\\.?$")


# --- Lesen ------------------------------------------------------------------------------------

## Text, ohne Leerzeichen am Rand.
static func parse_text(text: String) -> Array:
	return [true, text.strip_edges()]


## Ganze Zahl, auch mit Vorzeichen: „14“, „-3“.
static func parse_whole(text: String) -> Array:
	var clean := text.strip_edges()
	if _whole_pattern.search(clean) == null:
		return [false, "„%s“ ist keine ganze Zahl." % clean]
	return [true, clean.to_int()]


## Zahl mit Komma oder Punkt, wahlweise mit „%“ dahinter: „3,5“, „3.5“, „-30 %“.
static func parse_number(text: String) -> Array:
	var clean := text.strip_edges().trim_suffix("%").strip_edges().replace(",", ".")
	if _number_pattern.search(clean) == null:
		return [false, "„%s“ ist keine Zahl; erlaubt sind etwa 3,5 und 3.5." % text.strip_edges()]
	return [true, clean.to_float()]


## Prozent wie bei parse_number(), als Anteil: „3,5“ ergibt 0,035. Gespeichert werden Anteile auf
## vier Nachkommastellen (Schreibregel 3), deshalb rundet die Eingabe schon hier, genau wie der
## Katalog beim Schreiben: So ist der Wert im Speicher derselbe wie später in der Datei.
static func parse_percent(text: String) -> Array:
	var parsed := parse_number(text)
	if not parsed[0]:
		return parsed
	var percent: float = parsed[1]
	return [true, roundf(percent / 100.0 * 10000.0) / 10000.0]


## Gewicht je Anzahl in Prozent, auf zwei Nachkommastellen wie in der Datei.
static func parse_weight(text: String) -> Array:
	var parsed := parse_number(text)
	if not parsed[0]:
		return parsed
	var weight: float = parsed[1]
	return [true, roundf(weight * 100.0) / 100.0]


## Datum als Tagesindex aus „TT.MM.JJJJ“, auch ohne führende Nullen: „1.3.1993“. Ob es im
## Spielzeitraum liegt, prüft danach die Prüfung (V06) und meldet es am Feld.
static func parse_date(text: String) -> Array:
	var clean := text.strip_edges()
	var found := _date_pattern.search(clean)
	if found != null:
		var day := found.get_string(1).to_int()
		var month := found.get_string(2).to_int()
		var year := found.get_string(3).to_int()
		if GameDate.is_valid(year, month, day):
			return [true, GameDate.new(year, month, day).to_day_index()]
	return [false, "„%s“ ist kein Datum. Erwartet wird TT.MM.JJJJ, etwa 1.3.1993." % clean]


## Tag im Jahr als (Monat, Tag) aus „TT.MM.“: „1.11.“. Ob es den Tag in jedem Jahr gibt, prüft die
## Prüfung (V09).
static func parse_day_of_year(text: String) -> Array:
	var clean := text.strip_edges()
	var found := _day_pattern.search(clean)
	if found != null:
		var day := found.get_string(1).to_int()
		var month := found.get_string(2).to_int()
		if day >= 1 and day <= 31 and month >= 1 and month <= 12:
			return [true, Vector2i(month, day)]
	return [false, "„%s“ ist kein Tag im Jahr. Erwartet wird TT.MM., etwa 1.11." % clean]


# --- Zeigen -----------------------------------------------------------------------------------

## Zahl mit Komma und höchstens [param decimals] Nachkommastellen, ohne Nullen am Ende: „3,5“,
## „-30“, „33,33“.
static func format_number(value: float, decimals: int = 2) -> String:
	var text := ("%." + str(decimals) + "f") % value
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	if text == "-0":
		text = "0"
	return text.replace(".", ",")


## Anteil als Prozentzahl: 0,035 ergibt „3,5“.
static func format_percent(share: float) -> String:
	return format_number(share * 100.0)


static func format_date(day: int) -> String:
	return str(GameDate.from_day_index(day))


## (Monat, Tag) als „TT.MM.“; (0, 0) als leerer Text.
static func format_day_of_year(value: Vector2i) -> String:
	if value == Vector2i.ZERO:
		return ""
	return "%02d.%02d." % [value.y, value.x]


static func format_whole(value: int) -> String:
	return str(value)


## Der Name einer Kategorie für Auswahl und Filter; ohne Namen ihre Kennung.
static func category_label(category: EventCategory) -> String:
	return category.name if not category.name.strip_edges().is_empty() else category.id


# --- Meldungen --------------------------------------------------------------------------------

## Gibt einem Feld mit Fehler die Kontur von 2 Pixeln in kassenrot (Style-Guide, „Bedienelemente“:
## „Ein Feld mit Fehler, ob Eingabe- oder Auswahlfeld …“), über eine Variante im Theme je Art:
## ErrorLineEdit, ErrorOptionButton für Auswahlfelder wie „Kategorie“ (V05) und ErrorTextEdit für
## die Beschreibung, etwa wenn dort in der Datei eine Zahl steht (V22). Die Fokuslinie in tusche
## liegt außen um das Feld und bleibt sichtbar. Andere Eingaben sind keine Felder, etwa der Knopf
## „+“ der Bedingungen; sie bleiben, wie sie sind, und der Hinweis steht trotzdem darunter.
static func mark_error(input: Control) -> void:
	if input is LineEdit:
		input.theme_type_variation = &"ErrorLineEdit"
	elif input is OptionButton:
		input.theme_type_variation = &"ErrorOptionButton"
	elif input is TextEdit:
		input.theme_type_variation = &"ErrorTextEdit"


## Der Grund einer Meldung ohne den Ort davor: aus „Ereignis „x“, Feld „date“: Das Datum …“ wird
## „Das Datum …“, denn das Feld steht ja direkt darüber.
static func reason(issue: CatalogIssue) -> String:
	var cut := issue.message.find("“: ")
	if cut < 0:
		return issue.message
	return issue.message.substr(cut + 3)
