extends GutTest

## Prüft den echten Ereigniskatalog res://data/event_catalog.json mit denselben Regeln wie die
## Werkstatt (FR-048): Er darf keine Meldung der Stufe ERROR haben, weder beim Lesen (V22) noch
## bei der Prüfung. Warnungen sind erlaubt, die zeigt die Werkstatt.
##
## Teil 2 (T045) prüft die Kalender-Ereignisse, die immer im Katalog stehen müssen: die sechs aus
## FR-023 mit ihren Tagen im Jahr und das Weihnachtsgeschäft in allen 15 Spieljahren (SC-009).
##
## Mehr prüft dieser Test am echten Katalog bewusst nicht. Klaus ändert ihn in der Werkstatt, und
## ein Test, der einzelne Werte festschreibt, bräche bei jeder Änderung. Titel, Texte, Wirkungen
## und die genauen Tage der CeBIT bleiben deshalb frei. Was die Übernahme enthielt, prüft
## test_uebernahme.gd an einer eingefrorenen Kopie.

## Weihnachtsgeschäft und Jahreszeiten aus FR-023 mit Beginn und Ende im Jahr als (Monat, Tag);
## Tag 0 heißt Monatsende. Jede Jahreszeit reicht bis zum Monatsende vor der nächsten.
const JEDES_JAHR := {
	"weihnachtsgeschaeft": [Vector2i(11, 1), Vector2i(12, 0)],
	"fruehling": [Vector2i(3, 1), Vector2i(5, 0)],
	"sommer": [Vector2i(6, 1), Vector2i(8, 0)],
	"herbst": [Vector2i(9, 1), Vector2i(11, 0)],
	"winter": [Vector2i(12, 1), Vector2i(2, 0)],
}


func test_echter_katalog_hat_keine_fehler() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(EventCatalog.DEFAULT_PATH, issues)
	if catalog != null:
		issues.append_array(CatalogValidator.validate(catalog))

	# Assert
	assert_not_null(catalog, "Der Katalog muss sich lesen lassen: %s" % [issues])
	assert_false(CatalogValidator.has_errors(issues), "Meldungen zum Katalog: %s" % [issues])


func test_die_sechs_kalender_ereignisse_sind_vorhanden() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []
	var catalog := _katalog(issues)

	# Act und Assert: Weihnachtsgeschäft und Jahreszeiten, jedes Jahr von 1985 bis 1999 (FR-023)
	for kennung: String in JEDES_JAHR:
		var event := catalog.get_event(kennung)
		assert_not_null(event, "„%s“ fehlt im Katalog." % kennung)
		if event == null:
			continue
		assert_eq(event.kind, TimelineEvent.Kind.YEARLY, "%s ist jährlich." % kennung)
		assert_eq([event.yearly_start, event.yearly_end], JEDES_JAHR[kennung],
			"%s: Beginn und Ende im Jahr." % kennung)
		assert_eq([event.yearly_from, event.yearly_to], [1985, 1999],
			"%s: alle 15 Spieljahre." % kennung)
	# Die CeBIT jedes Jahr ab 1986 im März; ihre genauen Tage trägt Klaus ein (spec.md, Annahmen).
	var cebit := catalog.get_event("cebit")
	assert_not_null(cebit, "„cebit“ fehlt im Katalog.")
	if cebit == null:
		return
	assert_eq(cebit.kind, TimelineEvent.Kind.YEARLY, "cebit ist jährlich.")
	assert_eq([cebit.yearly_from, cebit.yearly_to], [1986, 1999], "Jedes Jahr ab 1986.")
	var im_maerz := cebit.yearly_start.x == 3 \
		and (cebit.yearly_end.x == 3 or cebit.yearly_end == Vector2i.ZERO)
	assert_true(im_maerz, "Beginn und Ende liegen im März: %s bis %s."
		% [cebit.yearly_start, cebit.yearly_end])


func test_weihnachtsgeschaeft_liegt_in_allen_15_jahren_vom_01_11_bis_31_12() -> void:
	# Arrange: ein Lauf wie im Spiel, ohne Ereignisse mit Fehlern. Jährliche Termine hängen nicht
	# am Seed; 4711 steht für jeden.
	var issues: Array[CatalogIssue] = []
	var catalog := _katalog(issues)
	issues.append_array(CatalogValidator.validate(catalog))
	var run := TimelineRun.new(catalog.without_faulty(issues), 4711)

	# Act
	run.advance_to(TimelineRun.LAST_DAY)

	# Assert (SC-009)
	var jahre := []
	var letzter: ScheduleEntry = null
	for termin in run.entries:
		if termin.event.id != "weihnachtsgeschaeft":
			continue
		var jahr := GameDate.from_day_index(termin.day).year
		jahre.append(jahr)
		assert_eq(str(GameDate.from_day_index(termin.day)), "01.11.%d" % jahr, "Beginn.")
		assert_eq(str(GameDate.from_day_index(termin.end_day - 1)), "31.12.%d" % jahr,
			"Letzter Tag.")
		letzter = termin
	assert_eq(jahre, range(1985, 2000), "In jedem der 15 Spieljahre ein Termin.")
	# 1999 käme das Ende am 01.01.2000, nach Spielende: Es wird nicht gemeldet, der Termin läuft
	# bis zum Schluss, und die Textausgabe sagt es dazu.
	assert_not_null(letzter)
	if letzter == null:
		return
	assert_gt(letzter.end_day, TimelineRun.LAST_DAY, "Das Ende von 1999 liegt nach Spielende.")
	assert_eq(letzter.state_label(), "läuft")
	var enden := 0
	for meldung in run.protocol:
		if meldung.kind == TimelineMessage.Kind.EVENT_ENDED \
				and meldung.event.id == "weihnachtsgeschaeft":
			enden += 1
	assert_eq(enden, 14, "Gemeldet werden nur die Enden der Jahre 1985 bis 1998.")
	var zeile := ""
	for kandidat in ScheduleText.plan_lines(run):
		if kandidat.begins_with("01.11.1999  bis 31.12.1999  weihnachtsgeschaeft "):
			zeile = kandidat
	assert_string_ends_with(zeile, "(Ende nach Spielende)")


# --- Helfer ----------------------------------------------------------------------

## Liest den echten Katalog und hängt die Meldungen beim Lesen an [param issues] an. Ist er nicht
## lesbar, scheitert der Test mit diesen Meldungen.
func _katalog(issues: Array[CatalogIssue]) -> EventCatalog:
	var catalog := EventCatalog.read_file(EventCatalog.DEFAULT_PATH, issues)
	if catalog == null:
		fail_test("Der Katalog lässt sich nicht lesen: %s" % [issues])
		return EventCatalog.new()
	return catalog
