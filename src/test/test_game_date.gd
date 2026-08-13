extends GutTest

## Prüft den Kalender: Schaltjahre, Monatslängen, die Umrechnung in den
## Tagesindex und die daraus abgeleiteten Auskünfte (Jahreszeit, Weihnachts-
## geschäft, Beschriftung).
##
## `GameDate` rechnet intern über einen absoluten Tagesindex mit 1985-01-01 als
## Nullpunkt. Stimmt diese Umrechnung nicht, verschiebt sich die gesamte
## Zeitleiste — und zwar lautlos, weil jedes Ereignis dann eben an einem
## anderen Tag feuert, ohne dass irgendetwas abstürzt.

const EPOCHE := 1985
const SPIELENDE := 1999


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


func test_alle_tage_des_spielzeitraums_bleiben_umkehrbar() -> void:
	# Läuft einmal über den kompletten Zeitraum 1985–1999 und prüft, dass der
	# Index lückenlos und ohne Sprung hochzählt.
	var start := GameDate.new(EPOCHE, 1, 1).to_day_index()
	var ende := GameDate.new(SPIELENDE, 12, 31).to_day_index()
	var fehler := 0

	for index in range(start, ende + 1):
		var datum := GameDate.from_day_index(index)
		if datum.to_day_index() != index:
			fehler += 1

	assert_eq(fehler, 0, "%d von %d Tagen im Zeitraum sind nicht umkehrbar."
		% [fehler, ende - start + 1])


# --- Abgeleitete Auskünfte ------------------------------------------------

func test_weihnachtsgeschaeft_umfasst_november_und_dezember() -> void:
	assert_true(GameDate.new(1993, 11, 1).is_holiday_season(), "November zählt dazu.")
	assert_true(GameDate.new(1993, 12, 24).is_holiday_season(), "Dezember zählt dazu.")
	assert_false(GameDate.new(1993, 10, 31).is_holiday_season(), "Oktober zählt nicht dazu.")
	assert_false(GameDate.new(1994, 1, 1).is_holiday_season(), "Januar zählt nicht dazu.")


func test_jahreszeiten_stimmen() -> void:
	var erwartet := {
		12: "Winter", 1: "Winter", 2: "Winter",
		3: "Frühling", 4: "Frühling", 5: "Frühling",
		6: "Sommer", 7: "Sommer", 8: "Sommer",
		9: "Herbst", 10: "Herbst", 11: "Herbst",
	}
	for monat: int in erwartet:
		assert_eq(GameDate.new(1993, monat, 15).season(), erwartet[monat],
			"Monat %d ist der falschen Jahreszeit zugeordnet." % monat)


func test_beschriftung_und_textform() -> void:
	var datum := GameDate.new(1993, 3, 22)

	assert_eq(datum.to_label(), "März 1993", "Lesbare Beschriftung stimmt nicht.")
	assert_eq(str(datum), "22.03.1993", "Textform stimmt nicht.")
