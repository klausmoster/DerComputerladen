extends GutTest

## Prüft den Titelbildschirm: den Text der Versionszeile (Feature 001, FR-014) und seit Feature 004
## die Blätter Hauptmenü und Gradwahl (T020; contracts/titelbildschirm.md, „TitleScreen“ und
## „Tests“; data-model.md, „Titelbildschirm: Blätter und Wege“): fünf Einträge, ihre Verfügbarkeit
## und Hinweise nach den Spielständen im Ordner, die Vorwahl, die Gradwahl mit Tastatur und Maus,
## Esc und „Zurück“, ein neues Spiel mit 3 Eingaben (SC-001), „Weiterspielen“ mit 1 (SC-002), die
## Meldung, wenn das Anlegen scheitert, und dass ohne Spiel nichts läuft und keine Datei entsteht
## (FR-003).
##
## Dazu die Liste der Spielstände (T026): bei jedem Öffnen neu gelesen, Fortsetzen über die Liste mit
## 2 Klicks oder 4 Tasten (SC-002), die Anzeige mit 20 Spielständen in höchstens 1 s, „Zurück“ und
## Esc. Und das Löschen (T027): Rückfrage, Abbrechen, Bestätigen, die Auswahl danach, das Ende des
## Löschmodus auf allen vier Wegen, fremde Dateien bleiben, Löschen scheitert, Datei schon weg. Die
## Meldung zum Löschen gehört zum Spielstand: Sie wandert beim Rollen mit, und ein anderer
## Spielstand an derselben Stelle bringt seinen Hinweis.
##
## Wie test_game_session.gd arbeiten die Tests nicht mit den Autoloads. _zeige_titel() baut je Test
## eine eigene Uhr, eine eigene Zeitleiste mit Test-Katalog und eine eigene GameSession mit dem
## Ordner ORDNER; den Szenenwechsel fängt ein eigener scene_callback ab, der nur mitschreibt. Nach
## user://spielstaende/ schreibt und liest kein Test; after_each() räumt WURZEL ab.
##
## Der Titel steht in einem eigenen Viewport von 640 × 360 wie die Menüs in test_main_menu.gd:
## eigene Eingabe, eigener Fokus, und GUTs Oberfläche fängt keine Klicks ab. Tasten und Klicks gehen
## über push_input wie echte Eingaben.

const TITEL := preload("res://scenes/title/title_screen.tscn")
const SITZUNG := preload("res://core/game_session.gd")
const ZEITLEISTE := preload("res://core/timeline.gd")
const UHR := preload("res://core/game_clock.gd")
const WURZEL := "user://test_title_screen/"
const ORDNER := "user://test_title_screen/spielstaende/"
const KATALOGE := "res://test/fixtures/"
const FIXTURES := "res://test/fixtures/spielstaende/"
const SPIELBILDSCHIRM := "res://scenes/game/game_screen.tscn"
## 26.10.2026, 20:40:12 UTC
const ANGELEGT := 1793047212
const WUERFEL_SEED := 20261026
const ZEILE := MainMenu.ROW_HEIGHT

## Die Sätze für den Spieler, hier ausgeschrieben statt als Konstanten aus dem Code: So fällt jede
## Änderung hier auf.
const NICHT_ANGELEGT := "Speichern ging nicht. Es ist kein Spiel angelegt."
const LOESCHEN_GING_NICHT := "Löschen ging nicht. Der Spielstand ist noch da."
## „Spiel laden“, immer derselbe Satz, auch wenn sich keiner fortsetzen lässt (T038).
const HINWEIS_LADEN := "Zurück in einen deiner Läden."
const HINWEIS_ZURUECK_IM_MODUS := "Nicht löschen. Esc geht auch."
## SC-002: so viele Spielstände, so lange darf die Anzeige der Liste dauern, so oft gemessen.
const SPIELSTAENDE := 20
const LISTE_MSEC := 1000.0
const LAEUFE := 3

var _titel: TitleScreen
var _sitzung: SITZUNG
## Die Pfade, mit denen der Titel scene_callback aufgerufen hat.
var _wechsel: Array = []
var _auto_accept_quit_vorher := true


func before_each() -> void:
	_raeume_auf(WURZEL)
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_wechsel.clear()
	_titel = null
	_sitzung = null
	_auto_accept_quit_vorher = get_tree().auto_accept_quit


func after_each() -> void:
	# Ein Bild, damit die Zeilen, die ein Blatt beim Neubau mit queue_free() abgibt, wirklich frei
	# sind, bevor GUT nach verwaisten Knoten sucht.
	await wait_process_frames(1)
	get_tree().auto_accept_quit = _auto_accept_quit_vorher
	_raeume_auf(WURZEL)


# --- Versionszeile (Feature 001) ------------------------------------------------------------------

func test_version_wird_mit_v_und_kennzeichen_gezeigt() -> void:
	# Act
	var text := TitleScreen.version_text("0.1")

	# Assert
	assert_eq(text, "V0.1 · PROTOTYP",
		"Vor der Nummer steht ein V, dahinter mit Mittelpunkt das Kennzeichen.")


func test_ohne_version_steht_nur_das_kennzeichen_da() -> void:
	# Act
	var text := TitleScreen.version_text("")

	# Assert
	assert_eq(text, "PROTOTYP", "Ohne Nummer darf kein „V“ ohne Zahl erscheinen.")


# --- Ohne Spiel läuft nichts (FR-003) -------------------------------------------------------------

func test_hauptszene_laeuft_und_es_beginnt_kein_spiel_und_entsteht_keine_datei() -> void:
	# Arrange (FR-003; US1, Szenario 5): die Hauptszene aus project.godot mit eigener Session und das
	# echte Autoload Timeline. Es kommt über seinen Pfad; seinen Namen kennt GDScript in einem
	# Skript, das mit -s startet, nicht. Der Test beginnt kein Spiel und schreibt nichts.
	var pfad: String = ProjectSettings.get_setting("application/run/main_scene")
	var zeitleiste_autoload := get_node(^"/root/Timeline")
	var szene: PackedScene = load(pfad)
	_sitzung = await _neue_sitzung()
	var titel := szene.instantiate() as TitleScreen
	titel.session = _sitzung
	titel.scene_callback = _merke_wechsel

	# Act: mehrere Bilder, länger als bis zum früheren Selbststart am Ende des ersten
	add_child_autofree(titel)
	await wait_process_frames(5)

	# Assert
	assert_eq(pfad, "res://scenes/title/title_screen.tscn", "Die Hauptszene ist der Titel.")
	assert_true(titel.is_inside_tree(), "Die Szene läuft.")
	assert_null(zeitleiste_autoload.run, "Ohne Beginn läuft kein Spiel.")
	assert_false(_sitzung.is_running(), "Auch die Session hat kein Spiel.")
	assert_null(_zeitleiste().run)
	assert_eq(_dateien(), [], "Im Ordner der Session entsteht keine Datei (FR-003).")
	assert_eq(_wechsel, [], "Kein Szenenwechsel.")


# --- Hauptmenü: Einträge, Verfügbarkeit, Hinweise, Vorwahl (FR-001, FR-001a, FR-002) -------------

func test_fuenf_eintraege_in_der_reihenfolge_von_fr_001() -> void:
	# Arrange
	await _zeige_titel()

	# Act
	var eintraege := _hauptmenue().entries

	# Assert
	assert_eq(eintraege.map(func(eintrag: MenuEntry) -> StringName: return eintrag.id),
		[&"continue", &"new_game", &"load_game", &"settings", &"quit"])
	assert_eq(_texte(_hauptmenue()),
		["Weiterspielen", "Neues Spiel", "Spiel laden", "Einstellungen", "Beenden"])
	assert_eq(_hauptmenue().header_text, "HAUPTMENÜ")
	assert_eq(_hauptmenue().size, Vector2(144, 6 * ZEILE), "Kopfzeile und fünf Zeilen.")
	assert_eq(_hauptmenue().global_position, Vector2(472, 150), "Lage wie in Feature 001.")


func test_ohne_spielstaende_ist_neues_spiel_gewaehlt_und_weiterspielen_und_laden_gesperrt() -> void:
	# Arrange
	await _zeige_titel()

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, false, false, true])
	assert_eq(_hinweise(_hauptmenue()), [
		"Noch kein Spiel angefangen.",
		"Einen neuen Laden aufmachen. Los geht es am 01.01.1985.",
		"Noch keine Spielstände.",
		"Noch nichts einzustellen. Kommt später.",
		"Laden abschließen und zurück zum Desktop.",
	])
	assert_eq(_hauptmenue().selected_index(), 1, "„Neues Spiel“ ist vorgewählt (FR-001a).")
	assert_true(_hat_fokus(_hauptmenue()), "Die Auswahl ist der Fokus.")
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	_assert_neben_zeile(_hauptmenue(), 1)
	_assert_nur_sichtbar(_hauptmenue())


func test_mit_spielstaenden_ist_weiterspielen_gewaehlt_und_nennt_den_zuletzt_gespielten() -> void:
	# Arrange: Spiel 2 ist zuletzt gespielt, obwohl Spiel 1 die kleinere Nummer hat.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 60)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 120)
	await _zeige_titel()

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [true, true, true, false, true])
	assert_eq(_hauptmenue().entries[0].hint, "Weiter mit Spiel 2, Schwer, am 14.03.1986.")
	assert_eq(_hauptmenue().entries[2].hint, "Zurück in einen deiner Läden.")
	assert_eq(_hauptmenue().selected_index(), 0, "„Weiterspielen“ ist vorgewählt (FR-001a).")
	assert_eq(_hinweis_text(), "Weiter mit Spiel 2, Schwer, am 14.03.1986.")
	_assert_neben_zeile(_hauptmenue(), 0)


func test_nur_beschaedigte_spielstaende_machen_nur_spiel_laden_verfuegbar() -> void:
	# Arrange (FR-002): Auch ein beschädigter Spielstand lässt sich später löschen.
	_kopiere("spiel_kein_json.json", 1)
	await _zeige_titel()

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, true, false, true])
	assert_eq(_hauptmenue().entries[0].hint, "Kein Spielstand lässt sich fortsetzen.")
	assert_eq(_hauptmenue().entries[2].hint, HINWEIS_LADEN,
		"Derselbe Satz, auch wenn sich keiner fortsetzen lässt (T038).")
	assert_eq(_hauptmenue().selected_index(), 1, "Ohne fortsetzbaren: „Neues Spiel“.")
	assert_push_warning("spiel_1.json", "Das Protokoll nennt die beschädigte Datei.")


func test_nur_zu_neue_und_beschaedigte_spielstaende_bei_spiel_laden_derselbe_satz() -> void:
	# Arrange (T038): ein zu neuer und ein beschädigter, keiner fortsetzbar
	_kopiere("spiel_format_2.json", 1)
	_kopiere("spiel_kein_json.json", 2)
	await _zeige_titel()

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, true, false, true])
	assert_eq(_hauptmenue().entries[2].hint, HINWEIS_LADEN)


func test_nur_ein_zu_neuer_spielstand_bei_spiel_laden_derselbe_satz() -> void:
	# Arrange (T038)
	_kopiere("spiel_format_2.json", 1)
	await _zeige_titel()

	# Assert
	assert_eq(_hauptmenue().entries[2].hint, HINWEIS_LADEN)


func test_ein_fortsetzbarer_neben_beschaedigten_bei_spiel_laden_derselbe_satz() -> void:
	# Arrange (T038)
	_kopiere("spiel_kein_json.json", 2)
	_kopiere("spiel_format_2.json", 3)
	_lege_an(1, Difficulty.Level.MITTEL, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()

	# Assert
	assert_eq(_hauptmenue().entries[2].hint, HINWEIS_LADEN)


func test_esc_im_hauptmenue_tut_nichts() -> void:
	# Arrange
	_lege_an(1, Difficulty.Level.MITTEL, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 0, "Die Auswahl bleibt.")
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())


# --- Gradwahl (FR-004, FR-005, FR-023) ------------------------------------------------------------

func test_neues_spiel_zeigt_die_gradwahl_mit_mittel_und_seinem_satz() -> void:
	# Arrange
	await _zeige_titel()

	# Act: „Neues Spiel“ ist gewählt.
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_gradwahl())
	assert_eq(_gradwahl().header_text, "SCHWIERIGKEIT")
	assert_eq(_texte(_gradwahl()), ["Leicht", "Mittel", "Schwer", "Zurück"])
	assert_eq(_verfuegbar(_gradwahl()), [true, true, true, true])
	assert_eq(_gradwahl().selected_index(), 1, "Mittel ist vorgewählt.")
	assert_true(_hat_fokus(_gradwahl()), "Die Gradwahl hat den Fokus.")
	assert_false(_hat_fokus(_hauptmenue()), "Das unsichtbare Hauptmenü hat keinen.")
	assert_eq(_hinweis_text(), "Das Glück hält sich raus.", "Sein Satz steht sofort da (R13).")
	assert_eq(_gradwahl().global_position, Vector2(472, 150), "An der Stelle des Hauptmenüs.")
	assert_eq(_gradwahl().size, Vector2(144, 5 * ZEILE), "144 breit wie das Hauptmenü.")
	_assert_neben_zeile(_gradwahl(), 1)


func test_der_satz_wechselt_mit_dem_grad() -> void:
	# Arrange
	await _zeige_titel()
	await _taste(KEY_ENTER)
	var saetze := []

	# Act: hoch auf Leicht, dann zweimal runter auf Schwer, dann auf Zurück.
	for taste: Key in [KEY_UP, KEY_DOWN, KEY_DOWN, KEY_DOWN]:
		await _taste(taste)
		saetze.append(_hinweis_text())

	# Assert
	assert_eq(saetze, [
		"Das Glück ist eher auf deiner Seite.",
		"Das Glück hält sich raus.",
		"Das Glück ist eher auf der Seite der anderen.",
		"Zurück zum Hauptmenü. Esc geht auch.",
	])


func test_esc_in_der_gradwahl_fuehrt_ohne_spielstand_zurueck() -> void:
	# Arrange (US1, Szenario 3)
	await _zeige_titel()
	await _taste(KEY_ENTER)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1, "Zurück auf „Neues Spiel“, das die Wahl öffnete.")
	assert_true(_hat_fokus(_hauptmenue()))
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	assert_eq(_dateien(), [], "Abbrechen legt keinen Spielstand an.")
	assert_false(_sitzung.is_running())
	assert_eq(_wechsel, [])


func test_zurueck_in_der_gradwahl_wirkt_wie_esc() -> void:
	# Arrange: „Zurück“ ist die letzte Zeile, von Mittel zweimal runter.
	await _zeige_titel()
	await _taste(KEY_ENTER)
	await _taste(KEY_DOWN)
	await _taste(KEY_DOWN)

	# Act
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1)
	assert_eq(_dateien(), [])
	assert_eq(_wechsel, [])


func test_beim_wiederoeffnen_ist_wieder_mittel_gewaehlt() -> void:
	# Arrange: Schwer wählen, dann zurück.
	await _zeige_titel()
	await _taste(KEY_ENTER)
	await _taste(KEY_DOWN)
	await _taste(KEY_ESCAPE)

	# Act
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_gradwahl().selected_index(), 1)
	assert_eq(_hinweis_text(), "Das Glück hält sich raus.")


func test_rueckkehr_ins_hauptmenue_liest_den_ordner_neu() -> void:
	# Arrange (Analyse, F2): Während die Gradwahl offen ist, kommt ein Spielstand in den Ordner.
	await _zeige_titel()
	await _taste(KEY_ENTER)
	_lege_an(4, Difficulty.Level.LEICHT, _tag(1985, 2, 15), ANGELEGT)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [true, true, true, false, true])
	assert_eq(_hauptmenue().entries[0].hint, "Weiter mit Spiel 4, Leicht, am 15.02.1985.")
	assert_eq(_hauptmenue().selected_index(), 1, "Die Auswahl bleibt beim Eintrag, der öffnete.")


# --- Spiel beginnen (FR-006, SC-001) --------------------------------------------------------------

func test_leicht_bestaetigen_legt_spiel_1_an_und_zeigt_den_spielbildschirm() -> void:
	# Arrange (US1, Szenario 2)
	await _zeige_titel()
	var szene_vorher := get_tree().current_scene

	# Act: Enter, hoch auf Leicht, Enter
	await _taste(KEY_ENTER)
	await _taste(KEY_UP)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "Einmal zum Spielbildschirm.")
	assert_eq(get_tree().current_scene, szene_vorher, "Gewechselt wird nur über scene_callback.")
	assert_true(_sitzung.is_running())
	assert_eq(_dateien(), ["spiel_1.json"])
	var slot := SaveSlot.read(ORDNER.path_join("spiel_1.json"), 1)
	assert_eq(slot.state, SaveSlot.State.OK, slot.reason)
	assert_eq(slot.game.difficulty, Difficulty.Level.LEICHT)
	assert_eq(slot.game.day_text(), "01.01.1985")


func test_sc_001_mit_drei_tasten_zum_spielbildschirm_mit_mittel() -> void:
	# Arrange: Mit einem Spielstand ist „Weiterspielen“ vorgewählt, der längste Weg.
	_lege_an(1, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT)
	await _zeige_titel()
	var eingaben := 0

	# Act: runter auf „Neues Spiel“, Enter, Enter für Mittel
	for taste: Key in [KEY_DOWN, KEY_ENTER, KEY_ENTER]:
		await _taste(taste)
		eingaben += 1

	# Assert
	assert_eq(eingaben, 3, "SC-001: höchstens 3 Eingaben.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.number, 2, "Ein neues Spiel überschreibt keinen Spielstand.")
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.MITTEL)
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json"])


func test_ohne_spielstaende_reichen_zwei_tasten() -> void:
	# Arrange
	await _zeige_titel()

	# Act
	await _taste(KEY_ENTER)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.MITTEL)


func test_gradwahl_mit_der_maus() -> void:
	# Arrange
	await _zeige_titel()

	# Act: auf „Neues Spiel“ klicken, über „Schwer“ fahren, klicken
	var neues_spiel := _mitte(_hauptmenue(), 1)
	await _maus_nach(neues_spiel)
	await _klick(neues_spiel)
	var gradwahl_offen := _gradwahl().visible
	var schwer := _mitte(_gradwahl(), 2)
	await _maus_nach(schwer)
	var satz := _hinweis_text()
	await _klick(schwer)

	# Assert
	assert_true(gradwahl_offen, "Ein Klick auf „Neues Spiel“ öffnet die Gradwahl.")
	assert_eq(satz, "Das Glück ist eher auf der Seite der anderen.", "Überfahren zeigt den Satz.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.SCHWER)


func test_zurueck_mit_der_maus() -> void:
	# Arrange
	await _zeige_titel()
	await _taste(KEY_ENTER)

	# Act
	var zurueck := _mitte(_gradwahl(), 3)
	await _maus_nach(zurueck)
	await _klick(zurueck)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_dateien(), [])


func test_meldung_wenn_das_anlegen_scheitert() -> void:
	# Arrange (FR-011): Der Ordner liegt unter einer Datei und lässt sich nicht anlegen.
	_schreibe(WURZEL.path_join("datei"), "keine Ordner hier")
	await _zeige_titel(WURZEL.path_join("datei/spielstaende/"))
	await _taste(KEY_ENTER)

	# Act: Mittel bestätigen
	await _taste(KEY_ENTER)

	# Assert: Die Meldung steht an der Stelle des Hinweises, die Gradwahl bleibt.
	assert_eq(_hinweis_text(), NICHT_ANGELEGT)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel", "Kontur kassenrot.")
	_assert_neben_zeile(_gradwahl(), 1)
	_assert_nur_sichtbar(_gradwahl())
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())
	assert_push_warning("Es ist kein Spiel angelegt.")
	assert_engine_error("Method/function failed")


func test_die_meldung_geht_mit_einer_anderen_zeile() -> void:
	# Arrange
	_schreibe(WURZEL.path_join("datei"), "keine Ordner hier")
	await _zeige_titel(WURZEL.path_join("datei/spielstaende/"))
	await _taste(KEY_ENTER)
	await _taste(KEY_ENTER)

	# Act
	await _taste(KEY_DOWN)

	# Assert
	assert_eq(_hinweis_text(), "Das Glück ist eher auf der Seite der anderen.")
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	assert_engine_error("Method/function failed")


func test_die_meldung_geht_mit_esc_auch_wenn_die_zeile_an_derselben_stelle_steht() -> void:
	# Arrange: Mittel und „Neues Spiel“ stehen beide in der zweiten Zeile, also an derselben Stelle.
	_schreibe(WURZEL.path_join("datei"), "keine Ordner hier")
	await _zeige_titel(WURZEL.path_join("datei/spielstaende/"))
	await _taste(KEY_ENTER)
	await _taste(KEY_ENTER)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert: Esc löst etwas aus, die Meldung geht (Style-Guide, Baustein Meldung).
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	assert_engine_error("Method/function failed")


# --- Weiterspielen (FR-016, SC-002) ---------------------------------------------------------------

func test_weiterspielen_mit_einer_eingabe_setzt_den_zuletzt_gespielten_fort() -> void:
	# Arrange
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 120)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 60)

	await _zeige_titel()

	# Act: „Weiterspielen“ ist vorgewählt.
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "SC-002: 1 Eingabe.")
	assert_true(_sitzung.is_running())
	assert_eq(_sitzung.current.number, 1, "Spiel 1 ist zuletzt gespielt.")
	assert_eq(_uhr().date.to_iso(), "1985-01-01")
	assert_eq(_sitzung.last_error, "", "Gespeichert beim Fortsetzen.")


func test_weiterspielen_mit_der_maus() -> void:
	# Arrange
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT)
	await _zeige_titel()

	# Act
	var weiterspielen := _mitte(_hauptmenue(), 0)
	await _maus_nach(weiterspielen)
	await _klick(weiterspielen)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_uhr().date.to_iso(), "1986-03-14")
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.SCHWER)


# --- Liste der Spielstände (T026; FR-015, FR-016, SC-002) -----------------------------------------

func test_spiel_laden_oeffnet_die_liste_mit_der_obersten_zeile() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()

	# Act: „Weiterspielen“ ist gewählt; zweimal runter auf „Spiel laden“, Enter
	await _taste(KEY_DOWN)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_liste())
	assert_eq(_namen(), ["Spiel 2", "Spiel 3", "Spiel 1"],
		"Das zuletzt gespielte oben (US3, Szenario 5).")
	assert_eq(_zellen(0), ["Spiel 2", "Schwer", "14.03.1986", SaveGame.time_text(ANGELEGT + 180)],
		"Name, Grad, Spieldatum, zuletzt gespielt (FR-015).")
	assert_eq(_kopfzeile_der_liste(), "SPIELSTÄNDE")
	assert_false(_liste().is_delete_mode())
	assert_eq(_liste().selected_index(), 0, "Die oberste Zeile ist vorgewählt.")
	assert_true(_hat_fokus(_liste()), "Die Liste hat den Fokus.")
	assert_false(_hat_fokus(_hauptmenue()), "Das unsichtbare Hauptmenü hat keinen.")
	assert_eq(_hinweis_text(), _zeilenhinweis("14.03.1986", ANGELEGT + 180))
	assert_eq(_liste().global_position, Vector2(312, 150), "Oben bei y 150, rechts bis x 616.")
	assert_eq(_liste().size, Vector2(304, 6 * ZEILE),
		"Kopfzeile, drei Spielstände, „Löschen …“ und „Zurück“.")
	_assert_neben_zeile(_liste(), 0)
	assert_eq(_wechsel, [])


func test_die_liste_ist_bei_jedem_oeffnen_neu_gelesen() -> void:
	# Arrange (CHK001; Analyse, E3): Nach dem Erscheinen des Titels kommt ein Spielstand dazu.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	_lege_an(5, Difficulty.Level.SCHWER, _tag(1990, 5, 5), ANGELEGT + 60)

	# Act: öffnen, zurück, Spiel 5 verschwindet von außen, wieder öffnen
	await _oeffne_liste()
	var beim_ersten_mal := _namen()
	await _taste(KEY_ESCAPE)
	assert_eq(DirAccess.remove_absolute(ORDNER.path_join("spiel_5.json")), OK)
	await _oeffne_liste()

	# Assert
	assert_eq(beim_ersten_mal, ["Spiel 5", "Spiel 1"], "Die neue Datei steht in der Liste.")
	assert_eq(_namen(), ["Spiel 1"], "Die verschwundene fehlt beim nächsten Öffnen.")


func test_eine_fortsetzbare_zeile_setzt_fort() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()

	# Act: runter auf Spiel 3, Enter
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert (FR-016)
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_true(_sitzung.is_running())
	assert_eq(_sitzung.current.number, 3)
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.MITTEL)
	assert_eq(_uhr().date.to_iso(), "1991-07-02")


func test_nicht_fortsetzbare_zeilen_loesen_ausserhalb_des_loeschmodus_nichts_aus() -> void:
	# Arrange: Spiel 4 beschädigt, Spiel 3 zu neu; sie stehen unten, nach Nummer absteigend (R12).
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	_kopiere("spiel_kein_json.json", 4)
	_kopiere("spiel_format_2.json", 3)
	await _zeige_titel()
	await _oeffne_liste()
	var hinweise := []

	# Act
	for zeile in [1, 2]:
		_liste().select(zeile)
		hinweise.append(_hinweis_text())
		await _taste(KEY_ENTER)

	# Assert
	assert_eq(_namen(), ["Spiel 1", "Spiel 4", "Spiel 3"])
	assert_eq(hinweise, ["Lässt sich nicht lesen: Die Datei ist beschädigt.",
		"Mit einer neueren Version gespeichert."], "Der Hinweis nennt den Grund.")
	_assert_nur_sichtbar(_liste())
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())


func test_zurueck_fuehrt_ins_hauptmenue_auf_spiel_laden_und_liest_neu() -> void:
	# Arrange: Während die Liste offen ist, kommt ein Spielstand dazu (Analyse, F2).
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	await _oeffne_liste()
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 60)

	# Act: Pfeil hoch läuft von der obersten Zeile um auf „Zurück“.
	await _taste(KEY_UP)
	var hinweis := _hinweis_text()
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(hinweis, "Zurück zum Hauptmenü. Esc geht auch.")
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 2, "Auf „Spiel laden“, das die Liste öffnete.")
	assert_true(_hat_fokus(_hauptmenue()))
	assert_eq(_hinweis_text(), HINWEIS_LADEN)
	assert_eq(_hauptmenue().entries[0].hint, "Weiter mit Spiel 2, Schwer, am 14.03.1986.",
		"Das Hauptmenü ist neu gelesen.")
	assert_eq(_wechsel, [])


func test_esc_in_der_liste_fuehrt_ins_hauptmenue_auf_spiel_laden() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	await _taste(KEY_DOWN)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 2)
	assert_eq(_hinweis_text(), HINWEIS_LADEN)
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())


func test_ein_aelterer_spielstand_rueckt_nach_dem_fortsetzen_nach_oben() -> void:
	# Arrange (US3, Szenario 3)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()

	# Act: das älteste, Spiel 1, fortsetzen und verlassen; danach erscheint der Titel neu.
	_liste().select(2)
	await _taste(KEY_ENTER)
	var fortgesetzt := _sitzung.current.number
	assert_eq(_sitzung.leave(), OK)
	await _baue_titel()
	var weiterspielen := _hauptmenue().entries[0].hint
	await _oeffne_liste()

	# Assert
	assert_eq(fortgesetzt, 1)
	assert_eq(weiterspielen, "Weiter mit Spiel 1, Leicht, am 01.01.1985.",
		"„Weiterspielen“ setzt es fort.")
	assert_eq(_namen(), ["Spiel 1", "Spiel 2", "Spiel 3"], "In der Liste steht es oben.")


func test_sc_002_ueber_die_liste_mit_vier_tasten() -> void:
	# Arrange: „Weiterspielen“ ist vorgewählt.
	_drei_spiele()
	await _zeige_titel()
	var eingaben := 0

	# Act: zweimal runter auf „Spiel laden“, Enter, Enter auf der obersten Zeile
	for taste: Key in [KEY_DOWN, KEY_DOWN, KEY_ENTER, KEY_ENTER]:
		await _taste(taste)
		eingaben += 1

	# Assert
	assert_eq(eingaben, 4, "SC-002: höchstens 4 Eingaben über die Liste.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.number, 2, "Der oberste Spielstand der Liste.")


func test_sc_002_ueber_die_liste_mit_zwei_klicks() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	var klicks := 0

	# Act: auf „Spiel laden“ klicken, dann auf Spiel 3 in der zweiten Zeile
	var spiel_laden := _mitte(_hauptmenue(), 2)
	await _maus_nach(spiel_laden)
	await _klick(spiel_laden)
	klicks += 1
	var liste_offen := _liste().visible
	var spiel_3 := _mitte_in_der_liste("Slot1")
	await _maus_nach(spiel_3)
	await _klick(spiel_3)
	klicks += 1

	# Assert
	assert_true(liste_offen, "Ein Klick auf „Spiel laden“ öffnet die Liste.")
	assert_eq(klicks, 2, "SC-002: 2 Klicks.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.number, 3)


func test_sc_002_liste_mit_zwanzig_spielstaenden_in_hoechstens_einer_sekunde() -> void:
	# Arrange (R16): 20 Spielstände, je mit einer Kopie von catalog_500.json
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(KATALOGE + "catalog_500.json", meldungen)
	assert_eq(katalog.events.size(), 500)
	for nummer in range(1, SPIELSTAENDE + 1):
		_lege_an(nummer, Difficulty.Level.MITTEL, _tag(1990, 1, 1), ANGELEGT + nummer, katalog)
	await _zeige_titel()
	var zeiten: Array[float] = []

	# Act: je Lauf „Spiel laden“ von Enter bis nach dem nächsten Bild, dann mit Esc zurück
	for lauf in LAEUFE:
		_hauptmenue().select(2)
		var beginn := Time.get_ticks_usec()
		await _taste(KEY_ENTER)
		zeiten.append((Time.get_ticks_usec() - beginn) / 1000.0)
		assert_true(_liste().visible, "Lauf %d: Die Liste ist zu sehen." % lauf)
		assert_eq(_namen().size(), SaveList.VISIBLE_ROWS)
		await _taste(KEY_ESCAPE)

	# Assert
	var sortiert := zeiten.duplicate()
	sortiert.sort()
	var median: float = sortiert[floori(sortiert.size() / 2.0)]
	gut.p("SC-002, Anzeige der Liste mit %d Spielständen zu je 500 Ereignissen: Median %.1f ms aus %s"
		% [SPIELSTAENDE, median, zeiten])
	assert_lt(median, LISTE_MSEC, "SC-002: Die Liste erscheint in höchstens einer Sekunde.")


func test_spiel_laden_bei_inzwischen_leerem_ordner_bleibt_im_hauptmenue() -> void:
	# Arrange: Nach dem Erscheinen des Titels verschwindet der einzige Spielstand, etwa durch ein
	# zweites Fenster.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	assert_eq(DirAccess.remove_absolute(ORDNER.path_join("spiel_1.json")), OK)

	# Act
	await _oeffne_liste()

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, false, false, true], "Neu gelesen.")
	assert_eq(_hauptmenue().selected_index(), 2, "Auf „Spiel laden“; sein Hinweis sagt, warum.")
	assert_eq(_hinweis_text(), "Noch keine Spielstände.")
	assert_eq(_wechsel, [])


# --- Löschen (T027; FR-017, FR-017a, FR-018, US4) -------------------------------------------------

func test_loeschen_und_eine_zeile_zeigen_die_rueckfrage_mit_abbrechen_vorgewaehlt() -> void:
	# Arrange (US4, Szenario 1)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	var vorher := _inhalte()

	# Act: „Löschen …“, dann Spiel 1 in der untersten Zeile; danach runter auf „Spiel 1 löschen“
	_liste().select(3)
	await _taste(KEY_ENTER)
	var kopfzeile := _kopfzeile_der_liste()
	var hinweis_im_modus := _hinweis_text()
	await _taste(KEY_UP)
	await _taste(KEY_ENTER)
	var hinweis_abbrechen := _hinweis_text()
	var vorwahl := _rueckfrage().selected_index()
	var fokus := _hat_fokus(_rueckfrage())
	await _taste(KEY_DOWN)

	# Assert
	assert_eq(kopfzeile, "WELCHES LÖSCHEN?")
	assert_eq(hinweis_im_modus, "Wähl oben den Spielstand, der weg soll. Esc bricht ab.")
	_assert_nur_sichtbar(_rueckfrage())
	assert_eq(_rueckfrage().header_text, "LÖSCHEN?")
	assert_eq(_texte(_rueckfrage()), ["Abbrechen", "Spiel 1 löschen"])
	assert_eq(_verfuegbar(_rueckfrage()), [true, true])
	assert_eq(vorwahl, 0, "„Abbrechen“ ist vorgewählt.")
	assert_true(fokus, "Die Rückfrage hat den Fokus.")
	assert_eq(hinweis_abbrechen, "Spiel 1 bleibt: Leicht, 01.01.1985. Esc geht auch.")
	assert_eq(_hinweis_text(), "Spiel 1 ist danach weg: Leicht, 01.01.1985. Für immer.")
	_assert_neben_zeile(_rueckfrage(), 1)
	assert_eq(_rueckfrage().global_position, Vector2(472, 150), "An der Stelle des Hauptmenüs.")
	assert_eq(_rueckfrage().size, Vector2(144, 3 * ZEILE), "144 breit wie das Hauptmenü.")
	assert_eq(_inhalte(), vorher, "Noch ist nichts gelöscht.")


func test_rueckfrage_zu_nicht_fortsetzbaren_nennt_den_zustand() -> void:
	# Arrange: Spiel 4 zu neu, Spiel 3 beschädigt
	_kopiere("spiel_kein_json.json", 3)
	_kopiere("spiel_format_2.json", 4)
	await _zeige_titel()
	await _oeffne_liste()
	var gesehen := []

	# Act: zu jeder Zeile die Rückfrage, dann mit Esc zurück
	for zeile in 2:
		await _frage_nach(zeile)
		gesehen.append([_texte(_rueckfrage())[1]] + _hinweise(_rueckfrage()))
		await _taste(KEY_ESCAPE)

	# Assert (FR-017; R14)
	assert_eq(gesehen, [
		["Spiel 4 löschen", "Spiel 4 bleibt: neuere Version. Esc geht auch.",
			"Spiel 4 ist danach weg: neuere Version. Für immer."],
		["Spiel 3 löschen", "Spiel 3 bleibt: beschädigt. Esc geht auch.",
			"Spiel 3 ist danach weg: beschädigt. Für immer."],
	])


func test_esc_in_der_rueckfrage_fuehrt_in_die_liste_und_der_spielstand_bleibt() -> void:
	# Arrange (US4, Szenario 4)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	var vorher := _inhalte()
	await _frage_nach(1)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_abgebrochen(vorher)


func test_abbrechen_in_der_rueckfrage_wirkt_wie_esc() -> void:
	# Arrange (US4, Szenario 4)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	var vorher := _inhalte()
	await _frage_nach(1)

	# Act: „Abbrechen“ ist vorgewählt.
	await _taste(KEY_ENTER)

	# Assert
	_assert_abgebrochen(vorher)


func test_bestaetigen_loescht_nur_diesen_spielstand() -> void:
	# Arrange (US4, Szenario 3; FR-018): Zu Spiel 3 gehört noch eine übrig gebliebene .alt; daneben
	# liegen fremde Dateien.
	_drei_spiele()
	assert_eq(DirAccess.copy_absolute(ORDNER.path_join("spiel_3.json"),
		ORDNER.path_join("spiel_3.json.alt")), OK)
	_schreibe(ORDNER.path_join("notizen.txt"), "Mein Laden")
	_schreibe(ORDNER.path_join("spiel_02.json"), "{}")
	await _zeige_titel()
	await _oeffne_liste()
	var andere := _inhalte()
	andere.erase("spiel_3.json")
	andere.erase("spiel_3.json.alt")

	# Act: Spiel 3 in der zweiten Zeile löschen
	await _frage_nach(1)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_dateien(), ["notizen.txt", "spiel_02.json", "spiel_1.json", "spiel_2.json"],
		"Weg sind spiel_3.json und spiel_3.json.alt, sonst nichts.")
	assert_eq(_inhalte(), andere, "Die anderen Dateien sind unverändert.")
	_assert_nur_sichtbar(_liste())
	assert_eq(_namen(), ["Spiel 2", "Spiel 1"], "Er verschwindet aus der Liste.")
	assert_false(_liste().is_delete_mode(), "Der Löschmodus ist aus.")
	assert_eq(_kopfzeile_der_liste(), "SPIELSTÄNDE")
	assert_eq(_liste().selected_index(), 1, "Auf der Zeile, die an seine Stelle rückt.")
	assert_true(_hat_fokus(_liste()))
	assert_eq(_hinweis_text(), _zeilenhinweis("01.01.1985", ANGELEGT + 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung.")
	assert_eq(_wechsel, [])


func test_nach_dem_loeschen_der_untersten_zeile_steht_die_auswahl_auf_der_letzten() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()

	# Act: Spiel 1 in der untersten Zeile löschen
	await _frage_nach(2)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_namen(), ["Spiel 2", "Spiel 3"])
	assert_eq(_liste().selected_index(), 1, "Auf dem letzten Spielstand.")
	assert_eq(_hinweis_text(), _zeilenhinweis("02.07.1991", ANGELEGT + 120))


func test_einen_beschaedigten_spielstand_loeschen() -> void:
	# Arrange (Edge Cases): Auch was sich nicht lesen lässt, lässt sich löschen.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	_kopiere("spiel_kein_json.json", 8)
	await _zeige_titel()
	await _oeffne_liste()

	# Act
	await _frage_nach(1)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_dateien(), ["spiel_1.json"])
	assert_eq(_namen(), ["Spiel 1"])
	assert_eq(_liste().selected_index(), 0)


func test_den_letzten_spielstand_loeschen_fuehrt_ins_hauptmenue_mit_neues_spiel() -> void:
	# Arrange (US4, Szenario 5)
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	await _oeffne_liste()

	# Act
	await _frage_nach(0)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, false, false, true])
	assert_eq(_hauptmenue().selected_index(), 1, "„Neues Spiel“ ist gewählt.")
	assert_true(_hat_fokus(_hauptmenue()))
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	assert_eq(_dateien(), [])
	assert_eq(_wechsel, [])


func test_den_zuletzt_gespielten_loeschen_dann_nennt_weiterspielen_den_naechsten() -> void:
	# Arrange (Analyse, F2)
	_drei_spiele()
	await _zeige_titel()
	var vorher := _hauptmenue().entries[0].hint
	await _oeffne_liste()

	# Act: Spiel 2 oben löschen, mit Esc ins Hauptmenü, „Weiterspielen“
	await _frage_nach(0)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)
	await _taste(KEY_ESCAPE)
	var nachher := _hauptmenue().entries[0].hint
	var auswahl := _hauptmenue().selected_index()
	_hauptmenue().select(0)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(vorher, "Weiter mit Spiel 2, Schwer, am 14.03.1986.")
	assert_eq(nachher, "Weiter mit Spiel 3, Mittel, am 02.07.1991.")
	assert_eq(auswahl, 2, "Zurück auf „Spiel laden“.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.number, 3)


func test_esc_im_loeschmodus_beendet_nur_den_modus() -> void:
	# Arrange (US4, Szenario 2; Analyse, F3)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	_liste().select(3)
	await _taste(KEY_ENTER)
	_liste().select(1)

	# Act: Esc, dann Enter auf derselben Zeile
	await _taste(KEY_ESCAPE)
	var sichtbar := _liste().visible
	var modus := _liste().is_delete_mode()
	var kopfzeile := _kopfzeile_der_liste()
	var auswahl := _liste().selected_index()
	var hinweis := _hinweis_text()
	await _taste(KEY_ENTER)

	# Assert
	assert_true(sichtbar, "Die Liste bleibt.")
	assert_false(modus, "Der Löschmodus ist aus.")
	assert_eq(kopfzeile, "SPIELSTÄNDE")
	assert_eq(auswahl, 1, "Die Auswahl bleibt, wo sie war.")
	assert_eq(hinweis, _zeilenhinweis("02.07.1991", ANGELEGT + 120))
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "Enter auf einer Zeile setzt wieder fort.")
	assert_eq(_sitzung.current.number, 3)
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json", "spiel_3.json"])


func test_zurueck_im_loeschmodus_beendet_nur_den_modus() -> void:
	# Arrange (Analyse, F3)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	_liste().select(3)
	await _taste(KEY_ENTER)
	_liste().select(4)
	var hinweis_im_modus := _hinweis_text()

	# Act
	await _taste(KEY_ENTER)
	var sichtbar := _liste().visible
	var modus := _liste().is_delete_mode()
	var hinweis := _hinweis_text()
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(hinweis_im_modus, HINWEIS_ZURUECK_IM_MODUS)
	assert_true(sichtbar, "Die Liste bleibt.")
	assert_false(modus, "Der Löschmodus ist aus.")
	assert_eq(hinweis, "Zurück zum Hauptmenü. Esc geht auch.", "Die Auswahl bleibt auf „Zurück“.")
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 2, "Ein zweites „Zurück“ führt ins Hauptmenü.")


func test_der_loeschmodus_endet_auf_allen_vier_wegen() -> void:
	# Arrange (FR-017a): nach dem Löschen, mit „Abbrechen“ in der Rückfrage, mit „Zurück“, mit Esc
	for nummer in range(1, 6):
		_lege_an(nummer, Difficulty.Level.MITTEL, _tag(1985, 1, 1), ANGELEGT + nummer)
	await _zeige_titel()
	await _oeffne_liste()
	var wege := {}

	# Act
	await _frage_nach(0)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)
	wege["nach dem Löschen"] = _zustand_der_liste()
	await _frage_nach(0)
	await _taste(KEY_ENTER)
	wege["Abbrechen"] = _zustand_der_liste()
	_liste().select(-2)
	await _taste(KEY_ENTER)
	_liste().select(-1)
	await _taste(KEY_ENTER)
	wege["Zurück"] = _zustand_der_liste()
	_liste().select(-2)
	await _taste(KEY_ENTER)
	await _taste(KEY_ESCAPE)
	wege["Esc"] = _zustand_der_liste()

	# Assert
	var erwartet := [true, false, "SPIELSTÄNDE"]
	assert_eq(wege, {"nach dem Löschen": erwartet, "Abbrechen": erwartet, "Zurück": erwartet,
		"Esc": erwartet}, "Liste sichtbar, Löschmodus aus, Kopfzeile SPIELSTÄNDE.")
	assert_eq(_namen().size(), 4, "Gelöscht wurde nur einmal.")


func test_loeschen_mit_der_maus() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()

	# Act: „Löschen …“, Spiel 3, „Spiel 3 löschen“
	for ziel: Vector2 in [_mitte_in_der_liste("DeleteMode"), _mitte_in_der_liste("Slot1")]:
		await _maus_nach(ziel)
		await _klick(ziel)
	var loeschen := _mitte(_rueckfrage(), 1)
	await _maus_nach(loeschen)
	await _klick(loeschen)

	# Assert
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json"])
	assert_eq(_namen(), ["Spiel 2", "Spiel 1"])
	assert_false(_liste().is_delete_mode())


func test_loeschen_scheitert_meldung_und_der_spielstand_bleibt_in_der_liste() -> void:
	# Arrange (CHK003; Analyse, E2): An der Stelle von spiel_2.json liegt ein Ordner mit Inhalt,
	# daneben eine fortsetzbare spiel_2.json.alt.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 120)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 60)
	assert_eq(DirAccess.rename_absolute(ORDNER.path_join("spiel_2.json"),
		ORDNER.path_join("spiel_2.json.alt")), OK)
	assert_eq(DirAccess.make_dir_recursive_absolute(ORDNER.path_join("spiel_2.json/inhalt")), OK)
	await _zeige_titel()
	await _oeffne_liste()

	# Act: Spiel 2 in der zweiten Zeile löschen
	await _frage_nach(1)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_liste())
	assert_eq(_namen(), ["Spiel 1", "Spiel 2"], "Der Spielstand steht noch in der Liste.")
	assert_false(_liste().is_delete_mode(), "Der Löschmodus ist aus.")
	assert_eq(_kopfzeile_der_liste(), "SPIELSTÄNDE")
	assert_eq(_liste().selected_index(), 1, "Auf seiner Zeile.")
	assert_eq(_hinweis_text(), LOESCHEN_GING_NICHT)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel", "Kontur kassenrot.")
	_assert_neben_zeile(_liste(), 1)
	assert_true(FileAccess.file_exists(ORDNER.path_join("spiel_2.json.alt")), "Die .alt bleibt.")
	assert_push_warning("ließ sich nicht löschen", "Das Protokoll nennt den Fehler.")


func test_die_meldung_zum_loeschen_geht_mit_einer_anderen_zeile() -> void:
	# Arrange
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 120)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 60)
	assert_eq(DirAccess.rename_absolute(ORDNER.path_join("spiel_2.json"),
		ORDNER.path_join("spiel_2.json.alt")), OK)
	assert_eq(DirAccess.make_dir_recursive_absolute(ORDNER.path_join("spiel_2.json/inhalt")), OK)
	await _zeige_titel()
	await _oeffne_liste()
	await _frage_nach(1)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Act
	await _taste(KEY_UP)

	# Assert
	assert_eq(_hinweis_text(), _zeilenhinweis("01.01.1985", ANGELEGT + 120))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	assert_push_warning("ließ sich nicht löschen")


# Die Meldung gehört zum Spielstand, nicht zur Stelle (Klaus, 2026-10-26, Phasenprüfung Phase 5):
# Beim Rollen zeigt dieselbe Zeile einen anderen Spielstand, und dann gilt dessen Hinweis.

func test_meldung_dann_pfeil_hoch_am_oberen_rand_zeigt_den_neuen_hinweis() -> void:
	# Arrange: acht Spielstände, das Fenster zwei Zeilen gerollt; Spiel 6 steht in der obersten
	# Zeile, darüber stehen noch zwei. Sein Löschen scheitert.
	_acht_spiele_eins_gesperrt(6)
	await _zeige_titel()
	await _oeffne_liste()
	_liste().select(7)
	await _scheitere_beim_loeschen(2)
	var vorher := [_hinweis_text(), _liste()._more_above()]
	_assert_neben_zeile(_liste(), 0)

	# Act: Das Fenster rollt eine Zeile; dieselbe Zeile zeigt jetzt Spiel 7.
	await _taste(KEY_UP)

	# Assert
	assert_eq(vorher, [LOESCHEN_GING_NICHT, true], "Voraussetzung: Meldung, oben steht mehr.")
	assert_eq(_liste().selected_slot().display_name(), "Spiel 7")
	assert_eq(_hinweis_text(), _zeilenhinweis("07.01.1985", ANGELEGT + 7 * 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung mehr.")
	_assert_neben_zeile(_liste(), 0)
	assert_push_warning("ließ sich nicht löschen")


func test_meldung_dann_pfeil_runter_am_unteren_rand_zeigt_den_neuen_hinweis() -> void:
	# Arrange: Spiel 3 steht in der untersten Zeile des Fensters, darunter noch zwei.
	_acht_spiele_eins_gesperrt(3)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(5)
	var vorher := [_hinweis_text(), _liste()._more_below()]
	_assert_neben_zeile(_liste(), 5)

	# Act
	await _taste(KEY_DOWN)

	# Assert
	assert_eq(vorher, [LOESCHEN_GING_NICHT, true], "Voraussetzung: Meldung, unten steht mehr.")
	assert_eq(_liste().selected_slot().display_name(), "Spiel 2")
	assert_eq(_hinweis_text(), _zeilenhinweis("02.01.1985", ANGELEGT + 2 * 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung mehr.")
	_assert_neben_zeile(_liste(), 5)
	assert_push_warning("ließ sich nicht löschen")


func test_mausrad_das_nur_rollt_laesst_die_meldung_beim_spielstand() -> void:
	# Arrange: Spiel 5 in der vierten Zeile mit Meldung.
	_acht_spiele_eins_gesperrt(5)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(3)
	_assert_neben_zeile(_liste(), 3)

	# Act: ein Dreh über der Kopfzeile; Spiel 5 bleibt zu sehen und gewählt, eine Zeile höher.
	await _rad(_liste().global_position + Vector2(150, 10), MOUSE_BUTTON_WHEEL_DOWN)

	# Assert
	assert_eq(_liste().selected_slot().display_name(), "Spiel 5")
	assert_eq(_hinweis_text(), LOESCHEN_GING_NICHT, "Die Meldung bleibt beim Spielstand.")
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel")
	_assert_neben_zeile(_liste(), 2)
	assert_push_warning("ließ sich nicht löschen")


func test_mausrad_das_die_auswahl_rueckt_zeigt_den_neuen_hinweis() -> void:
	# Arrange: Spiel 8 in der obersten Zeile mit Meldung.
	_acht_spiele_eins_gesperrt(8)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(0)
	assert_eq(_hinweis_text(), LOESCHEN_GING_NICHT, "Voraussetzung: Meldung.")

	# Act: Spiel 8 rollt oben hinaus; die Auswahl rückt auf Spiel 7 in derselben Zeile.
	await _rad(_liste().global_position + Vector2(150, 10), MOUSE_BUTTON_WHEEL_DOWN)

	# Assert
	assert_eq(_liste().selected_slot().display_name(), "Spiel 7")
	assert_eq(_hinweis_text(), _zeilenhinweis("07.01.1985", ANGELEGT + 7 * 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	_assert_neben_zeile(_liste(), 0)
	assert_push_warning("ließ sich nicht löschen")


func test_nach_esc_kommt_die_meldung_beim_naechsten_oeffnen_nicht_wieder() -> void:
	# Arrange
	_acht_spiele_eins_gesperrt(8)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(0)

	# Act: ins Hauptmenü und wieder in die Liste; Spiel 8 ist wieder oben gewählt.
	await _taste(KEY_ESCAPE)
	await _oeffne_liste()

	# Assert
	assert_eq(_liste().selected_slot().display_name(), "Spiel 8")
	assert_eq(_hinweis_text(), _zeilenhinweis("08.01.1985", ANGELEGT + 8 * 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Esc hat die Meldung beendet.")
	assert_push_warning("ließ sich nicht löschen")


func test_ist_die_datei_schon_weg_gibt_es_keine_meldung() -> void:
	# Arrange: Während die Rückfrage offen ist, löscht ein zweites Fenster Spiel 2.
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	await _frage_nach(0)
	assert_eq(DirAccess.remove_absolute(ORDNER.path_join("spiel_2.json")), OK)

	# Act
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_liste())
	assert_eq(_namen(), ["Spiel 3", "Spiel 1"], "Neu gelesen.")
	assert_false(_liste().is_delete_mode())
	assert_eq(_liste().selected_index(), 0)
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung.")
	assert_eq(_hinweis_text(), _zeilenhinweis("02.07.1991", ANGELEGT + 120))
	assert_eq(_dateien(), ["spiel_1.json", "spiel_3.json"])


func test_ist_die_datei_schon_weg_und_keiner_mehr_da_geht_es_ins_hauptmenue() -> void:
	# Arrange
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	await _oeffne_liste()
	await _frage_nach(0)
	assert_eq(DirAccess.remove_absolute(ORDNER.path_join("spiel_1.json")), OK)

	# Act
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1, "„Neues Spiel“ ist gewählt.")
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung.")


# --- Helfer ---------------------------------------------------------------------------------------

## Baut eine Session mit eigener Uhr, eigener Zeitleiste und dem Ordner [param ordner], dann den
## Titel in einem eigenen Viewport, und wartet, bis er seine Blätter gebaut hat.
func _zeige_titel(ordner: String = ORDNER) -> void:
	_sitzung = await _neue_sitzung(ordner)
	await _baue_titel()


## Baut den Titel mit der Session _sitzung in einem eigenen Viewport, wie beim Erscheinen nach dem
## Verlassen eines Spiels, und wartet, bis er seine Blätter gebaut hat.
func _baue_titel() -> void:
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	_titel = TITEL.instantiate() as TitleScreen
	_titel.session = _sitzung
	_titel.scene_callback = _merke_wechsel
	eigener_viewport.add_child(_titel)
	# Die Maus steht im Viewport. Im Fenster meldet das das Betriebssystem; ohne diese Meldung gibt
	# ein Viewport Mausbewegungen nicht an gui_input weiter, und die Liste wählt ihre Zeilen über
	# gui_input (wie in test_save_list.gd).
	eigener_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	# Die Blätter entstehen zeitversetzt, die Zeilen ordnet der VBoxContainer im nächsten Bild.
	await wait_process_frames(2)


func _neue_sitzung(ordner: String = ORDNER) -> SITZUNG:
	var uhr := UHR.new()
	add_child_autofree(uhr)
	var zeitleiste := ZEITLEISTE.new()
	zeitleiste.catalog_path = KATALOGE + "catalog_us1_grade.json"
	zeitleiste.clock = uhr
	add_child_autofree(zeitleiste)
	var sitzung := SITZUNG.new()
	sitzung.folder = ordner
	sitzung.clock = uhr
	sitzung.timeline = zeitleiste
	sitzung.now = func() -> int: return ANGELEGT + 3600
	sitzung.rng = RandomNumberGenerator.new()
	sitzung.rng.seed = WUERFEL_SEED
	sitzung.quit_callback = func() -> void: pass
	add_child_autofree(sitzung)
	await wait_process_frames(2)
	return sitzung


func _merke_wechsel(pfad: String) -> void:
	_wechsel.append(pfad)


func _uhr() -> UHR:
	return _sitzung.clock as UHR


func _zeitleiste() -> ZEITLEISTE:
	return _sitzung.timeline as ZEITLEISTE


func _hauptmenue() -> MainMenu:
	return _titel.get_node(^"MainMenu") as MainMenu


func _gradwahl() -> MainMenu:
	return _titel.get_node(^"DifficultySheet") as MainMenu


func _liste() -> SaveList:
	return _titel.get_node(^"SaveList") as SaveList


func _rueckfrage() -> MainMenu:
	return _titel.get_node(^"ConfirmSheet") as MainMenu


func _hinweis() -> MenuHint:
	return _titel.get_node(^"MenuHint") as MenuHint


func _hinweis_text() -> String:
	assert_true(_hinweis().visible, "Der Hinweis ist zu sehen.")
	return (_hinweis().get_node(^"Text") as Label).text


func _texte(blatt: MainMenu) -> Array:
	return blatt.entries.map(func(eintrag: MenuEntry) -> String: return eintrag.label)


func _verfuegbar(blatt: MainMenu) -> Array:
	return blatt.entries.map(func(eintrag: MenuEntry) -> bool: return eintrag.available)


func _hinweise(blatt: MainMenu) -> Array:
	return blatt.entries.map(func(eintrag: MenuEntry) -> String: return eintrag.hint)


## Ob der Fokus im Viewport des Titels auf einer Zeile von [param blatt] liegt.
func _hat_fokus(blatt: Control) -> bool:
	var besitzer := _titel.get_viewport().gui_get_focus_owner()
	return besitzer != null and blatt.is_ancestor_of(besitzer)


## Genau [param blatt] ist zu sehen, kein anderes Blatt.
func _assert_nur_sichtbar(blatt: Control) -> void:
	for anderes: Control in [_hauptmenue(), _gradwahl(), _liste(), _rueckfrage()]:
		assert_eq(anderes.visible, anderes == blatt,
			"%s sichtbar: %s" % [anderes.name, anderes == blatt])


## Der Hinweis steht 4 Pixel links neben Zeile [param index] von [param blatt], oben bündig. Bei der
## Liste ist [param index] die Zeile auf dem Papier unter der Kopfzeile.
func _assert_neben_zeile(blatt: Control, index: int) -> void:
	var oben := blatt.global_position.y + ZEILE * (index + 1)
	assert_eq(_hinweis().global_position.y, oben, "Oben bündig mit Zeile %d." % index)
	assert_eq(_hinweis().global_position.x + _hinweis().size.x,
		blatt.global_position.x - MenuHint.GAP, "4 Pixel links neben der Zeile.")


## Öffnet die Liste über „Spiel laden“ mit Enter.
func _oeffne_liste() -> void:
	_hauptmenue().select(2)
	await _taste(KEY_ENTER)


## Schaltet in der offenen Liste den Löschmodus ein und löst Zeile [param zeile] aus: Die Rückfrage
## erscheint. -2 ist „Löschen …“, denn select() läuft an den Enden um.
func _frage_nach(zeile: int) -> void:
	_liste().select(-2)
	await _taste(KEY_ENTER)
	_liste().select(zeile)
	await _taste(KEY_ENTER)


## Löscht in der offenen Liste Zeile [param zeile] über Löschmodus, Rückfrage und „löschen“; ist
## der Spielstand gesperrt, scheitert es, und die Meldung steht an seiner Zeile.
func _scheitere_beim_loeschen(zeile: int) -> void:
	await _frage_nach(zeile)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)


## Die Namen in den sichtbaren Zeilen der Liste, von oben nach unten.
func _namen() -> Array:
	var namen := []
	for zeile in SaveList.VISIBLE_ROWS:
		var knopf := _liste().get_node("Rows/Slot%d" % zeile) as Button
		if knopf.visible:
			namen.append((knopf.get_node(^"Name") as Label).text)
	return namen


## Die Texte der sichtbaren Spalten von Zeile [param zeile] der Liste, von links nach rechts.
func _zellen(zeile: int) -> Array:
	var texte := []
	var knopf := _liste().get_node("Rows/Slot%d" % zeile) as Button
	for zelle: StringName in [&"Name", &"Difficulty", &"State", &"Day", &"Played"]:
		var label := knopf.get_node(String(zelle)) as Label
		if label.visible:
			texte.append(label.text)
	return texte


func _kopfzeile_der_liste() -> String:
	return (_liste().get_node(^"Rows/Header") as Label).text


## Ist die Liste zu sehen, ist der Löschmodus an, und was steht in der Kopfzeile.
func _zustand_der_liste() -> Array:
	return [_liste().visible, _liste().is_delete_mode(), _kopfzeile_der_liste()]


## Nach Abbrechen in der Rückfrage: die Liste ohne Löschmodus, die Auswahl auf Spiel 3 in Zeile 1,
## nach dem gefragt wurde, und alle Dateien wie [param vorher].
func _assert_abgebrochen(vorher: Dictionary) -> void:
	_assert_nur_sichtbar(_liste())
	assert_false(_liste().is_delete_mode(), "Der Löschmodus ist aus.")
	assert_eq(_kopfzeile_der_liste(), "SPIELSTÄNDE")
	assert_eq(_liste().selected_index(), 1, "Auf dem Spielstand, nach dem gefragt wurde.")
	assert_true(_hat_fokus(_liste()))
	assert_eq(_hinweis_text(), _zeilenhinweis("02.07.1991", ANGELEGT + 120))
	assert_eq(_inhalte(), vorher, "Der Spielstand ist unverändert.")
	assert_eq(_wechsel, [])


## Die Mitte der Zeile [param knopf] der Liste, etwa „Slot1“ oder „DeleteMode“, in Koordinaten des
## Viewports.
func _mitte_in_der_liste(knopf: String) -> Vector2:
	return (_liste().get_node("Rows/" + knopf) as Button).get_global_rect().get_center()


## Die Mitte von Zeile [param index] in [param blatt], in Koordinaten des Viewports.
func _mitte(blatt: MainMenu, index: int) -> Vector2:
	var zeilen := blatt.find_children("*", "Button", true, false)
	return (zeilen[index] as Button).get_global_rect().get_center()


## Drückt [param taste] und lässt sie los, über push_input wie ein echter Tastendruck, und wartet
## ein Bild wie zwischen zwei Tasten eines Menschen. Erst dann hat der VBoxContainer eines eben
## gezeigten oder neu gebauten Blatts seine Zeilen angeordnet, und Pfeiltasten finden die
## Nachbarzeile.
func _taste(taste: Key) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = taste
		ereignis.physical_keycode = taste
		ereignis.pressed = gedrueckt
		_titel.get_viewport().push_input(ereignis)
	await wait_process_frames(1)


## Fährt mit der Maus nach [param ziel] und wartet ein Bild; true heißt: Koordinaten des Viewports.
func _maus_nach(ziel: Vector2) -> void:
	var ereignis := InputEventMouseMotion.new()
	ereignis.position = ziel
	ereignis.global_position = ziel
	_titel.get_viewport().push_input(ereignis, true)
	await wait_process_frames(1)


## Ein Dreh am Mausrad bei [param ziel], als Drücken und Loslassen wie in test_save_list.gd, ohne
## Mausbewegung; dann ein Bild.
func _rad(ziel: Vector2, richtung: MouseButton) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = richtung
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_titel.get_viewport().push_input(ereignis, true)
	await wait_process_frames(1)


## Klickt mit der linken Taste bei [param ziel] und wartet ein Bild.
func _klick(ziel: Vector2) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = MOUSE_BUTTON_LEFT
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_titel.get_viewport().push_input(ereignis, true)
	await wait_process_frames(1)


## Legt im Testordner Spiel [param nummer] an: Grad, Spieltag und „zuletzt gespielt“ wie angegeben,
## Katalog [param katalog], ohne ihn catalog_us1_grade.json.
func _lege_an(nummer: int, grad: Difficulty.Level, tag: int, zuletzt: int,
		katalog: EventCatalog = null) -> void:
	var meldungen: Array[CatalogIssue] = []
	var game := SaveGame.new()
	game.number = nummer
	game.name = SaveGame.default_name(nummer)
	game.difficulty = grad
	game.seed = 4711
	game.day = tag
	game.created_at = ANGELEGT
	game.last_played_at = zuletzt
	game.game_version = "0.1"
	game.catalog = katalog if katalog != null \
		else EventCatalog.read_file(KATALOGE + "catalog_us1_grade.json", meldungen)
	assert_eq(SaveStore.new(ORDNER).write(game, true), OK, "Spiel %d angelegt." % nummer)


## Kopiert eine Fixture als spiel_<nummer>.json in den Testordner.
func _kopiere(fixture: String, nummer: int) -> void:
	assert_eq(DirAccess.copy_absolute(FIXTURES.path_join(fixture),
		ORDNER.path_join("spiel_%d.json" % nummer)), OK, "Kopiert: %s" % fixture)


## Spiel 1 Leicht am 01.01.1985, Spiel 2 Schwer am 14.03.1986, Spiel 3 Mittel am 02.07.1991; zuletzt
## gespielt ist Spiel 2, dann 3, dann 1. Die Liste zeigt also Spiel 2, Spiel 3, Spiel 1.
func _drei_spiele() -> void:
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 60)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 180)
	_lege_an(3, Difficulty.Level.MITTEL, _tag(1991, 7, 2), ANGELEGT + 120)


## Der Hinweis einer fortsetzbaren Zeile der Liste: „Steht am 14.03.1986. Gespielt am 26.10.2026,
## 21:40 Uhr.“ Nur „zuletzt gespielt“ kommt aus der Ortszeit des Rechners.
func _zeilenhinweis(spieldatum: String, zuletzt: int) -> String:
	return "Steht am %s. Gespielt am %s Uhr." % [spieldatum,
		SaveGame.time_text(zuletzt).replace(" ", ", ")]


## Spiel 1 bis Spiel 8, Mittel, Spiel n am 0n.01.1985 und n Minuten nach ANGELEGT gespielt; die
## Liste zeigt also Spiel 8 bis Spiel 1, und es wird gerollt. Löschen von Spiel [param gesperrt]
## scheitert wie in test_loeschen_scheitert_…: An der Stelle von spiel_N.json liegt ein Ordner mit
## Inhalt, daneben die fortsetzbare spiel_N.json.alt.
func _acht_spiele_eins_gesperrt(gesperrt: int) -> void:
	for nummer in range(1, 9):
		_lege_an(nummer, Difficulty.Level.MITTEL, _tag(1985, 1, nummer), ANGELEGT + nummer * 60)
	var datei := ORDNER.path_join("spiel_%d.json" % gesperrt)
	assert_eq(DirAccess.rename_absolute(datei, datei + ".alt"), OK)
	assert_eq(DirAccess.make_dir_recursive_absolute(datei.path_join("inhalt")), OK)


## Name → Inhalt jeder Datei im Testordner.
func _inhalte() -> Dictionary:
	var inhalte := {}
	for datei in DirAccess.get_files_at(ORDNER):
		inhalte[datei] = FileAccess.get_file_as_string(ORDNER.path_join(datei))
	return inhalte


## Die Dateien und Ordner im Testordner, sortiert.
func _dateien() -> Array:
	var namen := Array(DirAccess.get_files_at(ORDNER))
	namen.append_array(DirAccess.get_directories_at(ORDNER))
	namen.sort()
	return namen


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
