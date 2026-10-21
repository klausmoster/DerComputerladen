extends GutTest

## Prüft den Zeitstrahl der Werkstatt (Feature 002, T050; contracts/werkstatt.md, „Zeitstrahl
## (TimelineView)“): Umrechnung Tag ↔ Pixel bei mehreren Zoomstufen, Zoom und Verschieben, Stapeln
## überlappender Marken, Ziehen mit genau einem event_moved, kein Ziehen bei jährlichen Ereignissen
## und die Vorschau, die V10 meldet, ohne den Katalog zu ändern. Dazu Doppelklick, Rechtsklick und
## Hinweise.
##
## Der Zeitstrahl liest catalog_us4_zeitstrahl.json über einen eigenen CatalogEditor; gespeichert
## wird nie. Mauseingaben gehen direkt an _gui_input(), mit Positionen im Zeitstrahl, so wie Godot
## sie schickt. Wie er aussieht, prüft Klaus von Hand (quickstart.md, Abschnitt 4.3).

const KATALOG := "res://test/fixtures/catalog_us4_zeitstrahl.json"
const THEMA := preload("res://tools/werkstatt/werkstatt_theme.tres")
## Mitte der ersten Unterzeile der ersten Zeile, Hardware; sie hängt nicht am Zoom.
const HARDWARE_Y := TimelineView.AXIS_HEIGHT + TimelineView.ROW_PADDING \
	+ TimelineView.LANE_HEIGHT / 2.0

var _zeitstrahl: TimelineView
var _editor: CatalogEditor


func before_each() -> void:
	_editor = CatalogEditor.new()
	_editor.backup_path = "user://test_timeline_view_sicherung.json"
	assert_eq(_editor.open(KATALOG), OK, "Der Test-Katalog lässt sich lesen.")
	_zeitstrahl = TimelineView.new()
	_zeitstrahl.theme = THEMA
	_zeitstrahl.editor = _editor
	_zeitstrahl.size = Vector2(1000, 400)
	add_child_autofree(_zeitstrahl)
	_zeitstrahl.refresh()


# --- Tag und Pixel, Zoom, Verschieben ---------------------------------------------------------

func test_ganz_herausgezoomt_passt_der_spielzeitraum_in_die_breite() -> void:
	# Arrange und Act: der Zustand nach dem Aufbau
	var flaeche := _zeitstrahl.time_rect()

	# Assert
	assert_eq(_zeitstrahl.visible_from, 0.0)
	assert_almost_eq(_zeitstrahl.days_per_pixel, 5478.0 / flaeche.size.x, 1e-9)
	assert_almost_eq(_zeitstrahl.day_to_x(0.0), flaeche.position.x, 0.001,
		"Der 01.01.1985 steht am linken Rand der Zeitfläche.")
	assert_almost_eq(_zeitstrahl.day_to_x(5478.0), flaeche.end.x, 0.001,
		"Das Ende des 31.12.1999 steht am rechten Rand.")


func test_tag_und_pixel_bei_mehreren_zoomstufen() -> void:
	# Arrange: ganz heraus, ein Tag je Pixel, vier Pixel je Tag, ganz hinein
	var flaeche := _zeitstrahl.time_rect()
	var stufen := [5478.0 / flaeche.size.x, 1.0, 0.25, 31.0 / flaeche.size.x]

	for zoom: float in stufen:
		# Act
		_zeitstrahl.days_per_pixel = zoom
		_zeitstrahl.visible_from = 1000.0

		# Assert
		assert_almost_eq(_zeitstrahl.day_to_x(1000.0), flaeche.position.x, 0.001,
			"visible_from steht am linken Rand (Zoom %s)." % zoom)
		assert_almost_eq(_zeitstrahl.day_to_x(1010.0) - _zeitstrahl.day_to_x(1000.0), 10.0 / zoom,
			0.001, "Zehn Tage sind 10 / days_per_pixel Pixel (Zoom %s)." % zoom)
		for tag: float in [1000.0, 1003.5, 1017.25]:
			assert_almost_eq(_zeitstrahl.x_to_day(_zeitstrahl.day_to_x(tag)), tag, 0.0001,
				"Hin und zurück ergibt %s (Zoom %s)." % [tag, zoom])
	# Bei vier Pixeln je Tag liegt der 1003,5. Tag 14 Pixel rechts vom linken Rand.
	_zeitstrahl.days_per_pixel = 0.25
	assert_almost_eq(_zeitstrahl.day_to_x(1003.5), flaeche.position.x + 14.0, 0.001)


func test_cmd_mausrad_zoomt_um_die_maus_vom_ganzen_zeitraum_bis_zu_einem_monat() -> void:
	# Arrange
	var flaeche := _zeitstrahl.time_rect()
	var maus := Vector2(flaeche.position.x + 300.0, 100.0)
	var tag_unter_maus := _zeitstrahl.x_to_day(maus.x)

	# Act und Assert: eine Raste hinein
	_rad(MOUSE_BUTTON_WHEEL_UP, maus, true)
	assert_lt(_zeitstrahl.days_per_pixel, 5478.0 / flaeche.size.x, "Cmd+Mausrad zoomt hinein.")
	assert_almost_eq(_zeitstrahl.x_to_day(maus.x), tag_unter_maus, 0.001,
		"Der Tag unter der Maus bleibt, wo er ist.")
	# … bis zum Anschlag: ein Monat füllt die Breite (FR-038).
	for i in 40:
		_rad(MOUSE_BUTTON_WHEEL_UP, maus, true)
	assert_almost_eq(_zeitstrahl.days_per_pixel * flaeche.size.x, 31.0, 0.001)
	assert_almost_eq(_zeitstrahl.x_to_day(maus.x), tag_unter_maus, 0.001)
	# … und wieder ganz heraus.
	for i in 40:
		_rad(MOUSE_BUTTON_WHEEL_DOWN, maus, true)
	assert_almost_eq(_zeitstrahl.days_per_pixel * flaeche.size.x, 5478.0, 0.001)
	assert_eq(_zeitstrahl.visible_from, 0.0, "Ganz heraus zeigt den ganzen Zeitraum.")


func test_mausrad_verschiebt_mit_shift_schneller() -> void:
	# Arrange: ein Tag je Pixel, ab dem 01.01.1990
	_zeitstrahl.days_per_pixel = 1.0
	_zeitstrahl.visible_from = 1826.0
	var spanne := _zeitstrahl.time_rect().size.x
	var maus := Vector2(500.0, 100.0)

	# Act und Assert
	_rad(MOUSE_BUTTON_WHEEL_DOWN, maus)
	assert_almost_eq(_zeitstrahl.visible_from, 1826.0 + 0.1 * spanne, 0.001,
		"Eine Raste verschiebt um ein Zehntel der sichtbaren Spanne.")
	_rad(MOUSE_BUTTON_WHEEL_UP, maus, false, true)
	assert_almost_eq(_zeitstrahl.visible_from, 1826.0 - 0.3 * spanne, 0.001,
		"Mit Shift viermal so weit, zurück.")
	# Unter macOS kommt Shift+Mausrad als waagerechtes Rad.
	_rad(MOUSE_BUTTON_WHEEL_RIGHT, maus, false, true)
	assert_almost_eq(_zeitstrahl.visible_from, 1826.0 + 0.1 * spanne, 0.001)
	for i in 30:
		_rad(MOUSE_BUTTON_WHEEL_UP, maus, false, true)
	assert_eq(_zeitstrahl.visible_from, 0.0, "Vor dem 01.01.1985 ist Schluss.")


func test_wischen_waagerecht_verschiebt_wie_das_mausrad() -> void:
	# Arrange: ein Tag je Pixel ab dem 01.01.1990
	_zeitstrahl.days_per_pixel = 1.0
	_zeitstrahl.visible_from = 1826.0
	var spanne := _zeitstrahl.time_rect().size.x

	# Act: Wischen mit zwei Fingern, vier Einheiten nach rechts
	_wischen(Vector2(500.0, 100.0), Vector2(4.0, 0.0))

	# Assert: Eine Einheit zählt wie GESTURE_STEPS Rasten des Mausrads.
	var rasten := 4.0 * TimelineView.GESTURE_STEPS
	assert_almost_eq(_zeitstrahl.visible_from, 1826.0 + rasten * TimelineView.PAN_STEP * spanne,
		0.001)


func test_wischen_senkrecht_rollt_die_zeilen_nur_wenn_sie_nicht_passen() -> void:
	# Arrange: Bei 400 Pixeln Höhe passen alle vier Zeilen hinein.
	var vorher := _mitte("neubaugebiet")

	# Act
	_wischen(vorher, Vector2(0.0, 6.0))

	# Assert
	assert_false(_rollleiste().visible)
	assert_eq(_mitte("neubaugebiet"), vorher, "Passt alles hinein, rollt nichts.")

	# Arrange: so niedrig, dass nur ein Teil der Zeilen hineinpasst
	_zeitstrahl.size = Vector2(1000.0, 120.0)
	assert_true(_rollleiste().visible, "Jetzt erscheint die Rollleiste.")
	var oben := _mitte("neubaugebiet")

	# Act: zwei Einheiten nach unten
	_wischen(oben, Vector2(0.0, 2.0))

	# Assert: Die Zeilen wandern nach oben, und die Rollleiste folgt.
	var weg := 2.0 * TimelineView.GESTURE_STEPS * TimelineView.ROW_SCROLL_STEP
	assert_almost_eq(_rollleiste().value, weg, 0.001)
	assert_almost_eq(_mitte("neubaugebiet").y, oben.y - weg, 0.001)
	assert_eq(_mitte("neubaugebiet").x, oben.x, "Senkrecht verschiebt nicht seitlich.")


func test_cmd_wischen_und_kneifen_zoomen_um_die_maus() -> void:
	# Arrange
	var flaeche := _zeitstrahl.time_rect()
	var maus := Vector2(flaeche.position.x + 300.0, 100.0)
	var tag := _zeitstrahl.x_to_day(maus.x)
	var vorher := _zeitstrahl.days_per_pixel

	# Act und Assert: Cmd+Wischen nach oben zoomt hinein wie Cmd+Mausrad nach oben.
	_wischen(maus, Vector2(0.0, -2.0), true)
	var rasten := -2.0 * TimelineView.GESTURE_STEPS
	assert_almost_eq(_zeitstrahl.days_per_pixel, vorher * pow(TimelineView.ZOOM_STEP, rasten), 1e-9)
	assert_almost_eq(_zeitstrahl.x_to_day(maus.x), tag, 0.001, "Der Tag unter der Maus bleibt.")
	# Kneifen mit den Fingern auseinander zoomt weiter hinein …
	vorher = _zeitstrahl.days_per_pixel
	_kneifen(maus, 1.5)
	assert_almost_eq(_zeitstrahl.days_per_pixel,
		vorher / pow(1.5, TimelineView.MAGNIFY_POWER), 1e-9)
	assert_almost_eq(_zeitstrahl.x_to_day(maus.x), tag, 0.001)
	# … bis zur Grenze von einem Monat, und zusammen wieder heraus bis zum ganzen Zeitraum.
	for i in 10:
		_kneifen(maus, 3.0)
	assert_almost_eq(_zeitstrahl.days_per_pixel * flaeche.size.x, 31.0, 0.001)
	for i in 10:
		_kneifen(maus, 0.2)
	assert_almost_eq(_zeitstrahl.days_per_pixel * flaeche.size.x, 5478.0, 0.001)
	assert_eq(_zeitstrahl.visible_from, 0.0)


func test_waagerechte_leiste_folgt_zoom_mausrad_und_wischen() -> void:
	# Arrange: ganz herausgezoomt füllt der Griff die Bahn.
	var leiste := _waagerechte_leiste()
	var flaeche := _zeitstrahl.time_rect()
	assert_true(leiste.visible, "Die Leiste ist immer da.")
	assert_eq([leiste.min_value, leiste.max_value, leiste.value], [0.0, 5478.0, 0.0])
	assert_almost_eq(leiste.page, 5478.0, 0.001, "Der Griff füllt die ganze Bahn.")

	# Act und Assert: Zoom ändert page, die sichtbaren Tage.
	var maus := Vector2(flaeche.position.x + 300.0, 100.0)
	for i in 6:
		_rad(MOUSE_BUTTON_WHEEL_UP, maus, true)
	assert_almost_eq(leiste.page, flaeche.size.x * _zeitstrahl.days_per_pixel, 0.001)
	assert_lt(leiste.page, 5478.0)
	assert_almost_eq(leiste.value, _zeitstrahl.visible_from, 0.001, "Nach dem Zoom")
	# Mausrad und Wischen ändern value.
	var vorher := leiste.value
	_rad(MOUSE_BUTTON_WHEEL_DOWN, maus)
	assert_gt(leiste.value, vorher, "Das Mausrad schiebt den Griff nach rechts.")
	assert_almost_eq(leiste.value, _zeitstrahl.visible_from, 0.001, "Nach dem Mausrad")
	_wischen(maus, Vector2(-4.0, 0.0))
	assert_almost_eq(leiste.value, _zeitstrahl.visible_from, 0.001, "Nach dem Wischen")
	# Auch nach refresh() stimmt die Leiste.
	_zeitstrahl.refresh()
	assert_almost_eq(leiste.value, _zeitstrahl.visible_from, 0.001, "Nach refresh()")


func test_ziehen_an_der_waagerechten_leiste_verschiebt_die_ansicht() -> void:
	# Arrange: ein Tag je Pixel ab dem 01.01.1985
	_zeitstrahl.days_per_pixel = 1.0
	_zeitstrahl.visible_from = 0.0
	var leiste := _waagerechte_leiste()
	var spanne := _zeitstrahl.time_rect().size.x

	# Act und Assert: Wer am Griff zieht, setzt value; die Ansicht folgt.
	leiste.value = 2000.0
	assert_almost_eq(_zeitstrahl.visible_from, 2000.0, 0.001)
	# Über das Ende hinaus geht es nicht, in denselben Grenzen wie beim Verschieben.
	leiste.value = 99999.0
	assert_almost_eq(_zeitstrahl.visible_from, 5478.0 - spanne, 0.001)
	assert_almost_eq(leiste.value, _zeitstrahl.visible_from, 0.001)


func test_waagerechte_leiste_verdeckt_keine_zeile() -> void:
	# Arrange: so niedrig, dass die Zeilen rollen müssen; dann ganz nach unten
	_zeitstrahl.size = Vector2(1000.0, 150.0)
	var leiste := _waagerechte_leiste()
	var rollleiste := _rollleiste()
	var flaeche := _zeitstrahl.time_rect()
	assert_true(rollleiste.visible)

	# Act
	rollleiste.value = rollleiste.max_value

	# Assert: Die Leiste liegt unten im Zeitstrahl unter der Zeitfläche, von der Spalte bis zur
	# senkrechten Leiste.
	assert_eq(leiste.position.y + leiste.size.y, _zeitstrahl.size.y, "Ganz unten, sichtbar.")
	assert_eq(leiste.position, Vector2(flaeche.position.x, flaeche.end.y))
	assert_eq(leiste.size.x, flaeche.size.x)
	assert_eq(rollleiste.position.y + rollleiste.size.y, leiste.position.y,
		"Die senkrechte Leiste endet, wo die waagerechte beginnt.")
	# Die unterste Zeile, Kalender, steht ganz über der Leiste.
	var marken := _zeitstrahl.mark_rects("weihnachtsgeschaeft")
	assert_eq(marken.size(), 15)
	var unterste := 0.0
	for marke in marken:
		unterste = maxf(unterste, marke.end.y)
	assert_lte(unterste, leiste.position.y, "Keine Marke steht unter der Leiste.")


func test_zoomknoepfe_zoomen_um_die_mitte() -> void:
	# Arrange: ganz herausgezoomt; die Mitte ist der Tag 2739.
	var leiste := _waagerechte_leiste()
	var mitte := _mittlerer_tag()

	# Act und Assert: „+“ halbiert die sichtbaren Tage um die Mitte …
	_knopf("+").pressed.emit()
	assert_almost_eq(_sichtbare_tage(), 5478.0 / 2.0, 0.001)
	assert_almost_eq(_mittlerer_tag(), mitte, 0.001, "Die Mitte bleibt.")
	_knopf("+").pressed.emit()
	assert_almost_eq(_sichtbare_tage(), 5478.0 / 4.0, 0.001)
	assert_almost_eq(_mittlerer_tag(), mitte, 0.001)
	# … „−“ verdoppelt sie, und die Leiste folgt.
	_knopf("−").pressed.emit()
	assert_almost_eq(_sichtbare_tage(), 5478.0 / 2.0, 0.001)
	assert_almost_eq(_mittlerer_tag(), mitte, 0.001)
	assert_almost_eq(leiste.page, _sichtbare_tage(), 0.001)
	assert_almost_eq(leiste.value, _zeitstrahl.visible_from, 0.001)
	# „Alles“ zeigt wieder 1985 bis 1999.
	_knopf("Alles").pressed.emit()
	assert_almost_eq(_sichtbare_tage(), 5478.0, 0.001)
	assert_eq(_zeitstrahl.visible_from, 0.0)
	assert_almost_eq(leiste.page, 5478.0, 0.001)
	assert_eq(leiste.value, 0.0)


func test_zoomknoepfe_sind_an_den_grenzen_gesperrt() -> void:
	# Arrange
	var plus := _knopf("+")
	var minus := _knopf("−")
	var alles := _knopf("Alles")

	# Assert: Ganz herausgezoomt geht nur „+“.
	assert_eq([plus.disabled, minus.disabled, alles.disabled], [false, true, true])

	# Act: bis zum Anschlag hinein
	for i in 10:
		plus.pressed.emit()

	# Assert: bei 31 Tagen ist „+“ gesperrt.
	assert_almost_eq(_sichtbare_tage(), 31.0, 0.001)
	assert_eq([plus.disabled, minus.disabled, alles.disabled], [true, false, false])
	alles.pressed.emit()
	assert_eq([plus.disabled, minus.disabled, alles.disabled], [false, true, true])


func test_zoomknoepfe_stehen_ueber_der_spalte_mit_hinweisen() -> void:
	# Arrange: das Feld über der Spalte, in der Höhe der Achse
	var feld := Rect2(0.0, 0.0, _zeitstrahl.time_rect().position.x, TimelineView.AXIS_HEIGHT)
	var befehl := "Cmd" if OS.get_name() == "macOS" else "Ctrl"

	# Assert
	for text: String in ["−", "+", "Alles"]:
		assert_true(feld.encloses(_knopf(text).get_rect()), "„%s“ steht im Feld." % text)
		assert_eq(_knopf(text).focus_mode, Control.FOCUS_NONE, "„%s“ nimmt keinen Fokus." % text)
	assert_false(_knopf("−").get_rect().intersects(_knopf("+").get_rect()), "nebeneinander")
	assert_false(_knopf("+").get_rect().intersects(_knopf("Alles").get_rect()), "nebeneinander")
	assert_eq(_knopf("+").tooltip_text, "Vergrößern; auch Kneifen oder %s+Mausrad" % befehl)
	assert_eq(_knopf("−").tooltip_text, "Verkleinern; auch Kneifen oder %s+Mausrad" % befehl)
	assert_eq(_knopf("Alles").tooltip_text, "Ganzer Zeitraum 1985 bis 1999")


func test_ziehen_auf_freier_flaeche_verschiebt() -> void:
	# Arrange: zwei Tage je Pixel, ab dem 18.03.1993; im Juni 1996 hat die Zeile Hardware nichts.
	_zeitstrahl.days_per_pixel = 2.0
	_zeitstrahl.visible_from = 3000.0
	var frei := Vector2(_zeitstrahl.day_to_x(_tag(1996, 6, 1)), HARDWARE_Y)
	assert_eq(_zeitstrahl.event_at(frei), "")
	watch_signals(_zeitstrahl)

	# Act
	_ziehen(frei, frei + Vector2(50.0, 0.0))

	# Assert
	assert_almost_eq(_zeitstrahl.visible_from, 2900.0, 0.001,
		"50 Pixel nach rechts sind 100 Tage früher.")
	assert_signal_not_emitted(_zeitstrahl, "event_moved")
	assert_signal_not_emitted(_zeitstrahl, "event_clicked")


# --- Marken und Stapeln ---------------------------------------------------------------------

func test_zwei_ereignisse_am_selben_tag_werden_gestapelt() -> void:
	# Arrange: intel_pentium und pentium_presse liegen beide am 22.03.1993, intel_486 vier Jahre
	# früher in derselben Zeile.
	var flaeche := _zeitstrahl.time_rect()

	for zoom: float in [5478.0 / flaeche.size.x, 1.0, 31.0 / flaeche.size.x]:
		# Act
		_zeitstrahl.days_per_pixel = zoom
		_zeitstrahl.visible_from = maxf(_tag(1993, 3, 22) - 200.0 * zoom, 0.0)

		# Assert
		var pentium := _zeitstrahl.mark_rects("intel_pentium")
		var presse := _zeitstrahl.mark_rects("pentium_presse")
		assert_eq([pentium.size(), presse.size()], [1, 1], "Beide sind zu sehen (Zoom %s)." % zoom)
		if pentium.size() == 1 and presse.size() == 1:
			assert_eq(pentium[0].position.x, presse[0].position.x, "Derselbe Tag (Zoom %s)." % zoom)
			assert_false(pentium[0].intersects(presse[0]), "Untereinander (Zoom %s)." % zoom)
	# Ganz heraus teilt sich intel_486 die erste Unterzeile mit dem Pentium.
	_zeitstrahl.days_per_pixel = 5478.0 / flaeche.size.x
	_zeitstrahl.visible_from = 0.0
	assert_eq(_mitte("intel_486").y, _mitte("intel_pentium").y)
	assert_lt(_mitte("intel_pentium").y, _mitte("pentium_presse").y, "Gleicher Tag: nach Kennung.")


func test_zeitfenster_und_balken_die_sich_ueberlappen_werden_gestapelt() -> void:
	# Arrange: Das Stadtfest liegt im Zeitfenster des Neubaugebiets, die Sonderaktion danach.
	var fenster := _mitte("neubaugebiet")

	# Assert
	assert_ne(_mitte("stadtfest").y, fenster.y, "Das Stadtfest kommt in eine eigene Unterzeile.")
	assert_eq(_mitte("sonderaktion").y, fenster.y, "Die Sonderaktion passt hinter das Fenster.")


func test_marken_je_art() -> void:
	# Assert: FR-037
	assert_eq(_zeitstrahl.mark_rects("weihnachtsgeschaeft").size(), 15,
		"Ein jährliches Ereignis hat in jedem Jahr 1985 bis 1999 eine Marke.")
	assert_eq(_zeitstrahl.mark_rects("zeitungsartikel").size(), 0,
		"„Nur als Folge“ hat keine Marke.")
	var flaeche := _zeitstrahl.time_rect()
	var band := _zeitstrahl.mark_rects("reklamationswelle")[0]
	assert_eq([band.position.x, band.end.x], [flaeche.position.x, flaeche.end.x],
		"Das Band reicht über das ganze Zeitfenster, hier 1985 bis 1999.")
	var punkt := _zeitstrahl.mark_rects("intel_pentium")[0]
	var balken := _zeitstrahl.mark_rects("sonderaktion")[0]
	assert_eq(punkt.size, Vector2(10.0, 10.0), "Ein fixes Ereignis ohne Dauer ist ein Punkt.")
	assert_gt(balken.size.x, 4.0, "Mit 42 Tagen Dauer ein Balken.")


# --- Ziehen und Vorschau --------------------------------------------------------------------

func test_klick_waehlt_ohne_zu_ziehen() -> void:
	# Arrange
	watch_signals(_zeitstrahl)
	var pentium := _mitte("intel_pentium")

	# Act
	_druecken(pentium)
	_bewegen(pentium + Vector2(1.0, 0.0))
	_loslassen(pentium + Vector2(1.0, 0.0))

	# Assert
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_clicked", ["intel_pentium"])
	assert_signal_not_emitted(_zeitstrahl, "event_moved", "Ein Pixel ist noch kein Ziehen.")


func test_ziehen_eines_fixen_ereignisses_meldet_beim_loslassen_genau_einmal() -> void:
	# Arrange: US4, Szenario 1, bei vier Pixeln je Tag ab dem 01.03.1993
	_zeitstrahl.days_per_pixel = 0.25
	_zeitstrahl.visible_from = _tag(1993, 3, 1)
	var start := _mitte("intel_pentium")
	var ziel := Vector2(_zeitstrahl.day_to_x(_tag(1993, 4, 15) + 0.5), start.y)
	watch_signals(_zeitstrahl)

	# Act
	_druecken(start)
	_bewegen(start + Vector2(20.0, 0.0))
	_bewegen(ziel)

	# Assert: Beim Ziehen steht das Datum am Mauszeiger, der Katalog bleibt.
	assert_eq(_zeitstrahl.preview_text(), "15.04.1993", "Tagesgenau am Mauszeiger.")
	assert_null(_zeitstrahl.preview_issue())
	assert_signal_not_emitted(_zeitstrahl, "event_moved")
	assert_eq(_editor.catalog.get_event("intel_pentium").date, _tag(1993, 3, 22))
	_loslassen(ziel)
	assert_signal_emit_count(_zeitstrahl, "event_moved", 1)
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_moved",
		["intel_pentium", &"date", _tag(1993, 4, 15)])
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_clicked", ["intel_pentium"])
	assert_eq(_zeitstrahl.preview_text(), "", "Nach dem Loslassen ist die Vorschau weg.")


func test_ziehen_rundet_auf_den_naechsten_tag() -> void:
	# Arrange: vier Pixel je Tag; drei Pixel sind drei Viertel eines Tags.
	_zeitstrahl.days_per_pixel = 0.25
	_zeitstrahl.visible_from = _tag(1993, 3, 1)
	var start := _mitte("intel_pentium")
	watch_signals(_zeitstrahl)

	# Act
	_ziehen(start, start + Vector2(3.0, 0.0))

	# Assert
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_moved",
		["intel_pentium", &"date", _tag(1993, 3, 23)])


func test_raender_aendern_dauer_und_zeitfenster() -> void:
	# Arrange: ein Tag je Pixel ab dem 01.02.1994; die Sonderaktion beginnt am 10.03.1994.
	_zeitstrahl.days_per_pixel = 1.0
	_zeitstrahl.visible_from = _tag(1994, 2, 1)
	var balken := _zeitstrahl.mark_rects("sonderaktion")[0]
	var ende := Vector2(balken.end.x - 1.0, balken.get_center().y)
	watch_signals(_zeitstrahl)

	# Act und Assert: das Ende des Balkens um sieben Tage nach rechts
	_druecken(ende)
	_bewegen(ende + Vector2(7.0, 0.0))
	assert_eq(_zeitstrahl.preview_text(), "bis 27.04.1994 (49 Tage)")
	_loslassen(ende + Vector2(7.0, 0.0))
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_moved",
		["sonderaktion", &"duration_days", 49])

	# Act und Assert: der Beginn des Zeitfensters der Reklamationswelle, ganz herausgezoomt
	_zeitstrahl.days_per_pixel = 5478.0 / _zeitstrahl.time_rect().size.x
	_zeitstrahl.visible_from = 0.0
	var band := _zeitstrahl.mark_rects("reklamationswelle")[0]
	var anfang := Vector2(band.position.x + 1.0, band.get_center().y)
	_ziehen(anfang, anfang + Vector2(100.0, 0.0))
	assert_signal_emit_count(_zeitstrahl, "event_moved", 2)
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_moved",
		["reklamationswelle", &"window_from", roundi(100.0 * _zeitstrahl.days_per_pixel)])


func test_jaehrliche_ereignisse_lassen_sich_nicht_ziehen() -> void:
	# Arrange: das Weihnachtsgeschäft 1990
	var weihnacht := _mitte("weihnachtsgeschaeft", 5)
	watch_signals(_zeitstrahl)

	# Act
	_druecken(weihnacht)
	_bewegen(weihnacht + Vector2(80.0, 0.0))

	# Assert: FR-039
	assert_eq(_zeitstrahl.preview_text(), "Nur im Formular änderbar")
	assert_null(_zeitstrahl.preview_issue())
	_loslassen(weihnacht + Vector2(80.0, 0.0))
	assert_signal_not_emitted(_zeitstrahl, "event_moved")
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_clicked", ["weihnachtsgeschaeft"])
	assert_string_contains(_zeitstrahl._get_tooltip(weihnacht), "Nur im Formular änderbar.",
		"Auch der Hinweis sagt es.")
	assert_false(_editor.can_undo(), "Der Katalog ist unverändert.")


func test_vorschau_meldet_v10_ohne_den_katalog_zu_aendern() -> void:
	# Arrange: US4, Szenario 2. Das Neubaugebiet bekommt 1 bis 2 Termine mit 365 Tagen Abstand im
	# Zeitfenster vom 01.01.1990 bis 31.12.1993.
	_zeitstrahl.days_per_pixel = 4.0
	_zeitstrahl.visible_from = _tag(1989, 1, 1)
	var rahmen := _zeitstrahl.mark_rects("neubaugebiet")[0]
	var rand := Vector2(rahmen.end.x - 1.0, rahmen.get_center().y)
	var vorher := _editor.catalog.get_event("neubaugebiet").window_to
	var zu_eng := Vector2(_zeitstrahl.day_to_x(_tag(1990, 6, 30)), rand.y)
	watch_signals(_zeitstrahl)

	# Act: das Ende des Zeitfensters in den Juni 1990 ziehen
	_druecken(rand)
	_bewegen(zu_eng)

	# Assert: R16, der Fehler steht schon beim Ziehen am Mauszeiger …
	var meldung := _zeitstrahl.preview_issue()
	assert_not_null(meldung, "Die Vorschau meldet einen Fehler.")
	if meldung != null:
		assert_eq([meldung.rule, meldung.event_id], ["V10", "neubaugebiet"])
	assert_string_starts_with(_zeitstrahl.preview_text(), "bis ")
	# … und der Katalog bleibt, wie er ist.
	assert_eq(_editor.catalog.get_event("neubaugebiet").window_to, vorher)
	assert_false(_editor.is_dirty(), "Nichts ist geändert.")
	assert_false(_editor.can_undo(), "Kein Schritt im Verlauf.")
	assert_eq(_editor.issues().size(), 0, "Die Prüfung des Katalogs kennt den Fehler nicht.")
	# Zurück in den Herbst 1993: Dort passen beide Termine wieder.
	_bewegen(Vector2(_zeitstrahl.day_to_x(_tag(1993, 10, 1)), rand.y))
	assert_null(_zeitstrahl.preview_issue(), "Mit genug Platz verschwindet die Meldung.")
	_bewegen(zu_eng)
	_loslassen(zu_eng)
	assert_signal_emit_count(_zeitstrahl, "event_moved", 1)
	var gemeldet: Array = get_signal_parameters(_zeitstrahl, "event_moved")
	assert_eq(gemeldet.slice(0, 2), ["neubaugebiet", &"window_to"])
	assert_lt(int(gemeldet[2]) - _tag(1990, 1, 1), 365, "Der gemeldete Wert ist der zu enge.")
	assert_eq(_editor.catalog.get_event("neubaugebiet").window_to, vorher,
		"Den Katalog ändert erst die Werkstatt über den CatalogEditor.")


func test_neu_aufbauen_bricht_ein_ziehen_ab() -> void:
	# Arrange: Während des Ziehens ändert sich der Katalog, etwa durch Cmd+Z.
	var pentium := _mitte("intel_pentium")
	watch_signals(_zeitstrahl)
	_druecken(pentium)
	_bewegen(pentium + Vector2(30.0, 0.0))
	assert_ne(_zeitstrahl.preview_text(), "")

	# Act
	_zeitstrahl.refresh()
	_loslassen(pentium + Vector2(30.0, 0.0))

	# Assert
	assert_eq(_zeitstrahl.preview_text(), "")
	assert_signal_not_emitted(_zeitstrahl, "event_moved", "Ein abgebrochenes Ziehen meldet nichts.")


# --- Doppelklick, Rechtsklick, Hinweis ------------------------------------------------------

func test_doppelklick_auf_freie_flaeche_legt_ein_ereignis_an() -> void:
	# Arrange: US4, Szenario 5, ein Tag je Pixel ab dem 01.06.1995
	_zeitstrahl.days_per_pixel = 1.0
	_zeitstrahl.visible_from = _tag(1995, 6, 1)
	var tag := _tag(1996, 3, 14)
	var frei := Vector2(_zeitstrahl.day_to_x(tag + 0.5), HARDWARE_Y)
	assert_eq(_zeitstrahl.event_at(frei), "", "Dort liegt keine Marke.")
	watch_signals(_zeitstrahl)

	# Act: Godot meldet erst einen einfachen Klick, dann einen mit double_click.
	_doppelklick(frei)

	# Assert
	assert_signal_emit_count(_zeitstrahl, "create_requested", 1)
	assert_signal_emitted_with_parameters(_zeitstrahl, "create_requested", ["hardware", tag])


func test_doppelklick_auf_eine_marke_legt_nichts_an() -> void:
	# Arrange
	watch_signals(_zeitstrahl)

	# Act
	_doppelklick(_mitte("intel_pentium"))

	# Assert
	assert_signal_not_emitted(_zeitstrahl, "create_requested")
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_clicked", ["intel_pentium"])


func test_doppelklick_in_ein_band_meint_die_zeile() -> void:
	# Arrange: Das Band der Reklamationswelle füllt seine ganze Zeile. Rahmen und Bänder sind nur
	# Linien um ein Zeitfenster; ihre Fläche gilt beim Doppelklick als frei.
	var band := _zeitstrahl.mark_rects("reklamationswelle")[0]
	var mitte := band.get_center()
	watch_signals(_zeitstrahl)

	# Act
	_doppelklick(mitte)

	# Assert
	assert_signal_emitted_with_parameters(_zeitstrahl, "create_requested",
		["reklamation", floori(_zeitstrahl.x_to_day(mitte.x))])


func test_rechtsklick_oeffnet_das_menue_mit_bearbeiten_duplizieren_loeschen() -> void:
	# Arrange: US4, Szenario 4
	var menue := _menue()
	watch_signals(_zeitstrahl)

	# Act und Assert: auf freier Fläche kein Menü …
	_rechtsklick(Vector2(_zeitstrahl.day_to_x(_tag(1996, 6, 1)), HARDWARE_Y))
	assert_false(menue.visible)
	# … auf einer Marke das Menü, und das Ereignis ist gewählt.
	_rechtsklick(_mitte("intel_pentium"))
	assert_true(menue.visible)
	var eintraege := []
	for i in menue.item_count:
		eintraege.append(menue.get_item_text(i))
	assert_eq(eintraege, ["Bearbeiten", "Duplizieren", "Löschen"])
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_clicked", ["intel_pentium"])
	menue.hide()

	# Act und Assert: die Einträge
	menue.id_pressed.emit(TimelineView.MenuItem.DELETE)
	assert_signal_emitted_with_parameters(_zeitstrahl, "delete_requested", ["intel_pentium"])
	assert_not_null(_editor.catalog.get_event("intel_pentium"),
		"Vor dem Löschen fragt die Werkstatt nach (FR-036).")
	menue.id_pressed.emit(TimelineView.MenuItem.EDIT)
	assert_signal_emitted_with_parameters(_zeitstrahl, "edit_requested", ["intel_pentium"])
	menue.id_pressed.emit(TimelineView.MenuItem.DUPLICATE)
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_created", ["intel_pentium_2"])
	assert_not_null(_editor.catalog.get_event("intel_pentium_2"),
		"Duplizieren geht wie in der Liste über den CatalogEditor.")


func test_hinweis_nennt_titel_art_datum_oder_fenster_und_chance() -> void:
	# Act
	var punkt := _zeitstrahl._get_tooltip(_mitte("intel_pentium"))
	var balken := _zeitstrahl._get_tooltip(_mitte("sonderaktion"))
	var rahmen := _zeitstrahl._get_tooltip(_mitte("neubaugebiet"))
	var band := _zeitstrahl._get_tooltip(_mitte("reklamationswelle"))
	var frei := _zeitstrahl._get_tooltip(Vector2(_zeitstrahl.day_to_x(_tag(1996, 6, 1)),
		HARDWARE_Y))

	# Assert: US4, Szenario 3
	assert_eq(punkt, "Intel Pentium erscheint\nfix · 22.03.1993")
	assert_eq(balken, "Sonderaktion\nfix · 10.03.1994 bis 20.04.1994 (42 Tage)")
	assert_eq(rahmen, "Neubaugebiet am Stadtrand\nbeim Start gesetzt · Zeitfenster 01.01.1990 bis "
		+ "31.12.1993\nAnzahl 1 bis 2, Mindestabstand 365 Tage")
	assert_eq(band, "Reklamationswelle\nüber Wahrscheinlichkeit · Zeitfenster 01.01.1985 bis "
		+ "31.12.1999\nChance 3 % pro Monat")
	assert_eq(frei, "", "Auf freier Fläche kein Hinweis.")


# --- Filter der Liste (T074) -----------------------------------------------------------------
#
# Die Regel kennt nur die Liste; der Zeitstrahl fragt event_filter je Ereignis. Die Tests geben
# ihm deshalb eigene kleine Regeln. Wie die Liste ihre Regel liefert, prüft test_werkstatt_scene.gd.


func test_filter_zeigt_nur_passende_marken_und_zeilen_mit_treffern() -> void:
	# Arrange: ohne Filter alle vier Zeilen
	assert_eq(_zeitstrahl.row_titles(),
		PackedStringArray(["Hardware", "Lokal", "Reklamation", "Kalender"]))

	# Act: nur Hardware
	_zeitstrahl.event_filter = func(ereignis: TimelineEvent) -> bool:
		return ereignis.category == "hardware"

	# Assert: nur die passenden Marken, nur die Zeile mit Treffern, der Hinweis zählt mit.
	assert_eq(_zeitstrahl.row_titles(), PackedStringArray(["Hardware"]))
	assert_eq(_zeitstrahl.marked_events(),
		PackedStringArray(["intel_486", "intel_pentium", "pentium_presse"]))
	assert_true(_zeitstrahl.is_filtered())
	assert_eq(_zeitstrahl.filter_text(), "Filter: 3 von 9")


func test_ohne_filter_bleiben_leere_zeilen_mit_filter_nicht() -> void:
	# Arrange: eine Kategorie ohne Ereignis, nur im Speicher
	_editor.add_category("Leer")
	_zeitstrahl.refresh()
	assert_has(_zeitstrahl.row_titles(), "Leer",
		"Ohne Filter bleibt die leere Zeile; ein Doppelklick dort legt ein Ereignis an.")

	# Act: ein Filter, der jedes Ereignis durchlässt
	_zeitstrahl.event_filter = func(_ereignis: TimelineEvent) -> bool: return true

	# Assert: Gefiltert zählen nur Zeilen mit Marke.
	assert_does_not_have(_zeitstrahl.row_titles(), "Leer")
	assert_eq(_zeitstrahl.row_titles().size(), 4)
	assert_eq(_zeitstrahl.filter_text(), "Filter: 9 von 9")

	# Act und Assert: Filter aufheben stellt alles wieder her.
	_zeitstrahl.event_filter = Callable()
	assert_has(_zeitstrahl.row_titles(), "Leer")
	assert_eq(_zeitstrahl.row_titles().size(), 5)
	assert_false(_zeitstrahl.is_filtered())
	assert_eq(_zeitstrahl.filter_text(), "", "Ohne Filter kein Hinweis.")


func test_ohne_kategorie_nur_wenn_dort_etwas_passt() -> void:
	# Arrange: Der Pentium bekommt eine Kategorie, die es nicht gibt (V05).
	_editor.set_event_field("intel_pentium", &"category", "gibt_es_nicht")
	_zeitstrahl.refresh()
	assert_has(_zeitstrahl.row_titles(), "Ohne Kategorie")
	var spalte := _zeitstrahl.time_rect().position.x

	# Act: ein Filter ohne den Pentium
	_zeitstrahl.event_filter = func(ereignis: TimelineEvent) -> bool:
		return ereignis.id != "intel_pentium"

	# Assert: Die Zeile fällt weg; die Spalte der Kategorien bleibt so breit, damit nichts springt.
	assert_does_not_have(_zeitstrahl.row_titles(), "Ohne Kategorie")
	assert_eq(_zeitstrahl.time_rect().position.x, spalte)

	# Act und Assert: ein Filter nur mit dem Pentium
	_zeitstrahl.event_filter = func(ereignis: TimelineEvent) -> bool:
		return ereignis.id == "intel_pentium"
	assert_eq(_zeitstrahl.row_titles(), PackedStringArray(["Ohne Kategorie"]))


func test_hinweis_steht_im_streifen_unter_der_achse() -> void:
	# Arrange
	var vorher := _mitte("intel_pentium")
	watch_signals(_zeitstrahl)

	# Act
	_zeitstrahl.event_filter = func(ereignis: TimelineEvent) -> bool:
		return ereignis.category == "hardware"

	# Assert: Die Zeilen rücken um den Streifen nach unten.
	assert_eq(_mitte("intel_pentium"), vorher + Vector2(0.0, TimelineView.FILTER_HEIGHT))
	# Im Streifen liegt keine Marke, ein Doppelklick legt dort nichts an, und der Hinweis über
	# ihm erklärt den Filter.
	var streifen := Vector2(vorher.x, TimelineView.AXIS_HEIGHT + TimelineView.FILTER_HEIGHT / 2.0)
	assert_eq(_zeitstrahl.event_at(streifen), "")
	_doppelklick(streifen)
	assert_signal_not_emitted(_zeitstrahl, "create_requested")
	assert_eq(_zeitstrahl._get_tooltip(streifen), TimelineView.FILTER_TOOLTIP)


func test_auswahl_und_ziehen_gehen_auch_gefiltert() -> void:
	# Arrange: nur Hardware, bei vier Pixeln je Tag ab dem 01.03.1993
	_zeitstrahl.event_filter = func(ereignis: TimelineEvent) -> bool:
		return ereignis.category == "hardware"
	_zeitstrahl.days_per_pixel = 0.25
	_zeitstrahl.visible_from = _tag(1993, 3, 1)
	var start := _mitte("intel_pentium")
	var ziel := Vector2(_zeitstrahl.day_to_x(_tag(1993, 4, 15) + 0.5), start.y)
	watch_signals(_zeitstrahl)

	# Act
	_druecken(start)
	_bewegen(start + Vector2(20.0, 0.0))
	_bewegen(ziel)
	_loslassen(ziel)

	# Assert: wie ohne Filter; ein Klick wählt, das Loslassen meldet genau einmal.
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_clicked", ["intel_pentium"])
	assert_signal_emit_count(_zeitstrahl, "event_moved", 1)
	assert_signal_emitted_with_parameters(_zeitstrahl, "event_moved",
		["intel_pentium", &"date", _tag(1993, 4, 15)])

	# Act und Assert: Der Katalog nimmt es an; die Marke steht am neuen Tag, der Filter gilt weiter.
	_editor.set_event_field("intel_pentium", &"date", _tag(1993, 4, 15))
	_zeitstrahl.refresh()
	assert_almost_eq(_mitte("intel_pentium").x, ziel.x, 1.0)
	assert_eq(_zeitstrahl.filter_text(), "Filter: 3 von 9")
	# Ein gewähltes Ereignis, das nicht passt, ist hier nicht zu sehen, wie in der Liste.
	_zeitstrahl.select_event("stadtfest")
	assert_eq(_zeitstrahl.mark_rects("stadtfest").size(), 0)


func test_ereignis_das_nicht_mehr_passt_verschwindet() -> void:
	# Arrange: eine Regel über den Titel, wie die Suche der Liste
	_zeitstrahl.event_filter = func(ereignis: TimelineEvent) -> bool:
		return ereignis.title.to_lower().contains("pentium")
	assert_eq(_zeitstrahl.marked_events(), PackedStringArray(["intel_pentium", "pentium_presse"]))

	# Act: ein neuer Titel; danach baut die Werkstatt den Zeitstrahl neu (catalog_changed).
	_editor.set_event_field("pentium_presse", &"title", "Presse zum neuen Prozessor")
	_zeitstrahl.refresh()

	# Assert
	assert_eq(_zeitstrahl.marked_events(), PackedStringArray(["intel_pentium"]))
	assert_eq(_zeitstrahl.filter_text(), "Filter: 1 von 9")


# --- Helfer -----------------------------------------------------------------------------------

func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


## Mitte der [param index]-ten sichtbaren Marke eines Ereignisses.
func _mitte(kennung: String, index: int = 0) -> Vector2:
	var marken := _zeitstrahl.mark_rects(kennung)
	if index >= marken.size():
		fail_test("Von %s ist keine Marke %d zu sehen." % [kennung, index])
		return Vector2.ZERO
	return marken[index].get_center()


## Das Menü beim Rechtsklick; es hängt als internes Kind am Zeitstrahl.
func _menue() -> PopupMenu:
	for kind in _zeitstrahl.get_children(true):
		if kind is PopupMenu:
			return kind
	fail_test("Der Zeitstrahl hat kein Menü.")
	return PopupMenu.new()


func _druecken(stelle: Vector2, doppelt: bool = false) -> void:
	var knopf := InputEventMouseButton.new()
	knopf.button_index = MOUSE_BUTTON_LEFT
	knopf.pressed = true
	knopf.double_click = doppelt
	knopf.position = stelle
	_zeitstrahl._gui_input(knopf)


func _bewegen(stelle: Vector2) -> void:
	var bewegung := InputEventMouseMotion.new()
	bewegung.position = stelle
	bewegung.button_mask = MOUSE_BUTTON_MASK_LEFT
	_zeitstrahl._gui_input(bewegung)


func _loslassen(stelle: Vector2) -> void:
	var knopf := InputEventMouseButton.new()
	knopf.button_index = MOUSE_BUTTON_LEFT
	knopf.position = stelle
	_zeitstrahl._gui_input(knopf)


func _ziehen(von: Vector2, nach: Vector2) -> void:
	_druecken(von)
	_bewegen(nach)
	_loslassen(nach)


func _doppelklick(stelle: Vector2) -> void:
	_druecken(stelle)
	_loslassen(stelle)
	_druecken(stelle, true)
	_loslassen(stelle)


## Eine Raste des Mausrads; [param zoom] hält Cmd bzw. Ctrl. Beide sind gesetzt, damit der Test
## unter macOS, Windows und Linux gleich läuft.
func _rad(knopf: MouseButton, stelle: Vector2, zoom: bool = false, shift: bool = false) -> void:
	var rad := InputEventMouseButton.new()
	rad.button_index = knopf
	rad.pressed = true
	rad.position = stelle
	rad.meta_pressed = zoom
	rad.ctrl_pressed = zoom
	rad.shift_pressed = shift
	_zeitstrahl._gui_input(rad)


func _rechtsklick(stelle: Vector2) -> void:
	var knopf := InputEventMouseButton.new()
	knopf.button_index = MOUSE_BUTTON_RIGHT
	knopf.pressed = true
	knopf.position = stelle
	_zeitstrahl._gui_input(knopf)


## Wischen mit zwei Fingern auf dem Trackpad; [param zoom] hält Cmd bzw. Ctrl.
func _wischen(stelle: Vector2, weg: Vector2, zoom: bool = false) -> void:
	var geste := InputEventPanGesture.new()
	geste.position = stelle
	geste.delta = weg
	geste.meta_pressed = zoom
	geste.ctrl_pressed = zoom
	_zeitstrahl._gui_input(geste)


## Kneifen auf dem Trackpad; ein Faktor über 1 heißt Finger auseinander.
func _kneifen(stelle: Vector2, faktor: float) -> void:
	var geste := InputEventMagnifyGesture.new()
	geste.position = stelle
	geste.factor = faktor
	_zeitstrahl._gui_input(geste)


## Die senkrechte Rollleiste; sie hängt als internes Kind am Zeitstrahl.
func _rollleiste() -> VScrollBar:
	for kind in _zeitstrahl.get_children(true):
		if kind is VScrollBar:
			return kind
	fail_test("Der Zeitstrahl hat keine Rollleiste.")
	return VScrollBar.new()


## Der Zoom-Knopf mit dem Text [param text]; die Knöpfe sind interne Kinder.
func _knopf(text: String) -> Button:
	for kind in _zeitstrahl.get_children(true):
		if kind is Button and kind.text == text:
			return kind
	fail_test("Der Zeitstrahl hat keinen Knopf „%s“." % text)
	return Button.new()


## Wie viele Tage die Zeitfläche gerade zeigt.
func _sichtbare_tage() -> float:
	return _zeitstrahl.time_rect().size.x * _zeitstrahl.days_per_pixel


## Der Tag in der Mitte der Zeitfläche.
func _mittlerer_tag() -> float:
	var flaeche := _zeitstrahl.time_rect()
	return _zeitstrahl.x_to_day(flaeche.position.x + flaeche.size.x / 2.0)


## Die waagerechte Leiste durch die Jahre, ebenfalls ein internes Kind.
func _waagerechte_leiste() -> HScrollBar:
	for kind in _zeitstrahl.get_children(true):
		if kind is HScrollBar:
			return kind
	fail_test("Der Zeitstrahl hat keine waagerechte Leiste.")
	return HScrollBar.new()
