extends GutTest

## Prüft die eingefrorene Übernahme res://test/fixtures/event_catalog_uebernahme.json
## (research.md, R19): 25 Ereignisse, die 19 fixen aus dem Schnappschuss der alten Engine und
## die sechs bisherigen über Wahrscheinlichkeit, und zehn Kategorien in der Reihenfolge aus dem
## Style-Guide (T001).
##
## Anders als der echte Katalog ändert sich diese Kopie nie mehr. Sie belegt SC-005 deshalb auch
## dann noch, wenn Klaus in der Werkstatt Ereignisse ändert. Teil 2 (T028) spielt mit ihr ganze
## Spiele ab: Die fixen Ereignisse kommen an demselben Tag und mit denselben Wirkungen wie bei der
## alten Engine.

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


# --- Teil 2: ganze Spiele (T028) ------------------------------------------------

func test_seeds_1_bis_100_bringen_die_historischen_ereignisse_wie_im_schnappschuss() -> void:
	# Arrange (SC-005): je fixes Ereignis eine Zeile „JJJJ-MM-TT|kennung|art:ziel:stärke:tage“,
	# so wie die alte Engine sie lieferte
	var schnappschuss := Array(FileAccess.get_file_as_string(SCHNAPPSCHUSS).split("\n", false))

	for seed_wert in range(1, 101):
		# Act
		var run := TimelineRun.new(_catalog, seed_wert)
		run.advance_to(TimelineRun.LAST_DAY)

		# Assert: dieselben Zeilen, gebaut aus dem Protokoll dieses Laufs
		assert_eq(_zeilen_aus_dem_protokoll(run), schnappschuss, "Seed %d." % seed_wert)


func test_pentium_erscheint_am_22_03_1993_mit_seinen_wirkungen() -> void:
	# Arrange
	var run := TimelineRun.new(_catalog, 4711)
	var schnappschuss := FileAccess.get_file_as_string(SCHNAPPSCHUSS).split("\n", false)

	# Assert (US1, Szenario 1): Schon beim Anlegen stehen alle 19 historischen Termine im
	# Fahrplan, an ihrem Tag.
	for zeile in schnappschuss:
		var termine := []
		for termin in run.entries:
			if termin.event.id == zeile.get_slice("|", 1):
				termine.append(GameDate.from_day_index(termin.day).to_iso())
		assert_eq(termine, [zeile.get_slice("|", 0)], "Termin von %s." % zeile.get_slice("|", 1))

	# Act und Assert (Szenario 5): der Pentium und seine verzögerte Wirkung, wie bisher
	var am_22_maerz := _zeilen(run.advance_to(GameDate.new(1993, 3, 22).to_day_index()))
	assert_has(am_22_maerz, "22.03.1993  Beginn  Intel Pentium erscheint")
	assert_has(am_22_maerz, "22.03.1993  Wirkung  Intel Pentium erscheint: Preis · cpu_486 · -30% "
		+ "— 486 wird zur Mittelklasse.")
	var bis_5_april := _zeilen(run.advance_to(GameDate.new(1993, 4, 5).to_day_index()))
	assert_has(bis_5_april, "05.04.1993  Wirkung  Intel Pentium erscheint: Nachfrage · ram · +20% "
		+ "— Pentium-Systeme wollen Speicher.")


# --- Helfer ---------------------------------------------------------------

## Die Kennungen der Ereignisse einer Art, sortiert.
func _kennungen(kind: TimelineEvent.Kind) -> Array:
	var ids := []
	for event in _catalog.events:
		if event.kind == kind:
			ids.append(event.id)
	ids.sort()
	return ids


## Je fixes Ereignis, das im Lauf begann, eine Zeile im Format des Schnappschusses, nur aus dem
## Protokoll gebaut: der Tag der Meldung „Beginn“ und je Meldung „Wirkung“ Art, Ziel, Stärke und
## Tage seit dem Beginn. Die Wirkungen stehen in ihrer Reihenfolge im Katalog, die Zeilen nach
## Datum, dann Kennung, wie im Schnappschuss.
func _zeilen_aus_dem_protokoll(run: TimelineRun) -> Array:
	var beginn := {}        # Kennung → Tag des Beginns
	var wirkungen := {}     # Kennung → Stelle der Wirkung im Katalog → Text
	var zeilen := []
	for meldung in run.protocol:
		if meldung.event.kind != TimelineEvent.Kind.FIXED:
			continue
		var kennung := meldung.event.id
		match meldung.kind:
			TimelineMessage.Kind.EVENT_STARTED:
				if beginn.has(kennung):
					# Ein fixes Ereignis beginnt nur einmal; eine Zeile mehr fiele im Vergleich auf.
					zeilen.append("%s|%s|noch einmal" % [
						GameDate.from_day_index(meldung.day).to_iso(), kennung])
					continue
				beginn[kennung] = meldung.day
				wirkungen[kennung] = {}
			TimelineMessage.Kind.EFFECT_STARTED:
				var wirkung := meldung.effect
				wirkungen[kennung][meldung.event.effects.find(wirkung)] = "%s:%s:%s:%d" % [
					EventEffect.KIND_NAMES[wirkung.kind], wirkung.target, str(wirkung.magnitude),
					meldung.day - int(beginn[kennung])]
	for kennung: String in beginn:
		var teile := PackedStringArray()
		var je_stelle: Dictionary = wirkungen[kennung]
		var stellen := je_stelle.keys()
		stellen.sort()
		for stelle: int in stellen:
			teile.append(je_stelle[stelle])
		zeilen.append("%s|%s|%s" % [GameDate.from_day_index(beginn[kennung]).to_iso(), kennung,
			";".join(teile)])
	zeilen.sort_custom(_nach_datum_und_kennung)
	return zeilen


## Reihenfolge des Schnappschusses: nach Datum, dann Kennung.
func _nach_datum_und_kennung(a: String, b: String) -> bool:
	if a.get_slice("|", 0) != b.get_slice("|", 0):
		return a.get_slice("|", 0) < b.get_slice("|", 0)
	return a.get_slice("|", 1) < b.get_slice("|", 1)


## Die Zeilen von Meldungen.
func _zeilen(meldungen: Array[TimelineMessage]) -> Array:
	var zeilen := []
	for meldung in meldungen:
		zeilen.append(meldung.to_line())
	return zeilen
