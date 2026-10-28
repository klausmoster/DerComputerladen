extends GutTest

## Prüft die Zusammenfassung des Selbsttests ohne Fenster (Feature 007, T029; contracts/
## selbsttest-app.md, „Zusammenfassung“ und „Texte“; contracts/protokoll.md, „Text für Kopieren“;
## Review CHK017 bis CHK027): Aufbau mit erfundenen Läufen (alles in Ordnung, mit Fehlern, Ordner
## nicht beschreibbar), Einträge mit Feld, Text in der Zwischenablage, Bestätigung, Fokus und
## Tasten, gesperrter Knopf, und die Kopie des Themes.
##
## Wie in test_main_menu.gd steht die Seite in einem eigenen Viewport: Im Haupt-Viewport läge GUTs
## Oberfläche darüber und finge Klicks und Fokus ab. Tasten und Klicks gehen über push_input(), den
## Eingang, über den auch das Fenster echte Eingaben weitergibt. Zwischenablage, Dateimanager und
## Beenden ersetzt der Test über die Callables der Seite; der Test schreibt nur unter ORDNER.
##
## Wie die Seite im Fenster aussieht, zeigen die Bildschirmfotos aus der Probeszene
## res://test/fixtures/selbsttest_ergebnis_probe.tscn.

const WERKSTATT_THEMA := "res://tools/werkstatt/werkstatt_theme.tres"
const SELBSTTEST_THEMA := "res://tools/selbsttest/selbsttest_theme.tres"
## Ein eigener Ordner für das Zip, das „Ordner zeigen“ markiert.
const ORDNER := "user://test_selbsttest_ergebnis/"
## 28.10.2026, 14:03:12, Ortszeit
const START := {"year": 2026, "month": 10, "day": 28, "hour": 14, "minute": 3, "second": 12}
const SYSTEM := {
	"system.os": "macOS",
	"system.os_version": "26.0.0",
	"system.gpu": "Apple M3 Pro",
	"system.grafik_api": "Metal",
}
## Die Varianten, die die Kopie zum Theme der Werkstatt hinzufügt, mit ihrem Grundtyp.
const EIGENE_VARIANTEN := {
	&"AlternateEntryPanel": &"PanelContainer",
	&"EntryPanel": &"PanelContainer",
	&"ErrorMarkLabel": &"Label",
	&"NotRunMarkLabel": &"Label",
	&"SmallMutedLabel": &"Label",
}
## Was die Kopie in Typen der Werkstatt ändert oder dazugibt: Umbrochene Zeilen in einem Label
## stehen so dicht wie getrennte Labels, eine Zeile werkzeug-text hoch (Phasenprüfung Phase 4).
const EIGENE_EINTRAEGE := {"Label/constants/line_spacing": 0}
## Höhe einer Zeile werkzeug-text in Pixeln (Style-Guide, „Werkzeuge“).
const ZEILENHOEHE := 20

## Namen der Arten in einer .tres, für EIGENE_EINTRAEGE.
const _ART_NAMEN := {
	Theme.DATA_TYPE_COLOR: "colors",
	Theme.DATA_TYPE_CONSTANT: "constants",
	Theme.DATA_TYPE_FONT_SIZE: "font_sizes",
	Theme.DATA_TYPE_ICON: "icons",
	Theme.DATA_TYPE_STYLEBOX: "styles",
}

var _viewport: SubViewport
var _ergebnis: SelbsttestErgebnis
var _ordner_absolut := ""
var _zip := ""
var _kopiert: PackedStringArray = []
var _gezeigt: PackedStringArray = []
var _beendet := 0


func before_each() -> void:
	_kopiert = PackedStringArray()
	_gezeigt = PackedStringArray()
	_beendet = 0
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_ordner_absolut = ProjectSettings.globalize_path(ORDNER + "2026-10-28_14-03-12")
	_zip = ProjectSettings.globalize_path(ORDNER + "2026-10-28_14-03-12_macos.zip")
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 720)
	add_child_autofree(_viewport)


func after_each() -> void:
	for datei in DirAccess.get_files_at(ORDNER):
		DirAccess.remove_absolute(ORDNER.path_join(datei))
	DirAccess.remove_absolute(ORDNER)


# --- Aufbau ---------------------------------------------------------------------------------------

func test_alles_in_ordnung_ohne_liste() -> void:
	# Arrange
	var lauf := _lauf_in_ordnung()

	# Act
	await _zeige(lauf)

	# Assert: Überschrift, Systemzeile, Summe, Pfad; Bereichstitel und Liste entfallen (CHK021).
	assert_eq(_label(&"Ueberschrift").text, "Selbsttest vom 28.10.2026, 14:03 Uhr")
	assert_eq(_label(&"Systemzeile").text, "macOS 26.0.0 · Apple M3 Pro · Metal")
	assert_eq(_label(&"Summe").text, "Alles in Ordnung: 2 von 2 Schritten.")
	assert_false(_label(&"Bereichstitel").is_visible_in_tree())
	assert_false(_knoten(&"Liste").is_visible_in_tree())
	assert_true(_knoten(&"Luecke").is_visible_in_tree(), "Die Lücke hält die Knopfreihe unten.")
	assert_false(_label(&"Meldung").is_visible_in_tree())
	assert_true(_label(&"Pfad").is_visible_in_tree())
	assert_eq(_ohne_umbruchstellen(_label(&"Pfad").text),
		"Protokoll und Fotos liegen hier: " + _ordner_absolut)


func test_schriften_und_farben_aus_dem_theme() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())

	# Assert: Schriften und Farben laut Vertrag (CHK018, CHK019, CHK022).
	for name: StringName in [&"Ueberschrift", &"Summe", &"Bereichstitel"]:
		assert_eq(_label(name).get_theme_font_size(&"font_size"), 16, "%s in werkzeug-titel" % name)
		assert_eq(_label(name).get_theme_color(&"font_color"), UiPalette.TUSCHE,
			"%s in tusche, auch die Summe" % name)
	assert_eq(_label(&"Systemzeile").get_theme_font_size(&"font_size"), 12, "werkzeug-klein")
	assert_eq(_label(&"Systemzeile").get_theme_color(&"font_color"), UiPalette.GEHAEUSE_DUNKEL)
	assert_eq(_label(&"Pfad").get_theme_font_size(&"font_size"), 14, "werkzeug-text")
	assert_eq(_label(&"Pfad").get_theme_color(&"font_color"), UiPalette.TUSCHE)
	var grund := (_ergebnis.get_node(^"Grund") as Panel).get_theme_stylebox(&"panel")
	assert_eq((grund as StyleBoxFlat).bg_color, UiPalette.PAPIER, "Grund papier (CHK022)")
	assert_eq(_ergebnis.theme.default_font, ThemeDB.fallback_font, "Eingebaute Schrift (CHK017)")


func test_abstaende_aus_dem_raster() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())
	var rand := _ergebnis.get_node(^"Rand") as MarginContainer
	var spalte := _ergebnis.get_node(^"Rand/Spalte") as VBoxContainer
	var fuss := _ergebnis.get_node(^"Rand/Spalte/Fuss") as HBoxContainer
	var reihe := _ergebnis.get_node(^"Rand/Spalte/Fuss/Knopfreihe") as HBoxContainer

	# Assert (CHK022; Style-Guide „Werkzeuge“, Version 60): Rand und Bereiche 16, Bereichstitel zur
	# Liste 8, Einträge 8 (Innenabstand 4 oben und unten), Knöpfe 8, Bestätigung 16 rechts daneben.
	for seite: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		assert_eq(rand.get_theme_constant(seite), 16, seite)
	assert_eq(spalte.get_theme_constant(&"separation"), 16)
	assert_eq(_knoten(&"Bereich").get_theme_constant(&"separation"), 8, "Titel über der Liste")
	assert_eq(_knoten(&"Bereichstitel").get_parent(), _knoten(&"Bereich"))
	assert_eq(_knoten(&"Liste").get_parent(), _knoten(&"Bereich"))
	assert_eq(reihe.get_theme_constant(&"separation"), 8,
		"Die Fokuslinie berührt den Nachbarn nicht.")
	assert_eq(fuss.get_theme_constant(&"separation"), 16)
	assert_eq(fuss.get_children(), [reihe, _knoten(&"Bestaetigung")], "Bestätigung rechts daneben")
	_ergebnis.kopiere()
	await wait_process_frames(1)
	var abstand := _knoten(&"Bestaetigung").get_global_rect().position.x \
		- _knopf(&"Beenden").get_global_rect().end.x
	assert_eq(abstand, 16.0, "16 von „Beenden“ zur Bestätigung")
	var kasten := _eintraege()[0].get_theme_stylebox(&"panel")
	assert_eq(kasten.content_margin_top + kasten.content_margin_bottom, 8.0,
		"Zwischen zwei Einträgen 8")
	assert_eq(_knoten(&"Eintraege").get_theme_constant(&"separation"), 0)


func test_mit_fehlern_feld_und_zeilen_je_eintrag() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())

	# Assert
	assert_eq(_label(&"Summe").text, "1 von 4 Schritten in Ordnung, 1 Fehler, 2 nicht gelaufen.")
	assert_true(_label(&"Bereichstitel").is_visible_in_tree())
	assert_eq(_label(&"Bereichstitel").text, "Was nicht stimmt")
	assert_true(_knoten(&"Liste").is_visible_in_tree())
	assert_false(_knoten(&"Luecke").is_visible_in_tree())
	var eintraege := _eintraege()
	assert_eq(eintraege.size(), 3, "Ein Eintrag je Schritt, der nicht in Ordnung ist.")
	assert_eq(_zeilen(eintraege[0]), ["titel.02_zwei · Zweiter Schritt",
		"Erwartet: Menü steht: HAUPTMENÜ, „Neues Spiel“",
		"Gefunden: Zeit abgelaufen, zuletzt: Menü steht: HAUPTMENÜ, „Spiel laden“"])
	assert_eq(_zeilen(eintraege[1]), ["titel.03_drei · Dritter Schritt",
		"Nicht gelaufen: Fehler in Schritt titel.02_zwei"])
	assert_eq(_zeilen(eintraege[2]), ["laden.01_eins · Erster Schritt von laden",
		"Nicht gelaufen: Fehler in Ablauf titel"])
	# Feld „!“ für Fehler, „–“ für nicht gelaufen (CHK019).
	assert_eq(_feld(eintraege[0]).text, "!")
	assert_eq(_feld(eintraege[0]).theme_type_variation, &"ErrorMarkLabel")
	assert_eq(_feld(eintraege[0]).get_theme_color(&"font_color"), UiPalette.PAPIER)
	assert_eq((_feld(eintraege[0]).get_theme_stylebox(&"normal") as StyleBoxFlat).bg_color,
		UiPalette.KASSENROT)
	assert_eq(_feld(eintraege[1]).text, "–")
	assert_eq(_feld(eintraege[1]).theme_type_variation, &"NotRunMarkLabel")
	var kontur := _feld(eintraege[1]).get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_eq(kontur.bg_color, UiPalette.PAPIER)
	assert_eq(kontur.border_color, UiPalette.TUSCHE)
	assert_eq(kontur.border_width_left, 1)
	assert_eq(_feld(eintraege[1]).get_theme_color(&"font_color"), UiPalette.TUSCHE)
	assert_eq(_feld(eintraege[0]).custom_minimum_size.x, _feld(eintraege[0]).custom_minimum_size.y,
		"Das Feld ist quadratisch.")


func test_zweite_farbe_je_eintrag_nicht_je_zeile() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())

	# Assert (CHK024)
	var farben := _eintraege().map(func(kasten: PanelContainer) -> Color:
		return (kasten.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color)
	assert_eq(farben, [UiPalette.PAPIER, UiPalette.ENDLOS_GRUEN, UiPalette.PAPIER])


func test_eintraege_sind_nicht_anklickbar_und_brechen_um() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())

	# Assert (CHK019, CHK027): Kein Teil eines Eintrags nimmt die Maus an; lange Werte brechen um,
	# nichts wird gekürzt.
	for kasten in _eintraege():
		for knoten in _alle(kasten):
			var control := knoten as Control
			assert_eq(control.mouse_filter, Control.MOUSE_FILTER_IGNORE, str(control.name))
			assert_eq(control.tooltip_text, "")
		for zeile: Label in _eintrag_labels(kasten):
			assert_eq(zeile.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
			assert_eq(zeile.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
	assert_eq((_knoten(&"Liste") as ScrollContainer).horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_DISABLED, "Breite Zeilen brechen um, statt zu rollen.")


func test_pfad_bricht_nach_einem_trenner_um_und_wird_nie_gekuerzt() -> void:
	# Arrange: ein Pfad, der in keine Zeile passt
	var lang := "/Users/klaus/Library/Application Support/" + "Ordner/".repeat(80) + "lauf"

	# Act
	var text := SelbsttestErgebnis.umbrechbar(lang)

	# Assert (CHK027)
	assert_eq(text.count(SelbsttestErgebnis.UMBRUCHSTELLE), lang.count("/"),
		"Hinter jedem Trenner eine Umbruchstelle.")
	assert_eq(_ohne_umbruchstellen(text), lang, "Nichts fehlt.")
	assert_false(text.contains(" "), "Im Pfad bricht kein Leerzeichen um, etwa in „Application "
		+ "Support“.")
	assert_eq(SelbsttestErgebnis.umbrechbar("C:\\Users\\klaus"), "C:\\\u200BUsers\\\u200Bklaus",
		"Unter Windows nach dem Rückstrich.")
	await _zeige(_lauf_in_ordnung())
	assert_eq(_label(&"Pfad").text, "Protokoll und Fotos liegen hier: "
		+ SelbsttestErgebnis.umbrechbar(_ordner_absolut), "Nur der Pfad, nicht der Satz davor.")
	assert_eq(_label(&"Pfad").autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_eq(_label(&"Pfad").text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
	assert_false(_label(&"Pfad").clip_text)


# --- Ordner nicht beschreibbar --------------------------------------------------------------------

func test_nicht_beschreibbar_meldung_an_stelle_von_summe_liste_und_pfad() -> void:
	# Arrange
	var lauf := _lauf_ohne_schritte()

	# Act
	await _zeige(lauf, false)

	# Assert (CHK020)
	assert_true(_label(&"Ueberschrift").is_visible_in_tree())
	assert_eq(_label(&"Systemzeile").text, "macOS 26.0.0 · Apple M3 Pro · Metal")
	for name: StringName in [&"Summe", &"Bereichstitel", &"Liste", &"Pfad"]:
		assert_false(_knoten(name).is_visible_in_tree(), "%s entfällt." % name)
	assert_true(_label(&"Meldung").is_visible_in_tree())
	assert_eq(_ohne_umbruchstellen(_label(&"Meldung").text),
		"Kein Protokoll: In %s lässt sich nicht schreiben." % _ordner_absolut)
	assert_eq(_label(&"Meldung").theme_type_variation, &"ErrorNoticeLabel")
	assert_eq((_label(&"Meldung").get_theme_stylebox(&"normal") as StyleBoxFlat).bg_color,
		UiPalette.KASSENROT)
	assert_eq(_label(&"Meldung").get_theme_color(&"font_color"), UiPalette.PAPIER)


func test_nicht_beschreibbar_ordner_zeigen_ist_gesperrt() -> void:
	# Arrange
	await _zeige(_lauf_ohne_schritte(), false)
	var knopf := _knopf(&"OrdnerZeigen")

	# Act: Klick auf den gesperrten Knopf
	await _klick(knopf)

	# Assert
	assert_true(knopf.disabled)
	assert_eq(knopf.focus_mode, Control.FOCUS_NONE, "Tab überspringt ihn.")
	assert_eq(knopf.mouse_default_cursor_shape, Control.CURSOR_ARROW)
	assert_eq(knopf.tooltip_text, "Kein Zip: Im Ordner lässt sich nicht schreiben.",
		"Der Tooltip sagt, warum er gesperrt ist.")
	assert_eq(_gezeigt.size(), 0, "Der Dateimanager öffnet sich nicht.")
	assert_false(_knopf(&"Kopieren").disabled)
	assert_false(_knopf(&"Beenden").disabled)


func test_nicht_beschreibbar_kopieren_legt_meldung_und_systemdaten_ab() -> void:
	# Arrange
	var lauf := _lauf_ohne_schritte()
	await _zeige(lauf, false)

	# Act
	await _klick(_knopf(&"Kopieren"))

	# Assert (contracts/protokoll.md; Analyse, U5)
	assert_eq(_kopiert.size(), 1)
	assert_eq(_kopiert[0], SelbsttestProtokoll.kopieren_nicht_beschreibbar(lauf, _ordner_absolut))
	assert_string_contains(_kopiert[0],
		"\nmeldung: Kein Protokoll: In %s lässt sich nicht schreiben\n" % _ordner_absolut)
	assert_false(_kopiert[0].contains("# Schritte"))


# --- Knöpfe ---------------------------------------------------------------------------------------

func test_knoepfe_mit_text_tooltip_und_handzeiger() -> void:
	# Arrange
	await _zeige(_lauf_in_ordnung())

	# Assert (CHK026), links beginnend
	var reihe := _ergebnis.get_node(^"Rand/Spalte/Fuss/Knopfreihe")
	var knoepfe := [_knopf(&"Kopieren"), _knopf(&"OrdnerZeigen"), _knopf(&"Beenden")]
	assert_eq(reihe.get_children(), knoepfe, "Kopieren, Ordner zeigen, Beenden")
	assert_eq(knoepfe.map(func(k: Button) -> String: return k.text),
		["Kopieren", "Ordner zeigen", "Beenden"])
	assert_eq(knoepfe.map(func(k: Button) -> String: return k.tooltip_text),
		["Legt das Ergebnis als Text in die Zwischenablage.",
		"Zeigt das Zip dieses Laufs im Dateimanager.", "Beendet den Selbsttest."])
	for knopf: Button in knoepfe:
		assert_eq(knopf.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, knopf.text)
		assert_eq(knopf.theme_type_variation, &"", "Standard-Button ohne eigene Styles")
		assert_false(knopf.has_theme_stylebox_override(&"normal"))


func test_kopieren_legt_den_text_aus_dem_protokoll_ab_und_bestaetigt() -> void:
	# Arrange
	var lauf := _lauf_mit_fehlern()
	await _zeige(lauf)
	assert_false(_label(&"Bestaetigung").visible, "Vorher keine Bestätigung.")

	# Act: ein Klick wie mit der Maus
	await _klick(_knopf(&"Kopieren"))

	# Assert (FR-014a, CHK025)
	assert_eq(_kopiert.size(), 1)
	assert_eq(_kopiert[0], SelbsttestProtokoll.kopieren(lauf, _ordner_absolut))
	assert_string_ends_with(_kopiert[0], "\nordner: %s\n" % _ordner_absolut)
	assert_true(_label(&"Bestaetigung").visible)
	assert_eq(_label(&"Bestaetigung").text, "Kopiert.")
	assert_eq(_label(&"Bestaetigung").get_theme_color(&"font_color"), UiPalette.TUSCHE)


func test_unter_linux_sagt_die_bestaetigung_mehr() -> void:
	# Arrange
	await _zeige(_lauf_in_ordnung(), true, "Linux")

	# Act
	_ergebnis.kopiere()

	# Assert (R11)
	assert_eq(_label(&"Bestaetigung").text, "Kopiert. Erst einfügen, dann beenden.")


func test_die_bestaetigung_steht_bis_zum_naechsten_klick() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())
	await _klick(_knopf(&"Kopieren"))

	# Act und Assert: Das Mausrad ist kein Klick, ein Klick daneben schon.
	await _maustaste(Vector2(600, 300), MOUSE_BUTTON_WHEEL_DOWN)
	assert_true(_label(&"Bestaetigung").visible, "Nach dem Mausrad noch da.")
	await _maustaste(Vector2(600, 300), MOUSE_BUTTON_LEFT)
	assert_false(_label(&"Bestaetigung").visible, "Nach dem nächsten Klick weg.")


func test_ordner_zeigen_markiert_das_zip() -> void:
	# Arrange: Das Zip gibt es.
	var datei := FileAccess.open(ORDNER + "2026-10-28_14-03-12_macos.zip", FileAccess.WRITE)
	datei.close()
	await _zeige(_lauf_in_ordnung())

	# Act
	await _klick(_knopf(&"OrdnerZeigen"))

	# Assert (CHK002, R11)
	assert_eq(_gezeigt, PackedStringArray([_zip]))


func test_ohne_zip_zeigt_ordner_zeigen_den_ordner_des_laufs() -> void:
	# Arrange: Das Packen ist gescheitert.
	await _zeige(_lauf_in_ordnung())

	# Act
	_ergebnis.zeige_ordner()

	# Assert
	assert_eq(_gezeigt, PackedStringArray([_ordner_absolut]))


func test_beenden_beendet() -> void:
	# Arrange
	await _zeige(_lauf_in_ordnung())

	# Act
	await _klick(_knopf(&"Beenden"))

	# Assert
	assert_eq(_beendet, 1)


# --- Fokus und Tasten -----------------------------------------------------------------------------

func test_fokus_beim_oeffnen_auf_kopieren() -> void:
	# Act
	await _zeige(_lauf_mit_fehlern())

	# Assert (CHK023)
	assert_eq(_viewport.gui_get_focus_owner(), _knopf(&"Kopieren"))


func test_tab_und_umschalt_tab_wechseln_zwischen_den_knoepfen() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())

	# Act und Assert (CHK023): nur die Knöpfe, ringsum
	var folge: Array[StringName] = []
	for i in 3:
		await _taste(KEY_TAB)
		folge.append(_viewport.gui_get_focus_owner().name)
	assert_eq(folge, [&"OrdnerZeigen", &"Beenden", &"Kopieren"])
	await _taste(KEY_TAB, true)
	assert_eq(_viewport.gui_get_focus_owner().name, &"Beenden", "Umschalt+Tab zurück")


func test_tab_ueberspringt_den_gesperrten_knopf() -> void:
	# Arrange
	await _zeige(_lauf_ohne_schritte(), false)

	# Act
	await _taste(KEY_TAB)

	# Assert
	assert_eq(_viewport.gui_get_focus_owner(), _knopf(&"Beenden"))


func test_enter_und_leertaste_loesen_aus() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())

	# Act
	await _taste(KEY_ENTER)
	await _taste(KEY_SPACE)

	# Assert
	assert_eq(_kopiert.size(), 2, "Enter und Leertaste auf „Kopieren“")
	assert_eq(_beendet, 0)


func test_esc_tut_nichts() -> void:
	# Arrange
	await _zeige(_lauf_mit_fehlern())

	# Act
	await _taste(KEY_ESCAPE)

	# Assert (CHK023)
	assert_eq(_beendet, 0)
	assert_eq(_kopiert.size(), 0)
	assert_eq(_gezeigt.size(), 0)
	assert_eq(_viewport.gui_get_focus_owner(), _knopf(&"Kopieren"))


# --- Theme ----------------------------------------------------------------------------------------

func test_das_theme_ist_eine_kopie_der_werkstatt_mit_eigenen_varianten() -> void:
	# Arrange: frisch aus der Datei, ohne die Schrift, die die Seite zur Laufzeit setzt
	var werkstatt := ResourceLoader.load(WERKSTATT_THEMA, "", ResourceLoader.CACHE_MODE_IGNORE) \
		as Theme
	var kopie := ResourceLoader.load(SELBSTTEST_THEMA, "", ResourceLoader.CACHE_MODE_IGNORE) \
		as Theme

	# Assert: Alles aus der Werkstatt steht unverändert in der Kopie (CHK017). Ändert sich das Theme
	# der Werkstatt, sagt dieser Test, dass die Kopie nachzuziehen ist.
	assert_false(kopie.has_default_font(), "Die Schrift kommt per Code.")
	assert_eq(kopie.default_font_size, werkstatt.default_font_size)
	for typ in werkstatt.get_type_list():
		assert_eq(kopie.get_type_variation_base(typ), werkstatt.get_type_variation_base(typ), typ)
		for art in [Theme.DATA_TYPE_COLOR, Theme.DATA_TYPE_CONSTANT, Theme.DATA_TYPE_FONT_SIZE,
				Theme.DATA_TYPE_ICON, Theme.DATA_TYPE_STYLEBOX]:
			for eintrag in werkstatt.get_theme_item_list(art, typ):
				assert_true(kopie.has_theme_item(art, eintrag, typ),
					"%s/%s fehlt." % [typ, eintrag])
				assert_true(_gleich(kopie.get_theme_item(art, eintrag, typ),
					werkstatt.get_theme_item(art, eintrag, typ)), "%s/%s" % [typ, eintrag])
			# Was die Kopie in diesem Typ mehr hat, muss in EIGENE_EINTRAEGE stehen.
			for eintrag in kopie.get_theme_item_list(art, typ):
				if werkstatt.has_theme_item(art, eintrag, typ):
					continue
				var schluessel := "%s/%s/%s" % [typ, _ART_NAMEN[art], eintrag]
				assert_has(EIGENE_EINTRAEGE, schluessel, "Unerwartet in der Kopie.")
				assert_eq(kopie.get_theme_item(art, eintrag, typ), EIGENE_EINTRAEGE.get(schluessel),
					schluessel)
	var dazu: Array[String] = []
	for typ in kopie.get_type_list():
		if not werkstatt.get_type_list().has(typ):
			dazu.append(typ)
	dazu.sort()
	assert_eq(dazu, EIGENE_VARIANTEN.keys().map(func(typ: StringName) -> String: return str(typ)),
		"Nur die eigenen Varianten kommen dazu.")
	for typ: StringName in EIGENE_VARIANTEN:
		assert_eq(kopie.get_type_variation_base(typ), EIGENE_VARIANTEN[typ], typ)


func test_umbrochene_zeilen_stehen_so_dicht_wie_getrennte_labels() -> void:
	# Arrange: eine Zeile eines Eintrags, die in einem Fenster von 400 Pixeln umbricht
	_viewport.size = Vector2i(400, 720)
	await _zeige(_lauf_mit_fehlern())
	var gefunden := _eintrag_labels(_eintraege()[0])[2]
	var erste := _eintrag_labels(_eintraege()[0])[0]

	# Assert (Phasenprüfung Phase 4, Befund 1): je Zeile 20 Pixel, ohne Abstand dazwischen.
	assert_eq(gefunden.get_theme_constant(&"line_spacing"), 0)
	assert_gt(gefunden.get_line_count(), 1, "Die Zeile bricht um.")
	assert_eq(gefunden.get_line_height(), ZEILENHOEHE, "werkzeug-text")
	assert_eq(gefunden.size.y, float(ZEILENHOEHE * gefunden.get_line_count()))
	assert_eq(erste.size.y, float(ZEILENHOEHE))
	assert_eq(_feld(_eintraege()[0]).custom_minimum_size, Vector2(ZEILENHOEHE, ZEILENHOEHE),
		"Das Feld ist eine Zeile hoch.")


func test_eigene_varianten_in_farben_der_palette_eckig_ohne_kantenglaettung() -> void:
	# Arrange
	var kopie := ResourceLoader.load(SELBSTTEST_THEMA, "", ResourceLoader.CACHE_MODE_IGNORE) \
		as Theme
	var palette := UiPalette.TOKENS.values()

	# Assert
	for typ: StringName in EIGENE_VARIANTEN:
		for eintrag in kopie.get_color_list(typ):
			assert_has(palette, kopie.get_color(eintrag, typ), "%s/%s" % [typ, eintrag])
		for eintrag in kopie.get_stylebox_list(typ):
			var kasten := kopie.get_stylebox(eintrag, typ) as StyleBoxFlat
			assert_not_null(kasten, "%s/%s ist flach." % [typ, eintrag])
			assert_has(palette, kasten.bg_color, "%s/%s: Fläche" % [typ, eintrag])
			assert_false(kasten.anti_aliasing)
			assert_eq(kasten.get_corner_radius(CORNER_TOP_LEFT), 0)
	assert_eq(kopie.get_font_size(&"font_size", &"SmallMutedLabel"), 12, "werkzeug-klein")
	assert_eq(kopie.get_color(&"font_color", &"SmallMutedLabel"), UiPalette.GEHAEUSE_DUNKEL)


# --- Helfer ---------------------------------------------------------------------------------------

## Zeigt die Zusammenfassung für [param lauf] im eigenen Viewport und wartet, bis sie steht.
func _zeige(lauf: SelbsttestLauf, beschreibbar: bool = true, system_name: String = "macOS") -> void:
	_ergebnis = SelbsttestErgebnis.erstelle(lauf, _ordner_absolut, _zip, beschreibbar)
	_ergebnis.system_name = system_name
	_ergebnis.zwischenablage = func(text: String) -> void: _kopiert.append(text)
	_ergebnis.dateimanager = func(pfad: String) -> Error:
		_gezeigt.append(pfad)
		return OK
	_ergebnis.beenden = func() -> void: _beendet += 1
	_viewport.add_child(_ergebnis)
	# Zwei Bilder: Container ordnen an, Labels mit Umbruch brauchen ein zweites.
	await wait_process_frames(2)


func _lauf_in_ordnung() -> SelbsttestLauf:
	var lauf := _lauf_ohne_schritte()
	lauf.plane(_ablauf("titel"), [_schritt("titel.01_start", "Start"),
		_schritt("titel.02_zwei", "Zweiter Schritt")])
	lauf.melde_ok("titel.01_start", 1712)
	lauf.melde_ok("titel.02_zwei", 80)
	return lauf


## 1 in Ordnung, 1 Fehler, 1 nicht gelaufen im selben Ablauf, 1 nicht gelaufen in einem Ablauf,
## der darauf aufbaut.
func _lauf_mit_fehlern() -> SelbsttestLauf:
	var lauf := _lauf_ohne_schritte()
	lauf.plane(_ablauf("titel"), [_schritt("titel.01_start", "Start"),
		_schritt("titel.02_zwei", "Zweiter Schritt", "Menü steht: HAUPTMENÜ, „Neues Spiel“"),
		_schritt("titel.03_drei", "Dritter Schritt")])
	lauf.plane(_ablauf("laden", "titel"), [_schritt("laden.01_eins", "Erster Schritt von laden")])
	lauf.melde_ok("titel.01_start", 1712)
	lauf.melde_fehler("titel.02_zwei",
		"Zeit abgelaufen, zuletzt: Menü steht: HAUPTMENÜ, „Spiel laden“", 5003)
	return lauf


func _lauf_ohne_schritte() -> SelbsttestLauf:
	var lauf := SelbsttestLauf.new(START)
	lauf.system = SYSTEM.duplicate()
	lauf.version = 1
	return lauf


func _ablauf(kennung: String, baut_auf: String = "") -> SelbsttestAblauf:
	var ablauf := SelbsttestAblauf.new()
	ablauf.kennung = kennung
	ablauf.name = SelbsttestTexte.ablauf_name(kennung)
	ablauf.baut_auf = baut_auf
	return ablauf


func _schritt(kennung: String, beschreibung: String, erwartet: String = "") -> Dictionary:
	return {"kennung": kennung, "beschreibung": beschreibung,
		"eingaben_text": SelbsttestTexte.EINGABEN_KEINE, "erwartet_text": erwartet}


func _knoten(name: StringName) -> Control:
	return _ergebnis.get_node("%" + name) as Control


func _label(name: StringName) -> Label:
	return _knoten(name) as Label


func _knopf(name: StringName) -> Button:
	return _knoten(name) as Button


func _eintraege() -> Array[PanelContainer]:
	var liste: Array[PanelContainer] = []
	for kind in _knoten(&"Eintraege").get_children():
		liste.append(kind as PanelContainer)
	return liste


## Das Feld vorn im Eintrag.
func _feld(kasten: PanelContainer) -> Label:
	return kasten.get_child(0).get_child(0) as Label


## Die Zeilen rechts im Eintrag.
func _eintrag_labels(kasten: PanelContainer) -> Array[Label]:
	var liste: Array[Label] = []
	for kind in kasten.get_child(0).get_child(1).get_children():
		liste.append(kind as Label)
	return liste


func _zeilen(kasten: PanelContainer) -> Array:
	return _eintrag_labels(kasten).map(func(zeile: Label) -> String: return zeile.text)


func _alle(knoten: Node) -> Array[Node]:
	var liste: Array[Node] = [knoten]
	for kind in knoten.get_children():
		liste.append_array(_alle(kind))
	return liste


## Der Text so, wie er ohne die Hilfen zum Umbrechen hieße.
func _ohne_umbruchstellen(text: String) -> String:
	return text.replace(SelbsttestErgebnis.UMBRUCHSTELLE, "") \
		.replace(SelbsttestErgebnis.FESTES_LEERZEICHEN, " ")


## Zwei Einträge eines Themes sind gleich: Werte direkt, Ressourcen nach ihren gespeicherten
## Eigenschaften.
func _gleich(a: Variant, b: Variant) -> bool:
	if a is Resource and b is Resource:
		if (a as Resource).get_class() != (b as Resource).get_class():
			return false
		# Eine eigene Datei, etwa ein Symbol, ist dieselbe, wenn der Pfad gleich ist. Eine
		# Unterressource heißt „datei.tres::id“; sie wird nach ihren Eigenschaften verglichen.
		var pfad := (a as Resource).resource_path
		if not pfad.is_empty() and not pfad.contains("::"):
			return pfad == (b as Resource).resource_path
		for eigenschaft in (a as Resource).get_property_list():
			if eigenschaft["usage"] & PROPERTY_USAGE_STORAGE == 0:
				continue
			var name: String = eigenschaft["name"]
			if name in ["resource_path", "resource_name", "resource_local_to_scene",
					"resource_scene_unique_id"]:
				continue
			if not _gleich(a.get(name), b.get(name)):
				return false
		return true
	return a == b


## Klickt mit der linken Taste mitten auf [param knopf]: Bewegung, Drücken, Loslassen.
func _klick(knopf: Control) -> void:
	var mitte := knopf.get_global_rect().get_center()
	var bewegung := InputEventMouseMotion.new()
	bewegung.position = mitte
	bewegung.global_position = mitte
	_viewport.push_input(bewegung, true)
	await _maustaste(mitte, MOUSE_BUTTON_LEFT)


func _maustaste(wo: Vector2, taste: MouseButton) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = taste
		ereignis.position = wo
		ereignis.global_position = wo
		ereignis.pressed = gedrueckt
		ereignis.button_mask = MOUSE_BUTTON_MASK_LEFT if gedrueckt \
			and taste == MOUSE_BUTTON_LEFT else 0
		_viewport.push_input(ereignis, true)
	await wait_process_frames(1)


## Drückt [param taste] und lässt sie los, mit [param shift] zusammen mit Umschalt.
func _taste(taste: Key, shift: bool = false) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = taste
		ereignis.physical_keycode = taste
		ereignis.unicode = 32 if taste == KEY_SPACE else 0
		ereignis.shift_pressed = shift
		ereignis.pressed = gedrueckt
		_viewport.push_input(ereignis)
	await wait_process_frames(1)
