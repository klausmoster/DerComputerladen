extends GutTest

## Prüft den CatalogEditor der Werkstatt (Feature 002, T033): Bearbeiten mit Rückgängig und
## Wiederholen, Kennungen und Verweise, Löschen, Artwechsel, Kategorien und ihre Farben,
## Speichern, Verwerfen, Meldungen beim Lesen und die Sicherungskopie.
##
## Jeder Test arbeitet mit einer Kopie eines Test-Katalogs in einem eigenen Ordner unter user://
## und mit einer eigenen Sicherungsdatei; after_each() räumt beides weg. Die Fixtures unter
## res://test/fixtures/ bleiben unberührt, der echte Katalog unter res://data/ erst recht.

const ORDNER := "user://test_catalog_editor/"
## Fünf Ereignisse, eines je Art: intel_pentium (fix, zwei Wirkungen), neubaugebiet (gesetzt,
## 30/70), reklamationswelle (über Wahrscheinlichkeit, Folgeereignis zeitungsartikel),
## weihnachtsgeschaeft (jährlich) und zeitungsartikel (nur als Folge, Bedingung
## reklamationswelle). Vier Kategorien: hardware, lokal, reklamation, kalender.
const MINIMAL := "res://test/fixtures/catalog_minimal.json"
## Die eingefrorene Übernahme mit den zehn Kategorien.
const UEBERNAHME := "res://test/fixtures/event_catalog_uebernahme.json"
## Kein gültiges JSON: In Zeile 12 fehlt am Ende das Komma, der Parser merkt es in Zeile 13.
const KAPUTT := "res://test/fixtures/catalog_v22_kaputt.json"
## 01.01.1985 = 0; der 22.03.1993 ist Tag 3002, der 15.04.1993 Tag 3026.
const PENTIUM_TAG := 3002
const NEUER_TAG := 3026

## Jede ändernde Methode einmal: Methode, Argumente, erwarteter Name der Aktion.
const AENDERUNGEN := [
	["add_event", [TimelineEvent.Kind.PRESET, "Neubaugebiet am Stadtrand", "lokal"],
		"Neubaugebiet am Stadtrand anlegen"],
	["duplicate_event", ["intel_pentium"], "Intel Pentium erscheint duplizieren"],
	["delete_event", ["zeitungsartikel"], "Zeitungsartikel über Reklamationen löschen"],
	["rename_event", ["reklamationswelle", "reklamationen"], "Kennung von Reklamationswelle"],
	["set_event_field", ["intel_pentium", &"date", NEUER_TAG], "Datum von Intel Pentium erscheint"],
	["set_event_fields", ["neubaugebiet", {&"count_min": 1, &"count_weights": [50.0, 50.0]}],
		"Anzahl und Gewichte von Neubaugebiet am Stadtrand"],
	["set_event_kind", ["reklamationswelle", TimelineEvent.Kind.PRESET],
		"Art von Reklamationswelle"],
	["add_item", ["intel_pentium", &"effects"], "Wirkung zu Intel Pentium erscheint hinzufügen"],
	["add_item", ["neubaugebiet", &"follow_ups"],
		"Folgeereignis zu Neubaugebiet am Stadtrand hinzufügen"],
	["add_item", ["reklamationswelle", &"conditions"], "Bedingung zu Reklamationswelle hinzufügen"],
	["remove_item", ["intel_pentium", &"effects", 1],
		"Wirkung 2 von Intel Pentium erscheint entfernen"],
	["set_item_field", ["intel_pentium", &"effects", 1, &"delay_days", 21],
		"Verzögerung der Wirkung 2 von Intel Pentium erscheint"],
	["set_item_field", ["reklamationswelle", &"follow_ups", 0, &"chance", 0.25],
		"Wahrscheinlichkeit des Folgeereignisses 1 von Reklamationswelle"],
	["set_item_field", ["zeitungsartikel", &"conditions", 0, &"occurred", false],
		"Zustand der Bedingung 1 von Zeitungsartikel über Reklamationen"],
	["add_category", ["Lokale Presse"], "Kategorie Lokale Presse anlegen"],
	["set_category_field", ["lokal", &"name", "Stadt"], "Name der Kategorie Lokal"],
	["set_category_field", ["kalender", &"color", &"holz"], "Farbe der Kategorie Kalender"],
]

## Titel und Kennung, die suggest_id() daraus vorschlägt (FR-032).
const KENNUNGEN := [
	["Neubaugebiet am Stadtrand", "neubaugebiet_am_stadtrand"],
	["Größter Ärger über Öl", "groesster_aerger_ueber_oel"],
	["  CeBIT '93 – Hannover!  ", "cebit_93_hannover"],
	["Übermaß", "uebermass"],
	["486er-Preise fallen", "486er_preise_fallen"],
	["!!!", "ereignis"],
	["", "ereignis"],
]

var _editor: CatalogEditor


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_editor = _neuer_editor()


func after_each() -> void:
	_editor = null
	var ordner := DirAccess.open(ORDNER)
	if ordner != null:
		for datei in ordner.get_files():
			ordner.remove(datei)
	DirAccess.remove_absolute(ORDNER)


# --- Öffnen und neu anlegen -------------------------------------------------------------------

func test_oeffnen_liest_den_katalog_mit_leerem_verlauf() -> void:
	# Arrange
	var ziel := _kopie(MINIMAL)

	# Act
	var fehler := _editor.open(ziel)

	# Assert
	assert_eq(fehler, OK)
	assert_eq(_editor.path, ziel)
	assert_eq(_editor.catalog.events.size(), 5)
	assert_eq(_editor.last_error, "")
	assert_false(_editor.is_dirty(), "Direkt nach dem Öffnen gibt es nichts zu speichern.")
	assert_false(_editor.can_undo())
	assert_eq(_editor.issues().size(), 0, "Der minimale Katalog hat keine Meldung.")
	assert_false(_editor.has_errors())


func test_neuer_katalog_hat_die_zehn_kategorien_und_ist_ungespeichert() -> void:
	# Act
	_editor.new_catalog()

	# Assert
	var kategorien := _editor.catalog.categories.map(
		func(kategorie: EventCategory) -> String:
			return "%s %s %s" % [kategorie.id, kategorie.name, kategorie.color])
	assert_eq(kategorien, [
		"hardware Hardware nacht-hell", "software Software petrol", "tech Tech nacht",
		"wirtschaft Wirtschaft kassenrot", "lokal Lokal holz-dunkel",
		"konkurrenz Konkurrenz gehaeuse-dunkel", "kunde Kunde holz",
		"reklamation Reklamation nacht-hell", "lieferung Lieferung petrol",
		"kalender Kalender nacht",
	], "Namen und Startfarben wie bei der Übernahme (Style-Guide, „Werkzeuge“).")
	assert_eq(_editor.catalog.events.size(), 0)
	assert_true(_editor.is_dirty(), "Bis zum Speichern steht der neue Katalog in keiner Datei.")
	assert_false(_editor.can_undo(), "Das Anlegen selbst ist kein Schritt im Verlauf.")
	assert_eq(_editor.issues().size(), 0, "Die Kategorien sind gültig.")


func test_fehlende_datei_wird_erst_beim_speichern_angelegt() -> void:
	# Arrange: Edge Case „Es gibt noch keine Katalogdatei“.
	var ziel := ORDNER + "neu.json"

	# Act
	var fehler := _editor.open(ziel)
	_editor.new_catalog()

	# Assert
	assert_eq(fehler, ERR_FILE_NOT_FOUND)
	assert_string_contains(_editor.last_error, ziel, false)
	assert_eq(_editor.path, ziel, "save() schreibt den neuen Katalog dorthin.")
	assert_false(FileAccess.file_exists(ziel), "Geschrieben wird erst beim Speichern.")
	assert_eq(_editor.save(), OK)
	assert_true(FileAccess.file_exists(ziel))
	assert_false(_editor.is_dirty())
	var zweiter := _neuer_editor()
	assert_eq(zweiter.open(ziel), OK)
	assert_eq(zweiter.catalog.categories.size(), 10)


# --- Jede Änderung ist ein Schritt ------------------------------------------------------------

func test_jede_aenderung_ist_ein_schritt_mit_namen(
		fall: Array = use_parameters(AENDERUNGEN)) -> void:
	# Arrange
	_oeffnen(MINIMAL)
	var vorher := _editor.catalog.to_json()
	var ereignisse_vorher := _editor.catalog.events.duplicate()
	var kategorien_vorher := _editor.catalog.categories.duplicate()

	# Act
	_editor.callv(fall[0], fall[1])
	var nachher := _editor.catalog.to_json()

	# Assert: genau eine Aktion mit deutschem Namen (Verfassung, R15) …
	assert_ne(nachher, vorher, "%s muss den Katalog ändern." % fall[0])
	assert_eq(_editor.undo_name(), fall[2])
	assert_true(_editor.is_dirty())
	# … die ein einziges Rückgängig ganz zurücknimmt, mit denselben Objekten wie vorher …
	assert_true(_editor.undo())
	assert_eq(_editor.catalog.to_json(), vorher, "Rückgängig stellt den Stand davor her.")
	assert_eq(_editor.catalog.events, ereignisse_vorher, "Die alten Ereignisse kehren zurück.")
	assert_eq(_editor.catalog.categories, kategorien_vorher)
	assert_false(_editor.can_undo(), "Mehr als ein Schritt war es nicht.")
	assert_eq(_editor.redo_name(), fall[2], "Wiederholen kennt denselben Namen.")
	assert_false(_editor.is_dirty(), "Der Stand davor ist der gespeicherte.")
	# … und Wiederholen wieder herstellt (US2, Szenario 7).
	assert_true(_editor.redo())
	assert_eq(_editor.catalog.to_json(), nachher, "Wiederholen stellt die Änderung wieder her.")
	assert_true(_editor.is_dirty())


func test_drei_aenderungen_schrittweise_zurueck_und_wieder_vor() -> void:
	# Arrange: US2, Szenario 7.
	_oeffnen(MINIMAL)
	var staende := [_editor.catalog.to_json()]
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	staende.append(_editor.catalog.to_json())
	_editor.set_event_field("intel_pentium", &"title", "Pentium kommt")
	staende.append(_editor.catalog.to_json())
	_editor.set_event_field("reklamationswelle", &"monthly_chance", 0.05)
	staende.append(_editor.catalog.to_json())

	# Act und Assert
	for i in range(2, -1, -1):
		_editor.undo()
		assert_eq(_editor.catalog.to_json(), staende[i], "Nach Rückgängig steht Stand %d da." % i)
	assert_false(_editor.can_undo())
	for i in range(1, 4):
		_editor.redo()
		assert_eq(_editor.catalog.to_json(), staende[i], "Nach Wiederholen steht Stand %d da." % i)
	assert_false(_editor.can_redo())


func test_namen_fuer_rueckgaengig_und_wiederholen() -> void:
	# Arrange: Die Knöpfe zeigen sie im Tooltip, etwa „Rückgängig: Datum von … (Cmd+Z)“.
	_oeffnen(MINIMAL)
	assert_eq([_editor.undo_name(), _editor.redo_name()], ["", ""], "Am Anfang gibt es keine.")

	# Act und Assert
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	_editor.set_event_field("intel_pentium", &"title", "Pentium kommt")
	assert_eq([_editor.undo_name(), _editor.redo_name()], ["Titel von Intel Pentium erscheint", ""],
		"Die Aktion heißt nach dem Titel vor der Änderung.")
	_editor.undo()
	assert_eq([_editor.undo_name(), _editor.redo_name()],
		["Datum von Intel Pentium erscheint", "Titel von Intel Pentium erscheint"])
	_editor.undo()
	assert_eq([_editor.undo_name(), _editor.redo_name()], ["", "Datum von Intel Pentium erscheint"])
	_editor.revert()
	assert_eq([_editor.undo_name(), _editor.redo_name()], ["", ""], "Verwerfen leert den Verlauf.")


func test_gleicher_wert_ergibt_keinen_schritt() -> void:
	# Arrange: Das Formular übernimmt beim Verlassen jedes Felds, auch ohne Änderung.
	_oeffnen(MINIMAL)

	# Act
	_editor.set_event_field("intel_pentium", &"date", PENTIUM_TAG)
	_editor.set_item_field("intel_pentium", &"effects", 1, &"delay_days", 14)
	_editor.set_category_field("lokal", &"name", "Lokal")

	# Assert
	assert_false(_editor.can_undo(), "Nichts geändert, nichts im Verlauf.")
	assert_false(_editor.is_dirty())


func test_werte_werden_dem_typ_des_felds_angepasst() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act: ganze Zahl in eine Kommazahl, untypisierte Liste ganzer Zahlen, Text als Farbe.
	_editor.set_event_field("reklamationswelle", &"monthly_chance", 1)
	_editor.set_event_field("neubaugebiet", &"count_weights", [40, 60])
	_editor.set_event_field("intel_pentium", &"duration_days", 3.0)
	_editor.set_category_field("lokal", &"color", "holz")

	# Assert
	var welle := _editor.catalog.get_event("reklamationswelle")
	assert_eq(typeof(welle.monthly_chance), TYPE_FLOAT)
	assert_eq(welle.monthly_chance, 1.0)
	var neubau := _editor.catalog.get_event("neubaugebiet")
	assert_eq(neubau.count_weights, [40.0, 60.0])
	assert_eq(neubau.count_weights.get_typed_builtin(), TYPE_FLOAT,
		"Die Liste bleibt Array[float].")
	assert_eq(_editor.catalog.get_event("intel_pentium").duration_days, 3)
	assert_eq(_editor.catalog.get_category("lokal").color, &"holz")


func test_unbekannte_felder_werden_abgelehnt() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act
	_editor.set_event_field("intel_pentium", &"datum", NEUER_TAG)
	_editor.set_event_field("intel_pentium", &"id", "pentium")
	_editor.set_event_field("intel_pentium", &"date", "1993-04-15")
	_editor.set_category_field("lokal", &"id", "stadt")

	# Assert
	assert_push_error("Das Feld „datum“ ändert set_event_field() nicht.")
	assert_push_error("Das Feld „id“ ändert set_event_field() nicht.",
		"Die Kennung ändert rename_event(), weil die Verweise mitwandern.")
	assert_push_error("1993-04-15 passt nicht in das Feld „date“.")
	assert_push_error("Bei Kategorien ändern sich nur Name und Farbe, nicht „id“.")
	assert_false(_editor.can_undo(), "Keine der Änderungen kam an.")
	assert_eq(_editor.catalog.get_event("intel_pentium").date, PENTIUM_TAG)


func test_beim_signal_stimmt_is_dirty_schon() -> void:
	# Arrange: Die Toolbar liest is_dirty() in catalog_changed. UndoRedo zählt seine Version aber
	# erst nach den Methoden einer Aktion weiter; gemeldet werden darf deshalb erst danach.
	_oeffnen(MINIMAL)
	var gesehen := []
	_editor.catalog_changed.connect(func() -> void: gesehen.append(_editor.is_dirty()))

	# Act
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	_editor.undo()
	_editor.redo()

	# Assert
	assert_eq(gesehen, [true, false, true])


func test_oeffnen_und_neuer_katalog_melden_sich_speichern_nur_mit_den_meldungen() -> void:
	# Arrange: Liste, Formular und Zeitstrahl zeichnen bei catalog_changed neu, auch nach dem
	# Öffnen; Speichern ändert nur die Meldungen beim Lesen.
	var ziel := _kopie(MINIMAL)
	watch_signals(_editor)

	# Act
	_editor.open(ziel)
	_editor.new_catalog()
	_editor.revert()
	_editor.save()

	# Assert
	assert_signal_emit_count(_editor, "catalog_changed", 3, "Öffnen, neuer Katalog, Verwerfen.")
	assert_signal_emit_count(_editor, "issues_changed", 4, "Dazu das Speichern.")


func test_nach_jeder_aenderung_kommen_beide_signale() -> void:
	# Arrange
	_oeffnen(MINIMAL)
	watch_signals(_editor)

	# Act
	_editor.set_event_field("intel_pentium", &"title", "")
	var meldungen: Array = get_signal_parameters(_editor, "issues_changed")[0]
	_editor.undo()

	# Assert
	assert_signal_emit_count(_editor, "catalog_changed", 2,
		"Einmal für die Änderung, einmal für Rückgängig.")
	assert_signal_emit_count(_editor, "issues_changed", 2)
	var regeln := meldungen.map(func(meldung: CatalogIssue) -> String: return meldung.rule)
	assert_eq(regeln, ["V04"], "Das Signal bringt die neue Prüfung mit: Titel leer.")
	assert_eq(_editor.issues().size(), 0, "Nach Rückgängig ist der Titel wieder da.")


# --- Kennungen und Verweise -------------------------------------------------------------------

func test_kennung_aus_dem_titel(fall: Array = use_parameters(KENNUNGEN)) -> void:
	# Arrange: ein leerer Katalog, damit keine Kennung schon vergeben ist.
	_editor.new_catalog()

	# Act und Assert
	assert_eq(_editor.suggest_id(fall[0]), fall[1], "Vorschlag für „%s“." % fall[0])


func test_vorgeschlagene_kennung_ist_eindeutig() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act
	var erste := _editor.suggest_id("Intel Pentium")
	_editor.add_event(TimelineEvent.Kind.FIXED, "Intel Pentium", "hardware")
	var zweite := _editor.suggest_id("Intel Pentium")

	# Assert
	assert_eq(erste, "intel_pentium_2", "intel_pentium gibt es schon.")
	assert_eq(zweite, "intel_pentium_3")


func test_kennungsregel_steht_auch_ohne_editor_bereit() -> void:
	# Arrange: Die Regel ist statisch; WhatIfProbe und der Simulator nutzen sie ohne Editor.
	var vergeben := {"intel_pentium": true, "intel_pentium_2": true}

	# Act und Assert
	assert_eq(CatalogEditor.id_from("Ware vom windigen Händler!", "modifikator"),
		"ware_vom_windigen_haendler")
	assert_eq(CatalogEditor.id_from("???", "modifikator"), "modifikator",
		"Ohne Buchstaben und Ziffern gilt die Vorgabe.")
	assert_eq(CatalogEditor.unique_id("intel_pentium", vergeben), "intel_pentium_3",
		"Die erste freie Nummer.")
	assert_eq(CatalogEditor.unique_id("intel_486", vergeben), "intel_486", "Frei bleibt frei.")


func test_neues_ereignis_bekommt_die_vorgaben_seiner_art() -> void:
	# Arrange: US2, Szenario 1.
	_oeffnen(MINIMAL)

	# Act
	var neubau := _editor.add_event(TimelineEvent.Kind.PRESET, "Neubaugebiet am Stadtrand", "lokal")
	var messe := _editor.add_event(TimelineEvent.Kind.FIXED, "Messe", "hardware", NEUER_TAG)
	var welle := _editor.add_event(TimelineEvent.Kind.CHANCE, "Welle", "reklamation", NEUER_TAG,
		"welle")

	# Assert: die Vorgaben aus data-model.md, „Vorgaben“
	assert_eq(neubau.id, "neubaugebiet_am_stadtrand", "Leere Kennung heißt Vorschlag.")
	assert_same(_editor.catalog.get_event(neubau.id), neubau)
	assert_eq([neubau.window_from, neubau.window_to], [0, 5477], "Zeitfenster 0 bis 5477.")
	assert_eq([neubau.count_min, neubau.count_weights], [1, [100.0]], "Genau einmal.")
	assert_eq([neubau.min_gap_days, neubau.duration_days], [0, 0])
	assert_eq(neubau.effects.size() + neubau.follow_ups.size() + neubau.conditions.size(), 0)
	assert_eq(messe.date, NEUER_TAG, "day ≥ 0 setzt bei fixen Ereignissen das Datum.")
	assert_eq(welle.id, "welle", "Eine angegebene Kennung gilt.")
	assert_eq(welle.monthly_chance, 0.0)
	assert_eq(welle.date, 0, "Bei anderen Arten zählt day nicht.")
	var ids := _editor.catalog.events.map(func(event: TimelineEvent) -> String: return event.id)
	var sortiert := ids.duplicate()
	sortiert.sort()
	assert_eq(ids, sortiert, "Neue Ereignisse stehen an ihrer Stelle nach Kennung.")


func test_doppelte_kennung_legt_nichts_an() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act
	var neu := _editor.add_event(TimelineEvent.Kind.FIXED, "Noch ein Pentium", "hardware", -1,
		"intel_pentium")

	# Assert
	assert_null(neu, "Doppelte Kennungen lässt die Werkstatt nicht zu (FR-032).")
	assert_false(_editor.can_undo())
	assert_eq(_editor.catalog.events.size(), 5)


func test_duplizieren_gibt_eine_neue_kennung() -> void:
	# Arrange
	_oeffnen(MINIMAL)
	var original := _editor.catalog.get_event("intel_pentium")

	# Act
	var kopie := _editor.duplicate_event("intel_pentium")

	# Assert
	assert_eq(kopie.id, "intel_pentium_2")
	assert_eq(kopie.title, original.title)
	assert_eq(kopie.date, original.date)
	assert_eq(kopie.effects.size(), 2)
	assert_ne(kopie.effects[0], original.effects[0], "Die Wirkungen sind eigene Objekte.")
	kopie.effects[0].note = "geändert"
	assert_eq(original.effects[0].note, "486 wird zur Mittelklasse.")


func test_umbenennen_zieht_verweise_nach() -> void:
	# Arrange: zeitungsartikel hat eine Bedingung auf reklamationswelle, reklamationswelle ein
	# Folgeereignis auf zeitungsartikel.
	var ziel := _oeffnen(MINIMAL)

	# Act: US2, Szenario 6.
	var erstes := _editor.rename_event("reklamationswelle", "reklamationen")
	var zweites := _editor.rename_event("zeitungsartikel", "artikel")
	_editor.save()

	# Assert
	assert_eq([erstes, zweites], [OK, OK])
	var gelesen := _neuer_editor()
	assert_eq(gelesen.open(ziel), OK)
	assert_null(gelesen.catalog.get_event("reklamationswelle"))
	assert_eq(gelesen.catalog.get_event("artikel").conditions[0].event, "reklamationen",
		"Die Bedingung zeigt auf die neue Kennung.")
	assert_eq(gelesen.catalog.get_event("reklamationen").follow_ups[0].target, "artikel",
		"Das Folgeereignis zeigt auf die neue Kennung.")
	assert_eq(gelesen.issues().size(), 0, "Keine Verweise ins Leere.")
	assert_eq(_editor.references_to("reklamationen"), PackedStringArray(["artikel"]))


func test_umbenennen_auf_vorhandene_kennung_wird_abgelehnt() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act
	var dublette := _editor.rename_event("intel_pentium", "neubaugebiet")
	var unbekannt := _editor.rename_event("gibt_es_nicht", "neu")
	var leer := _editor.rename_event("intel_pentium", "")

	# Assert
	assert_eq(dublette, ERR_ALREADY_EXISTS)
	assert_eq(unbekannt, ERR_DOES_NOT_EXIST)
	assert_eq(leer, ERR_INVALID_PARAMETER)
	assert_false(_editor.can_undo(), "Abgelehnt heißt: kein Schritt im Verlauf.")


func test_set_event_fields_ist_ein_schritt() -> void:
	# Arrange: Anzahl von–bis samt neu verteilten Gewichten, wie das Formular sie schickt.
	_oeffnen(MINIMAL)

	# Act
	_editor.set_event_fields("neubaugebiet",
		{&"count_min": 1, &"count_weights": [33.33, 33.33, 33.34]})
	var nachher := _editor.catalog.get_event("neubaugebiet")
	_editor.undo()
	var zurueck := _editor.catalog.get_event("neubaugebiet")

	# Assert
	assert_eq([nachher.count_min, nachher.count_weights], [1, [33.33, 33.33, 33.34]])
	assert_eq([zurueck.count_min, zurueck.count_weights], [0, [30.0, 70.0]],
		"Ein Rückgängig nimmt beide Felder zurück.")
	assert_false(_editor.can_undo())


# --- Löschen und Art --------------------------------------------------------------------------

func test_loeschen_mit_verweisen_ist_ein_schritt() -> void:
	# Arrange: US2, Szenario 4; FR-036.
	_oeffnen(MINIMAL)
	var vorher := _editor.catalog.to_json()

	# Act
	var verweise := _editor.references_to("zeitungsartikel")
	_editor.delete_event("zeitungsartikel")

	# Assert
	assert_eq(verweise, PackedStringArray(["reklamationswelle"]),
		"Die Rückfrage nennt den Verweis.")
	assert_null(_editor.catalog.get_event("zeitungsartikel"))
	assert_eq(_editor.catalog.get_event("reklamationswelle").follow_ups.size(), 0,
		"Das Folgeereignis auf das gelöschte Ereignis ist mit weg.")
	assert_eq(_editor.issues().size(), 0, "Kein Verweis zeigt ins Leere.")
	_editor.undo()
	assert_eq(_editor.catalog.to_json(), vorher, "Ein Rückgängig holt Ereignis und Verweis zurück.")
	assert_false(_editor.can_undo())


func test_loeschen_entfernt_auch_bedingungen() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act
	_editor.delete_event("reklamationswelle")

	# Assert
	assert_eq(_editor.catalog.get_event("zeitungsartikel").conditions.size(), 0)
	assert_eq(_editor.references_to("reklamationswelle").size(), 0)


func test_artwechsel_behaelt_gemeinsame_werte() -> void:
	# Arrange: ein Ereignis über Wahrscheinlichkeit mit eigenem Fenster, Abstand, Dauer und
	# Bedingung (FR-031).
	_oeffnen(MINIMAL)
	_editor.set_event_fields("reklamationswelle", {&"window_from": 1826, &"window_to": 3652,
		&"duration_days": 10, &"max_occurrences": 3})
	_editor.add_item("reklamationswelle", &"conditions")
	_editor.set_item_field("reklamationswelle", &"conditions", 0, &"event", "intel_pentium")
	var vorher := _editor.catalog.to_json()

	# Act
	_editor.set_event_kind("reklamationswelle", TimelineEvent.Kind.PRESET)

	# Assert: Zeitfenster, Mindestabstand, Dauer und Bedingungen bleiben …
	var gesetzt := _editor.catalog.get_event("reklamationswelle")
	assert_eq(gesetzt.kind, TimelineEvent.Kind.PRESET)
	assert_eq([gesetzt.window_from, gesetzt.window_to], [1826, 3652])
	assert_eq([gesetzt.min_gap_days, gesetzt.duration_days], [90, 10])
	assert_eq(gesetzt.conditions[0].event, "intel_pentium")
	assert_eq(gesetzt.follow_ups[0].target, "zeitungsartikel", "Gemeinsame Felder bleiben.")
	# … Anzahl und Gewichte bekommen Vorgaben, Chance und Höchstzahl fallen weg …
	assert_eq([gesetzt.count_min, gesetzt.count_weights], [1, [100.0]])
	assert_eq([gesetzt.monthly_chance, gesetzt.max_occurrences], [0.0, 0])
	# … und Rückgängig bringt alle alten Werte zurück.
	_editor.undo()
	var zurueck := _editor.catalog.get_event("reklamationswelle")
	assert_eq(_editor.catalog.to_json(), vorher)
	assert_eq([zurueck.monthly_chance, zurueck.max_occurrences], [0.03, 3])


func test_artwechsel_von_folge_zu_fix_behaelt_die_dauer_und_verwirft_bedingungen() -> void:
	# Arrange: „nur als Folge“ hat Dauer und Bedingungen, „fix“ hat Datum und Dauer.
	_oeffnen(MINIMAL)
	_editor.set_event_field("zeitungsartikel", &"duration_days", 5)

	# Act
	_editor.set_event_kind("zeitungsartikel", TimelineEvent.Kind.FIXED)

	# Assert
	var fix := _editor.catalog.get_event("zeitungsartikel")
	assert_eq(fix.duration_days, 5, "Die Dauer haben beide Arten.")
	assert_eq(fix.conditions.size(), 0, "Fixe Ereignisse haben keine Bedingungen (V17).")
	assert_eq(fix.date, 0, "Das Datum bekommt die Vorgabe 01.01.1985.")
	# Die Bedingung verschwindet mit, eine V17 bleibt also nicht zurück. Melden muss die Prüfung
	# aber das Folgeereignis der Reklamationswelle: Es zeigt jetzt auf ein fixes Ereignis.
	var meldungen := _editor.issues().map(
		func(meldung: CatalogIssue) -> String:
			return "%s %s %s" % [meldung.rule, meldung.event_id, meldung.field])
	assert_eq(meldungen, ["V16 reklamationswelle follow_ups[0].target"])


func test_belegte_kategorie_laesst_sich_nicht_loeschen() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act
	var belegt := _editor.delete_category("hardware")
	var unbekannt := _editor.delete_category("gibt_es_nicht")

	# Assert
	assert_eq(belegt, ERR_UNAVAILABLE, "intel_pentium gehört zu hardware.")
	assert_eq(unbekannt, ERR_DOES_NOT_EXIST)
	assert_not_null(_editor.catalog.get_category("hardware"))
	assert_false(_editor.can_undo())


func test_leere_kategorie_loeschen_ist_ein_schritt() -> void:
	# Arrange
	_oeffnen(MINIMAL)
	_editor.add_category("Lokale Presse")
	var vorher := _editor.catalog.categories.duplicate()

	# Act
	var fehler := _editor.delete_category("lokale_presse")

	# Assert
	assert_eq(fehler, OK)
	assert_eq(_editor.undo_name(), "Kategorie Lokale Presse löschen")
	assert_null(_editor.catalog.get_category("lokale_presse"))
	_editor.undo()
	assert_eq(_editor.catalog.categories, vorher, "Rückgängig setzt sie an ihre alte Stelle.")


# --- Kategorien und ihre Farben ----------------------------------------------------------------

func test_elfte_kategorie_bekommt_kassenrot() -> void:
	# Arrange: Die zehn Kategorien der Übernahme benutzen alle sieben Farben; nacht-hell, petrol
	# und nacht je zweimal, die übrigen vier einmal.
	_oeffnen(UEBERNAHME)

	# Act
	var presse := _editor.add_category("Presse")

	# Assert
	assert_eq(presse.color, &"kassenrot",
		"Die erste der am seltensten benutzten Farben (FR-031).")
	assert_eq(presse.id, "presse")
	assert_same(_editor.catalog.categories[10], presse,
		"Die neue Kategorie ist die unterste Zeile.")


func test_neue_kategorie_nimmt_die_erste_freie_farbe() -> void:
	# Arrange: Der minimale Katalog benutzt nacht-hell (zweimal), holz-dunkel und nacht.
	_oeffnen(MINIMAL)

	# Act
	var erste := _editor.add_category("Erste")
	var zweite := _editor.add_category("Zweite")

	# Assert
	assert_eq(erste.color, &"petrol", "petrol ist die erste noch freie Farbe der Liste.")
	assert_eq(zweite.color, &"kassenrot", "Danach ist es kassenrot.")


func test_kategorie_kennung_entsteht_aus_dem_namen_und_bleibt() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act
	var erste := _editor.add_category("Lokale Presse")
	var zweite := _editor.add_category("Lokale Presse")
	_editor.set_category_field("lokale_presse", &"name", "Zeitung")

	# Assert
	assert_eq(erste.id, "lokale_presse")
	assert_eq(zweite.id, "lokale_presse_2")
	var umbenannt := _editor.catalog.get_category("lokale_presse")
	assert_eq(umbenannt.name, "Zeitung", "Umbenennen ändert nur den Namen.")
	assert_eq(umbenannt.color, erste.color)


# --- Speichern und Verwerfen ------------------------------------------------------------------

func test_speichern_ohne_aenderung_ergibt_dieselbe_datei() -> void:
	# Arrange
	var ziel := _oeffnen(MINIMAL)
	var vorher := FileAccess.get_file_as_string(ziel)

	# Act
	var fehler := _editor.save()

	# Assert
	assert_eq(fehler, OK)
	assert_eq(FileAccess.get_file_as_string(ziel), vorher, "Die Fixture ist schon kanonisch.")


func test_feldaenderung_aendert_genau_eine_zeile() -> void:
	# Arrange: US2, Szenario 2; FR-035.
	var ziel := _oeffnen(MINIMAL)
	var vorher := FileAccess.get_file_as_string(ziel).split("\n")

	# Act
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	var fehler := _editor.save()

	# Assert
	assert_eq(fehler, OK)
	var nachher := FileAccess.get_file_as_string(ziel).split("\n")
	assert_eq(nachher.size(), vorher.size(), "Keine Zeile kommt dazu oder fällt weg.")
	var geaendert := []
	for i in mini(vorher.size(), nachher.size()):
		if vorher[i] != nachher[i]:
			geaendert.append(nachher[i].strip_edges())
	assert_eq(geaendert, ["\"date\": \"1993-04-15\","],
		"Genau die Zeile mit dem Datum ändert sich.")
	assert_false(_editor.is_dirty())
	assert_true(_editor.can_undo(), "Der Verlauf überlebt das Speichern (FR-034).")


func test_fremde_aenderung_wird_erkannt() -> void:
	# Arrange: Edge Case „von außen geändert“. Die fremde Änderung kommt in derselben Sekunde; die
	# Änderungszeit allein verriete sie deshalb nicht.
	var ziel := _oeffnen(MINIMAL)
	var fremd := FileAccess.get_file_as_string(ziel).replace("Superskalare", "Superskalar")
	_schreiben(ziel, fremd)
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)

	# Act
	var ohne_force := _editor.save()

	# Assert
	assert_eq(ohne_force, ERR_FILE_ALREADY_IN_USE)
	assert_string_contains(_editor.last_error, "geändert")
	assert_eq(FileAccess.get_file_as_string(ziel), fremd, "Die fremde Änderung bleibt stehen.")
	assert_true(_editor.is_dirty())
	assert_eq(_editor.save(true), OK, "Auf ausdrücklichen Wunsch wird überschrieben.")
	assert_eq(FileAccess.get_file_as_string(ziel), _editor.catalog.to_json())
	assert_eq(_editor.save(), OK, "Danach gilt der eigene Stand als bekannt.")


func test_unlesbare_datei_bleibt_unberuehrt() -> void:
	# Arrange: erst ein lesbarer Katalog, dann die kaputte Datei.
	_oeffnen(MINIMAL)
	var bisher := _editor.catalog
	var kaputt := _kopie(KAPUTT, "kaputt.json")
	var inhalt := FileAccess.get_file_as_string(kaputt)

	# Act
	var fehler := _editor.open(kaputt)

	# Assert: Edge Case „Katalog unlesbar“
	assert_eq(fehler, ERR_PARSE_ERROR)
	assert_string_contains(_editor.last_error, "Zeile 13", false)
	assert_same(_editor.catalog, bisher, "Der bisherige Katalog bleibt.")
	assert_eq(_editor.path, kaputt)
	assert_true(_editor.is_dirty(), "Der bisherige Katalog steht nicht in der kaputten Datei.")
	assert_eq(_editor.save(), ERR_FILE_ALREADY_IN_USE, "Ohne force bleibt die Datei, wie sie ist.")
	assert_eq(FileAccess.get_file_as_string(kaputt), inhalt, "Die Datei ist unberührt.")
	assert_eq(_editor.save(true), OK, "Mit force wird sie auf Wunsch überschrieben.")
	assert_ne(FileAccess.get_file_as_string(kaputt), inhalt)


func test_verwerfen_stellt_die_datei_her_und_leert_den_verlauf() -> void:
	# Arrange
	var ziel := _oeffnen(MINIMAL)
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	_editor.delete_event("weihnachtsgeschaeft")
	_editor.write_backup()

	# Act
	var fehler := _editor.revert()

	# Assert: FR-034
	assert_eq(fehler, OK)
	assert_eq(_editor.catalog.to_json(), FileAccess.get_file_as_string(ziel))
	assert_false(_editor.is_dirty())
	assert_false(_editor.can_undo(), "Verwerfen leert den Verlauf.")
	assert_false(_editor.can_redo())
	assert_false(_editor.has_backup(), "Verwerfen löscht die Sicherungskopie.")


func test_verwerfen_ohne_lesbare_datei_laesst_alles_stehen() -> void:
	# Arrange: Die Katalogdatei ist inzwischen verschwunden.
	var ziel := _oeffnen(MINIMAL)
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	_editor.write_backup()
	DirAccess.remove_absolute(ziel)

	# Act
	var fehler := _editor.revert()

	# Assert
	assert_eq(fehler, ERR_FILE_NOT_FOUND)
	assert_string_contains(_editor.last_error, ziel, false)
	assert_eq(_editor.catalog.get_event("intel_pentium").date, NEUER_TAG, "Die Änderung bleibt.")
	assert_true(_editor.can_undo(), "Der Verlauf bleibt.")
	assert_true(_editor.is_dirty())
	assert_true(_editor.has_backup(), "Ohne Datei wäre die Kopie der einzige Stand; sie bleibt.")


func test_neue_aktion_nach_rueckgaengig_bleibt_ungespeichert() -> void:
	# Arrange: speichern, eins zurück, dann etwas anderes. get_version() steht danach auf
	# derselben Zahl wie beim Speichern, der Katalog ist aber ein anderer.
	_oeffnen(MINIMAL)
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	_editor.save()
	_editor.undo()

	# Act
	_editor.set_event_field("intel_pentium", &"title", "Pentium kommt")

	# Assert
	assert_true(_editor.is_dirty(), "Der gespeicherte Stand ist nicht mehr im Verlauf.")
	_editor.undo()
	assert_true(_editor.is_dirty(), "Auch eins zurück ist es nicht der gespeicherte Stand.")


func test_unbekannter_schluessel_bleibt_v22_bis_zum_speichern() -> void:
	# Arrange: ereigniskatalog.md, Regel 5. Jemand hat von Hand "farbe" in ein Ereignis geschrieben.
	var text := FileAccess.get_file_as_string(MINIMAL).replace("\"id\": \"intel_pentium\",",
		"\"farbe\": \"rot\",\n\t\t\t\"id\": \"intel_pentium\",")
	var ziel := ORDNER + "katalog.json"
	_schreiben(ziel, text)
	assert_eq(_editor.open(ziel), OK)

	# Act: eine ganz andere Änderung
	_editor.set_event_field("neubaugebiet", &"min_gap_days", 1000)

	# Assert
	var v22 := _editor.issues().filter(
		func(meldung: CatalogIssue) -> bool: return meldung.rule == "V22")
	assert_eq(v22.size(), 1, "Die Meldung beim Lesen bleibt nach der Änderung stehen.")
	if v22.size() == 1:
		assert_eq([v22[0].event_id, v22[0].field], ["intel_pentium", "farbe"])
	assert_true(_editor.has_errors(), "Die Werkstatt fragt deshalb vor dem Speichern nach.")
	assert_eq(_editor.save(), OK)
	assert_eq(_editor.issues().size(), 0,
		"Nach dem Speichern ist der Schlüssel weg und die Meldung auch.")
	assert_false(_editor.has_errors())
	assert_false(FileAccess.get_file_as_string(ziel).contains("farbe"))


# --- Sicherungskopie --------------------------------------------------------------------------

func test_sicherung_nur_bei_ungespeicherten_aenderungen() -> void:
	# Arrange
	_oeffnen(MINIMAL)

	# Act und Assert
	assert_eq(_editor.write_backup(), OK)
	assert_false(_editor.has_backup(), "Ohne Änderung gibt es nichts zu sichern.")
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	assert_eq(_editor.write_backup(), OK)
	assert_true(_editor.has_backup())
	assert_true(_editor.backup_matches())


func test_sicherung_ist_kanonisch_mit_pfad_und_zeit() -> void:
	# Arrange
	var ziel := _oeffnen(MINIMAL)
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	var vorher := int(Time.get_unix_time_from_system())

	# Act
	_editor.write_backup()

	# Assert: {"catalog": …, "format": 1, "path": …, "saved": <Unix-Zeit>} (R23)
	var text := FileAccess.get_file_as_string(_editor.backup_path)
	var daten: Dictionary = JSON.parse_string(text)
	assert_eq(daten.keys(), ["catalog", "format", "path", "saved"], "Schlüssel alphabetisch.")
	assert_eq(daten["format"], 1.0)
	assert_eq(daten["path"], ziel)
	assert_between(int(daten["saved"]), vorher, vorher + 5)
	# Der Katalog steht darin Zeichen für Zeichen wie in seiner Datei, nur eine Ebene tiefer.
	var katalog := _editor.catalog.to_json().strip_edges().replace("\n", "\n\t")
	assert_string_contains(text, "\t\"catalog\": " + katalog + ",\n")
	assert_eq(_editor.backup_info(), {"path": ziel, "saved": int(daten["saved"]),
		"catalog_modified": FileAccess.get_modified_time(ziel)})


func test_sicherung_uebernehmen_nach_einem_absturz() -> void:
	# Arrange: Die Werkstatt hat gesichert und ist dann abgestürzt; eine neue fängt von vorn an.
	var ziel := _oeffnen(MINIMAL)
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	_editor.delete_event("weihnachtsgeschaeft")
	_editor.write_backup()
	var gesichert := _editor.catalog.to_json()
	var neustart := _neuer_editor()
	assert_eq(neustart.open(ziel), OK)

	# Act
	var passt := neustart.backup_matches()
	var fehler := neustart.restore_backup()

	# Assert
	assert_true(passt, "Die Kopie gehört zu diesem Katalog.")
	assert_eq(fehler, OK)
	assert_eq(neustart.catalog.to_json(), gesichert, "Der gesicherte Stand ist wieder da.")
	assert_true(neustart.is_dirty(), "Übernommen heißt noch nicht gespeichert.")
	assert_false(neustart.can_undo())
	assert_true(neustart.has_backup(), "Die Kopie bleibt bis zum Speichern liegen.")
	neustart.discard_backup()
	assert_false(neustart.has_backup())
	assert_eq(FileAccess.get_file_as_string(ziel), FileAccess.get_file_as_string(MINIMAL),
		"Die Katalogdatei selbst ist unverändert.")


func test_sicherung_eines_anderen_katalogs_passt_nicht() -> void:
	# Arrange: R23. Die Kopie gehört zu katalog.json, geöffnet wird ein anderer.
	_oeffnen(MINIMAL)
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	_editor.write_backup()
	var anderer := _neuer_editor()
	assert_eq(anderer.open(_kopie(UEBERNAHME, "anderer.json")), OK)

	# Act
	var passt := anderer.backup_matches()
	var fehler := anderer.restore_backup()

	# Assert
	assert_true(anderer.has_backup())
	assert_false(passt, "Angeboten wird nur eine Kopie desselben Katalogs.")
	assert_eq(anderer.backup_info()["path"], _editor.path, "Der Hinweis nennt ihren Katalog.")
	assert_eq(fehler, ERR_INVALID_DATA)
	assert_eq(anderer.catalog.events.size(), 25, "Der geöffnete Katalog bleibt.")
	assert_true(anderer.has_backup(), "Die fremde Kopie bleibt liegen.")


func test_fremde_sicherungskopie_wird_weder_ueberschrieben_noch_geloescht() -> void:
	# Arrange: R23, „bleibt sie liegen“. Die Kopie gehört zu katalog.json; geöffnet und geändert
	# wird ein anderer Katalog. Es gibt nur die eine Datei für die Kopie.
	_oeffnen(MINIMAL)
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	_editor.write_backup()
	var kopie := FileAccess.get_file_as_string(_editor.backup_path)
	var anderer := _neuer_editor()
	assert_eq(anderer.open(_kopie(UEBERNAHME, "anderer.json")), OK)
	anderer.set_event_field("intel_pentium", &"title", "Pentium kommt")

	# Act
	var schreiben := anderer.write_backup()
	anderer.discard_backup()
	anderer.revert()

	# Assert
	assert_eq(schreiben, ERR_ALREADY_EXISTS,
		"Die Kopie des anderen Katalogs wird nicht überschrieben.")
	assert_eq(FileAccess.get_file_as_string(_editor.backup_path), kopie,
		"Weder Löschen noch Verwerfen trifft die fremde Kopie.")
	_editor.discard_backup()
	assert_false(_editor.has_backup(), "Der eigene Katalog löscht seine Kopie.")


func test_unlesbare_sicherungskopie_darf_ueberschrieben_werden() -> void:
	# Arrange: Eine abgebrochen geschriebene Kopie gehört erkennbar zu keinem Katalog.
	_oeffnen(MINIMAL)
	_schreiben(_editor.backup_path, "{\"catalog\": ")
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)

	# Act
	var fehler := _editor.write_backup()

	# Assert
	assert_eq(fehler, OK)
	assert_true(_editor.backup_matches(), "Jetzt liegt die eigene, lesbare Kopie dort.")


# --- Inhalt vergleichen ----------------------------------------------------------------------

func test_inhaltsschluessel_ist_so_genau_wie_die_kanonische_form() -> void:
	# Arrange: Simulator und Statistik vergleichen damit, ob der Katalog ein anderer ist (FR-042).
	_oeffnen(MINIMAL)
	var anfang := _editor.content_key()
	var kanonisch := _editor.catalog.to_json()

	# Act und Assert: Eine Änderung ändert ihn, Rückgängig stellt ihn wieder her.
	_editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	assert_ne(_editor.content_key(), anfang)
	_editor.undo()
	assert_eq(_editor.content_key(), anfang, "Nach Rückgängig ist es wieder derselbe Inhalt.")
	# Auch die Kategorien gehören zum Inhalt.
	_editor.set_category_field("lokal", &"name", "Stadt")
	assert_ne(_editor.content_key(), anfang)
	_editor.undo()
	# Verwerfen liest neue Objekte mit demselben Inhalt: derselbe Text, wie bei to_json().
	_editor.set_event_field("intel_pentium", &"title", "Pentium kommt")
	assert_eq(_editor.revert(), OK)
	assert_eq(_editor.catalog.to_json(), kanonisch)
	assert_eq(_editor.content_key(), anfang, "Gleicher Inhalt in neuen Objekten.")
	assert_eq(CatalogEditor.new().content_key(), "", "Ohne Katalog ist er leer.")


# --- Speicher ---------------------------------------------------------------------------------

func test_editor_wird_samt_verlauf_freigegeben() -> void:
	# Arrange: R15. UndoRedo ist kein RefCounted; der Editor gibt es in NOTIFICATION_PREDELETE frei.
	# Das geht nur, wenn der Verlauf den Editor nicht selbst festhält.
	var editor := _neuer_editor()
	assert_eq(editor.open(_kopie(MINIMAL)), OK)
	editor.set_event_field("intel_pentium", &"date", NEUER_TAG)
	editor.delete_event("zeitungsartikel")
	editor.undo()
	var verweis: WeakRef = weakref(editor)

	# Act
	editor = null

	# Assert
	assert_null(verweis.get_ref(), "Ohne Verweis von außen ist der Editor samt Verlauf weg.")


# --- Helfer -----------------------------------------------------------------------------------

func _neuer_editor() -> CatalogEditor:
	var editor := CatalogEditor.new()
	editor.backup_path = ORDNER + "sicherung.json"
	return editor


## Kopiert [param fixture] in den Testordner und gibt den Pfad der Kopie zurück.
func _kopie(fixture: String, datei: String = "katalog.json") -> String:
	var ziel := ORDNER + datei
	_schreiben(ziel, FileAccess.get_file_as_string(fixture))
	return ziel


## Öffnet eine Kopie von [param fixture] im Editor des Tests und gibt ihren Pfad zurück.
func _oeffnen(fixture: String) -> String:
	var ziel := _kopie(fixture)
	assert_eq(_editor.open(ziel), OK, "Der Test-Katalog %s muss sich öffnen lassen." % fixture)
	return ziel


func _schreiben(ziel: String, text: String) -> void:
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()
