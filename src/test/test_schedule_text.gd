extends GutTest

## Prüft die Textausgabe des Fahrplans (Feature 002, T027): Kopfzeile, Spalten mit fester Breite,
## die Spalte „bis“, die Zusätze hinter dem Titel und die verzögerten Wirkungen unter ihrem Termin.
## Dazu SC-002: Zehn Läufe mit gleichem Seed ergeben zehn gleiche Ausgaben, ob Tag für Tag oder in
## Sprüngen geschaltet, auch mit gleichen Eingriffen (T085).
##
## Für die Spalte „bis“ und zwei der Zusätze legt ein Test Termine von Hand in einen leeren Lauf,
## so wie der Lauf sie anlegt. ScheduleText formatiert nur, was im Fahrplan steht; wie der Lauf
## Dauer und jährliche Ereignisse anlegt, prüft test_timeline_run.gd.

const ORDNER := "res://test/fixtures/"
const LETZTER_TAG := TimelineRun.LAST_DAY


func test_kopfzeile_und_zeile_mit_festen_spalten() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("catalog_minimal"), 4711)
	run.advance_to(LETZTER_TAG)

	# Act
	var zeilen := ScheduleText.plan_lines(run)

	# Assert: Die leere Spalte „bis“ hat 14 Zeichen, die Kennung 28, Herkunft und Zustand je 12,
	# jede gefolgt von zwei Leerzeichen.
	assert_eq(zeilen[0], "# Seed 4711, bis 31.12.1999")
	var pentium := zeilen.find("22.03.1993" + _leer(2 + 14 + 2) + "intel_pentium" + _leer(15 + 2)
		+ "fix" + _leer(9 + 2) + "eingetreten" + _leer(1 + 2) + "Intel Pentium erscheint")
	assert_gt(pentium, 0, "Die Zeile des Pentiums mit Spalten von 14, 28, 12 und 12 Zeichen.")
	if pentium > 0:
		assert_eq(zeilen[pentium + 1],
			"05.04.1993    └ Nachfrage · ram · +20% — Pentium-Systeme wollen Speicher.",
			"Die verzögerte Wirkung steht mit ihrem Tag unter ihrem Termin (FR-013).")


func test_bis_zu_einem_tag() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("event_catalog_uebernahme"), 4711)
	var bis := _tag(1990, 12, 31)
	run.advance_to(bis)

	# Act
	var zeilen := ScheduleText.plan_lines(run, bis)

	# Assert
	assert_eq(zeilen[0], "# Seed 4711, bis 31.12.1990")
	assert_gt(zeilen.size(), 1)
	for i in range(1, zeilen.size()):
		if zeilen[i].contains("└"):
			continue
		var datum := zeilen[i].substr(0, 10)
		var tag := GameDate.new(datum.substr(6, 4).to_int(), datum.substr(3, 2).to_int(),
			datum.substr(0, 2).to_int()).to_day_index()
		assert_lte(tag, bis, "Kein Termin nach dem 31.12.1990: %s" % zeilen[i])


func test_spalte_bis_und_zusaetze() -> void:
	# Arrange: ein leerer Lauf und drei Termine von Hand, so wie der Lauf sie anlegt
	var katalog := _katalog("catalog_minimal")
	var run := TimelineRun.new(EventCatalog.new(), 4711)
	var winter := TimelineEvent.new()
	winter.id = "winter"
	winter.title = "Winter"
	winter.kind = TimelineEvent.Kind.YEARLY
	var vorher := _termin(winter, _tag(1985, 1, 1), _tag(1985, 3, 1), ScheduleEntry.Origin.YEARLY,
		ScheduleEntry.State.ENDED)
	vorher.started_before_game = true
	var folge := _termin(katalog.get_event("zeitungsartikel"), _tag(1993, 6, 2), _tag(1993, 6, 2),
		ScheduleEntry.Origin.FOLLOW_UP, ScheduleEntry.State.OCCURRED)
	folge.source_event_id = "reklamationswelle"
	var weihnachten := _termin(katalog.get_event("weihnachtsgeschaeft"), _tag(1999, 11, 1),
		_tag(2000, 1, 1), ScheduleEntry.Origin.YEARLY, ScheduleEntry.State.RUNNING)
	run.entries.assign([vorher, folge, weihnachten])

	# Act
	var zeilen := ScheduleText.plan_lines(run)

	# Assert: Die letzte Zeile ist das Beispiel aus dem Vertrag.
	assert_eq(Array(zeilen), [
		"# Seed 4711, bis 31.12.1999",
		"01.01.1985  bis 28.02.1985  winter" + _leer(22 + 2) + "jährlich" + _leer(4 + 2)
			+ "beendet" + _leer(5 + 2) + "Winter (lief schon vor Spielbeginn)",
		"02.06.1993" + _leer(2 + 14 + 2) + "zeitungsartikel" + _leer(13 + 2) + "Folge"
			+ _leer(7 + 2) + "eingetreten" + _leer(1 + 2)
			+ "Zeitungsartikel über Reklamationen (Folge von reklamationswelle)",
		"01.11.1999  bis 31.12.1999  weihnachtsgeschaeft           jährlich      läuft         "
			+ "Weihnachtsgeschäft (Ende nach Spielende)",
	])
	# Ein entfallener Termin endet nie, auch nicht nach Spielende.
	weihnachten.state = ScheduleEntry.State.SKIPPED
	assert_false(ScheduleText.plan_lines(run)[3].contains("Ende nach Spielende"))


func test_folgetermine_aus_einem_lauf() -> void:
	# Arrange: Die Ketten aus catalog_us1_kette beginnen am 10.05.1990 (siehe test_timeline_run.gd).
	var run := TimelineRun.new(_katalog("catalog_us1_kette"), 4711)
	run.advance_to(LETZTER_TAG)

	# Act
	var zeilen := ScheduleText.plan_lines(run)

	# Assert
	assert_has(zeilen, "10.05.1990" + _leer(2 + 14 + 2) + "kette_01" + _leer(20 + 2) + "Folge"
		+ _leer(7 + 2) + "eingetreten" + _leer(1 + 2) + "Kette 01 (Folge von start_a)")
	assert_has(zeilen, "10.05.1990" + _leer(2 + 14 + 2) + "kette_16" + _leer(20 + 2) + "Folge"
		+ _leer(7 + 2) + "entfallen" + _leer(3 + 2) + "Kette 16 (Folge von kette_15)")


func test_abgesagter_termin_steht_ohne_verzoegerte_wirkung_da() -> void:
	# Arrange (T097): zweimal das Neubaugebiet per Eingriff, mit seiner Wirkung 30 Tage nach dem
	# Beginn; der erste Termin wird abgesagt. Der Lauf meldet dessen Wirkung nie.
	var run := TimelineRun.new(_katalog("catalog_minimal"), 4711)
	assert_eq(run.schedule_event("neubaugebiet", _tag(1990, 3, 1), "Erster Bauabschnitt"), OK)
	assert_eq(run.schedule_event("neubaugebiet", _tag(1994, 3, 1), "Zweiter Bauabschnitt"), OK)
	var abgesagt := run.find_planned("neubaugebiet", _tag(1990, 3, 1))
	assert_eq(run.cancel_entry(abgesagt.serial, "Bauamt sagt nein"), OK)
	run.advance_to(LETZTER_TAG)

	# Act
	var zeilen := ScheduleText.plan_lines(run)

	# Assert: unter dem abgesagten Termin keine Wirkung, unter dem eingetretenen seine.
	var erster := -1
	var zweiter := -1
	for i in zeilen.size():
		if zeilen[i].contains("neubaugebiet") and zeilen[i].contains("Eingriff"):
			if zeilen[i].begins_with("01.03.1990"):
				erster = i
			elif zeilen[i].begins_with("01.03.1994"):
				zweiter = i
	assert_gt(erster, 0, "Die Zeile des abgesagten Termins steht da.")
	assert_gt(zweiter, 0, "Die Zeile des zweiten Termins steht da.")
	if erster > 0 and zweiter > 0:
		assert_string_contains(zeilen[erster], "abgesagt")
		assert_false(zeilen[erster + 1].contains("└"),
			"Keine Wirkung unter dem abgesagten Termin: %s" % zeilen[erster + 1])
		assert_eq(zeilen[zweiter + 1],
			"31.03.1994    └ Kundenstrom · * · +20% — Neue Anwohner ziehen zu.",
			"Der eingetretene zeigt sie wie bisher.")
	var gemeldet := 0
	for meldung in run.protocol:
		if meldung.entry == abgesagt and meldung.kind == TimelineMessage.Kind.EFFECT_STARTED:
			gemeldet += 1
	assert_eq(gemeldet, 0, "Gemeldet wird sie auch nicht.")


func test_protokollzeilen_sind_die_zeilen_der_meldungen() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("event_catalog_uebernahme"), 4711)
	run.advance_to(LETZTER_TAG)
	var erwartet := []
	for meldung in run.protocol:
		erwartet.append(meldung.to_line())

	# Act
	var zeilen := ScheduleText.protocol_lines(run)

	# Assert
	assert_gt(zeilen.size(), 0)
	assert_eq(Array(zeilen), erwartet)


func test_zehn_laeufe_mit_gleichem_seed_ergeben_gleiche_ausgaben() -> void:
	# Arrange (SC-002): fünf Läufe Tag für Tag, fünf in verschieden großen Sprüngen
	var catalog := _katalog("event_catalog_uebernahme")
	var ausgaben := []

	# Act
	for durchgang in 5:
		var taeglich := TimelineRun.new(catalog, 4711)
		for tag in range(0, LETZTER_TAG + 1):
			taeglich.advance_to(tag)
		ausgaben.append(_ausgabe(taeglich))
	for sprung: int in [7, 30, 91, 365, 1000]:
		var in_spruengen := TimelineRun.new(catalog, 4711)
		var tag := 0
		while not in_spruengen.is_finished():
			in_spruengen.advance_to(tag)
			tag += sprung
		ausgaben.append(_ausgabe(in_spruengen))

	# Assert
	assert_eq(ausgaben.size(), 10)
	for i in range(1, ausgaben.size()):
		assert_eq(ausgaben[i], ausgaben[0], "Lauf %d gleicht Lauf 1 Zeichen für Zeichen." % (i + 1))


func test_zehn_laeufe_mit_gleichen_eingriffen_ergeben_gleiche_ausgaben() -> void:
	# Arrange (SC-002 mit Eingriffen, T085): catalog_us6_reklamation mit Folgen, Bedingungen,
	# Dauer, jährlichen und gesetzten Ereignissen, dazu ein festes Eingriffsprotokoll mit jeder Art
	# Eingriff. Jeder kommt an seinem Tag dran, wie im Simulator; nur die Schritte dazwischen sind
	# verschieden.
	var catalog := _katalog("catalog_us6_reklamation")
	var protokoll := _festes_protokoll()
	var ausgaben := []

	# Act: fünf Läufe Tag für Tag, fünf in verschieden großen Sprüngen
	for durchgang in 5:
		ausgaben.append(_ausgabe(_mit_eingriffen(catalog, protokoll, 1)))
	for sprung: int in [7, 30, 91, 365, 1000]:
		ausgaben.append(_ausgabe(_mit_eingriffen(catalog, protokoll, sprung)))

	# Assert
	assert_eq(ausgaben.size(), 10)
	for i in range(1, ausgaben.size()):
		assert_eq(ausgaben[i], ausgaben[0], "Lauf %d gleicht Lauf 1 Zeichen für Zeichen." % (i + 1))
	var ohne := TimelineRun.new(catalog, 4711)
	ohne.advance_to(LETZTER_TAG)
	assert_ne(ausgaben[0], _ausgabe(ohne),
		"Die Eingriffe ändern den Fahrplan; der Vergleich oben sagt also etwas.")


# --- Helfer ----------------------------------------------------------------------

## Liest einen Test-Katalog aus res://test/fixtures/.
func _katalog(datei: String) -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(ORDNER + datei + ".json", issues)
	if catalog == null:
		fail_test("%s lässt sich nicht lesen: %s" % [datei, issues])
		return EventCatalog.new()
	return catalog


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


## [param anzahl] Leerzeichen; so steht im Test, wie breit jede Lücke ist.
func _leer(anzahl: int) -> String:
	return " ".repeat(anzahl)


## Ein Termin von Hand, wie ihn der Lauf anlegt.
func _termin(event: TimelineEvent, tag: int, ende: int, herkunft: ScheduleEntry.Origin,
		zustand: ScheduleEntry.State) -> ScheduleEntry:
	var termin := ScheduleEntry.new()
	termin.event = event
	termin.day = tag
	termin.end_day = ende
	termin.origin = herkunft
	termin.state = zustand
	return termin


## Fahrplan und Protokoll eines Laufs als ein Text.
func _ausgabe(run: TimelineRun) -> String:
	return "\n".join(ScheduleText.plan_lines(run)) + "\n--\n" \
		+ "\n".join(ScheduleText.protocol_lines(run))


## Ein festes Eingriffsprotokoll in der Form von TimelineRun.interventions, nach at_day geordnet:
## der Modifikator aus US6, Szenario 1, vor Spielbeginn; am 30.06.1990 der Großauftrag für den
## 15.03.1991; am 01.01.1992 „Konkurrent eröffnet“ vom 01.06. auf den 01.09.1992, am 15.03.1992
## abgesagt; am 30.06.1993 der Modifikator wieder entfernt.
func _festes_protokoll() -> Array[Dictionary]:
	var modifikator := {"event_id": "reklamationswelle", "from_day": _tag(1990, 1, 1),
		"id": "windiger_haendler", "reason": "Ware vom windigen Händler",
		"to_day": _tag(1993, 12, 31), "value": 0.05}
	var protokoll: Array[Dictionary] = [
		{"at_day": -1, "kind": "add_modifier", "modifier": modifikator},
		{"at_day": _tag(1990, 6, 30), "day": _tag(1991, 3, 15), "event_id": "grossauftrag",
			"kind": "schedule", "reason": "Messeauftrag"},
		{"at_day": _tag(1992, 1, 1), "day": _tag(1992, 6, 1), "event_id": "konkurrent_eroeffnet",
			"kind": "move", "new_day": _tag(1992, 9, 1), "reason": "Bauarbeiten"},
		{"at_day": _tag(1992, 3, 15), "day": _tag(1992, 9, 1), "event_id": "konkurrent_eroeffnet",
			"kind": "cancel", "reason": "Laden nebenan selbst gemietet"},
		{"at_day": _tag(1993, 6, 30), "kind": "remove_modifier", "modifier": modifikator},
	]
	return protokoll


## Ein Lauf mit Seed 4711 bis zum Spielende, in Schritten von [param sprung] Tagen. Jeder Eintrag
## des Protokolls kommt an seinem at_day dran, wie im Simulator: Kein Schritt springt über diesen
## Tag hinweg. Dort wendet apply_intervention() ihn an.
func _mit_eingriffen(catalog: EventCatalog, protokoll: Array[Dictionary],
		sprung: int) -> TimelineRun:
	var run := TimelineRun.new(catalog, 4711)
	var naechster := 0
	while true:
		while naechster < protokoll.size() and int(protokoll[naechster]["at_day"]) <= run.today:
			assert_eq(run.apply_intervention(protokoll[naechster]), OK, run.last_refusal)
			naechster += 1
		if run.is_finished():
			break
		var ziel := run.today + sprung
		if naechster < protokoll.size():
			ziel = mini(ziel, int(protokoll[naechster]["at_day"]))
		run.advance_to(ziel)
	assert_eq(run.interventions.size(), protokoll.size(), "Jeder Eingriff gilt.")
	return run
