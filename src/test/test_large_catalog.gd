extends GutTest

## Großer Katalog (Feature 002, T068; SC-011): fixtures/catalog_500.json hat 500 Ereignisse, je zur
## Hälfte fix und über Wahrscheinlichkeit, in allen zehn Kategorien. Die Prüfung braucht unter
## 100 ms, eine Änderung über den CatalogEditor samt neuer Prüfung unter 100 ms und ein ganzes
## Spiel unter 2 s.
##
## Erzeugt hat die Datei einmal ein Skript außerhalb des Repos, deterministisch aus festen Formeln,
## geschrieben mit EventCatalog.write_file(). Sie ändert sich danach nicht mehr.
##
## Zeiten schwanken, weil der Rechner nebenher anderes tut. Jede Messung läuft deshalb mehrmals,
## und es zählt der Median: Ein einzelner Ausreißer nach oben, etwa wenn das Betriebssystem den
## Prozess kurz anhält, verschiebt ihn nicht. Das Minimum wäre noch ruhiger, zeigte aber die
## bestmögliche Dauer statt der gewöhnlichen; die Grenzen der Spec meinen die gewöhnliche.

const KATALOG := "res://test/fixtures/catalog_500.json"
const ORDNER := "user://test_large_catalog/"
## Grenzen aus SC-011, in Millisekunden.
const PRUEFUNG_MSEC := 100.0
const AENDERUNG_MSEC := 100.0
const SPIEL_MSEC := 2000.0
## So oft läuft jede Messung; der Median ist der mittlere Wert.
const LAEUFE := 5
const SPIELE := 3

var _editor: CatalogEditor


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_editor = CatalogEditor.new()
	_editor.backup_path = ORDNER + "sicherung.json"


func after_each() -> void:
	_editor = null
	var ordner := DirAccess.open(ORDNER)
	if ordner != null:
		for datei in ordner.get_files():
			ordner.remove(datei)
	DirAccess.remove_absolute(ORDNER)


func test_der_katalog_hat_500_ereignisse_halb_fix_halb_ueber_wahrscheinlichkeit() -> void:
	# Arrange und Act
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(KATALOG, meldungen)
	meldungen.append_array(CatalogValidator.validate(katalog))

	# Assert
	assert_eq(meldungen.size(), 0, "Keine Meldung, auch keine Warnung.")
	assert_eq(katalog.events.size(), 500)
	var arten := {}
	var je_kategorie := {}
	for ereignis in katalog.events:
		arten[ereignis.kind] = int(arten.get(ereignis.kind, 0)) + 1
		je_kategorie[ereignis.category] = int(je_kategorie.get(ereignis.category, 0)) + 1
	assert_eq(arten, {TimelineEvent.Kind.FIXED: 250, TimelineEvent.Kind.CHANCE: 250})
	assert_eq(katalog.categories.size(), 10)
	for kategorie in katalog.categories:
		assert_eq(je_kategorie.get(kategorie.id, 0), 50, "50 Ereignisse in %s." % kategorie.id)
	assert_eq(katalog.to_json(), FileAccess.get_file_as_string(KATALOG),
		"Die Datei ist kanonisch geschrieben.")


func test_pruefung_unter_100_ms() -> void:
	# Arrange
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(KATALOG, meldungen)
	var zeiten: Array[float] = []

	# Act
	for lauf in LAEUFE:
		var beginn := Time.get_ticks_usec()
		CatalogValidator.validate(katalog)
		zeiten.append((Time.get_ticks_usec() - beginn) / 1000.0)

	# Assert
	var median := _median(zeiten)
	gut.p("SC-011, Prüfung von 500 Ereignissen: Median %.1f ms aus %s" % [median, _liste(zeiten)])
	assert_lt(median, PRUEFUNG_MSEC, "SC-011: Die Prüfung braucht unter 100 ms.")


func test_aenderung_samt_pruefung_unter_100_ms() -> void:
	# Arrange: jede Art Änderung fünfmal, an verschiedenen Ereignissen. Jedes vierte Ereignis über
	# Wahrscheinlichkeit hat ein Folgeereignis auf das nächste; Umbenennen und Löschen finden so
	# Verweise, die sie mitnehmen.
	assert_eq(_editor.open(_kopie()), OK)
	var schritte := {
		"Datum": func(i: int) -> void:
			_editor.set_event_field("fix_%03d" % (10 + i), &"date", 4000 + i),
		"Chance": func(i: int) -> void:
			_editor.set_event_field("zufall_%03d" % (20 + i), &"monthly_chance", 0.25),
		"Art": func(i: int) -> void:
			_editor.set_event_kind("zufall_%03d" % (100 + i), TimelineEvent.Kind.PRESET),
		"Kennung": func(i: int) -> void:
			_editor.rename_event("zufall_%03d" % (4 * i + 1), "umbenannt_%d" % i),
		"Löschen": func(i: int) -> void: _editor.delete_event("zufall_%03d" % (4 * i + 41)),
		"Rückgängig": func(_i: int) -> void: _editor.undo(),
	}

	# Act und Assert
	var zeilen := PackedStringArray()
	for schritt: String in schritte:
		var zeiten: Array[float] = []
		for i in LAEUFE:
			var beginn := Time.get_ticks_usec()
			schritte[schritt].call(i)
			zeiten.append((Time.get_ticks_usec() - beginn) / 1000.0)
		var median := _median(zeiten)
		zeilen.append("%s %.1f ms" % [schritt, median])
		assert_lt(median, AENDERUNG_MSEC, "SC-011: %s samt Prüfung unter 100 ms." % schritt)
	gut.p("SC-011, Änderung samt Prüfung, Median je Art: " + ", ".join(zeilen))
	# Die fünf Rückgängig nehmen die fünf Löschungen zurück; die Umbenennungen bleiben.
	assert_eq(_editor.catalog.get_event("zufall_000").follow_ups[0].target, "umbenannt_0",
		"Das Umbenennen hat seinen Verweis nachgezogen.")
	assert_not_null(_editor.catalog.get_event("zufall_041"),
		"Rückgängig holt das Gelöschte zurück.")
	assert_eq(_editor.catalog.get_event("zufall_040").follow_ups.size(), 1,
		"… samt dem Verweis darauf.")


func test_ein_spiel_unter_2_sekunden() -> void:
	# Arrange
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(KATALOG, meldungen)
	var zeiten: Array[float] = []
	var lauf: TimelineRun

	# Act: anlegen und bis zum 31.12.1999 abspielen, mit verschiedenen Seeds
	for seed_wert in range(1, SPIELE + 1):
		var beginn := Time.get_ticks_usec()
		lauf = TimelineRun.new(katalog, seed_wert)
		lauf.advance_to(TimelineRun.LAST_DAY)
		zeiten.append((Time.get_ticks_usec() - beginn) / 1000.0)

	# Assert
	var median := _median(zeiten)
	gut.p("SC-011, ein Spiel mit 500 Ereignissen: Median %.1f ms aus %s" % [median,
		_liste(zeiten)])
	assert_true(lauf.is_finished())
	assert_gt(lauf.entries.size(), 500, "Mehr Termine als fixe Ereignisse: Es wird gewürfelt.")
	assert_lt(median, SPIEL_MSEC, "SC-011: Ein Spiel braucht unter 2 Sekunden.")


# --- Helfer -----------------------------------------------------------------------------------

## Kopie des großen Katalogs im Testordner; der CatalogEditor soll die Fixture nie anfassen.
func _kopie() -> String:
	var ziel := ORDNER + "katalog.json"
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(FileAccess.get_file_as_string(KATALOG))
	datei.close()
	return ziel


func _median(zeiten: Array[float]) -> float:
	var sortiert := zeiten.duplicate()
	sortiert.sort()
	# Mit / 2.0 und floori() statt / 2, sonst warnt GDScript mit -d vor der Ganzzahl-Division.
	return sortiert[floori(sortiert.size() / 2.0)]


func _liste(zeiten: Array[float]) -> String:
	var texte := PackedStringArray()
	for zeit in zeiten:
		texte.append("%.1f" % zeit)
	return "[%s]" % ", ".join(texte)
