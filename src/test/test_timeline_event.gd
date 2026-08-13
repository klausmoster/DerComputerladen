extends GutTest

## Prüft die Regeln, nach denen ein variables Ereignis eintreten darf.
##
## Anders als die Datenbank-Tests prüft diese Datei kein Datenbestand, sondern
## Verhalten: `TimelineEvent.can_occur()` entscheidet, ob ein Ereignis in einer
## Würfelrunde überhaupt in Frage kommt. Die Ereignisse werden hier eigens
## gebaut und nicht aus der Datenbank geholt — sonst würden diese Tests
## fehlschlagen, sobald jemand ein Ereignis in `EventDatabase` umstellt.
##
## Aufbau jedes Tests: erst herrichten, dann ausführen, dann prüfen
## (Arrange / Act / Assert).


# --- Zeitfenster ----------------------------------------------------------

func test_ereignis_im_zeitfenster_ist_moeglich() -> void:
	# Arrange
	var event := _ereignis(1990, 1995)
	var datum := GameDate.new(1992, 6, 1)

	# Act
	var moeglich := event.can_occur(datum, 0, -1, datum.to_day_index())

	# Assert
	assert_true(moeglich, "Innerhalb des Zeitfensters muss das Ereignis möglich sein.")


func test_vor_dem_zeitfenster_ausgeschlossen() -> void:
	# Arrange
	var event := _ereignis(1990, 1995)
	var datum := GameDate.new(1989, 12, 31)

	# Act
	var moeglich := event.can_occur(datum, 0, -1, datum.to_day_index())

	# Assert
	assert_false(moeglich, "Vor dem frühesten Jahr darf das Ereignis nicht eintreten.")


func test_nach_dem_zeitfenster_ausgeschlossen() -> void:
	# Arrange
	var event := _ereignis(1990, 1995)
	var datum := GameDate.new(1996, 1, 1)

	# Act
	var moeglich := event.can_occur(datum, 0, -1, datum.to_day_index())

	# Assert
	assert_false(moeglich, "Nach dem spätesten Jahr darf das Ereignis nicht mehr eintreten.")


# --- Höchstzahl -----------------------------------------------------------

func test_erreichte_hoechstzahl_schliesst_aus() -> void:
	# Arrange
	var event := _ereignis(1985, 1999, 4)
	var datum := GameDate.new(1992, 6, 1)

	# Act
	var moeglich := event.can_occur(datum, 4, -1, datum.to_day_index())

	# Assert
	assert_false(moeglich, "Bei erreichter Höchstzahl darf das Ereignis nicht mehr eintreten.")


func test_unterhalb_der_hoechstzahl_bleibt_moeglich() -> void:
	# Arrange
	var event := _ereignis(1985, 1999, 4)
	var datum := GameDate.new(1992, 6, 1)

	# Act
	var moeglich := event.can_occur(datum, 3, -1, datum.to_day_index())

	# Assert
	assert_true(moeglich, "Unterhalb der Höchstzahl muss das Ereignis möglich bleiben.")


func test_hoechstzahl_null_bedeutet_unbegrenzt() -> void:
	# Arrange
	var event := _ereignis(1985, 1999, 0)
	var datum := GameDate.new(1992, 6, 1)

	# Act
	var moeglich := event.can_occur(datum, 999, -1, datum.to_day_index())

	# Assert
	assert_true(moeglich, "max_occurrences = 0 muss 'unbegrenzt' bedeuten.")


# --- Cooldown -------------------------------------------------------------

func test_cooldown_verhindert_erneutes_ausloesen() -> void:
	# Arrange
	var event := _ereignis(1985, 1999, 0, 365)
	var datum := GameDate.new(1992, 6, 1)
	var heute := datum.to_day_index()
	var vor_100_tagen := heute - 100

	# Act
	var moeglich := event.can_occur(datum, 1, vor_100_tagen, heute)

	# Assert
	assert_false(moeglich, "Innerhalb des Cooldowns von 365 Tagen darf nichts feuern.")


func test_nach_ablauf_des_cooldowns_wieder_moeglich() -> void:
	# Arrange
	var event := _ereignis(1985, 1999, 0, 365)
	var datum := GameDate.new(1992, 6, 1)
	var heute := datum.to_day_index()
	var vor_400_tagen := heute - 400

	# Act
	var moeglich := event.can_occur(datum, 1, vor_400_tagen, heute)

	# Assert
	assert_true(moeglich, "Nach Ablauf des Cooldowns muss das Ereignis wieder möglich sein.")


func test_ohne_vorherige_ausloesung_greift_kein_cooldown() -> void:
	# Arrange
	var event := _ereignis(1985, 1999, 0, 365)
	var datum := GameDate.new(1992, 6, 1)

	# Act — -1 heißt: bisher noch nie ausgelöst.
	var moeglich := event.can_occur(datum, 0, -1, datum.to_day_index())

	# Assert
	assert_true(moeglich, "Ohne vorherige Auslösung darf der Cooldown nicht greifen.")


# --- Helfer ---------------------------------------------------------------

## Baut ein variables Ereignis mit genau den Werten, die der jeweilige Test
## braucht. Bewusst unabhängig von EventDatabase.
func _ereignis(earliest: int, latest: int, max_occ: int = 0, cooldown: int = 0) -> TimelineEvent:
	var event := TimelineEvent.new()
	event.id = "test_ereignis"
	event.title = "Test-Ereignis"
	event.is_fixed = false
	event.monthly_chance = 1.0
	event.earliest_year = earliest
	event.latest_year = latest
	event.max_occurrences = max_occ
	event.cooldown_days = cooldown
	return event
