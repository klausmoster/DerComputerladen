extends GutTest

## Prüft den Titelbildschirm: den Text der Versionszeile (Feature 001, FR-014) und seit Feature 004
## die Blätter Hauptmenü und Gradwahl (T020; contracts/titelbildschirm.md, „TitleScreen“ und
## „Tests“; data-model.md, „Titelbildschirm: Blätter und Wege“): fünf Einträge, ihre Verfügbarkeit
## und Hinweise nach den Spielständen im Ordner, die Vorwahl, die Gradwahl mit Tastatur und Maus,
## Esc und „Zurück“, ein neues Spiel mit 3 Eingaben (SC-001), „Weiterspielen“ mit 1 (SC-002), die
## Meldung, wenn das Anlegen scheitert, und dass ohne Spiel nichts läuft und keine Datei entsteht
## (FR-003).
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
	assert_eq(_hauptmenue().entries[2].hint, "Alle Spielstände: fortsetzen oder löschen.")
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
	assert_eq(_hauptmenue().entries[2].hint, "Alle Spielstände: fortsetzen oder löschen.")
	assert_eq(_hauptmenue().selected_index(), 1, "Ohne fortsetzbaren: „Neues Spiel“.")
	assert_push_warning("spiel_1.json", "Das Protokoll nennt die beschädigte Datei.")


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


func test_spiel_laden_tut_in_dieser_phase_noch_nichts() -> void:
	# Arrange: Die Liste kommt mit Phase 5 (T026).
	_lege_an(1, Difficulty.Level.MITTEL, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	await _taste(KEY_DOWN)
	await _taste(KEY_DOWN)

	# Act
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_hauptmenue().selected_index(), 2, "Voraussetzung: „Spiel laden“ gewählt.")
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_wechsel, [])
	assert_eq(_hinweis_text(), "Alle Spielstände: fortsetzen oder löschen.")


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


# --- Helfer ---------------------------------------------------------------------------------------

## Baut eine Session mit eigener Uhr, eigener Zeitleiste und dem Ordner [param ordner], dann den
## Titel in einem eigenen Viewport, und wartet, bis er seine Blätter gebaut hat.
func _zeige_titel(ordner: String = ORDNER) -> void:
	_sitzung = await _neue_sitzung(ordner)
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	_titel = TITEL.instantiate() as TitleScreen
	_titel.session = _sitzung
	_titel.scene_callback = _merke_wechsel
	eigener_viewport.add_child(_titel)
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
func _hat_fokus(blatt: MainMenu) -> bool:
	var besitzer := _titel.get_viewport().gui_get_focus_owner()
	return besitzer != null and blatt.is_ancestor_of(besitzer)


## Genau [param blatt] ist zu sehen, kein anderes Blatt.
func _assert_nur_sichtbar(blatt: MainMenu) -> void:
	for anderes in [_hauptmenue(), _gradwahl()]:
		assert_eq(anderes.visible, anderes == blatt,
			"%s sichtbar: %s" % [anderes.name, anderes == blatt])


## Der Hinweis steht 4 Pixel links neben Zeile [param index] von [param blatt], oben bündig.
func _assert_neben_zeile(blatt: MainMenu, index: int) -> void:
	var oben := blatt.global_position.y + ZEILE * (index + 1)
	assert_eq(_hinweis().global_position.y, oben, "Oben bündig mit Zeile %d." % index)
	assert_eq(_hinweis().global_position.x + _hinweis().size.x,
		blatt.global_position.x - MenuHint.GAP, "4 Pixel links neben der Zeile.")


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
## Katalog catalog_us1_grade.json.
func _lege_an(nummer: int, grad: Difficulty.Level, tag: int, zuletzt: int) -> void:
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
	game.catalog = EventCatalog.read_file(KATALOGE + "catalog_us1_grade.json", meldungen)
	assert_eq(SaveStore.new(ORDNER).write(game, true), OK, "Spiel %d angelegt." % nummer)


## Kopiert eine Fixture als spiel_<nummer>.json in den Testordner.
func _kopiere(fixture: String, nummer: int) -> void:
	assert_eq(DirAccess.copy_absolute(FIXTURES.path_join(fixture),
		ORDNER.path_join("spiel_%d.json" % nummer)), OK, "Kopiert: %s" % fixture)


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
