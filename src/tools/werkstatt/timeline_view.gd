class_name TimelineView
extends Control

## Der Zeitstrahl der Werkstatt (FR-037 bis FR-039; contracts/werkstatt.md, „Zeitstrahl
## (TimelineView)“; research.md, R16): der Katalog auf einer Achse von 1985 bis 1999, eine Zeile je
## Kategorie. Fixe Ereignisse sind Punkte oder, mit Dauer, Balken; jährliche stehen in jedem ihrer
## Jahre; gesetzte zeigen ihr Zeitfenster als Rahmen, Ereignisse über Wahrscheinlichkeit ein Band
## mit ihrer Chance. „Nur als Folge“ hat keine Marke.
##
## Ein einziges Control zeichnet alles selbst in _draw(), statt je Ereignis einen Node anzulegen.
## Bei 500 Ereignissen bleibt das schnell, und gezeichnet wird nur, was gerade zu sehen ist.
## _gui_input() nimmt die Maus entgegen: Mausrad zum Verschieben, mit Cmd bzw. Ctrl zum Zoomen,
## Ziehen von Marken und Rändern, Doppelklick und Rechtsklick; dazu auf dem Trackpad Wischen mit
## zwei Fingern und Kneifen. Hinweise liefert _get_tooltip(). Zwei Leisten und drei Zoom-Knöpfe
## in der Ecke oben links hängen als interne Kinder daran.
##
## Den Katalog ändert der Zeitstrahl nicht selbst. Beim Ziehen prüft er eine Kopie des Ereignisses
## (Vorschau), und erst beim Loslassen meldet er den neuen Wert mit event_moved; die Werkstatt gibt
## ihn an den CatalogEditor. Wie Liste und Formular meldet er nach oben (Signale) und wird von
## oben aufgerufen (refresh(), select_event()). Nur „Duplizieren“ im Menü ruft den CatalogEditor
## selbst auf, wie der Knopf in der Liste.
##
## Koordinaten: Tage sind Tagesindizes wie in GameDate (01.01.1985 = 0). Ein Tag d belegt auf der
## Achse die Strecke von d bis d + 1. Links steht die Spalte mit den Kategorien, oben die Achse,
## unten die waagerechte Leiste durch die Jahre; dazwischen liegt die Zeitfläche, und an ihrem
## linken Rand steht der Tag visible_from.
##
## Filter (T074): Der Zeitstrahl zeigt, was die Liste nach Suche, Art und Kategorie zeigt. Die
## Regel kennt nur die Liste; der Zeitstrahl bekommt sie als event_filter und fragt sie je
## Ereignis. Gefiltert zeigt er nur Zeilen mit mindestens einer Marke, und ein Streifen unter der
## Achse sagt, wie viele Ereignisse passen.

## Klaus hat auf eine Marke geklickt, auch mit rechts; die Werkstatt wählt das Ereignis.
signal event_clicked(id: String)
## Ein Ziehen ist zu Ende: Feld und neuer Wert für CatalogEditor.set_event_field(). Kommt beim
## Loslassen genau einmal, und nur, wenn sich der Wert geändert hat.
signal event_moved(id: String, field: StringName, value: Variant)
## Doppelklick auf freie Fläche einer Zeile: ein neues fixes Ereignis an diesem Tag in dieser
## Kategorie.
signal create_requested(category: String, day: int)
## „Bearbeiten“ im Menü: Die Werkstatt wählt das Ereignis und setzt den Fokus ins Formular.
signal edit_requested(id: String)
## „Duplizieren“ im Menü hat über den CatalogEditor eine Kopie angelegt; wie bei EventList wählt
## die Werkstatt sie und setzt den Fokus in den Titel.
signal event_created(id: String)
## „Löschen“ im Menü. Die Werkstatt fragt nach und nennt die Verweise (FR-036), wie bei EventList.
signal delete_requested(id: String)

## Wie eine Marke aussieht.
enum Shape { POINT, BAR, FRAME, BAND }
## Welcher Teil einer Marke unter der Maus liegt: die Fläche oder der linke bzw. rechte Rand.
enum Part { NONE, BODY, START, END }
## Was ein Ziehen gerade tut.
enum Drag { NONE, PAN, DATE, DURATION, WINDOW_FROM, WINDOW_TO, LOCKED }
## Die Einträge des Menüs beim Rechtsklick.
enum MenuItem { EDIT, DUPLICATE, DELETE }

## Tage im Spielzeitraum: vom 01.01.1985 bis zum Ende des 31.12.1999 (Tag 5477).
const TOTAL_DAYS := TimelineRun.LAST_DAY + 1
## So weit geht der Zoom hinein: Ein Monat füllt die Breite (FR-038).
const MIN_VISIBLE_DAYS := 31.0
## Zoomfaktor je Raste des Mausrads.
const ZOOM_STEP := 1.4
## Verschieben je Raste: ein Zehntel der sichtbaren Spanne, mit Shift vier Zehntel.
const PAN_STEP := 0.1
const PAN_STEP_FAST := 0.4
## Trackpad, Wischen mit zwei Fingern (InputEventPanGesture): macOS liefert viele kleine Schritte,
## ein normales Wischen summiert sich auf etwa 6 bis 10 Einheiten. Eine Einheit zählt wie eine
## halbe Raste des Mausrads, ein Wischen also wie drei bis fünf Rasten.
const GESTURE_STEPS := 0.5
## Kneifen (InputEventMagnifyGesture): Der Faktor eines Schritts wirkt quadratisch. Finger doppelt
## so weit auseinander vergrößern vierfach; so reichen wenige Griffe vom ganzen Zeitraum bis zu
## einem Monat.
const MAGNIFY_POWER := 2.0
## Ab so vielen Pixeln je Tag zeigt die Achse Monate, Tagesstriche und Tageszahlen.
const MONTHS_FROM := 0.7
const DAY_TICKS_FROM := 3.0
const DAY_NUMBERS_FROM := 18.0
## Was das Ziehen eines jährlichen Ereignisses am Mauszeiger sagt (FR-039).
const LOCKED_HINT := "Nur im Formular änderbar"
## Der Hinweis über dem Streifen „Filter: …“ (T074).
const FILTER_TOOLTIP := "Der Zeitstrahl zeigt nur, was die Liste nach Suche, Art und " \
	+ "Kategorie zeigt."
## Zoom-Knöpfe „−“ und „+“ in der Ecke über der Spalte: Faktor je Klick.
const BUTTON_ZOOM := 2.0

## Maße in logischen Pixeln (Style-Guide, „Werkzeuge“).
const AXIS_HEIGHT := 44.0
## Mit Filter liegt unter der Achse ein Streifen mit dem Hinweis „Filter: 12 von 500“.
const FILTER_HEIGHT := 22.0
## Beschriftungen der Achse stehen 4 Pixel hinter ihrem Strich und enden 2 Pixel vor dem nächsten.
const AXIS_PADDING := 4.0
const SECTION_GAP := 2.0
const DAY_TICK := 5.0
const LANE_HEIGHT := 24.0
## So weit rollt eine Raste die Zeilen beim senkrechten Wischen: eine Unterzeile.
const ROW_SCROLL_STEP := LANE_HEIGHT
const ROW_PADDING := 2.0
const LABEL_MIN_WIDTH := 100.0
const LABEL_MAX_WIDTH := 220.0
const LABEL_PADDING := 8.0
const SWATCH_SIZE := 10.0
const SWATCH_GAP := 6.0
## Abstand der Zoom-Knöpfe untereinander und zum Rand ihres Felds.
const BUTTON_GAP := 4.0
## Punkte und Balken sind 10 Pixel hoch, Punkte auch 10 breit; kürzere Marken werden 4 breit.
const POINT_SIZE := 10.0
const BAR_HEIGHT := 10.0
const MIN_MARK_WIDTH := 4.0
## Zeitfenster als Rahmen von 2 Pixeln, Wahrscheinlichkeit als Band von 4 Pixeln Höhe.
const FRAME_WIDTH := 2.0
const BAND_HEIGHT := 4.0
## So viel Platz bleibt mindestens zwischen zwei Marken einer Unterzeile, sonst wird gestapelt.
const MARK_GAP := 6.0
## Abstand des Titels zur Marke; so bleibt er auch neben der Linie der Auswahl frei.
const TITLE_GAP := 8.0
## So weit neben einem Rand greift die Maus ihn noch.
const EDGE_GRAB := 5.0
const POINT_GRAB := 2.0
## Ab so vielen Pixeln Bewegung wird aus einem Klick ein Ziehen.
const DRAG_THRESHOLD := 3.0
## Auswahl: eine Linie von 2 Pixeln mit 2 Pixeln Abstand um die Marke.
const SELECTION_LINE := 2.0
const SELECTION_GAP := 2.0
const HOVER_GROW := 2.0
## Lage der Texte beim Ziehen relativ zum Mauszeiger und ihre Innenabstände.
const CURSOR_OFFSET := Vector2(16.0, 20.0)
const BOX_PADDING := Vector2(6.0, 3.0)
const ERROR_WIDTH := 320.0

## Farbrollen aus dem Style-Guide, Abschnitt „Werkzeuge“; Farben kommen nur aus UiPalette.
const COLOR_GROUND := UiPalette.PAPIER               # Grund
const COLOR_SECOND_ROW := UiPalette.ENDLOS_GRUEN     # jede zweite Zeile
const COLOR_TEXT := UiPalette.TUSCHE                 # Text, Konturen, Auswahl
const COLOR_HOVER := UiPalette.SIGNALGELB            # Überfahren
const COLOR_DRAG := UiPalette.SIGNALGELB             # Ziehen, mit Kontur in tusche
const COLOR_ERROR := UiPalette.KASSENROT             # Fehler als gefülltes Feld …
const COLOR_ERROR_TEXT := UiPalette.PAPIER           # … mit Text in papier
const COLOR_YEAR_LINE := UiPalette.GEHAEUSE          # Jahresgrenzen in den Zeilen
const COLOR_MONTH_LINE := UiPalette.GEHAEUSE_HELL    # Monatsgrenzen in den Zeilen
const COLOR_MUTED := UiPalette.GEHAEUSE_DUNKEL       # gedämpfter Text: Hinweis auf den Filter

## Die Rasten des Mausrads, auch die waagerechten.
const WHEELS := [
	MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT,
	MOUSE_BUTTON_WHEEL_RIGHT,
]
## Welches Ziehen ein Feld ändert.
const DRAG_BY_FIELD := {
	&"date": Drag.DATE,
	&"duration_days": Drag.DURATION,
	&"window_from": Drag.WINDOW_FROM,
	&"window_to": Drag.WINDOW_TO,
}

## Der 01.01. jedes Jahres von 1985 bis 2000 und der Erste jedes Monats von Januar 1985 bis Januar
## 2000, als Tagesindizes; für Achse und Raster.
static var _year_starts := _first_days(12)
static var _month_starts := _first_days(1)

## Der einzige, der den Katalog ändert; der Zeitstrahl liest daraus.
var editor: CatalogEditor
## Tagesindex am linken Rand der Zeitfläche. Die waagerechte Leiste folgt.
var visible_from: float = 0.0:
	set(value):
		visible_from = value
		_sync_hscroll()
		queue_redraw()
## Zoom in Tagen je Pixel. Ganz herausgezoomt passen 1985–1999 genau in die Breite der Zeitfläche.
## Jeder neue Wert stapelt die Marken neu, denn ihre Breiten hängen am Zoom.
var days_per_pixel: float = 1.0:
	set(value):
		days_per_pixel = maxf(value, 0.000001)
		_fit_all = days_per_pixel >= _max_days_per_pixel() - 0.000001
		_stack()
		_update_zoom_buttons()
		queue_redraw()

## Der Filter der Liste (T074): ein Callable, das für ein TimelineEvent sagt, ob es passt, etwa
## EventList.passes. Ein leeres Callable() heißt: kein Filter. Dann zeigt der Zeitstrahl alles,
## auch Kategorien ohne Ereignis, damit ein Doppelklick dort eines anlegen kann. Jeder neue Wert
## baut die Zeilen neu.
var event_filter := Callable():
	set(value):
		event_filter = value
		refresh()

var _rows: Array[Row] = []
## Wie viele Ereignisse beim letzten Aufbau durch den Filter kamen, und wie viele es gibt.
var _filter_passed := 0
var _filter_total := 0
var _label_width := LABEL_MIN_WIDTH
## Was die Namen der Kategorien in der Spalte an Breite brauchen; 0 ohne Zeilen.
var _names_width := 0.0
var _content_height := 0.0
## Ob der ganze Zeitraum zu sehen ist; dann bleibt er es auch, wenn sich die Breite ändert.
var _fit_all := true
var _font: Font = ThemeDB.fallback_font
var _small_size := 12
var _text_size := 14
var _scroll_width := 8.0
var _hscroll_height := 8.0
## Ob _sync_hscroll() gerade die waagerechte Leiste einstellt; was sie dabei meldet, zählt nicht.
var _syncing_hscroll := false
var _selected_id := ""
var _hover: Mark
var _hover_part := Part.NONE
## Letzte Mausposition, für die Texte am Mauszeiger.
var _mouse := Vector2.ZERO
var _menu_event_id := ""
## Wie die Achse die Monate schreibt: 0 gar nicht, 1 mit drei Buchstaben, 2 ausgeschrieben.
var _month_style := 0
## Schriftgröße → { Text → Breite in Pixeln }, für _text_width(). Eine neue Schrift leert ihn.
var _widths := {}

# Zustand eines Ziehens, vom Drücken bis zum Loslassen.
var _drag := Drag.NONE
var _drag_moved := false
var _press_position := Vector2.ZERO
var _press_from := 0.0
var _drag_mark: Mark
var _drag_row: Row
var _drag_event: TimelineEvent
var _drag_field := &""
var _drag_original := 0
var _drag_value := 0
var _preview_ready := false
var _preview_issue: CatalogIssue

var _scroll := VScrollBar.new()
var _hscroll := HScrollBar.new()
var _zoom_out_button := Button.new()
var _zoom_in_button := Button.new()
var _zoom_all_button := Button.new()
var _menu := PopupMenu.new()


## Eine Marke: ein Ereignis oder, bei jährlichen, eines seiner Vorkommen.
class Mark:
	var event: TimelineEvent
	var shape := Shape.POINT
	## Erster und letzter Tag, beide einschließlich.
	var first := 0
	var last := 0
	var color := Color()
	## Unterzeile in ihrer Zeile, gezählt ab 0.
	var lane := 0
	## Anfang und Ende in Pixeln ab dem 01.01.1985 beim aktuellen Zoom und der Anfang der nächsten
	## Marke derselben Unterzeile, INF ohne eine; das setzt _stack().
	var start_px := 0.0
	var end_px := 0.0
	var next_px := INF
	## Beschriftung und ihre Breite; bei Bändern dazu die kurze Form, nur die Chance.
	var label := ""
	var label_width := 0.0
	var short_label := ""
	var short_width := 0.0


## Eine Zeile: eine Kategorie mit ihren Marken, gestapelt in Unterzeilen.
class Row:
	## null in der Zeile für Ereignisse ohne bekannte Kategorie (V05).
	var category: EventCategory
	var title := ""
	var color := Color()
	var marks: Array[Mark] = []
	var lanes := 1
	## Oberkante und Höhe in der Fläche der Zeilen, ohne das Rollen.
	var top := 0.0
	var height := 0.0


func _init() -> void:
	clip_contents = true
	_scroll.visible = false
	_scroll.value_changed.connect(func(_value: float) -> void: queue_redraw())
	_scroll.minimum_size_changed.connect(_on_parts_resized)
	# Interne Kinder gehören zum Control selbst: Sie stehen in keiner Szene und zählen bei
	# get_children() nicht mit.
	add_child(_scroll, false, INTERNAL_MODE_FRONT)
	# Die waagerechte Leiste zeigt die Jahre: value ist visible_from, page die sichtbaren Tage.
	# step 0 lässt Bruchteile von Tagen zu, wie visible_from sie hat.
	_hscroll.step = 0.0
	_hscroll.min_value = 0.0
	_hscroll.max_value = TOTAL_DAYS
	_hscroll.value_changed.connect(_on_hscroll_changed)
	_hscroll.minimum_size_changed.connect(_on_parts_resized)
	add_child(_hscroll, false, INTERNAL_MODE_FRONT)
	# Die Zoom-Knöpfe in der Ecke über der Spalte. Sie nehmen keinen Fokus, damit ein Feld im
	# Formular seinen behält; ihr Aussehen kommt aus dem Theme, die Schriftgröße wie bei der Achse.
	var command := "Cmd" if OS.get_name() == "macOS" else "Ctrl"
	_zoom_out_button.text = "−"
	_zoom_out_button.tooltip_text = "Verkleinern; auch Kneifen oder %s+Mausrad" % command
	_zoom_out_button.pressed.connect(_on_zoom_out)
	_zoom_in_button.text = "+"
	_zoom_in_button.tooltip_text = "Vergrößern; auch Kneifen oder %s+Mausrad" % command
	_zoom_in_button.pressed.connect(_on_zoom_in)
	_zoom_all_button.text = "Alles"
	_zoom_all_button.tooltip_text = "Ganzer Zeitraum 1985 bis 1999"
	_zoom_all_button.pressed.connect(_on_zoom_all)
	for button in _zoom_buttons():
		button.focus_mode = FOCUS_NONE
		button.minimum_size_changed.connect(_on_parts_resized)
		add_child(button, false, INTERNAL_MODE_FRONT)
	_menu.add_item("Bearbeiten", MenuItem.EDIT)
	_menu.add_item("Duplizieren", MenuItem.DUPLICATE)
	_menu.add_item("Löschen", MenuItem.DELETE)
	_menu.id_pressed.connect(_on_menu_id_pressed)
	add_child(_menu, false, INTERNAL_MODE_FRONT)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			# Kommt auch, wenn das Control in den Baum kommt; erst dann kennt es das Theme der
			# Werkstatt mit Schrift und Größen.
			_update_theme()
			refresh()
		NOTIFICATION_RESIZED:
			_update_view()
		NOTIFICATION_MOUSE_EXIT:
			_set_hover(null, Part.NONE)


# --- Für die Werkstatt ------------------------------------------------------------------------

## Baut die Marken aus dem Katalog neu, etwa nach catalog_changed. Zoom und Ausschnitt bleiben. Ein
## Ziehen, das gerade läuft, bricht ab, denn sein Ereignis kann inzwischen ersetzt worden sein.
func refresh() -> void:
	_cancel_drag()
	_hover = null
	_hover_part = Part.NONE
	_build_rows()
	_update_view()
	queue_redraw()


## Hebt das Ereignis hervor, das die Werkstatt gewählt hat, ohne event_clicked zu senden; leer
## heißt keins.
func select_event(id: String) -> void:
	_selected_id = id
	queue_redraw()


## x-Koordinate des Tags [param day] im Zeitstrahl; Tage dürfen Bruchteile haben.
func day_to_x(day: float) -> float:
	return _label_width + (day - visible_from) / days_per_pixel


## Tag an der x-Koordinate [param x], mit Bruchteil; der Tag selbst ist floor() davon.
func x_to_day(x: float) -> float:
	return visible_from + (x - _label_width) * days_per_pixel


## Die Zeitfläche: von der Spalte der Kategorien bis zur senkrechten Leiste, von oben bis zur
## waagerechten.
func time_rect() -> Rect2:
	var right := size.x - _scroll_width
	return Rect2(_label_width, 0.0, maxf(right - _label_width, 1.0),
		maxf(size.y - _hscroll_height, 0.0))


## Kennung des Ereignisses, dessen Marke unter [param point] liegt; leer auf freier Fläche.
func event_at(point: Vector2) -> String:
	var mark := _mark_at(point)
	return mark.event.id if mark != null else ""


## Die Rechtecke der sichtbaren Marken eines Ereignisses, bei jährlichen eines je Vorkommen, in
## der Reihenfolge der Tage. Leer bei „nur als Folge“ oder wenn gerade keine Marke zu sehen ist.
func mark_rects(id: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var time := time_rect()
	for row in _rows:
		for mark in row.marks:
			if mark.event.id != id:
				continue
			var box := _box(mark, row)
			if _is_shown(box, time):
				result.append(box)
	return result


## Der Text am Mauszeiger beim Ziehen: das neue Datum, bei jährlichen Ereignissen der Hinweis, dass
## sie nur im Formular änderbar sind; leer, solange nichts gezogen wird.
func preview_text() -> String:
	if not _drag_moved or _drag_event == null:
		return ""
	match _drag:
		Drag.DATE:
			if _drag_event.duration_days > 0:
				return _span_text(_drag_value, _drag_value + _drag_event.duration_days - 1)
			return _date(_drag_value)
		Drag.DURATION:
			return "bis %s (%s)" % [_date(_drag_event.date + _drag_value - 1),
				_days_text(_drag_value)]
		Drag.WINDOW_FROM:
			return "ab %s" % _date(_drag_value)
		Drag.WINDOW_TO:
			return "bis %s" % _date(_drag_value)
		Drag.LOCKED:
			return LOCKED_HINT
	return ""


## Die erste Fehlermeldung der Vorschau beim Ziehen oder null (R16). Die Vorschau prüft eine Kopie
## des Ereignisses mit dem neuen Wert; der Katalog bleibt dabei, wie er ist.
func preview_issue() -> CatalogIssue:
	return _preview_issue if _drag_moved else null


## Ob gerade ein Filter der Liste gilt.
func is_filtered() -> bool:
	return event_filter.is_valid()


## Der Hinweis im Streifen unter der Achse, etwa „Filter: 12 von 500“; leer ohne Filter. Gezählt
## werden die Ereignisse wie in der Liste, auch solche „nur als Folge“, die keine Marke haben.
func filter_text() -> String:
	if not is_filtered():
		return ""
	return "Filter: %d von %d" % [_filter_passed, _filter_total]


## Die Titel der Zeilen von oben nach unten; für die Tests.
func row_titles() -> PackedStringArray:
	var titles := PackedStringArray()
	for row in _rows:
		titles.append(row.title)
	return titles


## Die Kennungen der Ereignisse, die eine Marke haben, sortiert und jede einmal; für die Tests.
## Anders als mark_rects() hängt das nicht daran, was gerade zu sehen ist.
func marked_events() -> PackedStringArray:
	var seen := {}
	for row in _rows:
		for mark in row.marks:
			seen[mark.event.id] = true
	var ids := PackedStringArray(seen.keys())
	ids.sort()
	return ids


# --- Marken aus dem Katalog -------------------------------------------------------------------

func _update_theme() -> void:
	_font = get_theme_default_font()
	_widths.clear()
	_small_size = get_theme_font_size(&"small", &"Werkstatt")
	_text_size = get_theme_font_size(&"text", &"Werkstatt")
	for button in _zoom_buttons():
		button.add_theme_font_size_override(&"font_size", _small_size)


## Die Maße von Leisten und Knöpfen kommen aus dem Theme. Sie stehen erst fest, wenn die Kinder
## ihr Theme kennen, und das ist nach dem Zeitstrahl selbst; deshalb melden die Kinder sich hier.
func _on_parts_resized() -> void:
	_scroll_width = _scroll.get_combined_minimum_size().x
	_hscroll_height = _hscroll.get_combined_minimum_size().y
	_fit_label_width()
	_update_view()


## Je Kategorie eine Zeile in der Reihenfolge des Katalogs (data-model.md), darin die Marken ihrer
## Ereignisse. Ereignisse mit unbekannter Kategorie (V05) kommen in eine eigene Zeile am Ende, in
## kassenrot, damit sie nicht verschwinden.
##
## Mit Filter bekommen nur die Ereignisse eine Marke, die durchkommen, und es bleiben nur Zeilen
## mit mindestens einer Marke, auch bei „Ohne Kategorie“. Die Spalte der Kategorien bleibt dabei
## so breit wie ohne Filter, sonst spränge die ganze Zeitfläche bei jedem Tastendruck.
func _build_rows() -> void:
	_rows.clear()
	_names_width = 0.0
	_filter_passed = 0
	_filter_total = 0
	if editor == null or editor.catalog == null:
		_fit_label_width()
		return
	var filtered := is_filtered()
	var all_rows: Array[Row] = []
	var row_index := {}
	for category in editor.catalog.categories:
		if row_index.has(category.id):
			continue  # doppelte Kennung (V21): Die Ereignisse gehören zur ersten.
		var row := Row.new()
		row.category = category
		row.title = category.name if not category.name.strip_edges().is_empty() else category.id
		row.color = _row_color(category.color)
		row_index[category.id] = all_rows.size()
		all_rows.append(row)
	var orphans := Row.new()
	orphans.title = "Ohne Kategorie"
	orphans.color = COLOR_ERROR
	# Ob „Ohne Kategorie“ ohne Filter Marken hätte; davon hängt die Breite der Spalte ab.
	var orphans_unfiltered := false
	for event in editor.catalog.events:
		var index: int = row_index.get(event.category, -1)
		_filter_total += 1
		if filtered and not event_filter.call(event):
			if index < 0 and not orphans_unfiltered:
				var probe := Row.new()
				_add_marks(probe, event)
				orphans_unfiltered = not probe.marks.is_empty()
			continue
		_filter_passed += 1
		_add_marks(all_rows[index] if index >= 0 else orphans, event)
	orphans_unfiltered = orphans_unfiltered or not orphans.marks.is_empty()
	var widest := 0.0
	for row in all_rows:
		widest = maxf(widest, _text_width(row.title, _text_size))
		if not filtered or not row.marks.is_empty():
			_rows.append(row)
	if not orphans.marks.is_empty():
		_rows.append(orphans)
	if orphans_unfiltered:
		widest = maxf(widest, _text_width(orphans.title, _text_size))
	_names_width = 2.0 * LABEL_PADDING + SWATCH_SIZE + SWATCH_GAP + widest
	_fit_label_width()


## Die Spalte ist so breit, wie die Namen brauchen, und mindestens so breit, dass die drei
## Zoom-Knöpfe darüber nebeneinander passen; bei den zehn Kategorien des Katalogs genügt die
## Breite der Namen.
func _fit_label_width() -> void:
	var needed := maxf(_names_width, _buttons_width() + 2.0 * BUTTON_GAP)
	_label_width = roundf(clampf(needed, LABEL_MIN_WIDTH, LABEL_MAX_WIDTH))


## Die Farbe einer Zeile: die Kategorienfarbe, oder kassenrot, die Rolle Fehler, wenn das Token
## keine Kategorienfarbe ist (V21). UiPalette.by_token() gäbe dann Magenta oder eine Farbe, die
## der Style-Guide für Kategorien nicht erlaubt, etwa papier auf papier.
static func _row_color(token: StringName) -> Color:
	if UiPalette.CATEGORY_TOKENS.has(token):
		return UiPalette.by_token(token)
	return COLOR_ERROR


## Die Marken eines Ereignisses je nach Art (FR-037). Jährliche Vorkommen kommen aus derselben
## Regel wie im Fahrplan, TimelineRun.yearly_occurrences().
func _add_marks(row: Row, event: TimelineEvent) -> void:
	match event.kind:
		TimelineEvent.Kind.FIXED:
			var days := maxi(event.duration_days, 1)
			var shape := Shape.BAR if event.duration_days > 0 else Shape.POINT
			_add_mark(row, event, shape, event.date, event.date + days - 1)
		TimelineEvent.Kind.YEARLY:
			var shape := Shape.BAR if event.has_duration() else Shape.POINT
			for occurrence in TimelineRun.yearly_occurrences(event):
				_add_mark(row, event, shape, occurrence.x, occurrence.y)
		TimelineEvent.Kind.PRESET:
			_add_mark(row, event, Shape.FRAME, mini(event.window_from, event.window_to),
				maxi(event.window_from, event.window_to))
		TimelineEvent.Kind.CHANCE:
			_add_mark(row, event, Shape.BAND, mini(event.window_from, event.window_to),
				maxi(event.window_from, event.window_to))
		TimelineEvent.Kind.FOLLOW_ONLY:
			pass  # keine Marke: kommt nur als Folge, steht in der Liste und im Simulator


func _add_mark(row: Row, event: TimelineEvent, shape: Shape, first: int, last: int) -> void:
	var mark := Mark.new()
	mark.event = event
	mark.shape = shape
	mark.first = first
	mark.last = last
	mark.color = row.color
	mark.label = _title_of(event)
	if shape == Shape.BAND:
		mark.short_label = "%s %%" % EventForm.format_percent(event.monthly_chance)
		mark.label = "%s · %s" % [mark.short_label, mark.label]
		mark.short_width = _text_width(mark.short_label, _small_size)
	mark.label_width = _text_width(mark.label, _small_size)
	row.marks.append(mark)


# --- Zoom, Ausschnitt und Stapeln -------------------------------------------------------------

## Passt den Zoom an die Breite an: Wer den ganzen Zeitraum sah, sieht ihn weiter; sonst bleibt der
## Zoom innerhalb seiner Grenzen. Danach stapelt der Setter neu.
func _update_view() -> void:
	var widest := _max_days_per_pixel()
	if _fit_all:
		days_per_pixel = widest
	else:
		days_per_pixel = clampf(days_per_pixel, _min_days_per_pixel(), widest)
	visible_from = _clamped_from(visible_from)
	_layout_buttons()


func _max_days_per_pixel() -> float:
	return TOTAL_DAYS / time_rect().size.x


func _min_days_per_pixel() -> float:
	return minf(MIN_VISIBLE_DAYS / time_rect().size.x, _max_days_per_pixel())


## [param from] so begrenzt, dass die Zeitfläche nur Tage des Spielzeitraums zeigt.
func _clamped_from(from: float) -> float:
	var span := time_rect().size.x * days_per_pixel
	return clampf(from, 0.0, maxf(TOTAL_DAYS - span, 0.0))


## Zoomt um die Stelle [param x]. [param steps] zählt Rasten; positiv heißt heraus, negativ hinein.
func _zoom_at(x: float, steps: float) -> void:
	_zoom_to(x, days_per_pixel * pow(ZOOM_STEP, steps))


## Setzt den Zoom auf [param target] Tage je Pixel, in seinen Grenzen. Der Tag an der Stelle
## [param x] bleibt, wo er ist.
func _zoom_to(x: float, target: float) -> void:
	var day := x_to_day(x)
	days_per_pixel = clampf(target, _min_days_per_pixel(), _max_days_per_pixel())
	visible_from = _clamped_from(day - (x - _label_width) * days_per_pixel)


# --- Zoom-Knöpfe ------------------------------------------------------------------------------
#
# „+“ und „−“ zoomen um die Mitte des sichtbaren Ausschnitts, je Klick Faktor 2, über _zoom_to()
# in denselben Grenzen wie Kneifen und Cmd+Mausrad. „Alles“ zeigt wieder 1985 bis 1999.


func _on_zoom_in() -> void:
	_zoom_to(_center_x(), days_per_pixel / BUTTON_ZOOM)


func _on_zoom_out() -> void:
	_zoom_to(_center_x(), days_per_pixel * BUTTON_ZOOM)


func _on_zoom_all() -> void:
	_zoom_to(_center_x(), _max_days_per_pixel())


func _center_x() -> float:
	var time := time_rect()
	return time.position.x + time.size.x / 2.0


func _zoom_buttons() -> Array[Button]:
	return [_zoom_out_button, _zoom_in_button, _zoom_all_button]


## Gesperrt ist, was nichts mehr bewirkte: „+“ bei einem Monat, „−“ und „Alles“ beim ganzen
## Zeitraum.
func _update_zoom_buttons() -> void:
	_zoom_out_button.disabled = _fit_all
	_zoom_all_button.disabled = _fit_all
	_zoom_in_button.disabled = days_per_pixel <= _min_days_per_pixel() + 0.000001


## Breite der drei Knöpfe nebeneinander, mit den Abständen zwischen ihnen.
func _buttons_width() -> float:
	var width := 2.0 * BUTTON_GAP
	for button in _zoom_buttons():
		width += button.get_combined_minimum_size().x
	return width


## Die Knöpfe stehen nebeneinander mittig im Feld über der Spalte, in der Höhe der Achse.
func _layout_buttons() -> void:
	var x := roundf((_label_width - _buttons_width()) / 2.0)
	for button in _zoom_buttons():
		var button_size := button.get_combined_minimum_size()
		button.size = button_size
		button.position = Vector2(x, roundf((AXIS_HEIGHT - button_size.y) / 2.0))
		x += button_size.x + BUTTON_GAP


## Verteilt die Marken jeder Zeile auf Unterzeilen, so dass zwischen zwei Marken einer Unterzeile
## mindestens MARK_GAP Pixel frei bleiben, und legt die Zeilen untereinander. Gerechnet wird in
## Pixeln ab dem 01.01.1985, nicht ab dem linken Rand: So ändert Verschieben nichts am Stapel, nur
## Zoomen. Die Marken kommen nach ihrem Anfang dran, und jede nimmt die erste Unterzeile, in der
## sie Platz hat; so entstehen so wenige Unterzeilen wie möglich.
func _stack() -> void:
	var top := 0.0
	for row in _rows:
		for mark in row.marks:
			var extent := _extent(mark.shape, mark.first, mark.last)
			mark.start_px = extent.x
			mark.end_px = extent.y
			mark.next_px = INF
		row.marks.sort_custom(_starts_before)
		var lane_ends: Array[float] = []
		var lane_marks: Array[Mark] = []
		for mark in row.marks:
			var lane := 0
			while lane < lane_ends.size() and lane_ends[lane] + MARK_GAP > mark.start_px:
				lane += 1
			if lane == lane_ends.size():
				lane_ends.append(mark.end_px)
				lane_marks.append(mark)
			else:
				lane_marks[lane].next_px = mark.start_px
				lane_ends[lane] = mark.end_px
				lane_marks[lane] = mark
			mark.lane = lane
		row.lanes = maxi(lane_ends.size(), 1)
		row.top = top
		row.height = row.lanes * LANE_HEIGHT + 2.0 * ROW_PADDING
		top += row.height
	_content_height = top
	_update_scrollbars()


## Anfang und Ende einer Marke in Pixeln ab dem 01.01.1985: ein Punkt 10 Pixel breit um die Mitte
## seines Tags, alles andere vom Beginn des ersten bis zum Ende des letzten Tags, mindestens
## MIN_MARK_WIDTH breit.
func _extent(shape: Shape, first: int, last: int) -> Vector2:
	var start := first / days_per_pixel
	var end := (last + 1) / days_per_pixel
	var least := POINT_SIZE if shape == Shape.POINT else MIN_MARK_WIDTH
	if shape == Shape.POINT or end - start < least:
		var center := (start + end) / 2.0
		start = center - least / 2.0
		end = center + least / 2.0
	return Vector2(start, end)


## Reihenfolge beim Stapeln: nach Anfang, dann Ende, dann Kennung und Tag. So liegt bei gleichem
## Tag immer dasselbe Ereignis oben.
static func _starts_before(a: Mark, b: Mark) -> bool:
	if a.start_px != b.start_px:
		return a.start_px < b.start_px
	if a.end_px != b.end_px:
		return a.end_px < b.end_px
	if a.event.id != b.event.id:
		return a.event.id < b.event.id
	return a.first < b.first


## Die Leisten am Rand. Die senkrechte rechts erscheint erst, wenn die Zeilen höher sind als der
## Platz zwischen Achse und waagerechter Leiste; ihre Breite bleibt immer frei, damit die
## Zeitfläche nicht springt. Die waagerechte unter der Zeitfläche ist immer da, ganz
## herausgezoomt füllt ihr Griff die Bahn.
func _update_scrollbars() -> void:
	var time := time_rect()
	var area := maxf(time.end.y - _rows_top(), 0.0)
	_scroll.position = Vector2(size.x - _scroll_width, _rows_top())
	_scroll.size = Vector2(_scroll_width, area)
	_scroll.max_value = _content_height
	_scroll.page = area
	_scroll.visible = _content_height > area + 0.5
	if not _scroll.visible:
		_scroll.value = 0.0
	_hscroll.position = Vector2(time.position.x, time.end.y)
	_hscroll.size = Vector2(time.size.x, _hscroll_height)
	_sync_hscroll()


## Stellt die waagerechte Leiste nach der Ansicht ein: page sind die sichtbaren Tage, value ist
## visible_from. set_value_no_signal() meldet nichts, und die Sperre fängt ab, was Range beim
## Ändern von page selbst meldet. So läuft keine Änderung im Kreis zurück.
func _sync_hscroll() -> void:
	_syncing_hscroll = true
	_hscroll.page = minf(time_rect().size.x * days_per_pixel, TOTAL_DAYS)
	_hscroll.set_value_no_signal(visible_from)
	_syncing_hscroll = false


## Klaus zieht an der waagerechten Leiste oder rollt darüber: Die Ansicht folgt, in denselben
## Grenzen wie beim Verschieben.
func _on_hscroll_changed(value: float) -> void:
	if _syncing_hscroll:
		return
	visible_from = _clamped_from(value)


# --- Lage der Marken --------------------------------------------------------------------------

## x-Koordinate einer Stelle in Pixeln ab dem 01.01.1985.
func _px_to_x(px: float) -> float:
	return _label_width + px - visible_from / days_per_pixel


func _row_top(row: Row) -> float:
	return _rows_top() + row.top - _scroll.value


## Wo die Zeilen beginnen: unter der Achse, mit Filter unter dem Streifen mit dem Hinweis.
func _rows_top() -> float:
	return AXIS_HEIGHT + (FILTER_HEIGHT if is_filtered() else 0.0)


func _lane_top(row: Row, lane: int) -> float:
	return _row_top(row) + ROW_PADDING + lane * LANE_HEIGHT


## Das Rechteck einer Marke auf dem Bildschirm, auf ganze Pixel gerundet. Bei Rahmen und Bändern
## ist es fast so hoch wie die Unterzeile, denn darin stehen Rahmen bzw. Band und ihr Titel.
func _box(mark: Mark, row: Row) -> Rect2:
	return _box_at(mark.shape, mark.start_px, mark.end_px, _lane_top(row, mark.lane))


func _box_at(shape: Shape, start_px: float, end_px: float, lane_top: float) -> Rect2:
	var x0 := roundf(_px_to_x(start_px))
	var x1 := maxf(roundf(_px_to_x(end_px)), x0 + 1.0)
	if shape == Shape.POINT or shape == Shape.BAR:
		return Rect2(x0, lane_top + (LANE_HEIGHT - BAR_HEIGHT) / 2.0, x1 - x0, BAR_HEIGHT)
	return Rect2(x0, lane_top + 2.0, x1 - x0, LANE_HEIGHT - 4.0)


## Das Band einer Marke über Wahrscheinlichkeit: unten im Rechteck, darüber steht der Titel.
static func _band(box: Rect2) -> Rect2:
	return Rect2(box.position.x, box.end.y - BAND_HEIGHT, box.size.x, BAND_HEIGHT)


## Ob von einem Rechteck etwas in der Zeitfläche unterhalb der Achse zu sehen ist. Eine Marke, die
## genau am linken Rand endet, zählt nicht; sonst stünde ihr Titel dort ohne sie.
func _is_shown(box: Rect2, time: Rect2) -> bool:
	return box.end.x > time.position.x and box.position.x < time.end.x \
		and box.end.y > _rows_top() and box.position.y < time.end.y


# --- Zeichnen ---------------------------------------------------------------------------------
#
# _draw() malt von hinten nach vorn: Grund und zweite Zeilen, Raster, Marken mit Titeln, Auswahl,
# Vorschau beim Ziehen, dann die Spalte der Kategorien und die Achse darüber; was beim Rollen und
# Verschieben unter sie gerät, verschwindet so. Zuletzt die Texte am Mauszeiger. Godot ruft
# _draw() nur nach queue_redraw() auf und merkt sich die Befehle bis zum nächsten Mal.


func _draw() -> void:
	var time := time_rect()
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_GROUND)
	var shown: Array[int] = []
	for i in _rows.size():
		var row := _rows[i]
		var top := _row_top(row)
		if top + row.height <= _rows_top() or top >= time.end.y:
			continue
		shown.append(i)
		if i % 2 == 1:
			draw_rect(Rect2(0.0, top, size.x, row.height), COLOR_SECOND_ROW)
	_draw_grid(time)
	for i in shown:
		_draw_marks(_rows[i], time)
	_draw_selection(shown, time)
	_draw_preview()
	_draw_categories(shown)
	_draw_filter_hint()
	_draw_axis(time)
	# Unter der Zeitfläche liegt die waagerechte Leiste; was von den Zeilen dorthin reicht, deckt
	# der Grund zu, damit nichts halb unter ihr steht.
	draw_rect(Rect2(0.0, time.end.y, size.x, size.y - time.end.y), COLOR_GROUND)
	_draw_cursor_texts()


## Senkrechte Linien an den Jahresgrenzen, ab Monatszoom auch an den Monatsgrenzen.
func _draw_grid(time: Rect2) -> void:
	var top := _rows_top()
	var bottom := minf(time.end.y, top + _content_height - _scroll.value)
	if bottom <= top:
		return
	if 1.0 / days_per_pixel >= MONTHS_FROM:
		_draw_lines(_month_starts, top, bottom, COLOR_MONTH_LINE, time)
	_draw_lines(_year_starts, top, bottom, COLOR_YEAR_LINE, time)


## Linien von 1 Pixel an den Tagen [param days], soweit sie in der Zeitfläche liegen. bsearch()
## findet den ersten sichtbaren Tag, statt alle durchzugehen.
func _draw_lines(days: PackedInt32Array, top: float, bottom: float, color: Color,
		time: Rect2) -> void:
	for i in range(days.bsearch(floori(visible_from)), days.size()):
		var x := roundf(day_to_x(days[i]))
		if x > time.end.x:
			break
		if x >= time.position.x:
			draw_rect(Rect2(x, top, 1.0, bottom - top), color)


## Die Marken einer Zeile mit ihren Titeln; nur, was in der Zeitfläche zu sehen ist.
func _draw_marks(row: Row, time: Rect2) -> void:
	for mark in row.marks:
		var box := _box(mark, row)
		if not _is_shown(box, time):
			continue
		if mark == _hover:
			draw_rect(box.grow(HOVER_GROW), COLOR_HOVER)
		_draw_shape(mark.shape, box, mark.color)
		_draw_title(mark, box, time)


func _draw_shape(shape: Shape, box: Rect2, color: Color) -> void:
	match shape:
		Shape.POINT, Shape.BAR:
			draw_rect(box, color)
		Shape.FRAME:
			_draw_outline(box, FRAME_WIDTH, color)
		Shape.BAND:
			draw_rect(_band(box), color)


## Der Titel steht in tusche auf dem Grund, nie auf der Kategorienfarbe (R14), und nur, wenn er bis
## zur nächsten Marke derselben Unterzeile passt; sonst steht er nur im Hinweis (FR-037).
## - Punkt und Balken: rechts daneben.
## - Rahmen: innen, wo Grund ist; passt er dort nicht, rechts daneben.
## - Band: darüber, mit der Chance davor; passt nicht alles, nur die Chance.
## Rahmen und Bänder beginnen oft links außerhalb des Bilds; ihr Titel bleibt dann am linken Rand
## der Zeitfläche stehen.
func _draw_title(mark: Mark, box: Rect2, time: Rect2) -> void:
	var limit := _px_to_x(mark.next_px) - TITLE_GAP
	var ascent := _font.get_ascent(_small_size)
	var descent := _font.get_descent(_small_size)
	var middle := box.get_center().y + (ascent - descent) / 2.0
	match mark.shape:
		Shape.POINT, Shape.BAR:
			_draw_label(mark.label, mark.label_width, box.end.x + TITLE_GAP, middle, limit)
		Shape.FRAME:
			var inside := maxf(box.position.x, time.position.x) + FRAME_WIDTH + TITLE_GAP
			var inner_limit := minf(box.end.x - FRAME_WIDTH - TITLE_GAP, limit)
			if not _draw_label(mark.label, mark.label_width, inside, middle, inner_limit):
				_draw_label(mark.label, mark.label_width, box.end.x + TITLE_GAP, middle, limit)
		Shape.BAND:
			var x := maxf(box.position.x, time.position.x) + FRAME_WIDTH
			var baseline := _band(box).position.y - descent - 1.0
			if not _draw_label(mark.label, mark.label_width, x, baseline, limit):
				_draw_label(mark.short_label, mark.short_width, x, baseline, limit)


## Schreibt [param text] ab [param x] auf die Grundlinie [param baseline], wenn er vor
## [param limit] endet; gibt zurück, ob er gepasst hat.
func _draw_label(text: String, width: float, x: float, baseline: float, limit: float) -> bool:
	if text.is_empty() or x + width > limit:
		return false
	draw_string(_font, Vector2(roundf(x), roundf(baseline)), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		_small_size, COLOR_TEXT)
	return true


## Um jede sichtbare Marke des gewählten Ereignisses eine Linie in tusche, 2 Pixel breit mit 2
## Pixeln Abstand (Style-Guide, „Farbrollen“).
func _draw_selection(shown: Array[int], time: Rect2) -> void:
	if _selected_id.is_empty():
		return
	for i in shown:
		var row := _rows[i]
		for mark in row.marks:
			if mark.event.id != _selected_id:
				continue
			var box := _box(mark, row)
			if _is_shown(box, time):
				_draw_outline(box.grow(SELECTION_GAP + SELECTION_LINE), SELECTION_LINE, COLOR_TEXT)


## Die gezogene Marke an ihrem neuen Platz, in signalgelb mit Kontur in tusche. Die alte bleibt
## stehen, bis der Katalog sich nach dem Loslassen ändert.
func _draw_preview() -> void:
	if not _drag_moved or _drag_mark == null or _drag_field.is_empty():
		return
	var span := _preview_span()
	var extent := _extent(_drag_mark.shape, span.x, span.y)
	var box := _box_at(_drag_mark.shape, extent.x, extent.y, _lane_top(_drag_row, _drag_mark.lane))
	match _drag_mark.shape:
		Shape.FRAME:
			_draw_outline(box, 1.0, COLOR_TEXT)
			_draw_outline(box.grow(-1.0), FRAME_WIDTH, COLOR_DRAG)
			_draw_outline(box.grow(-1.0 - FRAME_WIDTH), 1.0, COLOR_TEXT)
		Shape.BAND:
			var band := _band(box)
			draw_rect(band.grow(1.0), COLOR_TEXT)
			draw_rect(band, COLOR_DRAG)
		_:
			draw_rect(box.grow(1.0), COLOR_TEXT)
			draw_rect(box, COLOR_DRAG)


## Erster und letzter Tag der gezogenen Marke mit dem neuen Wert.
func _preview_span() -> Vector2i:
	var event := _drag_event
	match _drag:
		Drag.DATE:
			return Vector2i(_drag_value, _drag_value + maxi(event.duration_days, 1) - 1)
		Drag.DURATION:
			return Vector2i(event.date, event.date + _drag_value - 1)
		Drag.WINDOW_FROM:
			return Vector2i(mini(_drag_value, event.window_to), maxi(_drag_value, event.window_to))
		Drag.WINDOW_TO:
			return Vector2i(mini(event.window_from, _drag_value),
				maxi(event.window_from, _drag_value))
	return Vector2i(_drag_mark.first, _drag_mark.last)


## Die Spalte links: je Zeile ein Farbfeld und der Name der Kategorie. Eine Marke gehört über ihre
## beschriftete Zeile zur Kategorie; die Farbe hilft nur, denn drei Farben kommen doppelt vor (R14).
func _draw_categories(shown: Array[int]) -> void:
	var offset := (_font.get_ascent(_text_size) - _font.get_descent(_text_size)) / 2.0
	var x := LABEL_PADDING + SWATCH_SIZE + SWATCH_GAP
	for i in shown:
		var row := _rows[i]
		var top := _row_top(row)
		var ground := COLOR_SECOND_ROW if i % 2 == 1 else COLOR_GROUND
		draw_rect(Rect2(0.0, top, _label_width, row.height), ground)
		var middle := top + ROW_PADDING + LANE_HEIGHT / 2.0
		draw_rect(Rect2(LABEL_PADDING, roundf(middle - SWATCH_SIZE / 2.0), SWATCH_SIZE,
			SWATCH_SIZE), row.color)
		# Mit einer Breite kürzt Godot zu lange Namen mit „…“.
		draw_string(_font, Vector2(x, roundf(middle + offset)), row.title,
			HORIZONTAL_ALIGNMENT_LEFT, _label_width - x - LABEL_PADDING, _text_size, COLOR_TEXT)
	draw_rect(Rect2(_label_width - 1.0, _rows_top(), 1.0, size.y - _rows_top()), COLOR_TEXT)


## Gefiltert: der Streifen unter der Achse. Links unter den Zoom-Knöpfen steht der Hinweis in
## gedämpftem Text auf dem Grund, darunter eine Linie in der Farbe des Rasters. Er deckt zu, was
## beim Rollen nach oben unter ihn gerät, wie die Achse.
func _draw_filter_hint() -> void:
	if not is_filtered():
		return
	draw_rect(Rect2(0.0, AXIS_HEIGHT, size.x, FILTER_HEIGHT), COLOR_GROUND)
	var ascent := _font.get_ascent(_small_size)
	var descent := _font.get_descent(_small_size)
	var baseline := AXIS_HEIGHT + (FILTER_HEIGHT + ascent - descent) / 2.0
	draw_string(_font, Vector2(LABEL_PADDING, roundf(baseline)), filter_text(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, _small_size, COLOR_MUTED)
	draw_rect(Rect2(0.0, _rows_top() - 1.0, size.x, 1.0), COLOR_YEAR_LINE)


## Die Achse oben, im Kasten der Tabellenköpfe: Jahre; ab Monatszoom Monate und Tagesstriche;
## ganz hinein Monat und Jahr oben, Tageszahlen unten.
func _draw_axis(time: Rect2) -> void:
	var header := get_theme_stylebox(&"title_button_normal", &"Tree")
	draw_style_box(header, Rect2(0.0, 0.0, size.x, AXIS_HEIGHT))
	var per_day := 1.0 / days_per_pixel
	var ascent := _font.get_ascent(_small_size)
	var upper := 3.0 + ascent
	var lower := AXIS_HEIGHT / 2.0 + 1.0 + ascent
	var last_day := mini(ceili(x_to_day(time.end.x)), TOTAL_DAYS)
	if per_day >= DAY_TICKS_FROM:
		for day in range(maxi(floori(visible_from), 0), last_day + 1):
			_draw_tick(day_to_x(day), AXIS_HEIGHT - DAY_TICK, time)
	if per_day >= MONTHS_FROM:
		_draw_ticks(_month_starts, AXIS_HEIGHT / 2.0, time)
	_draw_ticks(_year_starts, 0.0, time)
	if per_day >= DAY_NUMBERS_FROM:
		_draw_sections(_month_starts, _month_and_year, upper, time)
		_draw_day_numbers(lower, time)
	else:
		_draw_years(upper, time)
		if per_day >= MONTHS_FROM:
			# Alle Monate gleich: ausgeschrieben, wenn der längste Name in den Februar passt, sonst
			# mit drei Buchstaben, sonst gar nicht.
			var narrowest := 28.0 * per_day - AXIS_PADDING - SECTION_GAP
			_month_style = 0
			if _widest_month(false) <= narrowest:
				_month_style = 2
			elif _widest_month(true) <= narrowest:
				_month_style = 1
			_draw_sections(_month_starts, _month_name, lower, time)
	# Die Ecke über der Spalte deckt zu, was von der Beschriftung nach links rutscht.
	draw_style_box(header, Rect2(0.0, 0.0, _label_width, AXIS_HEIGHT))


func _draw_ticks(days: PackedInt32Array, top: float, time: Rect2) -> void:
	for i in range(days.bsearch(floori(visible_from)), days.size()):
		if days[i] > x_to_day(time.end.x) + 1.0:
			break
		_draw_tick(day_to_x(days[i]), top, time)


func _draw_tick(x: float, top: float, time: Rect2) -> void:
	var px := roundf(x)
	if px >= time.position.x and px <= time.end.x:
		draw_rect(Rect2(px, top, 1.0, AXIS_HEIGHT - top), COLOR_TEXT)


## Beschriftet Abschnitte der Achse, etwa Monate. Ein Abschnitt, dessen Anfang links aus dem Bild
## gerutscht ist, behält seine Beschriftung am linken Rand, bis der nächste sie wegschiebt.
## [param label_for] bekommt die Nummer des Abschnitts und seine Breite und gibt den Text zurück,
## der hineinpasst, sonst einen leeren.
func _draw_sections(starts: PackedInt32Array, label_for: Callable, baseline: float,
		time: Rect2) -> void:
	var last_day := x_to_day(time.end.x)
	var index := maxi(starts.bsearch(floori(visible_from), false) - 1, 0)
	while index < starts.size() - 1 and starts[index] <= last_day:
		var x0 := day_to_x(starts[index])
		var x1 := day_to_x(starts[index + 1])
		var text: String = label_for.call(index, x1 - x0)
		var width := _text_width(text, _small_size)
		var x := minf(maxf(x0, time.position.x) + AXIS_PADDING, x1 - SECTION_GAP - width)
		# Am rechten Rand lieber keine Beschriftung als eine angeschnittene.
		if not text.is_empty() and x + width <= time.end.x:
			draw_string(_font, Vector2(roundf(x), baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				_small_size, COLOR_TEXT)
		index += 1


## Die Jahre oben. Ist ein Jahr zu schmal für seine Zahl, steht nur jedes zweite, fünfte oder
## zehnte da.
func _draw_years(baseline: float, time: Rect2) -> void:
	var per_year := 365.25 / days_per_pixel
	var needed := _text_width("1999", _small_size) + AXIS_PADDING + SECTION_GAP
	var step := 1
	for candidate: int in [1, 2, 5, 10]:
		step = candidate
		if per_year * candidate >= needed:
			break
	if step == 1:
		_draw_sections(_year_starts, _year_label, baseline, time)
		return
	for i in range(0, _year_starts.size() - 1, step):
		var text := str(GameDate.EPOCH_YEAR + i)
		var x := day_to_x(_year_starts[i]) + AXIS_PADDING
		if x >= time.position.x and x + _text_width(text, _small_size) <= time.end.x:
			draw_string(_font, Vector2(roundf(x), baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				_small_size, COLOR_TEXT)


## Die Tageszahlen unten, je in der Mitte ihres Tags.
func _draw_day_numbers(baseline: float, time: Rect2) -> void:
	var last_day := mini(ceili(x_to_day(time.end.x)), TOTAL_DAYS - 1)
	for day in range(maxi(floori(visible_from), 0), last_day + 1):
		var text := str(GameDate.from_day_index(day).day)
		var width := _text_width(text, _small_size)
		var x := day_to_x(day + 0.5) - width / 2.0
		if x >= time.position.x and x + width <= time.end.x:
			draw_string(_font, Vector2(roundf(x), baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				_small_size, COLOR_TEXT)


func _year_label(index: int, width: float) -> String:
	return _fitting([str(GameDate.EPOCH_YEAR + index)], width)


## Der Monat in der Form, die _draw_axis() für alle Monate gewählt hat.
func _month_name(index: int, _width: float) -> String:
	var month_name: String = GameDate.MONTH_NAMES_DE[index % 12 + 1]
	match _month_style:
		2:
			return month_name
		1:
			return month_name.substr(0, 3)
	return ""


## Breite des breitesten Monatsnamens, ausgeschrieben oder mit drei Buchstaben.
func _widest_month(abbreviated: bool) -> float:
	var widest := 0.0
	for month in range(1, 13):
		var month_name: String = GameDate.MONTH_NAMES_DE[month]
		var text := month_name.substr(0, 3) if abbreviated else month_name
		widest = maxf(widest, _text_width(text, _small_size))
	return widest


func _month_and_year(index: int, width: float) -> String:
	var month_name: String = GameDate.MONTH_NAMES_DE[index % 12 + 1]
	var year := GameDate.EPOCH_YEAR + int(index / 12.0)
	return _fitting(["%s %d" % [month_name, year], "%s %d" % [month_name.substr(0, 3), year]],
		width)


## Der erste der Texte, der mit seinen Abständen in [param width] passt, sonst ein leerer.
func _fitting(texts: Array[String], width: float) -> String:
	for text in texts:
		if _text_width(text, _small_size) + AXIS_PADDING + SECTION_GAP <= width:
			return text
	return ""


## Beim Ziehen am Mauszeiger: das neue Datum in signalgelb mit Kontur in tusche, darunter die erste
## Fehlermeldung der Vorschau als gefülltes Feld in kassenrot. Jährliche Ereignisse bekommen statt
## des Datums den Hinweis auf papier.
func _draw_cursor_texts() -> void:
	var text := preview_text()
	if text.is_empty():
		return
	var reason := _reason(_preview_issue) if _preview_issue != null else ""
	var first := _box_size(text, -1.0)
	var second := _box_size(reason, ERROR_WIDTH) if not reason.is_empty() else Vector2.ZERO
	var total := Vector2(maxf(first.x, second.x), first.y + second.y)
	var at := _mouse + CURSOR_OFFSET
	# Am rechten oder unteren Rand wandern die Texte auf die andere Seite des Mauszeigers. Rechts
	# und unten liegen die Leisten; sie zeichnen über dem Zeitstrahl und verdeckten die Texte.
	var limit := time_rect().end
	if at.x + total.x > limit.x:
		at.x = _mouse.x - CURSOR_OFFSET.x - total.x
	if at.y + total.y > limit.y:
		at.y = _mouse.y - CURSOR_OFFSET.y - total.y
	at = at.clamp(Vector2.ZERO, (limit - total).max(Vector2.ZERO)).round()
	var fill := COLOR_GROUND if _drag == Drag.LOCKED else COLOR_DRAG
	_draw_box(Rect2(at, first), text, -1.0, fill, COLOR_TEXT)
	_draw_outline(Rect2(at, first), 1.0, COLOR_TEXT)
	if not reason.is_empty():
		_draw_box(Rect2(at + Vector2(0.0, first.y), second), reason, ERROR_WIDTH, COLOR_ERROR,
			COLOR_ERROR_TEXT)


func _box_size(text: String, wrap_width: float) -> Vector2:
	var text_size := _font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, wrap_width,
		_text_size)
	return (text_size + 2.0 * BOX_PADDING).ceil()


func _draw_box(rect: Rect2, text: String, wrap_width: float, fill: Color, ink: Color) -> void:
	draw_rect(rect, fill)
	var baseline := rect.position + BOX_PADDING + Vector2(0.0, _font.get_ascent(_text_size))
	draw_multiline_string(_font, baseline.round(), text, HORIZONTAL_ALIGNMENT_LEFT, wrap_width,
		_text_size, -1, ink)


## Ein Rahmen aus vier gefüllten Rechtecken, genau [param width] Pixel breit und innerhalb von
## [param rect]. draw_rect() ohne Füllung legt die Linie dagegen mittig auf den Rand.
func _draw_outline(rect: Rect2, width: float, color: Color) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, width)), color)
	draw_rect(Rect2(rect.position.x, rect.end.y - width, rect.size.x, width), color)
	var side := rect.size.y - 2.0 * width
	if side > 0.0:
		draw_rect(Rect2(rect.position.x, rect.position.y + width, width, side), color)
		draw_rect(Rect2(rect.end.x - width, rect.position.y + width, width, side), color)


# --- Maus -------------------------------------------------------------------------------------
#
# Godot schickt jede Mauseingabe über diesem Control an _gui_input(), die Position schon in seinen
# eigenen Koordinaten. Wer gedrückt hat, bekommt auch die Bewegungen und das Loslassen außerhalb,
# bis die Taste wieder oben ist. accept_event() hält eine verarbeitete Eingabe davon ab, weiter zu
# den Eltern zu wandern. Das Trackpad kommt unter macOS als eigene Eingaben: Wischen mit zwei
# Fingern als InputEventPanGesture, Kneifen als InputEventMagnifyGesture.


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		_mouse = button.position
		_on_button(button)
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		_mouse = motion.position
		if _drag != Drag.NONE:
			_on_drag_motion(motion.position)
			accept_event()
		else:
			_update_hover(motion.position)
		return
	var pan := event as InputEventPanGesture
	if pan != null:
		_on_pan_gesture(pan)
		accept_event()
		return
	var magnify := event as InputEventMagnifyGesture
	if magnify != null:
		_on_magnify_gesture(magnify)
		accept_event()


func _on_button(button: InputEventMouseButton) -> void:
	if WHEELS.has(button.button_index):
		if button.pressed:
			_on_wheel(button)
	elif button.button_index == MOUSE_BUTTON_LEFT:
		if not button.pressed:
			_on_release()
		elif button.double_click:
			_on_double_click(button.position)
		else:
			_on_press(button.position)
	elif button.button_index == MOUSE_BUTTON_RIGHT:
		if button.pressed and _drag == Drag.NONE:
			_on_right_click(button.position)


## Mausrad: verschieben, mit Shift schneller; mit Cmd bzw. Ctrl zoomen um die Mausposition (R16).
## Unter macOS kommt Shift+Mausrad als waagerechtes Rad an; beide Richtungen verschieben.
## factor ist bei feinen Rädern der Anteil einer Raste.
func _on_wheel(button: InputEventMouseButton) -> void:
	if _drag != Drag.NONE:
		return
	var amount := button.factor if button.factor > 0.0 else 1.0
	var later := button.button_index == MOUSE_BUTTON_WHEEL_DOWN \
		or button.button_index == MOUSE_BUTTON_WHEEL_RIGHT
	var direction := 1.0 if later else -1.0
	var vertical := button.button_index == MOUSE_BUTTON_WHEEL_UP \
		or button.button_index == MOUSE_BUTTON_WHEEL_DOWN
	var time := time_rect()
	if vertical and button.is_command_or_control_pressed():
		_zoom_at(clampf(button.position.x, time.position.x, time.end.x), direction * amount)
		return
	var step := PAN_STEP_FAST if button.shift_pressed else PAN_STEP
	visible_from = _clamped_from(visible_from
		+ direction * amount * step * time.size.x * days_per_pixel)


## Wischen mit zwei Fingern auf dem Trackpad. Unter macOS kommt es nicht als Mausrad, sondern als
## InputEventPanGesture mit delta; positiv heißt wie beim Mausrad nach unten bzw. rechts.
## - delta.x verschiebt seitlich wie das Mausrad.
## - delta.y rollt die Zeilen, wenn sie nicht alle hineinpassen; die Rollleiste folgt.
## - Mit Cmd bzw. Ctrl zoomt delta.y um die Maus, wie Cmd+Mausrad.
func _on_pan_gesture(pan: InputEventPanGesture) -> void:
	if _drag != Drag.NONE:
		return
	var time := time_rect()
	if pan.is_command_or_control_pressed():
		_zoom_at(clampf(pan.position.x, time.position.x, time.end.x), pan.delta.y * GESTURE_STEPS)
		return
	visible_from = _clamped_from(visible_from
		+ pan.delta.x * GESTURE_STEPS * PAN_STEP * time.size.x * days_per_pixel)
	if _scroll.visible:
		_scroll.value += pan.delta.y * GESTURE_STEPS * ROW_SCROLL_STEP


## Kneifen auf dem Trackpad: factor über 1 heißt Finger auseinander, also hinein. Gezoomt wird um
## die Maus, in denselben Grenzen wie mit dem Mausrad.
func _on_magnify_gesture(magnify: InputEventMagnifyGesture) -> void:
	if _drag != Drag.NONE or magnify.factor <= 0.0:
		return
	var time := time_rect()
	_zoom_to(clampf(magnify.position.x, time.position.x, time.end.x),
		days_per_pixel / pow(magnify.factor, MAGNIFY_POWER))


## Drücken: auf einer Marke wählt es das Ereignis und beginnt, sie zu ziehen; auf freier Fläche
## beginnt es, die Ansicht zu verschieben. Gezogen wird erst nach DRAG_THRESHOLD Pixeln.
func _on_press(at: Vector2) -> void:
	_release_focus()
	_press_position = at
	_press_from = visible_from
	_drag_moved = false
	var mark := _mark_at(at)
	if mark == null:
		_drag = Drag.PAN if time_rect().has_point(at) else Drag.NONE
		_update_cursor()
		return
	event_clicked.emit(mark.event.id)
	# Wer auf event_clicked hört, darf den Zeitstrahl neu aufbauen; die Marke kommt deshalb frisch.
	mark = _mark_at(at)
	if mark != null:
		var row := _row_at(at)
		_start_drag(mark, row, _part_at(mark, row, at))


func _start_drag(mark: Mark, row: Row, part: Part) -> void:
	_drag_mark = mark
	_drag_row = row
	_drag_event = mark.event
	_drag_field = &""
	_preview_ready = false
	if mark.event.kind == TimelineEvent.Kind.YEARLY:
		_drag = Drag.LOCKED
	else:
		_drag_field = _field_for(mark.event, part)
		if _drag_field.is_empty():
			# Die Fläche eines Zeitfensters lässt sich nicht als Ganzes ziehen, dafür bräuchte es
			# zwei Felder auf einmal. Wer dort zieht, verschiebt die Ansicht.
			_drag = Drag.PAN
		else:
			_drag = DRAG_BY_FIELD[_drag_field]
			_drag_original = mark.event.get(_drag_field)
			_drag_value = _drag_original
	_update_cursor()


func _on_drag_motion(at: Vector2) -> void:
	if not _drag_moved:
		if at.distance_to(_press_position) < DRAG_THRESHOLD:
			return
		_drag_moved = true
		_set_hover(null, Part.NONE)
	match _drag:
		Drag.PAN:
			visible_from = _clamped_from(_press_from - (at.x - _press_position.x) * days_per_pixel)
		Drag.LOCKED:
			queue_redraw()
		_:
			_update_preview(at.x)
	_update_cursor()


## Neuer Wert aus der Bewegung seit dem Drücken, tagesgenau gerundet, und die Vorschau dazu: Eine
## Kopie des Ereignisses bekommt den Wert, CatalogValidator.validate_event() prüft sie. Der Katalog
## ändert sich dabei nicht (R16).
func _update_preview(x: float) -> void:
	var value := _drag_original + roundi((x - _press_position.x) * days_per_pixel)
	if _drag == Drag.DURATION:
		value = maxi(value, 1)
	else:
		value = clampi(value, TimelineRun.FIRST_DAY, TimelineRun.LAST_DAY)
	if value != _drag_value or not _preview_ready:
		_drag_value = value
		_preview_ready = true
		_preview_issue = _first_error(value)
	queue_redraw()


func _first_error(value: int) -> CatalogIssue:
	if editor == null or editor.catalog == null:
		return null
	var copy := _drag_event.duplicate_event()
	copy.set(_drag_field, value)
	for issue in CatalogValidator.validate_event(editor.catalog, copy):
		if issue.severity == CatalogIssue.Severity.ERROR:
			return issue
	return null


## Loslassen: Hat sich ein Wert geändert, geht er jetzt, genau einmal, mit event_moved hinaus.
func _on_release() -> void:
	var moved := _drag_moved and not _drag_field.is_empty() and _drag_value != _drag_original
	var id := _drag_event.id if _drag_event != null else ""
	var field := _drag_field
	var value := _drag_value
	_cancel_drag()
	if moved:
		event_moved.emit(id, field, value)


func _cancel_drag() -> void:
	_drag = Drag.NONE
	_drag_moved = false
	_drag_mark = null
	_drag_row = null
	_drag_event = null
	_drag_field = &""
	_preview_ready = false
	_preview_issue = null
	queue_redraw()
	_update_cursor()


## Doppelklick auf freie Fläche einer Zeile (FR-039). Rahmen und Bänder sind nur Linien um ein
## Zeitfenster; wer in ihre Fläche doppelklickt, meint die Zeile. Godot meldet den ersten Klick
## als einfachen, erst den zweiten mit double_click.
func _on_double_click(at: Vector2) -> void:
	_cancel_drag()
	var row := _row_at(at)
	if row == null or row.category == null or not time_rect().has_point(at):
		return
	var mark := _mark_at(at)
	if mark != null:
		var outline := mark.shape == Shape.FRAME or mark.shape == Shape.BAND
		if not outline or _part_at(mark, row, at) != Part.BODY:
			return
	var day := clampi(floori(x_to_day(at.x)), TimelineRun.FIRST_DAY, TimelineRun.LAST_DAY)
	create_requested.emit(row.category.id, day)


## Rechtsklick auf eine Marke: wählt das Ereignis und öffnet das Menü an der Maus.
func _on_right_click(at: Vector2) -> void:
	var mark := _mark_at(at)
	if mark == null:
		return
	_menu_event_id = mark.event.id
	event_clicked.emit(_menu_event_id)
	# Das Menü ist ein eigenes Fenster. get_screen_transform() rechnet die Stelle im Control in die
	# Lage auf dem Bildschirm um, mit dem Bildschirmfaktor der Werkstatt.
	_menu.reset_size()
	_menu.position = Vector2i(get_screen_transform() * at)
	_menu.popup()


func _on_menu_id_pressed(item: int) -> void:
	var id := _menu_event_id
	match item:
		MenuItem.EDIT:
			edit_requested.emit(id)
		MenuItem.DUPLICATE:
			if editor == null or editor.catalog == null or editor.catalog.get_event(id) == null:
				return
			var copy := editor.duplicate_event(id)
			if copy != null:
				event_created.emit(copy.id)
		MenuItem.DELETE:
			delete_requested.emit(id)


## Hinweis beim Verweilen über einer Marke (US4, Szenario 3). Godot fragt danach, sobald die Maus
## kurz stillsteht; ein leerer Text heißt: kein Hinweis.
func _get_tooltip(at_position: Vector2) -> String:
	if _drag != Drag.NONE:
		return ""
	if is_filtered() and at_position.y >= AXIS_HEIGHT and at_position.y < _rows_top():
		return FILTER_TOOLTIP
	var mark := _mark_at(at_position)
	if mark == null:
		return ""
	return _tooltip_for(mark)


func _update_hover(at: Vector2) -> void:
	var mark := _mark_at(at)
	_set_hover(mark, _part_at(mark, _row_at(at), at) if mark != null else Part.NONE)


func _set_hover(mark: Mark, part: Part) -> void:
	if mark != _hover or part != _hover_part:
		_hover = mark
		_hover_part = part
		queue_redraw()
	_update_cursor()


## Der Mauszeiger zeigt, was ein Ziehen täte: Doppelpfeil an Rändern, Hand über Marken, beim
## Ziehen die geschlossene Hand, bei jährlichen Ereignissen das Verbotszeichen.
func _update_cursor() -> void:
	var shape := CURSOR_ARROW
	match _drag:
		Drag.PAN:
			shape = CURSOR_DRAG if _drag_moved else CURSOR_ARROW
		Drag.DATE:
			shape = CURSOR_DRAG
		Drag.DURATION, Drag.WINDOW_FROM, Drag.WINDOW_TO:
			shape = CURSOR_HSIZE
		Drag.LOCKED:
			shape = CURSOR_FORBIDDEN if _drag_moved else CURSOR_POINTING_HAND
		Drag.NONE:
			if _hover != null:
				var field := _field_for(_hover.event, _hover_part)
				var edge := field == &"duration_days" or field == &"window_from" \
					or field == &"window_to"
				shape = CURSOR_HSIZE if edge else CURSOR_POINTING_HAND
	mouse_default_cursor_shape = shape


## Ein Feld im Formular übernimmt seine Eingabe beim Verlassen. Ein Klick in den Zeitstrahl nimmt
## ihm deshalb den Fokus, wie Cmd+S in der Werkstatt; sonst bliebe das Getippte unübernommen.
func _release_focus() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var focused := viewport.gui_get_focus_owner()
	if focused != null:
		focused.release_focus()


# --- Treffer ----------------------------------------------------------------------------------

## Die Zeile unter [param at]; null über der Achse, unter der letzten Zeile und auf der Leiste.
func _row_at(at: Vector2) -> Row:
	if at.y < _rows_top() or at.y >= time_rect().end.y:
		return null
	for row in _rows:
		var top := _row_top(row)
		if at.y >= top and at.y < top + row.height:
			return row
	return null


## Die Marke unter [param at] oder null. Getroffen ist, was in der Unterzeile unter der Maus liegt,
## mit ein paar Pixeln Zugabe an den Seiten; liegen zwei so nah, gewinnt die nähere.
func _mark_at(at: Vector2) -> Mark:
	var time := time_rect()
	if at.x < time.position.x or at.x > time.end.x:
		return null
	var row := _row_at(at)
	if row == null:
		return null
	var lane := floori((at.y - _row_top(row) - ROW_PADDING) / LANE_HEIGHT)
	if lane < 0 or lane >= row.lanes:
		return null
	var best: Mark = null
	var best_distance := INF
	for mark in row.marks:
		if mark.lane != lane:
			continue
		var box := _box(mark, row)
		var grab := POINT_GRAB if mark.shape == Shape.POINT else EDGE_GRAB
		if at.x < box.position.x - grab or at.x > box.end.x + grab:
			continue
		var distance := maxf(maxf(box.position.x - at.x, at.x - box.end.x), 0.0)
		if distance < best_distance:
			best = mark
			best_distance = distance
	return best


## Welcher Teil der Marke unter [param at] liegt. Ränder gibt es bei Rahmen und Bändern auf beiden
## Seiten, bei Balken fixer Ereignisse nur rechts: Der Beginn ist dort das Datum, und das zieht
## der ganze Balken.
func _part_at(mark: Mark, row: Row, at: Vector2) -> Part:
	var box := _box(mark, row)
	match mark.shape:
		Shape.FRAME, Shape.BAND:
			var to_start := absf(at.x - box.position.x)
			var to_end := absf(at.x - box.end.x)
			if minf(to_start, to_end) <= EDGE_GRAB:
				return Part.START if to_start < to_end else Part.END
		Shape.BAR:
			var zone := minf(EDGE_GRAB, box.size.x / 3.0)
			if mark.event.kind == TimelineEvent.Kind.FIXED and at.x >= box.end.x - zone:
				return Part.END
	return Part.BODY


## Das Feld, das ein Ziehen an [param part] ändert; leer, wo sich nichts ziehen lässt. Ein Ziehen
## ändert genau ein Feld, so wie event_moved es meldet.
static func _field_for(event: TimelineEvent, part: Part) -> StringName:
	match event.kind:
		TimelineEvent.Kind.FIXED:
			if part == Part.NONE:
				return &""
			return &"duration_days" if part == Part.END else &"date"
		TimelineEvent.Kind.PRESET, TimelineEvent.Kind.CHANCE:
			if part != Part.START and part != Part.END:
				return &""
			# Der linke Rand ist der frühere Tag, bei einem umgedrehten Fenster (V07) window_to.
			var start_is_from := event.window_from <= event.window_to
			return &"window_from" if (part == Part.START) == start_is_from else &"window_to"
	return &""


# --- Texte ------------------------------------------------------------------------------------

## Der Hinweis zu einer Marke: Titel, Art, Datum oder Zeitfenster, gegebenenfalls die Chance
## (FR-039); bei jährlichen dazu das Vorkommen unter der Maus und dass sie sich nicht ziehen lassen.
func _tooltip_for(mark: Mark) -> String:
	var event := mark.event
	var lines := PackedStringArray([_title_of(event)])
	var kind := event.kind_label()
	match event.kind:
		TimelineEvent.Kind.FIXED:
			if event.duration_days > 0:
				lines.append("%s · %s (%s)" % [kind, _span_text(mark.first, mark.last),
					_days_text(event.duration_days)])
			else:
				lines.append("%s · %s" % [kind, _date(event.date)])
		TimelineEvent.Kind.YEARLY:
			lines.append("%s · %s, %d bis %d" % [kind, _yearly_text(event), event.yearly_from,
				event.yearly_to])
			lines.append("Hier: %s" % _span_text(mark.first, mark.last))
			lines.append("%s." % LOCKED_HINT)
		TimelineEvent.Kind.PRESET:
			lines.append("%s · Zeitfenster %s" % [kind, _span_text(mark.first, mark.last)])
			var high := event.count_min + event.count_weights.size() - 1
			var count := str(event.count_min) if high <= event.count_min \
				else "%d bis %d" % [event.count_min, high]
			lines.append("Anzahl %s, Mindestabstand %s" % [count, _days_text(event.min_gap_days)])
		TimelineEvent.Kind.CHANCE:
			lines.append("%s · Zeitfenster %s" % [kind, _span_text(mark.first, mark.last)])
			var chance := "Chance %s %% pro Monat" % EventForm.format_percent(event.monthly_chance)
			if event.max_occurrences > 0:
				chance += ", höchstens %d-mal" % event.max_occurrences
			lines.append(chance)
	return "\n".join(lines)


## „jedes Jahr vom 01.11. bis Ende Dezember“, „jedes Jahr am 22.05.“ oder mit festem Ende.
static func _yearly_text(event: TimelineEvent) -> String:
	var start := EventForm.format_day_of_year(event.yearly_start)
	var end := event.yearly_end
	if end == Vector2i.ZERO:
		return "jedes Jahr am %s" % start
	if end.y == 0 and end.x >= 1 and end.x <= 12:
		return "jedes Jahr vom %s bis Ende %s" % [start, GameDate.MONTH_NAMES_DE[end.x]]
	return "jedes Jahr vom %s bis %s" % [start, EventForm.format_day_of_year(end)]


## Breite eines Texts in Pixeln. Um einen Text zu messen, setzt Godot ihn erst (shaping); das
## kostet je Titel einige Mikrosekunden. Der Zeitstrahl misst jeden Titel bei jedem Neuaufbau und
## die Beschriftungen der Achse in jedem Bild, deshalb merkt er sich jede Breite. Mehr als ein
## paar Tausend verschiedene Texte kommen kaum zusammen; danach fängt er von vorn an.
func _text_width(text: String, font_size: int) -> float:
	if not _widths.has(font_size) or _widths[font_size].size() > 10000:
		_widths[font_size] = {}
	var known: Dictionary = _widths[font_size]
	if not known.has(text):
		known[text] = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return known[text]


static func _title_of(event: TimelineEvent) -> String:
	if not event.title.strip_edges().is_empty():
		return event.title
	return event.id if not event.id.is_empty() else "(ohne Titel)"


static func _date(day: int) -> String:
	return str(GameDate.from_day_index(day))


static func _span_text(first: int, last: int) -> String:
	if first == last:
		return _date(first)
	return "%s bis %s" % [_date(first), _date(last)]


static func _days_text(days: int) -> String:
	return "1 Tag" if days == 1 else "%d Tage" % days


## Der Grund einer Meldung ohne den Ort davor, wie im Formular: Aus „Ereignis „x“, Feld
## „window.to“: Das Zeitfenster …“ wird „Das Zeitfenster …“. Am Mauszeiger ist ja klar, welches
## Ereignis gemeint ist.
static func _reason(issue: CatalogIssue) -> String:
	var cut := issue.message.find("“: ")
	if cut < 0:
		return issue.message
	return issue.message.substr(cut + 3)


## Der Erste jedes [param step]-ten Monats von Januar 1985 bis Januar 2000 als Tagesindex.
static func _first_days(step: int) -> PackedInt32Array:
	var days := PackedInt32Array()
	for month in range(0, TimelineRun.MONTHS + 1, step):
		var year := GameDate.EPOCH_YEAR + int(month / 12.0)
		days.append(GameDate.new(year, month % 12 + 1, 1).to_day_index())
	return days
