extends GutTest

## Prüft die eingefrorene Übernahme res://test/fixtures/event_catalog_uebernahme.json
## (research.md, R19): 25 Ereignisse, die 19 fixen aus dem Schnappschuss der alten Engine und
## die sechs bisherigen über Wahrscheinlichkeit, und zehn Kategorien in der Reihenfolge aus dem
## Style-Guide (T001).
##
## Anders als der echte Katalog ändert sich diese Kopie nie mehr. Sie belegt SC-005 deshalb auch
## dann noch, wenn Klaus in der Werkstatt Ereignisse ändert. Teil 2 (T028) prüft mit dem Lauf
## die Termine.

const UEBERNAHME := "res://test/fixtures/event_catalog_uebernahme.json"
## Je fixes Ereignis der alten Engine eine Zeile „JJJJ-MM-TT|kennung|wirkungen“ (T003).
const SCHNAPPSCHUSS := "res://test/fixtures/historische_ereignisse.txt"
## Die variablen Ereignisse der alten EventDatabase, nach Kennung.
const BISHERIGE_UEBER_WAHRSCHEINLICHKEIT := [
	"grosskunde", "konkurrent_eroeffnet", "konkurrent_schliesst", "lieferengpass",
	"neubaugebiet", "reklamationswelle",
]
## Die zehn Kategorien in der Reihenfolge der Zeilen im Zeitstrahl (T001).
const KATEGORIEN := [
	"hardware", "software", "tech", "wirtschaft", "lokal", "konkurrenz", "kunde",
	"reklamation", "lieferung", "kalender",
]

var _catalog: EventCatalog
var _issues: Array[CatalogIssue] = []


func before_each() -> void:
	_issues.clear()
	_catalog = EventCatalog.read_file(UEBERNAHME, _issues)


func test_uebernahme_liest_sich_ohne_meldung() -> void:
	assert_not_null(_catalog, "Die Übernahme muss sich lesen lassen.")
	assert_eq(_issues.size(), 0, "%s" % [_issues])


func test_25_ereignisse_davon_19_fix_und_6_ueber_wahrscheinlichkeit() -> void:
	# Act
	var fix := _kennungen(TimelineEvent.Kind.FIXED)
	var zufall := _kennungen(TimelineEvent.Kind.CHANCE)

	# Assert
	assert_eq(_catalog.events.size(), 25)
	assert_eq(fix.size(), 19, "19 fixe Ereignisse.")
	assert_eq(zufall.size(), 6, "6 Ereignisse über Wahrscheinlichkeit, keine anderen Arten.")


func test_fixe_ereignisse_haben_die_kennungen_aus_dem_schnappschuss() -> void:
	# Arrange
	var erwartet := []
	for zeile in FileAccess.get_file_as_string(SCHNAPPSCHUSS).split("\n", false):
		erwartet.append(zeile.get_slice("|", 1))
	erwartet.sort()

	# Act
	var fix := _kennungen(TimelineEvent.Kind.FIXED)

	# Assert
	assert_eq(erwartet.size(), 19, "Der Schnappschuss hat je fixes Ereignis eine Zeile.")
	assert_eq(fix, erwartet)


func test_die_sechs_bisherigen_ereignisse_ueber_wahrscheinlichkeit() -> void:
	assert_eq(_kennungen(TimelineEvent.Kind.CHANCE), BISHERIGE_UEBER_WAHRSCHEINLICHKEIT)


func test_zehn_kategorien_in_der_reihenfolge_aus_t001() -> void:
	# Act
	var ids := []
	for category in _catalog.categories:
		ids.append(category.id)

	# Assert
	assert_eq(ids, KATEGORIEN)


# --- Helfer ---------------------------------------------------------------

## Die Kennungen der Ereignisse einer Art, sortiert.
func _kennungen(kind: TimelineEvent.Kind) -> Array:
	var ids := []
	for event in _catalog.events:
		if event.kind == kind:
			ids.append(event.id)
	ids.sort()
	return ids
