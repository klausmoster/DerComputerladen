extends GutTest

## Prüft, dass die Ereignis-Datenbank vollständig und in sich stimmig ist.
##
## Die Timeline ist nur so gut wie ihre Daten. Ein Tippfehler in einer Ereignis-Id
## oder ein Datum außerhalb des Spielzeitraums fällt im laufenden Spiel nicht auf:
## Ein Ereignis, das nie feuert, meldet auch nicht, dass es fehlt. Genau diese
## stillen Fehler fangen die folgenden Tests ab.

const ERWARTETE_FESTE := 19
const ERWARTETE_VARIABLE := 6

const SPIELSTART_JAHR := 1985
const SPIELENDE_JAHR := 1999

## Effektarten, die eine Wirkung behaupten. PRESSE ist ein reiner Info-Effekt
## und darf deshalb die Stärke 0 haben.
const WIRKSAME_EFFEKTE := [
	EventEffect.Kind.PREIS,
	EventEffect.Kind.NACHFRAGE,
	EventEffect.Kind.REPUTATION,
	EventEffect.Kind.KUNDENSTROM,
]

var _feste: Array[TimelineEvent] = []
var _variable: Array[TimelineEvent] = []
var _alle: Array[TimelineEvent] = []


func before_each() -> void:
	_feste = EventDatabase.build_fixed_events()
	_variable = EventDatabase.build_variable_events()
	_alle = []
	_alle.append_array(_feste)
	_alle.append_array(_variable)


# --- Umfang ---------------------------------------------------------------

func test_anzahl_fester_ereignisse() -> void:
	assert_eq(_feste.size(), ERWARTETE_FESTE,
		"Anzahl der festen Ereignisse hat sich geändert. Wenn das gewollt war, " +
		"ERWARTETE_FESTE anpassen.")


func test_anzahl_variabler_ereignisse() -> void:
	assert_eq(_variable.size(), ERWARTETE_VARIABLE,
		"Anzahl der variablen Ereignisse hat sich geändert. Wenn das gewollt war, " +
		"ERWARTETE_VARIABLE anpassen.")


# --- Identität ------------------------------------------------------------

func test_jedes_ereignis_hat_id_und_titel() -> void:
	for event in _alle:
		assert_false(event.id.is_empty(),
			"Ereignis ohne Id gefunden (Titel: '%s')." % event.title)
		assert_false(event.title.is_empty(),
			"Ereignis ohne Titel gefunden (Id: '%s')." % event.id)


func test_ids_sind_eindeutig() -> void:
	var gesehen := {}
	var doppelte: Array[String] = []

	for event in _alle:
		if gesehen.has(event.id):
			doppelte.append(event.id)
		gesehen[event.id] = true

	assert_true(doppelte.is_empty(),
		"Doppelt vergebene Ereignis-Ids: %s. Ids müssen eindeutig sein, weil " % [doppelte] +
		"Cooldown und Häufigkeit darüber gezählt werden.")


# --- Feste Ereignisse -----------------------------------------------------

func test_feste_ereignisse_sind_als_fix_markiert() -> void:
	for event in _feste:
		assert_true(event.is_fixed,
			"'%s' steht bei den festen Ereignissen, ist aber nicht als fix markiert. " % event.id +
			"Es würde monatlich ausgewürfelt statt an seinem Datum zu feuern.")


func test_feste_daten_liegen_im_spielzeitraum() -> void:
	for event in _feste:
		assert_between(event.year, SPIELSTART_JAHR, SPIELENDE_JAHR,
			"'%s' liegt im Jahr %d und damit außerhalb des Spielzeitraums." % [event.id, event.year])


func test_feste_daten_sind_gueltige_kalendertage() -> void:
	for event in _feste:
		assert_between(event.month, 1, 12,
			"'%s' hat den ungültigen Monat %d." % [event.id, event.month])

		if event.month < 1 or event.month > 12:
			continue

		var letzter_tag := GameDate.days_in_month(event.year, event.month)
		assert_between(event.day, 1, letzter_tag,
			"'%s' liegt auf dem %d., aber der Monat %d/%d hat nur %d Tage."
			% [event.id, event.day, event.month, event.year, letzter_tag])


func test_pentium_erscheint_am_22_maerz_1993() -> void:
	# Ein bekannter Ankerpunkt. Verrutscht dieses Datum, stimmt entweder die
	# Datenbank nicht mehr oder die Umrechnung im Kalender ist kaputt.
	var pentium := _finde("intel_pentium", _feste)

	assert_not_null(pentium, "Das Ereignis 'intel_pentium' fehlt in der Datenbank.")
	if pentium == null:
		return

	assert_eq(pentium.year, 1993, "Falsches Jahr für den Pentium-Release.")
	assert_eq(pentium.month, 3, "Falscher Monat für den Pentium-Release.")
	assert_eq(pentium.day, 22, "Falscher Tag für den Pentium-Release.")
	assert_eq(pentium.trigger_day_index(), GameDate.new(1993, 3, 22).to_day_index(),
		"Der Tagesindex des Ereignisses passt nicht zum Datum.")


# --- Variable Ereignisse --------------------------------------------------

func test_variable_ereignisse_sind_nicht_als_fix_markiert() -> void:
	for event in _variable:
		assert_false(event.is_fixed,
			"'%s' steht bei den variablen Ereignissen, ist aber als fix markiert. " % event.id +
			"Es würde an Jahr/Monat/Tag feuern statt ausgewürfelt zu werden.")


func test_variable_ereignisse_koennen_ueberhaupt_eintreten() -> void:
	for event in _variable:
		assert_gt(event.monthly_chance, 0.0,
			"'%s' hat die Wahrscheinlichkeit 0 und kann damit nie eintreten." % event.id)


func test_variable_ereignisse_haben_ein_gueltiges_zeitfenster() -> void:
	for event in _variable:
		assert_lte(event.earliest_year, event.latest_year,
			"'%s' hat ein umgedrehtes Zeitfenster (%d bis %d) und kann nie eintreten."
			% [event.id, event.earliest_year, event.latest_year])
		assert_between(event.earliest_year, SPIELSTART_JAHR, SPIELENDE_JAHR,
			"'%s' beginnt außerhalb des Spielzeitraums (%d)." % [event.id, event.earliest_year])
		assert_between(event.latest_year, SPIELSTART_JAHR, SPIELENDE_JAHR,
			"'%s' endet außerhalb des Spielzeitraums (%d)." % [event.id, event.latest_year])


# --- Effekte --------------------------------------------------------------

func test_jedes_ereignis_hat_mindestens_einen_effekt() -> void:
	for event in _alle:
		assert_gt(event.effects.size(), 0,
			"'%s' hat keine Wirkung und wäre damit eine reine Meldung." % event.id)


func test_spawn_effekte_zeigen_auf_bekannte_ereignisse() -> void:
	# Der wichtigste Test der Datei, sobald SPAWN benutzt wird: Ein Tippfehler im
	# Ziel fällt sonst nirgends auf — das Folgeereignis bliebe einfach stumm.
	var bekannte_ids := {}
	for event in _alle:
		bekannte_ids[event.id] = true

	var spawns := 0
	for event in _alle:
		for effect in event.effects:
			if effect.kind != EventEffect.Kind.SPAWN:
				continue
			spawns += 1
			assert_true(bekannte_ids.has(effect.target),
				"'%s' will das Ereignis '%s' auslösen, aber diese Id gibt es nicht."
				% [event.id, effect.target])

	if spawns == 0:
		# Ohne diesen Zweig wäre der Test ein stiller Nichtstuer: GUT meldet
		# Tests, die keine einzige Zusage machen, als „Risky".
		pass_test("Derzeit nutzt kein Ereignis SPAWN — nichts zu prüfen.")


func test_wirksame_effekte_haben_eine_staerke() -> void:
	for event in _alle:
		for effect in event.effects:
			if not WIRKSAME_EFFEKTE.has(effect.kind):
				continue
			assert_ne(effect.magnitude, 0.0,
				"Effekt '%s' von '%s' hat die Stärke 0 und bewirkt damit nichts."
				% [effect.kind_label(), event.id])


func test_verzoegerungen_sind_nicht_negativ() -> void:
	for event in _alle:
		for effect in event.effects:
			assert_gte(effect.delay_days, 0,
				"Effekt '%s' von '%s' hat eine negative Verzögerung (%d Tage)."
				% [effect.kind_label(), event.id, effect.delay_days])


# --- Helfer ---------------------------------------------------------------

func _finde(id: String, liste: Array[TimelineEvent]) -> TimelineEvent:
	for event in liste:
		if event.id == id:
			return event
	return null
