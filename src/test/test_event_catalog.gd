extends GutTest

## Prüft den Ereigniskatalog als Datei (Feature 002, T013): lesen, kanonisch schreiben, Zahlen,
## Strukturfehler beim Lesen (V22) mit ihren Vorgaben und das Ausnehmen fehlerhafter Ereignisse.
##
## Der wichtigste Test ist die Rundreise: Eine Datei lesen und wieder schreiben muss denselben
## Text ergeben, Byte für Byte. Sonst erzeugte schon das erste Speichern in der Werkstatt einen
## Diff, ohne dass Klaus etwas geändert hat, und eine Feldänderung änderte mehr als eine Zeile
## (FR-035).
##
## Die Tests lesen nie den echten Katalog unter res://data/. Sie nehmen Kataloge unter
## res://test/fixtures/ oder bauen sich kleine Kataloge im Code; so bleiben sie grün, wenn
## Klaus den echten Katalog in der Werkstatt ändert.

## Die eingefrorene Übernahme aus T012; sie ändert sich nie mehr.
const UEBERNAHME := "res://test/fixtures/event_catalog_uebernahme.json"
## Das Beispiel aus contracts/ereigniskatalog.md: jede Art einmal.
const ALLE_ARTEN := "res://test/fixtures/catalog_alle_arten.json"
## Kein gültiges JSON: In Zeile 12 fehlt am Ende das Komma, der Parser merkt es in Zeile 13.
const KAPUTT := "res://test/fixtures/catalog_v22_kaputt.json"
const FEHLT := "res://test/fixtures/gibt_es_nicht.json"


# --- Rundreise ------------------------------------------------------------

func test_uebernahme_lesen_und_schreiben_ergibt_denselben_text() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []
	var datei := FileAccess.get_file_as_string(UEBERNAHME)

	# Act
	var catalog := EventCatalog.read_file(UEBERNAHME, issues)

	# Assert
	assert_eq(issues.size(), 0, "Die Übernahme muss sich ohne Meldung lesen lassen: %s" % [issues])
	assert_not_null(catalog, "Die Übernahme muss sich lesen lassen.")
	if catalog != null:
		assert_eq(catalog.to_json(), datei, "Lesen und Schreiben muss bytegleich sein.")


func test_jede_art_lesen_und_schreiben_ergibt_denselben_text() -> void:
	# Die Übernahme hat nur fixe Ereignisse und solche über Wahrscheinlichkeit. Das Beispiel
	# aus dem Vertrag hat jede Art einmal, dazu ein Folgeereignis und eine Wirkung „during“.
	var issues: Array[CatalogIssue] = []
	var datei := FileAccess.get_file_as_string(ALLE_ARTEN)

	var catalog := EventCatalog.read_file(ALLE_ARTEN, issues)

	assert_eq(issues.size(), 0, "Das Beispiel muss sich ohne Meldung lesen lassen: %s" % [issues])
	assert_not_null(catalog, "Das Beispiel muss sich lesen lassen.")
	if catalog != null:
		assert_eq(catalog.to_json(), datei, "Lesen und Schreiben muss bytegleich sein.")


func test_felder_jeder_art_kommen_richtig_an() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(ALLE_ARTEN, issues)
	if catalog == null:
		fail_test("Das Beispiel muss sich lesen lassen: %s" % [issues])
		return

	# Assert: fix, mit Datum als Tagesindex und verzögerter Wirkung
	var pentium := catalog.get_event("intel_pentium")
	assert_eq(pentium.kind, TimelineEvent.Kind.FIXED)
	assert_eq(pentium.date, GameDate.new(1993, 3, 22).to_day_index(), "Datum als Tagesindex.")
	assert_eq(pentium.effects[1].delay_days, 14)
	assert_eq(pentium.effects[0].describe(), "Preis · cpu_486 · -30% — 486 wird zur Mittelklasse.")

	# Assert: beim Start gesetzt, mit Zeitfenster und Gewichten
	var neubau := catalog.get_event("neubaugebiet_am_stadtrand")
	assert_eq(neubau.kind, TimelineEvent.Kind.PRESET)
	assert_eq(neubau.window_from, GameDate.new(1987, 1, 1).to_day_index())
	assert_eq(neubau.window_to, GameDate.new(1996, 12, 31).to_day_index())
	assert_eq(neubau.count_min, 0)
	assert_eq(neubau.count_weights, [30.0, 70.0])
	assert_eq(neubau.min_gap_days, 1095)

	# Assert: über Wahrscheinlichkeit, mit Folgeereignis
	var welle := catalog.get_event("reklamationswelle")
	assert_eq(welle.kind, TimelineEvent.Kind.CHANCE)
	assert_eq(welle.monthly_chance, 0.03)
	assert_eq(welle.max_occurrences, 0)
	assert_eq(welle.follow_ups[0].target, "zeitungsartikel_reklamation")
	assert_eq(welle.follow_ups[0].chance, 0.5)
	assert_eq([welle.follow_ups[0].delay_min, welle.follow_ups[0].delay_max], [7, 21])

	# Assert: jährlich bis Monatsende, Wirkung nur während
	var weihnachten := catalog.get_event("weihnachtsgeschaeft")
	assert_eq(weihnachten.kind, TimelineEvent.Kind.YEARLY)
	assert_eq(weihnachten.yearly_start, Vector2i(11, 1))
	assert_eq(weihnachten.yearly_end, Vector2i(12, 0), "„12-ende“ heißt Dezember, Tag 0.")
	assert_eq([weihnachten.yearly_from, weihnachten.yearly_to], [1985, 1999])
	assert_true(weihnachten.has_duration())
	assert_eq(weihnachten.effects[0].scope, EventEffect.Scope.DURING)

	# Assert: nur als Folge
	var artikel := catalog.get_event("zeitungsartikel_reklamation")
	assert_eq(artikel.kind, TimelineEvent.Kind.FOLLOW_ONLY)
	assert_eq(artikel.kind_label(), "nur als Folge")


func test_jede_art_schreibt_genau_ihre_schluessel() -> void:
	# Schreibregel 4: die gemeinsamen Schlüssel und die der eigenen Art, auch leere Listen.
	for wert: int in TimelineEvent.Kind.values():
		# Arrange
		var event := TimelineEvent.new()
		event.kind = wert as TimelineEvent.Kind
		var erwartet: Array = TimelineEvent.COMMON_KEYS.duplicate()
		erwartet.append_array(TimelineEvent.KIND_KEYS[event.kind])
		erwartet.sort()

		# Act
		var schluessel := event.to_dict().keys()
		schluessel.sort()

		# Assert
		assert_eq(schluessel, erwartet, "Schlüssel der Art %s." % event.kind_label())


# --- Zahlen ---------------------------------------------------------------

func test_ganze_zahlen_stehen_ohne_nachkomma() -> void:
	# Arrange: JSON.parse() liest jede Zahl als float. Hier stehen die ganzen Zahlen deshalb
	# gleich als 14.0, 90.0 und so weiter im Text.
	var welle := _zufall("reklamationswelle", {"min_gap_days": 90.0, "max_occurrences": 4.0})
	welle["effects"] = [_wirkung({"delay_days": 14.0})]
	var neubau := _gesetzt("neubaugebiet", {"count_min": 0.0, "count_weights": [30.0, 70.0]})
	var text := _text([welle, neubau])
	assert_string_contains(text, "\"delay_days\": 14.0", false)

	# Act
	var issues: Array[CatalogIssue] = []
	var geschrieben := EventCatalog.from_json(text, issues).to_json()

	# Assert
	assert_eq(issues.size(), 0, "%s" % [issues])
	for zeile in ["\"delay_days\": 14,", "\"min_gap_days\": 90,", "\"max_occurrences\": 4,",
			"\"count_min\": 0,", "\"duration_days\": 0,", "\"format\": 1"]:
		assert_string_contains(geschrieben, zeile)
	assert_false(geschrieben.contains("30.0") or geschrieben.contains("70.0"),
		"Gewichte ohne Nachkommastellen stehen als 30 und 70 in der Datei.")
	assert_false(geschrieben.contains("14.0"), "Aus 14.0 muss beim Schreiben 14 werden.")


func test_anteile_auf_vier_und_gewichte_auf_zwei_stellen() -> void:
	# Arrange
	var welle := _zufall("reklamationswelle", {"monthly_chance": 0.123456})
	welle["effects"] = [_wirkung({"kind": "reputation", "magnitude": -0.123456})]
	welle["follow_ups"] = [_folgeereignis({"chance": 0.123456})]
	var neubau := _gesetzt("neubaugebiet",
		{"count_min": 0.0, "count_weights": [33.333333, 33.333333, 33.333334]})

	# Act
	var issues: Array[CatalogIssue] = []
	var geschrieben := EventCatalog.from_json(_text([welle, neubau]), issues).to_json()

	# Assert
	assert_eq(issues.size(), 0, "%s" % [issues])
	assert_string_contains(geschrieben, "\"monthly_chance\": 0.1235,")
	assert_string_contains(geschrieben, "\"magnitude\": -0.1235,")
	assert_string_contains(geschrieben, "\"chance\": 0.1235,")
	assert_eq(geschrieben.count("33.33"), 3, "Jedes Gewicht steht auf zwei Stellen gerundet da.")
	assert_false(geschrieben.contains("33.333"), "Kein Gewicht hat mehr als zwei Stellen.")


# --- Fehler beim Lesen (V22) ----------------------------------------------

func test_kaputtes_json_ergibt_keinen_katalog_und_nennt_die_zeile() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(KAPUTT, issues)

	# Assert
	assert_null(catalog, "Aus kaputtem JSON darf kein Katalog entstehen.")
	assert_eq(issues.size(), 1, "Genau eine Meldung: %s" % [issues])
	if issues.size() == 1:
		assert_eq(issues[0].rule, "V22")
		assert_eq(issues[0].severity, CatalogIssue.Severity.ERROR)
		assert_eq(issues[0].field, "Zeile 13", "Die Zeile zählt ab 1 wie im Texteditor.")
		assert_string_contains(issues[0].message, "Zeile 13")
		assert_string_contains(issues[0].message, KAPUTT)


func test_fehlende_datei_nennt_den_pfad() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(FEHLT, issues)

	# Assert
	assert_null(catalog)
	assert_eq(issues.size(), 1, "%s" % [issues])
	if issues.size() == 1:
		assert_eq(issues[0].rule, "V22")
		assert_string_contains(issues[0].message, FEHLT)


func test_unbekannter_schluessel_ist_v22_und_faellt_beim_schreiben_weg() -> void:
	# Arrange
	var pentium := _fixes("intel_pentium", {"datum": "1993"})
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text([pentium]), issues)

	# Assert
	assert_not_null(catalog, "Ein unbekannter Schlüssel verhindert den Katalog nicht.")
	assert_eq(issues.size(), 1, "%s" % [issues])
	if issues.size() == 1:
		assert_eq(issues[0].rule, "V22")
		assert_eq(issues[0].event_id, "intel_pentium")
		assert_eq(issues[0].field, "datum")
		assert_string_contains(issues[0].message, "intel_pentium")
	if catalog != null:
		assert_eq(catalog.events.size(), 1,
			"Das Ereignis bleibt im Katalog, damit die Werkstatt es zeigt.")
		assert_false(catalog.to_json().contains("datum"), "Der Katalog behält den Schlüssel nicht.")


func test_datum_ohne_kalendertag_ist_v22_mit_vorgabe() -> void:
	# Arrange: den 30. Februar gibt es nicht, einen Monat 13 auch nicht.
	var pentium := _fixes("intel_pentium", {"date": "1993-02-30"})
	var welle := _zufall("reklamationswelle")
	welle["window"] = {"from": "1990-13-01", "to": "1999-12-31"}
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text([pentium, welle]), issues)

	# Assert
	assert_eq(_felder(issues), ["intel_pentium date", "reklamationswelle window.from"],
		"Je Datum eine Meldung an seiner Stelle: %s" % [issues])
	assert_eq(catalog.get_event("intel_pentium").date, 0, "Vorgabe ist der 01.01.1985.")
	assert_eq(catalog.get_event("reklamationswelle").window_from, 0, "Vorgabe ist Tag 0.")


func test_fehlende_felder_bekommen_die_vorgaben() -> void:
	# Arrange: ein Ereignis über Wahrscheinlichkeit, dem alles Eigene seiner Art fehlt.
	var welle := _zufall("reklamationswelle")
	for schluessel in ["conditions", "duration_days", "max_occurrences", "min_gap_days",
			"monthly_chance", "window"]:
		welle.erase(schluessel)
	var neubau := _gesetzt("neubaugebiet")
	neubau.erase("count_min")
	neubau.erase("count_weights")
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text([welle, neubau]), issues)

	# Assert: je fehlendem Schlüssel eine Meldung V22 …
	assert_eq(issues.size(), 8, "%s" % [issues])
	for issue in issues:
		assert_eq(issue.rule, "V22")
	# … und dieselben Vorgaben wie bei einem neuen Ereignis (data-model.md, „Vorgaben“).
	var neu := TimelineEvent.new()
	var gelesen := catalog.get_event("reklamationswelle")
	assert_eq(gelesen.monthly_chance, neu.monthly_chance)
	assert_eq([gelesen.window_from, gelesen.window_to], [0, 5477], "Zeitfenster 0 bis 5477.")
	assert_eq([gelesen.max_occurrences, gelesen.min_gap_days, gelesen.duration_days], [0, 0, 0])
	assert_eq(gelesen.conditions.size(), 0)
	var gesetzt := catalog.get_event("neubaugebiet")
	assert_eq(gesetzt.count_min, 1, "Vorgabe: genau einmal.")
	assert_eq(gesetzt.count_weights, [100.0])


func test_wirkung_ohne_scope_gilt_bei_dauer_nur_waehrend() -> void:
	# Arrange: FR-007, die Vorgabe hängt an der Dauer des Ereignisses.
	var ohne_scope := _wirkung()
	ohne_scope.erase("scope")
	var lang := _fixes("messe", {"duration_days": 7, "effects": [ohne_scope]})
	var kurz := _fixes("meldung", {"effects": [ohne_scope.duplicate()]})
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text([lang, kurz]), issues)

	# Assert
	assert_eq(_felder(issues), ["meldung effects[0].scope", "messe effects[0].scope"],
		"Der fehlende Scope ist je Ereignis eine Meldung: %s" % [issues])
	assert_eq(catalog.get_event("messe").effects[0].scope, EventEffect.Scope.DURING)
	assert_eq(catalog.get_event("meldung").effects[0].scope, EventEffect.Scope.ONCE)


func test_bedingung_bei_fixem_ereignis_ist_kein_v22() -> void:
	# Arrange: Das meldet erst die Prüfung, als V17 (data-model.md).
	var pentium := _fixes("intel_pentium", {"conditions": [{"event": "win_95", "occurred": true}]})
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text([pentium]), issues)

	# Assert
	assert_eq(issues.size(), 0,
		"conditions ist bei jeder Art ein bekannter Schlüssel: %s" % [issues])
	assert_eq(catalog.get_event("intel_pentium").conditions.size(), 1,
		"Die Bedingung wird gelesen, damit die Prüfung sie sieht.")


func test_anderes_format_ergibt_keinen_katalog() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text([], 2), issues)

	# Assert
	assert_null(catalog, "Ein Katalog im Format 2 darf nicht als Format 1 gelesen werden.")
	assert_eq(_felder(issues), [" format"], "%s" % [issues])


func test_ereignisse_stehen_nach_kennung_sortiert() -> void:
	# Arrange: in der Datei absichtlich durcheinander.
	var ids := ["win_95", "intel_pentium2", "amd_386dx40", "intel_pentium"]
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text(ids.map(_fixes)), issues)

	# Assert
	var gelesen := catalog.events.map(func(event: TimelineEvent) -> String: return event.id)
	assert_eq(gelesen, ["amd_386dx40", "intel_pentium", "intel_pentium2", "win_95"],
		"Verglichen wird Zeichen für Zeichen, das kürzere Wort zuerst.")
	var text := catalog.to_json()
	assert_lt(text.find("\"intel_pentium\""), text.find("\"intel_pentium2\""))


# --- Fehlerhafte Ereignisse ausnehmen -------------------------------------

func test_ohne_fehlerhafte_ereignisse_fehlt_auch_das_folgeereignis_darauf() -> void:
	# Arrange: „kaputt“ hat einen unbekannten Schlüssel, also einen Fehler. „ausloeser“ zeigt
	# per Folgeereignis auf „kaputt“ und auf „folge“, „wartet“ hat eine Bedingung auf „kaputt“.
	var ausloeser := _zufall("ausloeser")
	ausloeser["follow_ups"] = [_folgeereignis({"target": "kaputt"}),
		_folgeereignis({"target": "folge"})]
	var wartet := _zufall("wartet")
	wartet["conditions"] = [{"event": "kaputt", "occurred": true}]
	var kaputt := _folge("kaputt", {"farbe": "rot"})
	var folge := _folge("folge")
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.from_json(_text([ausloeser, wartet, kaputt, folge]), issues)
	# Eine Warnung nimmt nichts aus.
	issues.append(CatalogIssue.new(CatalogIssue.Severity.WARNING, "V13", "wartet", "monthly_chance",
		"Ereignis „wartet“: Grundchance 0."))

	# Act
	var sauber := catalog.without_faulty(issues)

	# Assert
	var ids := sauber.events.map(func(event: TimelineEvent) -> String: return event.id)
	assert_eq(ids, ["ausloeser", "folge", "wartet"], "Nur „kaputt“ fehlt.")
	var ziele := sauber.get_event("ausloeser").follow_ups.map(
		func(follow_up: FollowUp) -> String: return follow_up.target)
	assert_eq(ziele, ["folge"], "Das Folgeereignis auf „kaputt“ fällt mit weg.")
	assert_eq(sauber.get_event("wartet").conditions[0].event, "kaputt",
		"Bedingungen bleiben stehen.")
	assert_eq(catalog.events.size(), 4, "Der Katalog selbst bleibt unverändert.")
	assert_eq(catalog.get_event("ausloeser").follow_ups.size(), 2)


# --- Helfer ---------------------------------------------------------------

## Ein Katalog als Text mit einer Kategorie und den Ereignissen [param events].
func _text(events: Array, format: int = EventCatalog.FORMAT) -> String:
	var data := {
		"categories": [{"color": "nacht-hell", "id": "hardware", "name": "Hardware"}],
		"events": events,
		"format": format,
	}
	return JSON.stringify(data, "\t", true) + "\n"


## Ein fixes Ereignis, wie es in der Datei steht; [param overrides] ersetzt oder ergänzt
## Schlüssel.
func _fixes(id: String, overrides: Dictionary = {}) -> Dictionary:
	var data := {
		"category": "hardware", "date": "1993-03-22", "description": "", "duration_days": 0,
		"effects": [], "follow_ups": [], "id": id, "kind": "fixed", "title": "Test %s" % id,
	}
	data.merge(overrides, true)
	return data


## Ein Ereignis über Wahrscheinlichkeit.
func _zufall(id: String, overrides: Dictionary = {}) -> Dictionary:
	var data := {
		"category": "hardware", "conditions": [], "description": "", "duration_days": 0,
		"effects": [], "follow_ups": [], "id": id, "kind": "chance", "max_occurrences": 0,
		"min_gap_days": 0, "monthly_chance": 0.03, "title": "Test %s" % id,
		"window": {"from": "1985-01-01", "to": "1999-12-31"},
	}
	data.merge(overrides, true)
	return data


## Ein Ereignis „beim Start gesetzt“.
func _gesetzt(id: String, overrides: Dictionary = {}) -> Dictionary:
	var data := {
		"category": "hardware", "conditions": [], "count_min": 1, "count_weights": [100],
		"description": "", "duration_days": 0, "effects": [], "follow_ups": [], "id": id,
		"kind": "preset", "min_gap_days": 0, "title": "Test %s" % id,
		"window": {"from": "1987-01-01", "to": "1996-12-31"},
	}
	data.merge(overrides, true)
	return data


## Ein Ereignis „nur als Folge“.
func _folge(id: String, overrides: Dictionary = {}) -> Dictionary:
	var data := {
		"category": "hardware", "conditions": [], "description": "", "duration_days": 0,
		"effects": [], "follow_ups": [], "id": id, "kind": "follow_only", "title": "Test %s" % id,
	}
	data.merge(overrides, true)
	return data


func _wirkung(overrides: Dictionary = {}) -> Dictionary:
	var data := {
		"delay_days": 0, "kind": "presse", "magnitude": 0.0, "note": "", "scope": "once",
		"target": "*",
	}
	data.merge(overrides, true)
	return data


func _folgeereignis(overrides: Dictionary = {}) -> Dictionary:
	var data := {"chance": 1.0, "delay_max": 0, "delay_min": 0, "target": "folge"}
	data.merge(overrides, true)
	return data


## Die Meldungen als „<kennung> <feld>“, sortiert; so vergleicht ein Test alle auf einmal.
func _felder(issues: Array[CatalogIssue]) -> Array:
	var felder := []
	for issue in issues:
		felder.append("%s %s" % [issue.event_id, issue.field])
	felder.sort()
	return felder
