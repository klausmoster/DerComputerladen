extends GutTest

## Prüft SaveStore (Feature 004, T008; data-model.md, „SaveStore“; research.md, R3, R4, R12 und
## R16): die Liste mit ihrer Ordnung und der Leseregel aus R3, fremde Dateien, die nächste Nummer,
## das Schreiben in fünf Schritten mit jedem Abbruch und dem lesbaren Stand danach, das Ausweichen
## eines neuen Spiels und das Löschen. Dazu die Messung zu SC-002. Seit T036 auch zwei Fehler beim
## Speichern hintereinander, nach denen der Spielstand noch fortsetzbar ist.
##
## Jeder Test arbeitet in ORDNER, den after_each() samt allem darin wieder abräumt, auch den
## Ordnern, die ein Test als Hindernis anlegt. Nach user://spielstaende/ schreibt kein Test.
##
## Ein Abbruch mitten im Speichern lässt sich nicht auf Kommando auslösen. Die Tests legen deshalb
## die Dateien an, die er hinterließe (R3, „Grund“), und prüfen, welcher Stand dann gilt. Echte
## Fehlschläge entstehen ohne Hilfe im Code: Ein Ordner mit Inhalt an der Stelle einer Datei lässt
## sich weder löschen noch überschreiben (R16). Nur Schritt 2 braucht eine Hilfe: SaveStoreMitDefekt
## stellt einen Datenträger nach, der etwas anderes speichert als verlangt.

const ORDNER := "user://test_save_store/"
const KATALOG := "res://test/fixtures/catalog_alle_arten.json"
const KATALOG_500 := "res://test/fixtures/catalog_500.json"
const FIXTURES := "res://test/fixtures/spielstaende/"
## 26.10.2026, 20:40:12 UTC
const ANGELEGT := 1793047212
## SC-002: so viele Spielstände, so lange darf das Lesen dauern.
const SPIELSTAENDE := 20
const LISTE_MSEC := 1000.0
const LAEUFE := 3


## Ein Datenträger, der nur die erste Hälfte des Texts speichert, etwa weil er voll ist, ohne es
## zu melden. Schritt 2 muss das finden.
class SaveStoreMitDefekt:
	extends SaveStore

	func _store_text(path: String, text: String) -> Error:
		# Mit / 2.0 und floori(), sonst warnt GDScript mit -d vor der Ganzzahl-Division.
		return super._store_text(path, text.substr(0, floori(text.length() / 2.0)))


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)


func after_each() -> void:
	_raeume_auf(ORDNER)


# --- Ordner, Pfad, Liste ------------------------------------------------------------------------

func test_ordner_und_pfad() -> void:
	# Act und Assert: nur rechnen, nichts lesen oder schreiben
	assert_eq(SaveStore.FOLDER, "user://spielstaende/")
	assert_eq(SaveStore.new().folder, SaveStore.FOLDER, "Die Vorgabe ist der Ordner des Spiels.")
	assert_eq(SaveStore.new().path_of(2), "user://spielstaende/spiel_2.json")
	assert_eq(_store().path_of(12), ORDNER + "spiel_12.json")
	assert_eq(SaveStore.new("user://ohne_schraegstrich").path_of(3),
		"user://ohne_schraegstrich/spiel_3.json")


func test_fehlender_ordner() -> void:
	# Arrange
	var store := SaveStore.new(ORDNER.path_join("gibt_es_nicht"))

	# Act und Assert
	assert_eq(store.list_slots(), [], "Fehlt der Ordner, ist die Liste leer.")
	assert_eq(store.next_number(), 1, "Ohne Dateien ist die nächste Nummer 1.")
	assert_eq(store.delete(1), ERR_FILE_NOT_FOUND)
	assert_false(DirAccess.dir_exists_absolute(store.folder), "Lesen legt keinen Ordner an.")


func test_liste_nach_zuletzt_gespielt_dann_die_nicht_fortsetzbaren() -> void:
	# Arrange (R12): fortsetzbare nach „zuletzt gespielt“, das jüngste oben, bei Gleichstand die
	# höhere Nummer zuerst; darunter die übrigen nach Nummer absteigend.
	var store := _store()
	for fall: Array in [[1, 300], [2, 100], [3, 300], [5, 200], [8, 50]]:
		assert_eq(store.write(_spielstand(fall[0], fall[1])), OK)
	_kopiere("spiel_kein_json.json", 4)
	_kopiere("spiel_format_2.json", 9)
	_kopiere("spiel_grad_extrem.json", 6)

	# Act
	var slots := store.list_slots()

	# Assert
	assert_eq(_nummern(slots), [3, 1, 5, 2, 8, 9, 6, 4])
	assert_eq(_zustaende(slots), ["OK", "OK", "OK", "OK", "OK", "TOO_NEW", "DAMAGED", "DAMAGED"])
	assert_eq(slots[0].game.last_played_at, ANGELEGT + 300)


func test_fremde_dateien_werden_nie_gelistet_gezaehlt_oder_geloescht() -> void:
	# Arrange: nur spiel_1.json gehört zu einem Spielstand.
	var store := _store()
	assert_eq(store.write(_spielstand(1)), OK)
	var fremde := ["notizen.txt", "spiel_01.json", "spiel_1.json.bak", "Spiel_2.json",
		"spiel_x.json", "spiel_1.json.neu.alt", "spiel_0.json", "spiel_1234567890.json",
		"spiel_3.jsonx", "xspiel_4.json", "spiel_-5.json", "spiel_6.json.tmp"]
	for datei: String in fremde:
		_schreibe(ORDNER.path_join(datei), _spielstand(7).to_json())

	# Act
	var slots := store.list_slots()
	var naechste := store.next_number()
	var geloescht := store.delete(1)

	# Assert
	assert_eq(_nummern(slots), [1], "Nur der Spielstand nach dem Muster.")
	assert_eq(naechste, 2, "Fremde Dateien zählen nicht mit.")
	assert_eq(geloescht, OK)
	assert_eq(_dateien(), _sortiert(fremde), "Gelöscht ist nur spiel_1.json.")


# --- Nächste Nummer (R4) ------------------------------------------------------------------------

func test_naechste_nummer_mit_luecken_beschaedigten_und_zwischendateien() -> void:
	# Arrange
	var store := _store()
	assert_eq(store.next_number(), 1, "Leerer Ordner.")
	assert_eq(store.write(_spielstand(1)), OK)
	_kopiere("spiel_kein_json.json", 3)
	_schreibe(ORDNER.path_join("spiel_7.json.neu"), "{ halb")

	# Act und Assert
	assert_eq(store.next_number(), 8, "Lücken bleiben, die übrig gebliebene .neu zählt mit.")
	_schreibe(ORDNER.path_join("spiel_11.json.alt"), _spielstand(11).to_json())
	assert_eq(store.next_number(), 12, "Auch eine .alt.")
	_kopiere("spiel_format_2.json", 20)
	assert_eq(store.next_number(), 21, "Auch ein zu neuer Spielstand.")
	assert_eq(_nummern(store.list_slots()), [11, 1, 20, 3],
		"Die .neu allein ergibt keinen Spielstand, zählt aber für die Nummer. 11 und 1 wurden "
		+ "zur selben Zeit gespielt, also die höhere Nummer zuerst (R12).")


func test_naechste_nummer_weicht_auch_einem_ordner_mit_dem_namen_aus() -> void:
	# Arrange: Ein Ordner heißt wie eine Datei eines Spielstands. write() mit is_new weicht ihm
	# aus, also zählt er auch hier.
	var store := _store()
	DirAccess.make_dir_recursive_absolute(ORDNER.path_join("spiel_5.json.neu/inhalt"))

	# Act und Assert
	assert_eq(store.next_number(), 6)
	assert_eq(store.write(_spielstand(5), true), ERR_ALREADY_EXISTS)
	assert_string_contains(store.last_error, store.path_of(5) + ".neu.",
		"Das Protokoll nennt, was wirklich da ist.")
	assert_eq(store.list_slots(), [], "Ein Ordner ist kein Spielstand.")


# --- Schreiben (R3) -----------------------------------------------------------------------------

func test_schreiben_legt_den_ordner_an_und_hinterlaesst_nur_die_json() -> void:
	# Arrange
	var store := SaveStore.new(ORDNER.path_join("neu/tiefer"))
	var game := _spielstand(2, 0, _katalog())

	# Act
	var ergebnis := store.write(game)

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(store.last_error, "")
	assert_eq(Array(DirAccess.get_files_at(store.folder)), ["spiel_2.json"],
		"Keine .neu und keine .alt bleiben übrig.")
	assert_eq(FileAccess.get_file_as_string(store.path_of(2)), game.to_json())
	var slots := store.list_slots()
	assert_eq(_zustaende(slots), ["OK"])
	assert_eq(slots[0].game.to_json(), game.to_json(), "Gelesen ist es derselbe Spielstand.")


func test_schreiben_ueber_einen_vorhandenen_stand() -> void:
	# Arrange
	var store := _store()
	var game := _spielstand(2)
	assert_eq(store.write(game), OK)
	game.day = _tag(1986, 3, 14)
	game.last_played_at += 3600

	# Act
	var ergebnis := store.write(game)

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(_dateien(), ["spiel_2.json"])
	assert_eq(FileAccess.get_file_as_string(store.path_of(2)), game.to_json(), "Der neue Stand.")
	assert_eq(store.list_slots()[0].game.day_text(), "14.03.1986")


func test_abbruch_in_schritt_1_oder_2_laesst_den_alten_stand() -> void:
	# Arrange: Eine halbe .neu liegt neben dem alten Stand, etwa weil der Datenträger voll war.
	var store := _store()
	var alt := _spielstand(2)
	assert_eq(store.write(alt), OK)
	var neu := _spielstand(2, 3600)
	_schreibe(store.path_of(2) + ".neu", neu.to_json().substr(0, 200))

	# Act
	var slots := store.list_slots()

	# Assert
	assert_eq(_zustaende(slots), ["OK"])
	assert_eq([slots[0].path, slots[0].game.to_json()], [store.path_of(2), alt.to_json()],
		"Die alte spiel_2.json gilt, die halbe .neu wird übergangen.")
	assert_push_warning_count(0, "Aus der .json gelesen, also keine Warnung.")
	# Das nächste Speichern räumt die halbe .neu ab.
	assert_eq(store.write(neu), OK)
	assert_eq(_dateien(), ["spiel_2.json"])
	assert_eq(store.list_slots()[0].game.to_json(), neu.to_json())


func test_abbruch_zwischen_schritt_3_und_4_liest_die_geprufte_neu() -> void:
	# Arrange: Der alte Stand ist schon .alt, die geprüfte .neu noch nicht umbenannt.
	var store := _store()
	var alt := _spielstand(2)
	var neu := _spielstand(2, 3600)
	_schreibe(store.path_of(2) + ".alt", alt.to_json())
	_schreibe(store.path_of(2) + ".neu", neu.to_json())

	# Act
	var slots := store.list_slots()

	# Assert
	assert_eq(_zustaende(slots), ["OK"])
	assert_eq([slots[0].path, slots[0].game.to_json()], [store.path_of(2) + ".neu", neu.to_json()])
	assert_push_warning("Spielstand 2: gelesen aus %s.neu" % store.path_of(2),
		"Lesen aus .neu steht im Protokoll (CHK021).")
	# Das nächste Speichern schreibt eine neue spiel_2.json und räumt auf.
	assert_eq(store.write(slots[0].game), OK)
	assert_eq(_dateien(), ["spiel_2.json"])


func test_abbruch_nach_schritt_4_mit_halber_json_liest_die_alt() -> void:
	# Arrange: Strom weg, die neue spiel_2.json ist nur halb auf der Platte, Schritt 5 lief nicht.
	var store := _store()
	var alt := _spielstand(2)
	_schreibe(store.path_of(2), _spielstand(2, 3600).to_json().substr(0, 300))
	_schreibe(store.path_of(2) + ".alt", alt.to_json())

	# Act
	var slots := store.list_slots()

	# Assert
	assert_eq(_zustaende(slots), ["OK"])
	assert_eq([slots[0].path, slots[0].game.to_json()], [store.path_of(2) + ".alt", alt.to_json()])
	assert_push_warning("Spielstand 2: gelesen aus %s.alt" % store.path_of(2))
	assert_eq(store.write(slots[0].game), OK)
	assert_eq(_dateien(), ["spiel_2.json"], "Die beschädigte .json ist ersetzt, die .alt weg.")


func test_abbruch_vor_schritt_5_die_neue_json_gilt() -> void:
	# Arrange
	var store := _store()
	var neu := _spielstand(2, 3600)
	_schreibe(store.path_of(2), neu.to_json())
	_schreibe(store.path_of(2) + ".alt", _spielstand(2).to_json())

	# Act
	var slots := store.list_slots()

	# Assert
	assert_eq([slots[0].path, slots[0].game.to_json()], [store.path_of(2), neu.to_json()])
	assert_push_warning_count(0)


func test_allein_stehende_neu() -> void:
	# Arrange: Das erste Speichern eines neuen Spiels scheiterte (4), oder es brach zwischen
	# Schritt 3 und 4 ab, als es noch keine .json gab (6).
	var store := _store()
	_schreibe(store.path_of(4) + ".neu", "{ halb")
	_schreibe(store.path_of(6) + ".neu", _spielstand(6).to_json())

	# Act
	var slots := store.list_slots()

	# Assert
	assert_eq(_nummern(slots), [6], "Eine nicht fortsetzbare .neu allein ergibt keinen Spielstand.")
	assert_eq(slots[0].path, store.path_of(6) + ".neu")


func test_zu_neue_json_faellt_nie_auf_eine_zwischendatei_zurueck() -> void:
	# Arrange (Analyse, B2): neben der zu neuen .json eine fortsetzbare .alt und eine .neu
	var store := _store()
	_kopiere("spiel_format_2.json", 2)
	_schreibe(store.path_of(2) + ".alt", _spielstand(2).to_json())
	_schreibe(store.path_of(2) + ".neu", _spielstand(2, 60).to_json())

	# Act
	var slots := store.list_slots()

	# Assert
	assert_eq(_zustaende(slots), ["TOO_NEW"])
	assert_eq([slots[0].path, slots[0].reason],
		[store.path_of(2), "Mit einer neueren Version gespeichert."],
		"Sonst überschriebe das nächste Speichern den neueren Stand.")


func test_ohne_fortsetzbare_datei_gilt_der_zustand_der_json_sonst_der_alt() -> void:
	# Arrange: 2 mit beschädigter .json und .alt; 3 nur mit einer zu neuen .alt; 5 mit beschädigter
	# .json und einer zu neuen .neu.
	var store := _store()
	_kopiere("spiel_grad_extrem.json", 2)
	_kopiere("spiel_kein_json.json", 2, ".alt")
	_kopiere("spiel_format_2.json", 3, ".alt")
	_kopiere("spiel_seed_negativ.json", 5)
	_kopiere("spiel_format_2.json", 5, ".neu")

	# Act
	var slots := store.list_slots()

	# Assert
	assert_eq(_nummern(slots), [5, 3, 2])
	assert_eq([slots[0].path, slots[0].reason], [store.path_of(5),
		"Lässt sich nicht lesen: Ein Teil der Datei stimmt nicht."],
		"Zu neu zählt nur bei der .json; der Seed steht nur im Protokoll.")
	assert_eq([slots[1].path, slots[1].state], [store.path_of(3) + ".alt", SaveSlot.State.TOO_NEW])
	assert_eq([slots[2].path, slots[2].reason], [store.path_of(2),
		"Der Schwierigkeitsgrad ist unbekannt."])


func test_speichern_scheitert_ordner_mit_inhalt_an_der_stelle_der_neu() -> void:
	# Arrange
	var store := _store()
	var alt := _spielstand(2)
	assert_eq(store.write(alt), OK)
	DirAccess.make_dir_recursive_absolute(store.path_of(2) + ".neu/inhalt")

	# Act
	var ergebnis := store.write(_spielstand(2, 3600))

	# Assert
	assert_ne(ergebnis, OK)
	assert_string_contains(store.last_error, "Schritt 1")
	assert_string_contains(store.last_error, store.path_of(2) + ".neu")
	assert_eq(FileAccess.get_file_as_string(store.path_of(2)), alt.to_json(),
		"Alter Stand unberührt.")
	assert_eq(store.list_slots()[0].game.to_json(), alt.to_json())


func test_speichern_scheitert_ordner_mit_inhalt_an_der_stelle_der_alt() -> void:
	# Arrange
	var store := _store()
	var alt := _spielstand(2)
	assert_eq(store.write(alt), OK)
	DirAccess.make_dir_recursive_absolute(store.path_of(2) + ".alt/inhalt")

	# Act
	var ergebnis := store.write(_spielstand(2, 3600))

	# Assert
	assert_ne(ergebnis, OK)
	assert_string_contains(store.last_error, "Schritt 3")
	assert_string_contains(store.last_error, store.path_of(2) + ".alt")
	assert_eq(FileAccess.get_file_as_string(store.path_of(2)), alt.to_json(),
		"Alter Stand unberührt.")
	var slots := store.list_slots()
	assert_eq([slots[0].path, slots[0].game.to_json()], [store.path_of(2), alt.to_json()],
		"Die .json ist fortsetzbar und gilt, auch neben der geprüften .neu.")


func test_speichern_scheitert_ordner_mit_inhalt_an_der_stelle_der_json() -> void:
	# Arrange: Nur eine Datei wandert nach .alt; der Ordner bleibt, und Schritt 4 scheitert.
	var store := _store()
	DirAccess.make_dir_recursive_absolute(store.path_of(2) + "/inhalt")
	var neu := _spielstand(2)

	# Act
	var ergebnis := store.write(neu)

	# Assert
	assert_ne(ergebnis, OK)
	assert_string_contains(store.last_error, "Schritt 4")
	assert_true(DirAccess.dir_exists_absolute(store.path_of(2) + "/inhalt"), "Der Ordner bleibt.")
	var slots := store.list_slots()
	assert_eq([slots[0].path, slots[0].game.to_json()], [store.path_of(2) + ".neu", neu.to_json()],
		"Die geprüfte .neu ist lesbar.")


func test_schritt_2_findet_einen_text_der_nicht_stimmt() -> void:
	# Arrange
	var store := _store()
	var alt := _spielstand(2)
	assert_eq(store.write(alt), OK)
	var defekt := SaveStoreMitDefekt.new(ORDNER)

	# Act
	var ergebnis := defekt.write(_spielstand(2, 3600))

	# Assert
	assert_eq(ergebnis, ERR_FILE_CORRUPT)
	assert_string_contains(defekt.last_error, "Schritt 2")
	assert_string_contains(defekt.last_error, store.path_of(2) + ".neu")
	assert_eq(FileAccess.get_file_as_string(store.path_of(2)), alt.to_json(),
		"Nichts am alten Stand ist berührt.")
	assert_false(FileAccess.file_exists(store.path_of(2) + ".alt"), "Schritt 3 lief nicht.")
	assert_eq(store.list_slots()[0].game.to_json(), alt.to_json())


# --- Zwei Fehler hintereinander (T036) ----------------------------------------------------------

# Gilt die .neu nach der Leseregel, ist sie der einzige lesbare Stand. Schritt 1 des nächsten
# Speicherns macht sie zu .alt, statt sie zu löschen; scheitert dieses Speichern danach auch, ist
# der Spielstand nicht verloren. Das Scheitern kommt aus Schritt 2 (SaveStoreMitDefekt).

func test_einzige_neu_bleibt_fortsetzbar_wenn_das_naechste_speichern_scheitert() -> void:
	# Arrange: nur eine fortsetzbare .neu, ohne .json und ohne .alt
	var store := _store()
	var gerettet := _spielstand(2)
	_schreibe(store.path_of(2) + ".neu", gerettet.to_json())

	# Act
	var ergebnis := SaveStoreMitDefekt.new(ORDNER).write(_spielstand(2, 3600))

	# Assert
	assert_eq(ergebnis, ERR_FILE_CORRUPT, "Voraussetzung: Das Speichern scheitert in Schritt 2.")
	var slots := store.list_slots()
	assert_eq(_zustaende(slots), ["OK"], "Der Spielstand lässt sich weiter fortsetzen.")
	assert_eq([slots[0].path, slots[0].game.to_json()],
		[store.path_of(2) + ".alt", gerettet.to_json()], "Die .neu von vorher gilt jetzt als .alt.")


func test_einzige_neu_ersetzt_eine_beschaedigte_alt() -> void:
	# Arrange: daneben eine .alt, die sich nicht fortsetzen lässt
	var store := _store()
	var gerettet := _spielstand(2)
	_schreibe(store.path_of(2) + ".neu", gerettet.to_json())
	_kopiere("spiel_kein_json.json", 2, ".alt")

	# Act
	var ergebnis := SaveStoreMitDefekt.new(ORDNER).write(_spielstand(2, 3600))

	# Assert
	assert_eq(ergebnis, ERR_FILE_CORRUPT)
	var slots := store.list_slots()
	assert_eq(_zustaende(slots), ["OK"])
	assert_eq([slots[0].path, slots[0].game.to_json()],
		[store.path_of(2) + ".alt", gerettet.to_json()], "Die beschädigte .alt ist ersetzt.")


func test_einzige_neu_neben_einer_beschaedigten_json_bleibt_fortsetzbar() -> void:
	# Arrange: Die .json ist beschädigt, also gilt die .neu, wie nach einem Abbruch zwischen
	# Schritt 3 und 4, als die .json noch halb war.
	var store := _store()
	var gerettet := _spielstand(2)
	_kopiere("spiel_grad_extrem.json", 2)
	_schreibe(store.path_of(2) + ".neu", gerettet.to_json())

	# Act
	var ergebnis := SaveStoreMitDefekt.new(ORDNER).write(_spielstand(2, 3600))

	# Assert
	assert_eq(ergebnis, ERR_FILE_CORRUPT)
	var slots := store.list_slots()
	assert_eq([slots[0].path, slots[0].game.to_json()],
		[store.path_of(2) + ".alt", gerettet.to_json()])


func test_eine_fortsetzbare_alt_bleibt_und_die_neu_wird_geloescht() -> void:
	# Arrange: eine fortsetzbare .neu und eine ältere fortsetzbare .alt
	var store := _store()
	var aelter := _spielstand(2)
	_schreibe(store.path_of(2) + ".neu", _spielstand(2, 60).to_json())
	_schreibe(store.path_of(2) + ".alt", aelter.to_json())

	# Act
	var ergebnis := SaveStoreMitDefekt.new(ORDNER).write(_spielstand(2, 3600))

	# Assert
	assert_eq(ergebnis, ERR_FILE_CORRUPT)
	assert_eq(FileAccess.get_file_as_string(store.path_of(2) + ".alt"), aelter.to_json(),
		"Die .alt bleibt, wie sie war.")
	var slots := store.list_slots()
	assert_eq([slots[0].path, slots[0].game.to_json()], [store.path_of(2) + ".alt", aelter.to_json()],
		"Die halbe neue .neu wird übergangen, die .alt gilt.")


func test_neben_einer_fortsetzbaren_json_wird_die_neu_geloescht_wie_bisher() -> void:
	# Arrange: Die .json gilt, die .neu ist nicht der einzige lesbare Stand.
	var store := _store()
	var alt := _spielstand(2)
	assert_eq(store.write(alt), OK)
	_schreibe(store.path_of(2) + ".neu", _spielstand(2, 60).to_json())

	# Act
	var ergebnis := SaveStoreMitDefekt.new(ORDNER).write(_spielstand(2, 3600))

	# Assert
	assert_eq(ergebnis, ERR_FILE_CORRUPT)
	assert_false(FileAccess.file_exists(store.path_of(2) + ".alt"), "Keine .alt entsteht.")
	assert_eq(FileAccess.get_file_as_string(store.path_of(2)), alt.to_json())


func test_gelungenes_speichern_nach_zwei_fehlern_hinterlaesst_nur_die_json() -> void:
	# Arrange: wie oben, eine einzige .neu, und das nächste Speichern scheitert.
	var store := _store()
	_schreibe(store.path_of(2) + ".neu", _spielstand(2).to_json())
	assert_eq(SaveStoreMitDefekt.new(ORDNER).write(_spielstand(2, 3600)), ERR_FILE_CORRUPT)
	assert_eq(_dateien(), ["spiel_2.json.alt", "spiel_2.json.neu"],
		"Voraussetzung: die gerettete .alt und die halbe .neu.")
	var neu := _spielstand(2, 7200)

	# Act
	var ergebnis := store.write(neu)

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(_dateien(), ["spiel_2.json"], "Schritt 5 räumt auf.")
	assert_eq(FileAccess.get_file_as_string(store.path_of(2)), neu.to_json())


func test_neues_spiel_weicht_einer_vorhandenen_nummer_aus() -> void:
	# Arrange (CHK002; Analyse, C4): Ein zweites Fenster legt die nächste Nummer an, bevor dieses
	# schreibt.
	var store := _store()
	assert_eq(store.write(_spielstand(1)), OK)
	var nummer := store.next_number()
	var anderes_fenster := _spielstand(nummer, 99)
	assert_eq(store.write(anderes_fenster, true), OK)

	# Act
	var erster_versuch := store.write(_spielstand(nummer), true)
	var fehler := store.last_error
	var zweiter_versuch := store.write(_spielstand(store.next_number()), true)

	# Assert
	assert_eq(erster_versuch, ERR_ALREADY_EXISTS)
	assert_eq(fehler, "Speichern: Zur Nummer 2 gibt es schon eine Datei, etwa %s."
		% store.path_of(2))
	assert_eq(FileAccess.get_file_as_string(store.path_of(2)), anderes_fenster.to_json(),
		"Der Spielstand des anderen Fensters bleibt.")
	assert_eq(zweiter_versuch, OK)
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json", "spiel_3.json"])


func test_neues_spiel_weicht_auch_zwischendateien_aus() -> void:
	# Arrange
	var store := _store()
	_schreibe(store.path_of(4) + ".neu", "{ halb")
	_schreibe(store.path_of(5) + ".alt", _spielstand(5).to_json())

	# Act und Assert: Das Protokoll nennt die Datei, die wirklich da ist, nicht spiel_N.json.
	assert_eq(store.write(_spielstand(4), true), ERR_ALREADY_EXISTS)
	assert_eq(store.last_error, "Speichern: Zur Nummer 4 gibt es schon eine Datei, etwa %s."
		% (store.path_of(4) + ".neu"))
	assert_eq(store.write(_spielstand(5), true), ERR_ALREADY_EXISTS)
	assert_eq(store.last_error, "Speichern: Zur Nummer 5 gibt es schon eine Datei, etwa %s."
		% (store.path_of(5) + ".alt"))
	assert_eq(store.write(_spielstand(4)), OK, "Ohne is_new schreibt es und räumt die .neu ab.")


func test_beschaedigte_und_zu_neue_werden_nie_ueberschrieben() -> void:
	# Arrange
	var store := _store()
	_kopiere("spiel_kein_json.json", 3)
	_kopiere("spiel_format_2.json", 4)
	var vorher := _dateien_mit_inhalt()

	# Act: wie ein neues Spiel, erst mit den Nummern der beiden, dann mit der nächsten
	var auf_3 := store.write(_spielstand(3), true)
	var auf_4 := store.write(_spielstand(4), true)
	var naechste := store.next_number()
	var neu := store.write(_spielstand(naechste), true)

	# Assert
	assert_eq([auf_3, auf_4], [ERR_ALREADY_EXISTS, ERR_ALREADY_EXISTS])
	assert_eq(naechste, 5)
	assert_eq(neu, OK)
	var danach := _dateien_mit_inhalt()
	danach.erase("spiel_5.json")
	assert_eq(danach, vorher, "Beide Dateien sind Byte für Byte unverändert.")
	assert_eq(_zustaende(store.list_slots()), ["OK", "TOO_NEW", "DAMAGED"],
		"Das neue Spiel, der zu neue, der beschädigte.")


func test_ungueltige_nummer_wird_nicht_geschrieben() -> void:
	# Arrange
	var store := _store()

	# Act und Assert
	assert_eq(store.write(null), ERR_INVALID_PARAMETER)
	assert_eq(store.write(_spielstand(0)), ERR_INVALID_PARAMETER)
	assert_eq(store.write(_spielstand(SaveStore.MAX_NUMBER + 1)), ERR_INVALID_PARAMETER)
	assert_ne(store.last_error, "")
	assert_eq(_dateien(), [])


# --- Löschen (FR-018) ---------------------------------------------------------------------------

func test_loeschen_nur_der_drei_dateien_einer_nummer() -> void:
	# Arrange
	var store := _store()
	for endung: String in ["", ".neu", ".alt"]:
		_schreibe(store.path_of(2) + endung, _spielstand(2).to_json())
	assert_eq(store.write(_spielstand(20)), OK)
	assert_eq(store.write(_spielstand(1)), OK)
	for fremd: String in ["spiel_2.json.bak", "notizen.txt", "spiel_02.json"]:
		_schreibe(ORDNER.path_join(fremd), "fremd")

	# Act
	var ergebnis := store.delete(2)

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(store.last_error, "")
	assert_eq(_dateien(), ["notizen.txt", "spiel_02.json", "spiel_1.json", "spiel_2.json.bak",
		"spiel_20.json"])
	assert_eq(store.delete(2), ERR_FILE_NOT_FOUND, "Fehlt alles: ERR_FILE_NOT_FOUND.")
	assert_eq(store.delete(0), ERR_INVALID_PARAMETER, "Keine Nummer eines Spielstands.")


func test_loeschen_scheitert_ordner_an_der_stelle_der_json_neben_einer_fortsetzbaren_alt() -> void:
	# Arrange (Analyse, E2)
	var store := _store()
	DirAccess.make_dir_recursive_absolute(store.path_of(2) + "/inhalt")
	var alt := _spielstand(2)
	_schreibe(store.path_of(2) + ".alt", alt.to_json())

	# Act
	var ergebnis := store.delete(2)

	# Assert
	assert_ne(ergebnis, OK)
	assert_string_contains(store.last_error, store.path_of(2))
	assert_true(FileAccess.file_exists(store.path_of(2) + ".alt"), "Die .alt bleibt.")
	var slots := store.list_slots()
	assert_eq(_nummern(slots), [2], "Der Spielstand steht noch in der Liste.")
	assert_eq(slots[0].game.to_json(), alt.to_json())


func test_loeschen_in_der_reihenfolge_json_neu_alt_und_halt_beim_ersten_fehler() -> void:
	# Arrange: .json und .alt als Dateien, an der Stelle der .neu ein Ordner mit Inhalt
	var store := _store()
	_schreibe(store.path_of(2), _spielstand(2).to_json())
	DirAccess.make_dir_recursive_absolute(store.path_of(2) + ".neu/inhalt")
	_schreibe(store.path_of(2) + ".alt", _spielstand(2).to_json())

	# Act
	var ergebnis := store.delete(2)

	# Assert
	assert_ne(ergebnis, OK)
	assert_string_contains(store.last_error, store.path_of(2) + ".neu")
	assert_false(FileAccess.file_exists(store.path_of(2)), "Die .json ist zuerst gelöscht.")
	assert_true(FileAccess.file_exists(store.path_of(2) + ".alt"),
		"Nach dem Fehler hört es auf; aus der .alt ist der Spielstand noch lesbar.")
	assert_eq(_nummern(store.list_slots()), [2])


# --- SC-002 ------------------------------------------------------------------------------------

func test_sc_002_zwanzig_spielstaende_mit_500_ereignissen_in_hoechstens_einer_sekunde() -> void:
	# Arrange: je eine Kopie von catalog_500.json, rund 25-mal so viele Ereignisse wie heute
	var store := _store()
	var katalog := _katalog(KATALOG_500)
	assert_eq(katalog.events.size(), 500)
	for nummer in range(1, SPIELSTAENDE + 1):
		assert_eq(store.write(_spielstand(nummer, nummer, katalog)), OK)
	var zeiten: Array[float] = []
	var slots: Array[SaveSlot] = []

	# Act
	for lauf in LAEUFE:
		var beginn := Time.get_ticks_usec()
		slots = store.list_slots()
		zeiten.append((Time.get_ticks_usec() - beginn) / 1000.0)

	# Assert
	var sortiert := zeiten.duplicate()
	sortiert.sort()
	var median: float = sortiert[floori(sortiert.size() / 2.0)]
	gut.p("SC-002, Liste mit %d Spielständen zu je 500 Ereignissen: Median %.1f ms aus %s" % [
		SPIELSTAENDE, median, zeiten])
	assert_eq(slots.size(), SPIELSTAENDE)
	assert_eq(_zustaende(slots).count("OK"), SPIELSTAENDE, "Alle fortsetzbar.")
	assert_lt(median, LISTE_MSEC, "SC-002: gelesen in höchstens einer Sekunde.")


# --- Hilfen ---------------------------------------------------------------------------------

func _store() -> SaveStore:
	return SaveStore.new(ORDNER)


## Ein Spielstand mit der Nummer [param nummer]; zuletzt gespielt ANGELEGT plus [param spaeter]
## Sekunden. Ohne Katalog der Katalog aller Arten.
func _spielstand(nummer: int, spaeter: int = 0, katalog: EventCatalog = null) -> SaveGame:
	var game := SaveGame.new()
	game.number = nummer
	game.name = SaveGame.default_name(nummer)
	game.difficulty = Difficulty.Level.SCHWER
	game.seed = 4711
	game.day = _tag(1985, 2, 15)
	game.created_at = ANGELEGT
	game.last_played_at = ANGELEGT + spaeter
	game.game_version = "0.1"
	game.catalog = katalog if katalog != null else _katalog()
	game.interventions.append({"at_day": -1, "kind": "add_modifier", "modifier": {
		"event_id": "reklamationswelle", "from_day": _tag(1990, 1, 1), "id": "windiger_haendler",
		"reason": "Ware vom windigen Händler", "to_day": _tag(1993, 12, 31), "value": 0.05}})
	return game


func _katalog(pfad: String = KATALOG) -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	return EventCatalog.read_file(pfad, issues)


func _nummern(slots: Array[SaveSlot]) -> Array:
	return slots.map(func(slot: SaveSlot) -> int: return slot.number)


func _zustaende(slots: Array[SaveSlot]) -> Array:
	return slots.map(func(slot: SaveSlot) -> String: return SaveSlot.State.keys()[slot.state])


## Die Dateien im Testordner, sortiert.
func _dateien() -> Array:
	return _sortiert(Array(DirAccess.get_files_at(ORDNER)))


## Datei → Inhalt für alle Dateien im Testordner.
func _dateien_mit_inhalt() -> Dictionary:
	var inhalt := {}
	for datei: String in DirAccess.get_files_at(ORDNER):
		inhalt[datei] = FileAccess.get_file_as_string(ORDNER.path_join(datei))
	return inhalt


func _sortiert(liste: Array) -> Array:
	var kopie := liste.duplicate()
	kopie.sort()
	return kopie


## Kopiert eine Fixture als spiel_<nummer>.json<endung> in den Testordner.
func _kopiere(fixture: String, nummer: int, endung: String = "") -> void:
	var ziel := ORDNER.path_join("spiel_%d.json%s" % [nummer, endung])
	assert_eq(DirAccess.copy_absolute(FIXTURES.path_join(fixture), ziel), OK,
		"Kopiert: %s" % fixture)


func _schreibe(pfad: String, text: String) -> void:
	var datei := FileAccess.open(pfad, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
