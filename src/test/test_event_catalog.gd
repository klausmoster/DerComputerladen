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


func test_falscher_typ_ist_v22_mit_vorgabe() -> void:
	# Arrange (T085; data-model.md, V22): eine Zahl statt eines Datums, ein Text statt einer Zahl
	# und eine Kommazahl, wo eine ganze Zahl hingehört.
	var pentium := _fixes("intel_pentium", {"date": 5})
	var welle := _zufall("reklamationswelle",
		{"monthly_chance": "drei Prozent", "min_gap_days": 1.5})
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text([pentium, welle]), issues)

	# Assert: je Wert eine Meldung an seiner Stelle, die sagt, was dort stehen muss.
	assert_eq(_felder(issues), ["intel_pentium date", "reklamationswelle min_gap_days",
		"reklamationswelle monthly_chance"], "%s" % [issues])
	assert_eq(_texte(issues), [
		"Ereignis „intel_pentium“, Feld „date“: Erwartet wird ein Datum als Text, in der Datei "
			+ "steht die Zahl 5.",
		"Ereignis „reklamationswelle“, Feld „min_gap_days“: Erwartet wird eine ganze Zahl, in der "
			+ "Datei steht die Zahl 1.5.",
		"Ereignis „reklamationswelle“, Feld „monthly_chance“: Erwartet wird eine Zahl, in der "
			+ "Datei steht der Text „drei Prozent“.",
	])
	for issue in issues:
		assert_eq([issue.rule, issue.severity], ["V22", CatalogIssue.Severity.ERROR])
	# Das Ereignis bleibt mit den Vorgaben im Katalog, damit die Werkstatt es zeigt.
	assert_eq(catalog.get_event("intel_pentium").date, 0, "Vorgabe ist der 01.01.1985.")
	var gelesen := catalog.get_event("reklamationswelle")
	assert_eq([gelesen.monthly_chance, gelesen.min_gap_days], [0.0, 0])


func test_unbekannter_wert_fuer_kind_und_scope_ist_v22() -> void:
	# Arrange (T085): „monatlich“ ist keine Art, „immer“ kein Scope; die Messe dauert eine Woche.
	var welle := _zufall("reklamationswelle", {"kind": "monatlich"})
	var messe := _fixes("messe", {"duration_days": 7, "effects": [_wirkung({"scope": "immer"})]})
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text([welle, messe]), issues)

	# Assert: je eine Meldung mit den erlaubten Werten. Für die Schlüssel der unbekannten Art,
	# etwa window und monthly_chance, kommt keine weitere.
	assert_eq(_felder(issues), ["messe effects[0].scope", "reklamationswelle kind"],
		"%s" % [issues])
	assert_eq(_texte(issues), [
		"Ereignis „reklamationswelle“, Feld „kind“: Unbekannter Wert „monatlich“, erlaubt sind: "
			+ "fixed, yearly, preset, chance, follow_only.",
		"Ereignis „messe“, Feld „effects[0].scope“: Unbekannter Wert „immer“, erlaubt sind: once, "
			+ "during.",
	])
	for issue in issues:
		assert_eq([issue.rule, issue.severity], ["V22", CatalogIssue.Severity.ERROR])
	# Vorgaben: ohne lesbare Art „fix“, ohne lesbaren Scope bei Dauer „während“ (FR-007).
	assert_eq(catalog.get_event("reklamationswelle").kind, TimelineEvent.Kind.FIXED)
	assert_eq(catalog.get_event("messe").effects[0].scope, EventEffect.Scope.DURING)


func test_monat_ausserhalb_von_01_bis_12_ist_v22() -> void:
	# Arrange (T098; ereigniskatalog.md, Feld end): Einen Monat 00 gibt es nicht. „00-00“ und
	# „00-ende“ ergaben bisher (0, 0), also still „ohne Dauer“, und beim Speichern „“. Ein Monat 13
	# ist ebenso keiner, und beim Beginn gilt dasselbe.
	var events := [
		_jaehrlich("beginn_null", {"start": "00-05"}),
		_jaehrlich("beginn_null_null", {"start": "00-00"}),
		_jaehrlich("ende_dreizehn", {"end": "13-ende"}),
		_jaehrlich("ende_null", {"end": "00-00"}),
		_jaehrlich("ende_null_ende", {"end": "00-ende"}),
	]
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text(events), issues)

	# Assert: je Wert eine Meldung an seiner Stelle, wie bei anderen ungültigen Werten.
	assert_eq(_felder(issues), ["beginn_null yearly.start", "beginn_null_null yearly.start",
		"ende_dreizehn yearly.end", "ende_null yearly.end", "ende_null_ende yearly.end"],
		"%s" % [issues])
	for issue in issues:
		assert_eq([issue.rule, issue.severity], ["V22", CatalogIssue.Severity.ERROR])
	assert_has(_texte(issues), "Ereignis „ende_null“, Feld „yearly.end“: „00-00“ ist kein Tag im "
		+ "Jahr wie 11-01 oder 12-ende.")
	assert_has(_texte(issues), "Ereignis „beginn_null“, Feld „yearly.start“: „00-05“ ist kein Tag "
		+ "im Jahr wie 11-01 oder 12-ende.")
	# Das Ereignis bleibt mit den Vorgaben im Katalog: ohne Dauer, Beginn am 01.01.
	assert_eq(catalog.get_event("ende_null").yearly_end, Vector2i.ZERO)
	assert_eq(catalog.get_event("beginn_null").yearly_start, Vector2i(1, 1))


func test_tag_00_ist_v22() -> void:
	# Arrange (T098; Klaus, 2026-10-21): Einen Tag 00 gibt es nicht; das Format kennt nur „MM-TT“,
	# „MM-ende“ und „“. „05-00“ ergab bisher (5, 0), also still „Monatsende“, und beim Speichern
	# „05-ende“. Beim Beginn gilt dasselbe.
	var events := [
		_jaehrlich("beginn_tag_null", {"start": "12-00"}),
		_jaehrlich("ende_tag_null", {"end": "05-00"}),
	]
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text(events), issues)

	# Assert: je Wert eine Meldung an seiner Stelle, wie bei anderen ungültigen Werten.
	assert_eq(_felder(issues), ["beginn_tag_null yearly.start", "ende_tag_null yearly.end"],
		"%s" % [issues])
	for issue in issues:
		assert_eq([issue.rule, issue.severity], ["V22", CatalogIssue.Severity.ERROR])
	assert_has(_texte(issues), "Ereignis „ende_tag_null“, Feld „yearly.end“: „05-00“ ist kein "
		+ "Tag im Jahr wie 11-01 oder 12-ende.")
	assert_has(_texte(issues), "Ereignis „beginn_tag_null“, Feld „yearly.start“: „12-00“ ist "
		+ "kein Tag im Jahr wie 11-01 oder 12-ende.")
	# Das Ereignis bleibt mit den Vorgaben im Katalog: ohne Dauer, Beginn am 01.01.
	assert_eq(catalog.get_event("ende_tag_null").yearly_end, Vector2i.ZERO)
	assert_eq(catalog.get_event("beginn_tag_null").yearly_start, Vector2i(1, 1))


func test_monate_01_bis_12_und_ohne_dauer_sind_kein_v22() -> void:
	# Arrange: die Gegenprobe zu T098, mit dem ersten und dem letzten Monat
	var events := [
		_jaehrlich("dezember", {"end": "12-ende", "start": "12-01"}),
		_jaehrlich("januar", {"end": "01-31", "start": "01-01"}),
		_jaehrlich("ohne_dauer", {"end": ""}),
	]
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_text(events), issues)

	# Assert
	assert_eq(issues.size(), 0, "%s" % [issues])
	var dezember := catalog.get_event("dezember")
	assert_eq([dezember.yearly_start, dezember.yearly_end], [Vector2i(12, 1), Vector2i(12, 0)])
	assert_eq(catalog.get_event("januar").yearly_end, Vector2i(1, 31))
	assert_eq(catalog.get_event("ohne_dauer").yearly_end, Vector2i.ZERO)


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


## Ein jährliches Ereignis wie der Winter, vom 01.12. bis Ende Februar; [param yearly] ersetzt
## Schlüssel im Objekt "yearly".
func _jaehrlich(id: String, yearly: Dictionary = {}) -> Dictionary:
	var tage := {"end": "02-ende", "from": 1985, "start": "12-01", "to": 1999}
	tage.merge(yearly, true)
	return {
		"category": "hardware", "description": "", "effects": [], "follow_ups": [], "id": id,
		"kind": "yearly", "title": "Test %s" % id, "yearly": tage,
	}


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


## Die Texte der Meldungen in ihrer Reihenfolge.
func _texte(issues: Array[CatalogIssue]) -> Array:
	var texte := []
	for issue in issues:
		texte.append(issue.message)
	return texte
