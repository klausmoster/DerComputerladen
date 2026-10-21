extends GutTest

## Prüft den Kalender: Schaltjahre, Monatslängen, die Umrechnung in den
## Tagesindex auch vor 1985, das Datum als Text „JJJJ-MM-TT“ und die
## Beschriftung. Jahreszeiten und Weihnachtsgeschäft sind seit Feature 002
## Ereignisse der Zeitleiste (FR-023, FR-024), keine Auskünfte des Datums.
##
## `GameDate` rechnet intern über einen absoluten Tagesindex mit 1985-01-01 als
## Nullpunkt. Stimmt diese Umrechnung nicht, verschiebt sich die gesamte
## Zeitleiste — und zwar lautlos, weil jedes Ereignis dann eben an einem
## anderen Tag feuert, ohne dass irgendetwas abstürzt.

const EPOCHE := 1985
const SPIELENDE := 1999
## Erster Tag der Rundreise: gut ein Jahr vor Spielbeginn, damit sie das
## Schaltjahr 1984 ganz durchläuft.
const ERSTER_PROBETAG := -400


# --- Schaltjahre ----------------------------------------------------------

func test_durch_vier_teilbare_jahre_sind_schaltjahre() -> void:
	for jahr in [1988, 1992, 1996]:
		assert_true(GameDate.is_leap_year(jahr), "%d muss ein Schaltjahr sein." % jahr)


func test_normale_jahre_sind_keine_schaltjahre() -> void:
	for jahr in [1985, 1990, 1993, 1999]:
		assert_false(GameDate.is_leap_year(jahr), "%d darf kein Schaltjahr sein." % jahr)


func test_hundertjahresregel_greift() -> void:
	# Liegt außerhalb des Spielzeitraums, prüft aber die Regel selbst:
	# durch 100 teilbar heißt kein Schaltjahr …
	assert_false(GameDate.is_leap_year(1900), "1900 ist kein Schaltjahr (durch 100 teilbar).")
	# … außer bei Teilbarkeit durch 400.
	assert_true(GameDate.is_leap_year(2000), "2000 ist ein Schaltjahr (durch 400 teilbar).")


func test_februar_hat_im_schaltjahr_29_tage() -> void:
	assert_eq(GameDate.days_in_month(1988, 2), 29, "Februar 1988 muss 29 Tage haben.")
	assert_eq(GameDate.days_in_month(1989, 2), 28, "Februar 1989 muss 28 Tage haben.")


func test_monatslaengen_stimmen() -> void:
	var erwartet := {1: 31, 3: 31, 4: 30, 5: 31, 6: 30, 7: 31,
		8: 31, 9: 30, 10: 31, 11: 30, 12: 31}
	for monat: int in erwartet:
		assert_eq(GameDate.days_in_month(1993, monat), erwartet[monat],
			"Monat %d hat die falsche Länge." % monat)


# --- Tagesindex -----------------------------------------------------------

func test_epoche_ist_index_null() -> void:
	assert_eq(GameDate.new(EPOCHE, 1, 1).to_day_index(), 0,
		"1985-01-01 muss der Nullpunkt sein.")


func test_index_und_datum_lassen_sich_umkehren() -> void:
	# Wichtigster Test der Datei: Was in einen Index umgerechnet und wieder
	# zurückgeholt wird, muss dasselbe Datum ergeben.
	var proben := [
		GameDate.new(1985, 1, 1),
		GameDate.new(1988, 2, 29),   # Schalttag
		GameDate.new(1990, 10, 3),
		GameDate.new(1993, 3, 22),
		GameDate.new(1995, 12, 31),
		GameDate.new(1999, 12, 31),
	]

	for datum: GameDate in proben:
		var zurueck := GameDate.from_day_index(datum.to_day_index())
		assert_eq(zurueck.year, datum.year, "Jahr stimmt nicht nach dem Umweg über den Index.")
		assert_eq(zurueck.month, datum.month, "Monat stimmt nicht nach dem Umweg über den Index.")
		assert_eq(zurueck.day, datum.day, "Tag stimmt nicht nach dem Umweg über den Index.")


func test_der_index_waechst_mit_dem_datum() -> void:
	var frueher := GameDate.new(1993, 3, 22)
	var spaeter := GameDate.new(1993, 3, 23)

	assert_gt(spaeter.to_day_index(), frueher.to_day_index(),
		"Ein späteres Datum muss einen größeren Index haben.")


func test_jahresabstand_entspricht_der_jahreslaenge() -> void:
	# Arrange
	var anfang_1988 := GameDate.new(1988, 1, 1)   # Schaltjahr
	var anfang_1989 := GameDate.new(1989, 1, 1)
	var anfang_1990 := GameDate.new(1990, 1, 1)

	# Act
	var schaltjahr := anfang_1989.to_day_index() - anfang_1988.to_day_index()
	var normaljahr := anfang_1990.to_day_index() - anfang_1989.to_day_index()

	# Assert
	assert_eq(schaltjahr, 366, "1988 muss 366 Tage haben.")
	assert_eq(normaljahr, 365, "1989 muss 365 Tage haben.")


func test_spielende_hat_den_index_5477() -> void:
	# 15 Jahre, davon drei Schaltjahre: 15 · 365 + 3 − 1 = 5477 (data-model.md).
	assert_eq(GameDate.new(SPIELENDE, 12, 31).to_day_index(), 5477,
		"Der 31.12.1999 muss der Tag 5477 sein.")


func test_alle_tage_ab_400_vor_spielbeginn_bleiben_umkehrbar() -> void:
	# Läuft vom Index −400 bis zum Spielende und prüft für jeden Tag zweierlei:
	# Der Index ergibt einen echten Kalendertag, und dieser Tag führt wieder zum
	# selben Index. Ohne die erste Prüfung fiele etwa ein „0. Januar 1985“ nicht
	# auf, denn auch er ergäbe rechnerisch wieder −1.
	var ende := GameDate.new(SPIELENDE, 12, 31).to_day_index()
	var fehler := 0

	for index in range(ERSTER_PROBETAG, ende + 1):
		var datum := GameDate.from_day_index(index)
		var gueltig := GameDate.is_valid(datum.year, datum.month, datum.day)
		if not gueltig or datum.to_day_index() != index:
			fehler += 1

	assert_eq(fehler, 0, "%d von %d Tagen sind nicht umkehrbar."
		% [fehler, ende - ERSTER_PROBETAG + 1])


# --- Tage vor 1985 --------------------------------------------------------

func test_silvester_1984_ist_minus_eins() -> void:
	# Bisher zog die Umrechnung die Jahre vor 1985 nicht ab und ergab hier 365.
	assert_eq(GameDate.new(1984, 12, 31).to_day_index(), -1,
		"Der Tag vor dem Nullpunkt muss −1 sein.")


func test_erster_dezember_1984_ist_minus_31() -> void:
	assert_eq(GameDate.new(1984, 12, 1).to_day_index(), -31,
		"Der Winter 1984/85 beginnt 31 Tage vor dem Nullpunkt.")


func test_minus_31_ergibt_den_ersten_dezember_1984() -> void:
	# Act
	var datum := GameDate.from_day_index(-31)

	# Assert
	assert_eq([datum.year, datum.month, datum.day], [1984, 12, 1],
		"Der Index −31 muss auf den 01.12.1984 zurückführen.")


# --- Kalendertage und Datum als Text --------------------------------------

func test_29_februar_gibt_es_nur_im_schaltjahr() -> void:
	assert_true(GameDate.is_valid(1988, 2, 29), "1988 ist ein Schaltjahr.")
	assert_false(GameDate.is_valid(1989, 2, 29), "1989 hat keinen 29. Februar.")


func test_dreizehnter_monat_ist_kein_datum() -> void:
	assert_null(GameDate.from_iso("1993-13-01"), "Einen Monat 13 gibt es nicht.")


func test_nur_echte_kalendertage_in_voller_form_sind_ein_datum() -> void:
	# Der Ereigniskatalog meldet solche Daten beim Lesen als Fehler (V22).
	assert_null(GameDate.from_iso("1993-02-30"), "Den 30. Februar gibt es nicht.")
	assert_null(GameDate.from_iso("1993-3-22"),
		"Ohne führende Null ist es nicht die Form JJJJ-MM-TT.")
	assert_null(GameDate.from_iso("22.03.1993"),
		"Die deutsche Schreibweise ist nicht die Form der Datei.")
	assert_null(GameDate.from_iso(""), "Ein leerer Text ist kein Datum.")


func test_datum_als_text_hin_und_zurueck() -> void:
	# Arrange
	var proben := [GameDate.new(EPOCHE, 1, 1), GameDate.new(SPIELENDE, 12, 31)]
	var texte := ["1985-01-01", "1999-12-31"]

	for i in proben.size():
		var datum: GameDate = proben[i]

		# Act
		var text := datum.to_iso()
		var zurueck := GameDate.from_iso(text)

		# Assert
		assert_eq(text, texte[i], "Das Datum muss als JJJJ-MM-TT erscheinen.")
		assert_not_null(zurueck, "%s muss sich wieder lesen lassen." % text)
		if zurueck != null:
			assert_eq(zurueck.to_day_index(), datum.to_day_index(),
				"%s muss auf denselben Tag zurückführen." % text)


# --- Abgeleitete Auskünfte ------------------------------------------------

func test_beschriftung_und_textform() -> void:
	var datum := GameDate.new(1993, 3, 22)

	assert_eq(datum.to_label(), "März 1993", "Lesbare Beschriftung stimmt nicht.")
	assert_eq(str(datum), "22.03.1993", "Textform stimmt nicht.")
