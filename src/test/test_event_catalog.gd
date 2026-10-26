extends GutTest

## Prüft den Ereigniskatalog als Datei (Feature 002, T013): lesen, kanonisch schreiben, Zahlen,
## Strukturfehler beim Lesen (V22) mit ihren Vorgaben und das Ausnehmen fehlerhafter Ereignisse.
## Seit Feature 004 (T005) auch from_data() für schon geparste Daten, wie sie im Spielstand stehen.
##
## Der wichtigste Test ist die Rundreise: Eine Datei lesen und wieder schreiben muss denselben
## Text ergeben, Byte für Byte. Sonst erzeugte schon das erste Speichern in der Werkstatt einen
## Diff, ohne dass Klaus etwas geändert hat, und eine Feldänderung änderte mehr als eine Zeile
## (FR-035).
##
## Die Tests lesen nie den echten Katalog unter res://data/. Sie nehmen Kataloge unter
## res://test/fixtures/ oder bauen sich kleine Kataloge im Code; so bleiben sie grün, wenn
## Klaus den echten Katalog in der Werkstatt ändert.

## Die eingefrorene Übernahme aus T012; sie ändert sich nie mehr. Sie ist eine Datei aus
## Feature 002, ohne den Abschnitt „profiles“.
const UEBERNAHME := "res://test/fixtures/event_catalog_uebernahme.json"
## Das Beispiel aus contracts/ereigniskatalog.md: jede Art einmal, dazu je ein Start-Modifikator in
## Leicht und Schwer (Feature 003).
const ALLE_ARTEN := "res://test/fixtures/catalog_alle_arten.json"
## Kein gültiges JSON: In Zeile 12 fehlt am Ende das Komma, der Parser merkt es in Zeile 13.
const KAPUTT := "res://test/fixtures/catalog_v22_kaputt.json"
const FEHLT := "res://test/fixtures/gibt_es_nicht.json"
## Strukturfehler im Abschnitt „profiles“ (Feature 003, T005): ein Profil für Mittel, eines für
## einen Grad, den es nicht gibt, und ein Wert als Text an der Stelle 1 von Schwer.
const PROFIL_MITTEL := "res://test/fixtures/catalog_v22_profil_mittel.json"
const PROFIL_UNBEKANNT := "res://test/fixtures/catalog_v22_profil_unbekannt.json"
const PROFIL_WERT_TEXT := "res://test/fixtures/catalog_v22_profil_wert_text.json"
## So endet eine Datei aus Feature 002, und so nach dem ersten Speichern: Komma hinter
## "format": 1, dazu vier Zeilen (research.md, R3).
const ENDE_OHNE_PROFILE := "\t\"format\": 1\n}\n"
const ENDE_MIT_LEEREN_PROFILEN := "\t\"format\": 1,\n\t\"profiles\": {\n\t\t\"leicht\": [],\n" \
	+ "\t\t\"schwer\": []\n\t}\n}\n"


# --- Rundreise ------------------------------------------------------------

func test_uebernahme_bekommt_beim_schreiben_nur_den_leeren_abschnitt() -> void:
	# Arrange (Feature 003, R3 und R17): Die Übernahme bleibt Byte für Byte, wie sie ist, eine Datei
	# aus Feature 002 ohne Profile.
	var issues: Array[CatalogIssue] = []
	var datei := FileAccess.get_file_as_string(UEBERNAHME)
	assert_false(datei.contains("\"profiles\""), "Die eingefrorene Übernahme hat keine Profile.")
	assert_string_ends_with(datei, ENDE_OHNE_PROFILE)

	# Act
	var catalog := EventCatalog.read_file(UEBERNAHME, issues)
	if catalog == null:
		fail_test("Die Übernahme muss sich lesen lassen: %s" % [issues])
		return
	var erste := catalog.to_json()
	var zweite := EventCatalog.from_json(erste, issues).to_json()

	# Assert
	assert_eq(issues.size(), 0, "Die Übernahme muss sich ohne Meldung lesen lassen: %s" % [issues])
	assert_eq(erste, datei.trim_suffix(ENDE_OHNE_PROFILE) + ENDE_MIT_LEEREN_PROFILEN,
		"Bis auf das Komma hinter \"format\": 1 und die vier Zeilen des Abschnitts bytegleich.")
	assert_eq(erste.split("\n").size(), datei.split("\n").size() + 4, "Genau vier Zeilen mehr.")
	assert_eq(zweite, erste, "Eine zweite Rundreise ändert nichts mehr.")


func test_jede_art_lesen_und_schreiben_ergibt_denselben_text() -> void:
	# Die Übernahme hat nur fixe Ereignisse und solche über Wahrscheinlichkeit. Das Beispiel
	# aus dem Vertrag hat jede Art einmal, dazu ein Folgeereignis, eine Wirkung „during“ und den
	# Abschnitt „profiles“ mit je einem Start-Modifikator.
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

	# Assert: die Profile, Leicht −2 das ganze Spiel und Schwer +5 von 1990 bis 1994
	var leicht := catalog.get_profile(Difficulty.Level.LEICHT)
	var schwer := catalog.get_profile(Difficulty.Level.SCHWER)
	assert_eq([leicht.level, schwer.level], [Difficulty.Level.LEICHT, Difficulty.Level.SCHWER])
	assert_eq([leicht.modifiers.size(), schwer.modifiers.size()], [1, 1])
	var nachsichtig := leicht.modifiers[0]
	assert_eq([nachsichtig.id, nachsichtig.event_id, nachsichtig.reason],
		["reklamationswelle", "reklamationswelle", "Nachsichtige Kunden"])
	assert_eq([nachsichtig.value, nachsichtig.from_day, nachsichtig.to_day], [-0.02, 0, 5477])
	assert_eq([schwer.modifiers[0].from_day, schwer.modifiers[0].to_day],
		[GameDate.new(1990, 1, 1).to_day_index(), GameDate.new(1994, 12, 31).to_day_index()])
	assert_eq(schwer.modifiers[0].value, 0.05)


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


# --- Profile (Feature 003) ------------------------------------------------

func test_profile_lesen_und_schreiben() -> void:
	# Arrange: Leicht mit einem Start-Modifikator, Schwer mit zweien in absichtlich unsortierter
	# Reihenfolge
	var profile := {
		"leicht": [_start_modifikator({"value": -0.02})],
		"schwer": [_start_modifikator({"id": "zweiter"}), _start_modifikator({"id": "erster"})],
	}
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_mit_profilen(profile), issues)

	# Assert
	assert_eq(issues.size(), 0, "%s" % [issues])
	assert_eq(catalog.profiles.size(), 2, "Immer zwei Profile.")
	assert_eq([catalog.profiles[0].level, catalog.profiles[1].level],
		[Difficulty.Level.LEICHT, Difficulty.Level.SCHWER], "[0] Leicht, [1] Schwer.")
	assert_same(catalog.get_profile(Difficulty.Level.SCHWER), catalog.profiles[1])
	assert_null(catalog.get_profile(Difficulty.Level.MITTEL), "Mittel hat kein Profil.")
	assert_null(catalog.get_profile(7), "Einen Grad 7 gibt es nicht.")
	var kennungen := catalog.profiles[1].modifiers.map(
		func(modifikator: ChanceModifier) -> String: return modifikator.id)
	assert_eq(kennungen, ["zweiter", "erster"], "Die Reihenfolge der Datei bleibt (R2).")
	var text := catalog.to_json()
	assert_eq(EventCatalog.from_json(text, issues).to_json(), text, "Kanonisch geschrieben.")
	assert_lt(text.find("\"format\": 1,"), text.find("\"profiles\": {"),
		"Der Abschnitt steht am Ende, hinter format.")


func test_fehlender_abschnitt_und_fehlender_grad_ohne_meldung() -> void:
	# Arrange: eine Datei aus Feature 002 und eine, in der Leicht fehlt (FR-005)
	var issues: Array[CatalogIssue] = []

	# Act
	var ohne_abschnitt := EventCatalog.from_json(_text([_zufall("reklamationswelle")]), issues)
	var nur_schwer := EventCatalog.from_json(
		_mit_profilen({"schwer": [_start_modifikator()]}), issues)

	# Assert
	assert_eq(issues.size(), 0, "Kein Abschnitt und kein Grad sind kein Fehler: %s" % [issues])
	for profil in ohne_abschnitt.profiles:
		assert_eq(profil.modifiers.size(), 0, "Ohne Abschnitt sind beide Profile leer.")
	assert_eq(nur_schwer.get_profile(Difficulty.Level.LEICHT).modifiers.size(), 0)
	assert_eq(nur_schwer.get_profile(Difficulty.Level.SCHWER).modifiers.size(), 1)
	assert_string_ends_with(ohne_abschnitt.to_json(), ENDE_MIT_LEEREN_PROFILEN,
		"Geschrieben wird der Abschnitt immer, mit beiden Graden (Schreibregel 4).")


func test_profil_fuer_mittel_ist_v22() -> void:
	# Arrange (R4): neben Leicht und Schwer ein Profil „mittel“ mit einem Start-Modifikator
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(PROFIL_MITTEL, issues)

	# Assert
	assert_eq(_stellen(issues), ["V22 ERROR - profiles.mittel"], "%s" % [issues])
	assert_eq(_texte(issues), ["Katalog, Feld „profiles.mittel“: Für „Mittel“ gibt es kein Profil: "
		+ "Mittel ist der Katalog ohne Start-Modifikatoren."])
	assert_not_null(catalog, "Der Katalog entsteht trotzdem.")
	if catalog != null:
		assert_false(catalog.to_json().contains("\"mittel\""), "Der Katalog behält es nicht.")


func test_unbekannter_grad_ist_v22() -> void:
	# Arrange (R4): ein Profil „extrem“ in der Datei, eines „Schwer“ mit großem S im Code
	var issues: Array[CatalogIssue] = []
	var gross: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(PROFIL_UNBEKANNT, issues)
	EventCatalog.from_json(_mit_profilen({"Schwer": []}), gross)

	# Assert
	assert_eq(_stellen(issues), ["V22 ERROR - profiles.extrem"], "%s" % [issues])
	assert_eq(_texte(issues), ["Katalog, Feld „profiles.extrem“: Den Schwierigkeitsgrad „extrem“ "
		+ "gibt es nicht; Profile gibt es nur für „leicht“ und „schwer“."])
	assert_eq(_stellen(gross), ["V22 ERROR - profiles.Schwer"], "Groß- und Kleinschreibung zählt.")
	if catalog != null:
		assert_false(catalog.to_json().contains("extrem"), "Der Katalog behält es nicht.")


func test_wert_als_text_ist_v22_an_seiner_stelle() -> void:
	# Arrange: Schwer hat zwei Start-Modifikatoren, der zweite mit dem Wert „fünf“
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(PROFIL_WERT_TEXT, issues)

	# Assert
	assert_eq(_stellen(issues), ["V22 ERROR - profiles.schwer[1].value"], "%s" % [issues])
	assert_eq(_texte(issues), ["Profil „Schwer“, Start-Modifikator „reklamationswelle_2“, Feld "
		+ "„profiles.schwer[1].value“: Erwartet wird eine Zahl, in der Datei steht der Text "
		+ "„fünf“."])
	var schwer := catalog.get_profile(Difficulty.Level.SCHWER)
	assert_eq(schwer.modifiers.size(), 2,
		"Er bleibt mit der Vorgabe, damit die Werkstatt ihn zeigt.")
	assert_eq([schwer.modifiers[0].value, schwer.modifiers[1].value], [0.05, 0.0])


func test_falscher_typ_fuer_abschnitt_profil_und_eintrag_ist_v22() -> void:
	# Arrange: der Abschnitt als Liste; Leicht als Objekt und in Schwer eine Zahl statt eines
	# Objekts
	var abschnitt: Array[CatalogIssue] = []
	var innen: Array[CatalogIssue] = []

	# Act
	var als_liste := EventCatalog.from_json(_mit_profilen([]), abschnitt)
	var catalog := EventCatalog.from_json(_mit_profilen({"leicht": {}, "schwer": [5]}), innen)

	# Assert
	assert_eq(_texte(abschnitt), ["Katalog, Feld „profiles“: Erwartet wird ein Objekt, in der "
		+ "Datei steht eine Liste."])
	assert_eq(_stellen(abschnitt), ["V22 ERROR - profiles"])
	assert_eq(als_liste.profiles.size(), 2, "Beide Profile bleiben, leer.")
	assert_eq(_stellen(innen), ["V22 ERROR - profiles.leicht", "V22 ERROR - profiles.schwer[0]"])
	assert_eq(_texte(innen), [
		"Profil „Leicht“, Feld „profiles.leicht“: Erwartet wird eine Liste, in der Datei steht ein "
			+ "Objekt.",
		"Profil „Schwer“, Start-Modifikator Nr. 1 ohne Kennung, Feld „profiles.schwer[0]“: "
			+ "Erwartet wird ein Objekt, in der Datei steht die Zahl 5.",
	])
	assert_eq(catalog.get_profile(Difficulty.Level.LEICHT).modifiers.size(), 0)
	assert_eq(catalog.get_profile(Difficulty.Level.SCHWER).modifiers.size(), 1,
		"An der Stelle steht ein Start-Modifikator mit den Vorgaben.")


func test_datum_unbekannter_und_fehlender_schluessel_im_profil_sind_v22() -> void:
	# Arrange
	var ohne_grund := _start_modifikator({"id": "ohne_grund"})
	ohne_grund.erase("reason")
	var schwer := [
		_start_modifikator({"from_day": "1990-02-30"}),
		_start_modifikator({"id": "farbig", "farbe": "rot"}),
		ohne_grund,
	]
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_json(_mit_profilen({"schwer": schwer}), issues)

	# Assert
	assert_eq(_stellen(issues), ["V22 ERROR - profiles.schwer[0].from_day",
		"V22 ERROR - profiles.schwer[1].farbe", "V22 ERROR - profiles.schwer[2].reason"])
	assert_eq(_texte(issues), [
		"Profil „Schwer“, Start-Modifikator „reklamationswelle“, Feld "
			+ "„profiles.schwer[0].from_day“: „1990-02-30“ ist kein Kalendertag in der Form "
			+ "JJJJ-MM-TT.",
		"Profil „Schwer“, Start-Modifikator „farbig“, Feld „profiles.schwer[1].farbe“: Diesen "
			+ "Schlüssel kennt der Katalog nicht.",
		"Profil „Schwer“, Start-Modifikator „ohne_grund“, Feld „profiles.schwer[2].reason“: Der "
			+ "Schlüssel fehlt.",
	])
	assert_false(catalog.to_json().contains("farbe"), "Der Katalog behält den Schlüssel nicht.")


func test_to_dict_stellt_die_oberste_ebene_zusammen() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(ALLE_ARTEN, issues)
	var leer := EventCatalog.new()

	# Act
	var daten := catalog.to_dict()

	# Assert
	var schluessel := daten.keys()
	schluessel.sort()
	assert_eq(schluessel, EventCatalog.KEYS, "categories, events, format und profiles.")
	assert_eq(EventCatalog.KEYS, ["categories", "events", "format", "profiles"])
	assert_eq(daten["profiles"]["leicht"], catalog.profiles[0].to_list())
	assert_eq(JSON.stringify(daten, "\t", true) + "\n", catalog.to_json(), "to_json() nutzt es.")
	assert_eq(leer.to_dict()["profiles"], {"leicht": [], "schwer": []},
		"Ein neuer Katalog hat zwei leere Profile.")
	assert_eq(leer.profiles.size(), 2)


func test_kopie_kopiert_die_profile() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(ALLE_ARTEN, issues)

	# Act
	var kopie := catalog.duplicate_catalog()
	kopie.profiles[1].modifiers[0].value = 0.5

	# Assert
	assert_eq(kopie.profiles.size(), 2)
	assert_eq(kopie.profiles[0].to_list(), catalog.profiles[0].to_list(), "Gleicher Inhalt.")
	assert_ne(kopie.profiles[1], catalog.profiles[1], "Neue Objekte.")
	assert_eq(catalog.profiles[1].modifiers[0].value, 0.05, "Das Original bleibt unberührt.")


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


func test_ohne_fehlerhafte_start_modifikatoren() -> void:
	# Arrange (data-model.md, „Fehlerhafte Start-Modifikatoren ausnehmen“): Die Meldungen stehen
	# hier von Hand da, so wie Lesen und Prüfung sie bringen. In Schwer:
	# [0] gilt, mit einer Warnung; [1] hat einen eigenen Fehler; [2] zeigt auf „kaputt“, das selbst
	# einen Fehler hat und ausgenommen wird; [3] zeigt auf das fixe „intel_pentium“; [4] auf ein
	# Ereignis, das es nicht gibt. In Leicht hat [1] einen Fehler am ganzen Eintrag.
	var catalog := _katalog_mit_kaputten_start_modifikatoren()
	var issues := _meldungen_zu_kaputten_start_modifikatoren()

	# Act
	var sauber := catalog.without_faulty(issues)

	# Assert
	var schwer := sauber.get_profile(Difficulty.Level.SCHWER).modifiers.map(
		func(modifikator: ChanceModifier) -> String: return modifikator.id)
	var leicht := sauber.get_profile(Difficulty.Level.LEICHT).modifiers.map(
		func(modifikator: ChanceModifier) -> String: return modifikator.id)
	assert_eq(schwer, ["gilt"], "Nur der fehlerfreie auf ein Ereignis über Wahrscheinlichkeit.")
	assert_eq(leicht, ["gilt"])
	assert_not_null(sauber.get_event("reklamationswelle"),
		"Fehler in Profilen nehmen kein Ereignis aus (R8).")
	assert_null(sauber.get_event("kaputt"))
	assert_eq(catalog.get_profile(Difficulty.Level.SCHWER).modifiers.size(), 5,
		"Der Katalog selbst bleibt unverändert.")
	assert_eq(catalog.get_profile(Difficulty.Level.LEICHT).modifiers.size(), 2)


func test_weggelassene_start_modifikatoren_mit_ort_und_grund() -> void:
	# Arrange: dieselben wie oben
	var catalog := _katalog_mit_kaputten_start_modifikatoren()
	var issues := _meldungen_zu_kaputten_start_modifikatoren()

	# Act
	var weg := catalog.skipped_start_modifiers(issues)

	# Assert: Leicht vor Schwer, je Profil nach Stelle; genau die, die without_faulty() weglässt.
	var kurz := weg.map(
		func(eintrag: Dictionary) -> String:
			return "%s %d %s" % [Difficulty.key(eintrag["level"]), eintrag["index"],
				"Ereignis" if eintrag["by_event"] else "eigener Fehler"])
	assert_eq(kurz, ["leicht 1 eigener Fehler", "schwer 1 eigener Fehler", "schwer 2 Ereignis",
		"schwer 3 Ereignis", "schwer 4 Ereignis"])
	if weg.size() != 5:
		return
	assert_same(weg[1]["modifier"], catalog.get_profile(Difficulty.Level.SCHWER).modifiers[1],
		"Der Start-Modifikator des Katalogs selbst.")
	assert_eq(weg[1]["place"], "Profil „Schwer“, Start-Modifikator „ohne_grund“")
	assert_eq(weg[1]["reason"], "Profil „Schwer“, Start-Modifikator „ohne_grund“, Feld "
		+ "„profiles.schwer[1].reason“: Der Grund ist leer.", "Der Text der ersten Meldung.")
	assert_eq(weg[0]["reason"], "Leicht kaputt.")
	assert_eq(weg[2]["place"], "Profil „Schwer“, Start-Modifikator „auf_kaputt“")
	assert_eq(weg[2]["reason"],
		"Das Ereignis „kaputt“ wird übersprungen, deshalb auch dieser Start-Modifikator.")
	var leer: Array[CatalogIssue] = []
	assert_eq(EventCatalog.read_file(ALLE_ARTEN, leer).skipped_start_modifiers(leer).size(), 0,
		"Ohne Meldungen fällt bei einem gültigen Katalog nichts weg.")


# --- Schon geparste Daten (Feature 004, T005) ------------------------------

func test_from_data_liest_ein_objekt_ohne_json_text() -> void:
	# Arrange (R2): So steht der Katalog im Spielstand, als Abschnitt „catalog“ im gelesenen JSON,
	# mit jeder Zahl als float.
	var datei := FileAccess.get_file_as_string(ALLE_ARTEN)
	var daten: Variant = JSON.parse_string(datei)
	var vorher: Dictionary = daten.duplicate(true)
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_data(daten, issues)

	# Assert
	assert_eq(issues.size(), 0, "Ohne Meldung: %s" % [issues])
	assert_not_null(catalog)
	if catalog == null:
		return
	assert_eq(catalog.to_json(), datei, "Derselbe Katalog wie aus dem Text, bytegleich.")
	assert_eq(catalog.profiles[1].modifiers.size(), 1, "Mit den Profilen.")
	assert_eq(daten, vorher, "Die Daten selbst bleiben, wie sie waren.")
	var noch_einmal := EventCatalog.from_data(catalog.to_dict(), issues)
	assert_eq(noch_einmal.to_json(), datei, "Auch aus to_dict(), mit ganzen Zahlen als int.")
	assert_eq(issues.size(), 0, "%s" % [issues])


func test_from_data_mit_zahl_statt_objekt() -> void:
	# Arrange: ein Spielstand mit "catalog": 42
	var issues: Array[CatalogIssue] = []
	var aus_text: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_data(42.0, issues)
	EventCatalog.from_json("42", aus_text)

	# Assert
	assert_null(catalog, "Aus einer Zahl entsteht kein Katalog.")
	assert_eq(_texte(issues),
		["Katalog: Erwartet wird ein Objekt { … }, in der Datei steht die Zahl 42."])
	assert_eq(_stellen(issues), ["V22 ERROR - "])
	assert_eq(_texte(aus_text), _texte(issues), "Dieselbe Meldung wie aus dem Text.")
	issues.clear()
	assert_null(EventCatalog.from_data(null, issues), "Fehlt der Abschnitt, auch keiner.")
	assert_eq(_texte(issues),
		["Katalog: Erwartet wird ein Objekt { … }, in der Datei steht null."])


func test_from_data_im_format_2_ergibt_keinen_katalog() -> void:
	# Arrange: ein Katalog aus einer späteren Version, mit dem Format als float wie aus JSON
	var daten: Variant = JSON.parse_string(_text([_fixes("intel_pentium")], 2))
	var issues: Array[CatalogIssue] = []
	var aus_text: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_data(daten, issues)
	EventCatalog.from_json(_text([_fixes("intel_pentium")], 2), aus_text)

	# Assert
	assert_null(catalog, "Ein Katalog im Format 2 darf nicht als Format 1 gelesen werden.")
	assert_eq(_texte(issues), ["Katalog, Feld „format“: Das Format 2 kennt diese Version nicht, "
		+ "sie liest nur 1."])
	assert_eq(_stellen(issues), ["V22 ERROR - format"])
	assert_eq(_texte(aus_text), _texte(issues), "Dieselbe Meldung wie aus dem Text.")


func test_from_data_meldet_fehler_in_eintraegen_wie_from_json() -> void:
	# Arrange: die Fehler aus test_falscher_typ_ist_v22_mit_vorgabe(), dazu ein unbekannter
	# Schlüssel oben
	var pentium := _fixes("intel_pentium", {"date": 5})
	var welle := _zufall("reklamationswelle",
		{"monthly_chance": "drei Prozent", "min_gap_days": 1.5})
	var text := _text([pentium, welle]).replace("\"format\": 1", "\"format\": 1,\n\t\"farbe\": 2")
	var issues: Array[CatalogIssue] = []
	var aus_text: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.from_data(JSON.parse_string(text), issues)
	var aus_dem_text := EventCatalog.from_json(text, aus_text)

	# Assert: Fehler in Einträgen erlauben einen Katalog, mit denselben Meldungen wie aus dem Text.
	assert_not_null(catalog)
	assert_eq(issues.size(), 4, "%s" % [issues])
	assert_eq(_texte(issues), _texte(aus_text))
	assert_eq(_stellen(issues), _stellen(aus_text))
	if catalog != null and aus_dem_text != null:
		assert_eq(catalog.to_json(), aus_dem_text.to_json(), "Derselbe Katalog.")


# --- Helfer ---------------------------------------------------------------

## Ein Katalog als Text wie _text(), dazu der Abschnitt profiles mit [param profile]; ohne
## [param events] mit der Reklamationswelle über Wahrscheinlichkeit.
func _mit_profilen(profile: Variant, events: Array = []) -> String:
	var data := {
		"categories": [{"color": "nacht-hell", "id": "hardware", "name": "Hardware"}],
		"events": events if not events.is_empty() else [_zufall("reklamationswelle")],
		"format": EventCatalog.FORMAT,
		"profiles": profile,
	}
	return JSON.stringify(data, "\t", true) + "\n"


## Ein Start-Modifikator, wie er in der Datei steht: +5 auf die Reklamationswelle, das ganze Spiel.
func _start_modifikator(overrides: Dictionary = {}) -> Dictionary:
	var data := {
		"event_id": "reklamationswelle", "from_day": "1985-01-01", "id": "reklamationswelle",
		"reason": "Anspruchsvolle Kunden", "to_day": "1999-12-31", "value": 0.05,
	}
	data.merge(overrides, true)
	return data


## Reklamationswelle und „kaputt“ über Wahrscheinlichkeit, intel_pentium fix; dazu die
## Start-Modifikatoren aus test_ohne_fehlerhafte_start_modifikatoren().
func _katalog_mit_kaputten_start_modifikatoren() -> EventCatalog:
	var schwer := [
		_start_modifikator({"id": "gilt"}),
		_start_modifikator({"id": "ohne_grund", "reason": ""}),
		_start_modifikator({"id": "auf_kaputt", "event_id": "kaputt"}),
		_start_modifikator({"id": "auf_fix", "event_id": "intel_pentium"}),
		_start_modifikator({"id": "ins_leere", "event_id": "gibt_es_nicht"}),
	]
	var leicht := [_start_modifikator({"id": "gilt"}), _start_modifikator({"id": "kaputt_leicht"})]
	var events := [_zufall("reklamationswelle"), _zufall("kaputt"), _fixes("intel_pentium")]
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.from_json(_mit_profilen({"leicht": leicht, "schwer": schwer},
		events), issues)
	assert_eq(issues.size(), 0, "Der Test-Katalog liest sich ohne Meldung: %s" % [issues])
	return catalog


## Die Meldungen dazu: ein Fehler an Schwer [1] mit Feld, einer an Leicht [1] am ganzen Eintrag,
## einer am Ereignis „kaputt“ und eine Warnung an Schwer [0].
func _meldungen_zu_kaputten_start_modifikatoren() -> Array[CatalogIssue]:
	var fehler := CatalogIssue.Severity.ERROR
	return [
		CatalogIssue.new(CatalogIssue.Severity.WARNING, "V31", "", "profiles.schwer[0].from_day",
			"Eine Warnung nimmt nichts aus."),
		CatalogIssue.new(fehler, "V12", "kaputt", "monthly_chance", "Ereignis „kaputt“: zu hoch."),
		CatalogIssue.new(fehler, "V29", "", "profiles.schwer[1].reason", "Profil „Schwer“, "
			+ "Start-Modifikator „ohne_grund“, Feld „profiles.schwer[1].reason“: Der Grund ist "
			+ "leer."),
		CatalogIssue.new(fehler, "V22", "", "profiles.leicht[1]", "Leicht kaputt."),
		CatalogIssue.new(fehler, "V30", "", "profiles.schwer[1].id",
			"Die zweite Meldung zählt nicht."),
	]


## Die Meldungen als „<Regel> <Stufe> <Kennung> <Feld>“ in ihrer Reihenfolge; eine leere Kennung
## steht als „-“.
func _stellen(issues: Array[CatalogIssue]) -> Array:
	var stellen := []
	for issue in issues:
		var kennung := issue.event_id if not issue.event_id.is_empty() else "-"
		stellen.append("%s %s %s %s"
			% [issue.rule, CatalogIssue.Severity.keys()[issue.severity], kennung, issue.field])
	return stellen


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
