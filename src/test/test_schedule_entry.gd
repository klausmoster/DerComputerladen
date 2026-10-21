extends GutTest

## Prüft den Termin im Fahrplan (Feature 002, T016): Vorgaben, Bezeichnungen für Herkunft und
## Zustand, die Begründung mit deutschem Komma und die verzögerten Wirkungen.
##
## Die Tests füllen die Felder von Hand, so wie der Lauf es tut. So prüfen sie Beschriftungen und
## Begründungen ohne Katalog; die Termine aus einem Lauf prüft test_timeline_run.gd.


func test_vorgaben_heissen_nicht_gewuerfelt_und_nicht_verschoben() -> void:
	# Act
	var entry := ScheduleEntry.new()

	# Assert
	assert_eq([entry.roll, entry.threshold, entry.base_chance], [-1.0, -1.0, -1.0])
	assert_eq(entry.moved_from_day, -1)
	assert_eq(entry.state, ScheduleEntry.State.PLANNED)
	assert_eq(entry.state_label(), "geplant")


func test_herkunft_und_zustand_als_text() -> void:
	# Arrange
	var entry := ScheduleEntry.new()
	entry.source_event_id = "reklamationswelle"
	entry.source_title = "Reklamationswelle"
	var herkunft := ["fix", "jährlich", "gesetzt", "gewürfelt", "Folge von Reklamationswelle",
		"Eingriff"]
	var zustand := ["geplant", "läuft", "eingetreten", "beendet", "entfallen", "abgesagt"]

	# Act und Assert
	for wert: int in ScheduleEntry.Origin.values():
		entry.origin = wert as ScheduleEntry.Origin
		assert_eq(entry.origin_label(), herkunft[wert])
	for wert: int in ScheduleEntry.State.values():
		entry.state = wert as ScheduleEntry.State
		assert_eq(entry.state_label(), zustand[wert])


func test_folge_ohne_titel_nennt_die_kennung() -> void:
	# Arrange: Den Titel setzt der Lauf; fehlt er, bleibt die Kennung.
	var entry := ScheduleEntry.new()
	entry.origin = ScheduleEntry.Origin.FOLLOW_UP
	entry.source_event_id = "reklamationswelle"

	# Act und Assert
	assert_eq(entry.origin_label(), "Folge von reklamationswelle")


func test_gewuerfelt_nennt_wurf_schwelle_grundchance_und_modifikatoren() -> void:
	# Arrange: 3 % Grundchance und +5 Prozentpunkte, gewürfelt 0,02137 (US6, Szenario 1).
	var entry := ScheduleEntry.new()
	entry.origin = ScheduleEntry.Origin.ROLLED
	entry.roll = 0.02137
	entry.threshold = 0.08
	entry.base_chance = 0.03
	entry.modifier_notes = PackedStringArray(["Ware vom windigen Händler +5"])

	# Act und Assert: vier Stellen, der Würfel abgerundet
	assert_eq(entry.explain(),
		"Würfel 0,0213 < Schwelle 0,0800 (3 % + Ware vom windigen Händler +5)")
	entry.modifier_notes = PackedStringArray()
	entry.base_chance = 0.025
	entry.threshold = 0.025
	entry.roll = 0.021
	assert_eq(entry.explain(), "Würfel 0,0210 < Schwelle 0,0250 (2,5 %)", "Ohne Modifikator.")


func test_gewuerfelt_sieht_nie_gleich_der_schwelle_aus() -> void:
	# Arrange: knapp unter 3 %; aufgerundet stünde dort „0,0300 < 0,0300“.
	var entry := ScheduleEntry.new()
	entry.origin = ScheduleEntry.Origin.ROLLED
	entry.roll = 0.02999
	entry.threshold = 0.03
	entry.base_chance = 0.03

	# Act und Assert
	assert_eq(entry.explain(), "Würfel 0,0299 < Schwelle 0,0300 (3 %)")
	# Nur 100 % trifft auch mit dem Wurf 1,0, den randf() liefern kann (R8).
	entry.roll = 1.0
	entry.threshold = 1.0
	entry.base_chance = 1.0
	assert_eq(entry.explain(), "Würfel 1,0000 ≤ Schwelle 1,0000 (100 %)")


func test_folge_nennt_wurf_wahrscheinlichkeit_und_ausloeser() -> void:
	# Arrange
	var entry := ScheduleEntry.new()
	entry.origin = ScheduleEntry.Origin.FOLLOW_UP
	entry.source_event_id = "reklamationswelle"
	entry.source_title = "Reklamationswelle"
	entry.roll = 0.412
	entry.threshold = 0.5
	entry.base_chance = 0.5

	# Act und Assert: mit Titel der Titel, ohne Titel die Kennung.
	assert_eq(entry.explain(), "Würfel 0,4120 < 50 %, Folge von Reklamationswelle")
	entry.source_title = ""
	assert_eq(entry.explain(), "Würfel 0,4120 < 50 %, Folge von reklamationswelle")


func test_verschiebung_entfall_und_absage_haengen_ihren_grund_an() -> void:
	# Arrange: beim Start gesetzt auf den 01.06.1992, ein Eingriff schob ihn vom 01.03.1992 dorthin.
	var entry := ScheduleEntry.new()
	entry.origin = ScheduleEntry.Origin.PRESET
	entry.day = GameDate.new(1992, 6, 1).to_day_index()
	entry.moved_from_day = GameDate.new(1992, 3, 1).to_day_index()
	entry.note = "Laden nebenan selbst gemietet"

	# Act und Assert
	assert_eq(entry.explain(),
		"Beim Spielstart gesetzt, verschoben vom 01.03.1992; Grund: Laden nebenan selbst gemietet")
	entry.moved_from_day = -1
	entry.state = ScheduleEntry.State.CANCELLED
	assert_eq(entry.explain(), "Beim Spielstart gesetzt; abgesagt: Laden nebenan selbst gemietet")
	entry.state = ScheduleEntry.State.SKIPPED
	entry.note = "läuft noch"
	assert_eq(entry.explain(), "Beim Spielstart gesetzt; entfallen: läuft noch")


func test_jaehrlich_nennt_den_lauf_vor_spielbeginn() -> void:
	# Arrange
	var entry := ScheduleEntry.new()
	entry.origin = ScheduleEntry.Origin.YEARLY

	# Act und Assert
	assert_eq(entry.explain(), "Jedes Jahr laut Katalog")
	entry.started_before_game = true
	assert_eq(entry.explain(), "Jedes Jahr laut Katalog, lief schon vor Spielbeginn")


func test_verzoegerte_wirkungen_mit_faelligkeitstag() -> void:
	# Arrange: der Pentium am 22.03.1993 mit einer sofortigen und einer verzögerten Wirkung.
	var sofort := EventEffect.new()
	var spaeter := EventEffect.new()
	spaeter.delay_days = 14
	var pentium := TimelineEvent.new()
	pentium.effects.assign([sofort, spaeter])
	var entry := ScheduleEntry.new()
	entry.event = pentium
	entry.day = GameDate.new(1993, 3, 22).to_day_index()

	# Act
	var faellig := entry.due_effects()

	# Assert: nur die verzögerte, fällig am 05.04.1993 (US1, Szenario 5).
	assert_eq(faellig.size(), 1)
	if faellig.size() == 1:
		assert_eq(faellig[0]["effect"], spaeter)
		assert_eq(faellig[0]["day"], GameDate.new(1993, 4, 5).to_day_index())
	assert_eq(ScheduleEntry.new().due_effects().size(), 0, "Ohne Ereignis keine Wirkung.")


func test_entfallene_und_abgesagte_termine_haben_keine_verzoegerten_wirkungen() -> void:
	# Arrange (T097; Klaus, 2026-10-21): der Pentium mit einer Wirkung 14 Tage nach dem Beginn
	var spaeter := EventEffect.new()
	spaeter.delay_days = 14
	var pentium := TimelineEvent.new()
	pentium.effects.assign([spaeter])
	var entry := ScheduleEntry.new()
	entry.event = pentium
	entry.day = GameDate.new(1993, 3, 22).to_day_index()
	var erwartet := {
		ScheduleEntry.State.PLANNED: 1, ScheduleEntry.State.RUNNING: 1,
		ScheduleEntry.State.OCCURRED: 1, ScheduleEntry.State.ENDED: 1,
		ScheduleEntry.State.SKIPPED: 0, ScheduleEntry.State.CANCELLED: 0,
	}

	# Act und Assert: Ein Termin, der nie beginnt, hat keine Wirkung, die noch käme.
	for zustand: int in ScheduleEntry.State.values():
		entry.state = zustand as ScheduleEntry.State
		assert_eq(entry.due_effects().size(), erwartet[zustand], entry.state_label())
