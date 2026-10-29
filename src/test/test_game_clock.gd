extends GutTest

## Prüft das Fortschreiten der Spieluhr: Tageswechsel, Monats- und Jahressprünge,
## die Signale und das Ende der Zeitleiste.
##
## Wichtig: Diese Tests arbeiten NICHT mit dem Autoload `GameClock`, sondern
## bauen sich für jeden Test eine eigene Uhr. Sonst würde ein Test die Zeit für
## alle folgenden verstellen — und die echte Uhr hängt am Autoload `Timeline`,
## das dann ebenfalls Ereignisse feuern würde.

const UHR := preload("res://core/game_clock.gd")

var _clock: Node


func before_each() -> void:
	_clock = UHR.new()
	# add_child_autofree hängt den Knoten in den Baum (damit _ready() läuft) und
	# räumt ihn nach dem Test wieder weg.
	add_child_autofree(_clock)


# --- Ausgangszustand ------------------------------------------------------

func test_startet_am_ersten_januar_1985() -> void:
	assert_eq(_clock.date.year, 1985)
	assert_eq(_clock.date.month, 1)
	assert_eq(_clock.date.day, 1)


func test_startet_angehalten() -> void:
	assert_true(_clock.paused, "Die Uhr muss angehalten starten, sonst läuft die Zeit sofort los.")
	assert_false(_clock.is_finished(), "Am Anfang darf die Zeitleiste nicht zu Ende sein.")


# --- Tageswechsel ---------------------------------------------------------

func test_ein_tag_weiter() -> void:
	# Act
	_clock.advance_day()

	# Assert
	assert_eq(_clock.date.day, 2)
	assert_eq(_clock.date.month, 1)


func test_wechsel_ueber_die_monatsgrenze() -> void:
	# Arrange
	_vorspulen_bis(1993, 1, 31)

	# Act
	_clock.advance_day()

	# Assert
	assert_eq(_clock.date.day, 1, "Nach dem 31. Januar kommt der 1. Februar.")
	assert_eq(_clock.date.month, 2)


func test_schalttag_wird_nicht_uebersprungen() -> void:
	# Arrange
	_vorspulen_bis(1988, 2, 28)

	# Act
	_clock.advance_day()

	# Assert
	assert_eq(_clock.date.day, 29, "1988 ist ein Schaltjahr, der 29. Februar muss existieren.")
	assert_eq(_clock.date.month, 2)


func test_jahreswechsel() -> void:
	# Arrange
	_vorspulen_bis(1993, 12, 31)

	# Act
	_clock.advance_day()

	# Assert
	assert_eq(_clock.date.year, 1994)
	assert_eq(_clock.date.month, 1)
	assert_eq(_clock.date.day, 1)


# --- Sprünge --------------------------------------------------------------

func test_monatssprung_landet_auf_dem_ersten() -> void:
	# Arrange — der Sprung geht bis zum Ersten des Folgemonats, nicht um
	# 30 Tage weiter.
	_vorspulen_bis(1993, 3, 15)

	# Act
	_clock.advance_one_month()

	# Assert
	assert_eq(_clock.date.month, 4)
	assert_eq(_clock.date.day, 1, "Der Sprung muss auf dem Ersten landen, nicht auf dem 15.")


func test_jahressprung_landet_auf_dem_ersten_januar() -> void:
	# Arrange
	_vorspulen_bis(1993, 7, 20)

	# Act
	_clock.advance_one_year()

	# Assert
	assert_eq(_clock.date.year, 1994)
	assert_eq(_clock.date.month, 1)
	assert_eq(_clock.date.day, 1)


# --- Signale --------------------------------------------------------------

func test_tageswechsel_meldet_sich() -> void:
	# Arrange
	watch_signals(_clock)

	# Act
	_clock.advance_day()

	# Assert
	assert_signal_emitted(_clock, "day_passed", "Jeder Tageswechsel muss gemeldet werden.")


func test_monatswechsel_meldet_sich_nur_beim_monatswechsel() -> void:
	# Arrange
	watch_signals(_clock)

	# Act — vom 1. auf den 2. Januar, also kein Monatswechsel
	_clock.advance_day()

	# Assert
	assert_signal_not_emitted(_clock, "month_passed",
		"Innerhalb eines Monats darf month_passed nicht feuern.")


# --- Ende der Zeitleiste --------------------------------------------------

func test_uhr_endet_nach_1999() -> void:
	# Arrange
	_vorspulen_bis(1999, 12, 31)
	watch_signals(_clock)

	# Act
	_clock.advance_day()

	# Assert
	assert_true(_clock.is_finished(), "Nach dem 31.12.1999 muss die Zeitleiste zu Ende sein.")
	assert_true(_clock.paused, "Am Ende muss die Uhr angehalten sein.")
	assert_signal_emit_count(_clock, "reached_end", 1, "reached_end darf genau einmal feuern.")
	# Festgehalten, weil es überrascht: Das Datum steht danach auf dem
	# 01.01.2000 — die Uhr merkt das Ende erst, nachdem sie darüber hinaus ist.
	assert_eq(_clock.date.year, 2000, "Das Enddatum liegt einen Tag hinter dem Spielende.")


func test_nach_dem_ende_bewegt_sich_nichts_mehr() -> void:
	# Arrange
	_vorspulen_bis(1999, 12, 31)
	_clock.advance_day()
	# Typ ausdrücklich angeben: _clock ist nur als Node bekannt (game_clock.gd
	# hat kein class_name), deshalb kann ":=" den Typ hier nicht ableiten.
	var enddatum: int = _clock.date.to_day_index()

	# Act
	_clock.advance_day()
	_clock.advance_one_month()
	_clock.advance_one_year()

	# Assert
	assert_eq(_clock.date.to_day_index(), enddatum,
		"Nach dem Ende darf kein Aufruf die Zeit noch weiterschieben.")


# --- Datum setzen (Feature 004, T012) -------------------------------------

func test_datum_setzen_sendet_kein_signal() -> void:
	# Arrange (R6): Fortsetzen am 14.03.1986, mitten im Jahr nach dem Start
	watch_signals(_clock)

	# Act
	_clock.set_date(GameDate.new(1986, 3, 14))

	# Assert
	assert_eq(str(_clock.date), "14.03.1986")
	for signal_name in ["day_passed", "month_passed", "year_passed", "reached_end"]:
		assert_signal_not_emitted(_clock, signal_name,
			"Die Tage dazwischen vergehen nicht im Spiel, also kein %s." % signal_name)


func test_datum_setzen_laesst_pause_wie_sie_ist() -> void:
	# Arrange und Act: einmal angehalten, einmal laufend
	_clock.set_date(GameDate.new(1990, 6, 1))
	var angehalten: bool = _clock.paused
	_clock.paused = false
	_clock.set_date(GameDate.new(1991, 6, 1))

	# Assert
	assert_true(angehalten, "Angehalten bleibt angehalten.")
	assert_false(_clock.paused, "Laufend bleibt laufend.")


func test_nach_dem_setzen_geht_es_vom_neuen_datum_aus_weiter() -> void:
	# Arrange: Der Tagesindex muss mitkommen, sonst ginge es vom alten Datum weiter.
	_clock.set_date(GameDate.new(1986, 3, 14))
	watch_signals(_clock)

	# Act
	_clock.advance_day()

	# Assert
	assert_eq(str(_clock.date), "15.03.1986")
	assert_signal_emit_count(_clock, "day_passed", 1)
	assert_eq(str(get_signal_parameters(_clock, "day_passed")[0]), "15.03.1986")


func test_datum_setzen_haengt_nicht_am_uebergebenen_objekt() -> void:
	# Arrange
	var datum := GameDate.new(1986, 3, 14)

	# Act: Der Aufrufer ändert sein Datum danach.
	_clock.set_date(datum)
	datum.day = 20

	# Assert
	assert_eq(str(_clock.date), "14.03.1986", "Die Uhr hat eine eigene Kopie.")


func test_am_letzten_tag_gesetzt_ist_die_uhr_nicht_am_ende() -> void:
	# Arrange und Act (R6): ein Spielstand vom 31.12.1999
	_clock.set_date(GameDate.new(1999, 12, 31))

	# Assert
	assert_false(_clock.is_finished(), "Der 31.12.1999 gehört noch zum Spiel.")
	assert_eq(str(_clock.date), "31.12.1999")
	watch_signals(_clock)
	_clock.advance_day()
	assert_signal_emit_count(_clock, "day_passed", 1, "Der Tag danach kommt noch.")
	assert_signal_emit_count(_clock, "reached_end", 1, "Danach ist das Spiel aus.")


func test_nach_dem_ende_zurueckgesetzt_laeuft_die_uhr_wieder() -> void:
	# Arrange: Die Uhr ist über den 31.12.1999 hinaus und am Ende.
	_clock.set_date(GameDate.new(1999, 12, 31))
	_clock.advance_day()
	assert_true(_clock.is_finished())

	# Act: Verlassen setzt sie zurück auf den 01.01.1985 (data-model.md, „GameSession“).
	_clock.set_date(GameDate.new(1985, 1, 1))

	# Assert
	assert_false(_clock.is_finished(), "Im Spielzeitraum ist die Uhr nicht am Ende.")
	_clock.advance_day()
	assert_eq(str(_clock.date), "02.01.1985", "Sie geht wieder weiter.")


func test_angefangener_tag_verfaellt_beim_setzen() -> void:
	# Arrange: Die Uhr läuft und hat fast einen ganzen Tag angesammelt.
	_clock.paused = false
	_clock._process(0.49 / _clock.days_per_second)
	watch_signals(_clock)

	# Act
	_clock.set_date(GameDate.new(1986, 3, 14))
	_clock._process(0.6 / _clock.days_per_second)

	# Assert
	assert_signal_not_emitted(_clock, "day_passed",
		"Nach dem Setzen zählt der Tag von vorn, sonst käme der 15.03. zu früh.")
	assert_eq(str(_clock.date), "14.03.1986")


# --- Obergrenze je Bild und Zustand (Feature 008, T036a, K1 und K2) -----

func test_hoechstens_vier_tage_je_bild_der_rest_verfaellt() -> void:
	# Arrange: Nach einem Hänger kommt ein Bild mit zehn Tagen Zeit (AR-10).
	_clock.paused = false
	watch_signals(_clock)

	# Act
	_clock._process(10.0 / _clock.days_per_second)
	_clock._process(0.0)

	# Assert
	assert_eq(UHR.MAX_DAYS_PER_FRAME, 4, "Wie InvadersPage.MAX_STEPS.")
	assert_signal_emit_count(_clock, "day_passed", 4, "Höchstens vier Tage in einem Bild.")
	assert_eq(str(_clock.date), "05.01.1985", "Die übrigen sechs Tage verfallen.")


func test_bis_zur_obergrenze_bleibt_der_angefangene_tag() -> void:
	# Arrange: Vier Tage und ein halber, also genau die Obergrenze und ein angefangener Tag.
	_clock.paused = false
	watch_signals(_clock)

	# Act
	_clock._process(4.5 / _clock.days_per_second)
	var nach_dem_ersten: String = str(_clock.date)
	_clock._process(0.6 / _clock.days_per_second)

	# Assert
	assert_eq(nach_dem_ersten, "05.01.1985", "Vier Tage im ersten Bild.")
	assert_eq(str(_clock.date), "06.01.1985", "Der halbe Tag zählt im nächsten Bild mit.")
	assert_signal_emit_count(_clock, "day_passed", 5)


func test_am_ende_bleibt_die_uhr_stehen_auch_mit_paused_false() -> void:
	# Arrange: Die Uhr ist über den 31.12.1999 hinaus.
	_clock.set_date(GameDate.new(1999, 12, 31))
	_clock.paused = false
	_clock.advance_day()

	# Act
	_clock.paused = false
	var nach_dem_setzen: bool = _clock.paused
	_clock.toggle_paused()
	_clock.set_paused(false)
	_clock._process(3.0 / _clock.days_per_second)

	# Assert (K2): Am Ende ist die Uhr angehalten, was auch gesetzt wird.
	assert_true(nach_dem_setzen, "paused = false holt die Uhr nicht aus dem Ende.")
	assert_true(_clock.paused)
	assert_true(_clock.is_finished())
	assert_eq(str(_clock.date), "01.01.2000", "Sie rechnet keinen Tag weiter.")


func test_aus_dem_ende_zurueckgesetzt_ist_die_uhr_angehalten() -> void:
	# Arrange: Sie lief bis über das Ende hinaus.
	_clock.set_date(GameDate.new(1999, 12, 31))
	_clock.paused = false
	_clock.advance_day()

	# Act: Verlassen setzt sie zurück (data-model.md, „GameSession“).
	_clock.set_date(GameDate.new(1985, 1, 1))

	# Assert
	assert_false(_clock.is_finished())
	assert_true(_clock.paused, "Angehalten, wie am Ende.")
	_clock.paused = false
	assert_false(_clock.paused, "Danach lässt sie sich wieder starten.")


# --- Helfer ---------------------------------------------------------------

## Schiebt die Uhr Tag für Tag bis zum Zieldatum, mit allen Signalen unterwegs.
## Ohne Signale springt set_date().
func _vorspulen_bis(jahr: int, monat: int, tag: int) -> void:
	var ziel := GameDate.new(jahr, monat, tag).to_day_index()
	while _clock.date.to_day_index() < ziel and not _clock.is_finished():
		_clock.advance_day()
