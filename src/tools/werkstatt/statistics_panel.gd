class_name StatisticsPanel
extends VBoxContainer

## Die Statistik der Werkstatt (FR-044, FR-045; contracts/werkstatt.md, „Statistik
## (StatisticsPanel)“): Klaus lässt viele Spiele mit den Seeds 1, 2, 3 und so weiter durchrechnen
## und sieht je Ereignis, wie oft es im Schnitt beginnt, wie oft mindestens und höchstens, in wie
## vielen Spielen gar nicht oder bis zur Obergrenze, und für die gewählte Zeile die Verteilung auf
## die Jahre als Balken.
##
## Gerechnet wird in Häppchen (research.md, R17): Je Bild rechnet TimelineStatistics.run_for()
## 15 ms, dann wartet _calculate() mit await auf das nächste Bild. Dazwischen zeichnet Godot die
## Werkstatt und nimmt Maus und Tastatur an; sie bleibt bedienbar, und „Abbrechen“ wirkt sofort. Ein
## abgebrochenes Ergebnis zeigt die fertigen Spiele und nennt ihre Zahl.
##
## Wie der Simulator rechnet die Statistik mit einer Kopie des Katalogs, wie er gerade in der
## Werkstatt steht, auch ungespeichert und ohne die Ereignisse mit Fehlern; ein Hinweis nennt sie
## (FR-042). Ändert sich der Katalog während einer Rechnung, rechnet sie mit ihrer Kopie weiter, und
## „Katalog geändert, neu starten“ erscheint. Die Werkstatt ruft dafür nach catalog_changed und
## issues_changed refresh() auf.
##
## Mit dem Häkchen bekommt die Statistik das Eingriffsprotokoll des Simulators. Modifikatoren und
## Einplanungen gelten dann in jedem Spiel an ihrem Tag, Absagen und Verschiebungen nicht (FR-045).
## Das Protokoll holt das Panel beim Start über [member interventions_source]; die Werkstatt setzt
## es, denn die Teile der Werkstatt kennen sich untereinander nicht.

enum Column { EVENT, MEAN, MINIMUM, MAXIMUM, WITHOUT, AT_MAX }

## Vorgabe und Höchstwert für die Zahl der Spiele (FR-044). 100.000 Spiele dauern mit dem echten
## Katalog rund eine Viertelstunde; mehr braucht keine Statistik.
const DEFAULT_GAMES := 1000
const MAX_GAMES := 100000
## So viele Millisekunden rechnet die Statistik je Bild (R17).
const BUDGET_MSEC := 15
const TITLES: Array[String] = ["Ereignis", "Mittelwert", "kleinste", "größte", "ohne", "Obergrenze"]
const TITLE_TIPS: Array[String] = [
	"Das Ereignis; die Zeilen stehen nach Kennung.",
	"Beginne im Schnitt je Spiel",
	"Die kleinste Anzahl an Beginnen in einem Spiel",
	"Die größte Anzahl an Beginnen in einem Spiel",
	"Anteil der Spiele, in denen das Ereignis nie begann",
	("Anteil der Spiele, in denen es seine Obergrenze erreichte: die Höchstzahl bei Ereignissen "
		+ "über Wahrscheinlichkeit, die höchste Anzahl bei gesetzten. „–“ heißt: keine "
		+ "Obergrenze."),
]
## Breite der Zahlenspalten; das Ereignis nimmt den Rest.
const WIDTHS: Array[int] = [0, 104, 84, 84, 84, 104]
## Was in der Spalte „Obergrenze“ steht, wenn es keine gibt.
const NO_LIMIT := "–"
## Die Balken der Verteilung nehmen so viel ihrer Spalte ein; der Rest bleibt Grund.
const BAR_SHARE := 0.6
## Abstand zwischen Balken bzw. Grundlinie und ihrer Beschriftung.
const LABEL_GAP := 4.0

## Der einzige, der den Katalog ändert; die Statistik liest nur daraus. Die Werkstatt setzt ihn.
var editor: CatalogEditor
## Liefert das Eingriffsprotokoll des Simulators als Array[Dictionary], alle gesammelten
## Eingriffe; welche davon gelten, entscheidet TimelineStatistics. Die Werkstatt setzt es; ohne
## Quelle gibt es keine Eingriffe.
var interventions_source: Callable
## Die laufende oder zuletzt gerechnete Statistik; null bis zum ersten „Starten“.
var statistics: TimelineStatistics

var _running := false
var _aborted := false
var _started_usec := 0
## Wie lange die letzte Rechnung vom Start bis zum Ende oder Abbruch dauerte.
var _elapsed_msec := 0.0
## Das Ergebnis, das die Tabelle zeigt; leer, solange gerechnet wird.
var _results: Array[EventStatistic] = []
## Die gewählte Zeile als Kennung ihres Ereignisses; sie bleibt über neue Rechnungen gewählt.
var _selected_id := ""
## Der Katalog, mit dem die Statistik rechnet, als Text (_catalog_key()); daran erkennt refresh(),
## dass sich der Katalog seitdem geändert hat.
var _run_key := ""
var _stale := false
## Die Titel der Ereignisse, die die Statistik wegen Fehlern auslässt.
var _excluded := PackedStringArray()
## Wie viele Eingriffe aus dem Simulator in der Rechnung gelten.
var _applied := 0
var _refresh_queued := false
## Ob das Panel die Tabelle gerade selbst füllt; ihre Signale zählen dann nicht.
var _syncing := false
var _zebra: Zebra

@onready var _count_edit: LineEdit = %CountEdit
@onready var _with_interventions: CheckBox = %WithInterventions
@onready var _start_button: Button = %StartButton
@onready var _cancel_button: Button = %CancelButton
@onready var _progress: ProgressBar = %Progress
@onready var _progress_label: Label = %ProgressLabel
@onready var _intervention_info: Label = %InterventionInfo
@onready var _count_hint: Label = %CountHint
@onready var _catalog_notice: Label = %CatalogNotice
@onready var _excluded_notice: Label = %ExcludedNotice
@onready var _result_label: Label = %ResultLabel
@onready var _table: Tree = %ResultTable
@onready var _year_title: Label = %YearTitle
@onready var _chart: Control = %YearChart


func _ready() -> void:
	_set_up_table()
	_zebra = Zebra.new(_table)
	_count_edit.text = _grouped(DEFAULT_GAMES)
	_connect_signals()
	_fill_results()
	_show_progress()
	_update_all()


## Verlässt das Panel den Baum, etwa weil die Werkstatt schließt, hält die Rechnung an.
func _exit_tree() -> void:
	cancel()


func _connect_signals() -> void:
	_count_edit.text_changed.connect(_on_count_changed)
	_count_edit.text_submitted.connect(func(_text: String) -> void:
		_normalize_count()
		start())
	_count_edit.focus_exited.connect(_normalize_count)
	_with_interventions.toggled.connect(func(_on: bool) -> void: _update_intervention_info())
	_start_button.pressed.connect(start)
	_cancel_button.pressed.connect(cancel)
	_table.item_selected.connect(_on_result_selected)
	_chart.draw.connect(_draw_years)
	_chart.resized.connect(_chart.queue_redraw)
	# Kommt der Reiter nach vorn, kann der Simulator inzwischen anderes gesammelt haben.
	visibility_changed.connect(_update_intervention_info)


# --- Für die Werkstatt ------------------------------------------------------------------------

## Nach catalog_changed und issues_changed: prüft am Ende des Bilds, ob ein neuer Start jetzt mit
## einem anderen Katalog rechnen würde, und zeigt dann „Katalog geändert, neu starten“. Die
## Rechnung behält ihren Stand (FR-042). Am Ende des Bilds, weil beide Signale nach jeder Änderung
## kommen; so wird nur einmal verglichen.
func refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_apply_refresh.call_deferred()


## „Starten“ (FR-044): rechnet so viele Spiele, wie im Feld steht, mit den Seeds ab 1, auf einer
## Kopie des Katalogs, wie er jetzt dasteht; mit dem Häkchen samt den Eingriffen des Simulators
## (FR-045). Das erste Häppchen rechnet start() selbst, den Rest _calculate() Bild für Bild.
func start() -> void:
	if _running or not _can_start():
		return
	statistics = TimelineStatistics.new(_effective_catalog(), _game_count())
	var records: Array[Dictionary] = []
	if _with_interventions.button_pressed:
		records = _simulator_records()
	statistics.interventions = records
	_applied = _count_kinds(records, TimelineStatistics.SEED_FREE_KINDS)
	_run_key = _catalog_key()
	_stale = false
	_excluded = _excluded_titles()
	_running = true
	_aborted = false
	_results.clear()
	_started_usec = Time.get_ticks_usec()
	_fill_results()
	_update_all()
	_calculate(statistics)


## „Abbrechen“: hält die Rechnung an. Die Tabelle zeigt sofort das Ergebnis der fertigen Spiele;
## das angefangene zählt nicht.
func cancel() -> void:
	if _running:
		_finish(true)


## Ob gerade gerechnet wird.
func is_running() -> bool:
	return _running


## Wie die Balken der Verteilung liegen, je Jahr ein Dictionary: "year" (1985 bis 1999), "value"
## (Beginne im Schnitt je Spiel), "bar" (Rect2, leer bei 0), "color", "value_text" mit
## "value_rect" darüber und "year_text" mit "year_rect" darunter, alles in Koordinaten der
## Zeichenfläche. Leer ohne gewählte Zeile. _draw_years() zeichnet genau das; die Tests prüfen
## daran, dass kein Text auf einem Balken steht.
func year_bars() -> Array[Dictionary]:
	var bars: Array[Dictionary] = []
	var statistic := _selected_statistic()
	if statistic == null or statistic.games <= 0:
		return bars
	var font := _chart.get_theme_default_font()
	var font_size := _chart.get_theme_font_size(&"small", &"Werkstatt")
	var line := font.get_height(font_size)
	var slot := _chart.size.x / EventStatistic.YEARS
	# Unten die Jahreszahlen und 1 Pixel Grundlinie, oben Platz für den Wert über dem höchsten
	# Balken.
	var base := floorf(_chart.size.y - line - LABEL_GAP - 1.0)
	var room := maxf(base - line - LABEL_GAP, 0.0)
	var values := _year_values(statistic)
	var highest := 0.0
	for value in values:
		highest = maxf(highest, value)
	var bar_width := maxf(roundf(slot * BAR_SHARE), 1.0)
	var color := _bar_color(statistic.event_id)
	for index in EventStatistic.YEARS:
		var value := values[index]
		var height := 0.0
		if value > 0.0 and highest > 0.0:
			height = maxf(roundf(room * value / highest), 1.0)
		var left := roundf(slot * index + (slot - bar_width) / 2.0)
		var bar := Rect2(left, base - height, bar_width, height)
		var year := EventStatistic.FIRST_YEAR + index
		var year_text := str(year)
		if _text_width(year_text, font, font_size) > slot:
			year_text = "%02d" % (year % 100)
		var value_text := _value_text(value)
		if _text_width(value_text, font, font_size) > slot:
			value_text = ""
		bars.append({
			"year": year,
			"value": value,
			"bar": bar,
			"color": color,
			"value_text": value_text,
			"value_rect": _label_rect(value_text, font, font_size, index * slot, slot,
				bar.position.y - LABEL_GAP - line),
			"year_text": year_text,
			"year_rect": _label_rect(year_text, font, font_size, index * slot, slot,
				base + 1.0 + LABEL_GAP),
		})
	return bars


# --- Rechnen ----------------------------------------------------------------------------------

## Rechnet Bild für Bild weiter, bis alle Spiele fertig sind oder Klaus abbricht (R17): je Bild
## run_for(15), dann await auf das nächste Bild. Bei await gibt die Funktion die Kontrolle an Godot
## zurück; das zeichnet, nimmt Eingaben an und setzt sie zu Beginn des nächsten Bilds hier fort.
func _calculate(current: TimelineStatistics) -> void:
	while true:
		var done := current.run_for(BUDGET_MSEC)
		_show_progress()
		if done:
			_finish(false)
			return
		await get_tree().process_frame
		# Abgebrochen oder neu gestartet: Diese Rechnung ist vorbei, eine neue hat ihre eigene
		# Schleife.
		if current != statistics or not _running or not is_inside_tree():
			return


## Die Rechnung ist fertig oder abgebrochen: Die Tabelle zeigt das Ergebnis der fertigen Spiele.
## Ist noch keins fertig, bleibt sie leer, statt lauter Nullen zu zeigen; mit einem großen Katalog
## kann schon das erste Spiel länger dauern als ein Häppchen.
func _finish(aborted: bool) -> void:
	_running = false
	_aborted = aborted
	_elapsed_msec = (Time.get_ticks_usec() - _started_usec) / 1000.0
	_results = []
	if statistics.games_done > 0:
		_results = statistics.results()
	_fill_results()
	_show_progress()
	_update_all()


func _effective_catalog() -> EventCatalog:
	return editor.catalog.without_faulty(editor.issues())


func _has_catalog() -> bool:
	return editor != null and editor.catalog != null


func _can_start() -> bool:
	return _has_catalog() and _game_count() > 0


## Das Eingriffsprotokoll des Simulators als Kopie; ohne Quelle leer.
func _simulator_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if not interventions_source.is_valid():
		return records
	var source: Variant = interventions_source.call()
	if typeof(source) == TYPE_ARRAY:
		var list: Array = source
		records.assign(list.duplicate(true))
	return records


# --- Anzahl -----------------------------------------------------------------------------------

## Das Feld nimmt Ziffern und Tausenderpunkte an, höchstens 100.000 (FR-044). Wie beim Seed im
## Simulator meldet ein LineEdit text_changed erst am Ende des Bilds; was keine Ziffer und kein
## Punkt ist, fällt weg, bevor Klaus es sieht.
func _on_count_changed(text: String) -> void:
	var kept := ""
	for character in text:
		if (character >= "0" and character <= "9") or character == ".":
			kept += character
	var caret := _count_edit.caret_column - (text.length() - kept.length())
	# Die Länge zuerst, ohne führende Nullen: Eine sehr lange Zahl liefe in to_int() über.
	if _digits(kept).lstrip("0").length() > 6 or _parse_count(kept) > MAX_GAMES:
		kept = _grouped(MAX_GAMES)
		caret = kept.length()
	if kept != text:
		_count_edit.text = kept
		_count_edit.caret_column = clampi(caret, 0, kept.length())
	_update_controls()


## Beim Verlassen und mit Enter steht die Anzahl mit Tausenderpunkt da: „2500“ wird „2.500“.
func _normalize_count() -> void:
	var count := _game_count()
	if count > 0 and _count_edit.text != _grouped(count):
		_count_edit.text = _grouped(count)


func _game_count() -> int:
	return _parse_count(_count_edit.text)


static func _parse_count(text: String) -> int:
	var digits := _digits(text)
	return digits.to_int() if not digits.is_empty() else 0


static func _digits(text: String) -> String:
	return text.replace(".", "")


# --- Anzeige ----------------------------------------------------------------------------------

func _update_all() -> void:
	_update_controls()
	_update_notices()
	_update_intervention_info()
	_result_label.text = _result_text()
	_result_label.theme_type_variation = &"MutedLabel" if statistics == null else &""


## Sperrt, was gerade nicht geht: Während gerechnet wird, gelten Anzahl und Häkchen erst für den
## nächsten Start.
func _update_controls() -> void:
	var count_ok := _game_count() > 0
	_start_button.disabled = _running or not _can_start()
	if not _has_catalog():
		_start_button.tooltip_text = "Ohne lesbaren Katalog gibt es keine Statistik."
	elif not count_ok:
		_start_button.tooltip_text = "Gib zuerst eine Anzahl von 1 bis %s ein." \
			% _grouped(MAX_GAMES)
	else:
		_start_button.tooltip_text = ("%s Spiele mit den Seeds 1 bis %s durchrechnen, mit dem "
			+ "Katalog, wie er gerade dasteht, auch ungespeichert. Die Spieluhr bleibt, wie sie "
			+ "ist.") % [_grouped(_game_count()), _grouped(_game_count())]
	_cancel_button.disabled = not _running
	_cancel_button.tooltip_text = "Anhalten; das Ergebnis zeigt die fertigen Spiele."
	_count_edit.editable = not _running
	_with_interventions.disabled = _running
	_count_hint.visible = not count_ok
	_count_hint.text = "Gib eine Anzahl von 1 bis %s ein." % _grouped(MAX_GAMES)


func _apply_refresh() -> void:
	_refresh_queued = false
	_stale = statistics != null and _catalog_key() != _run_key
	_update_notices()
	_update_controls()
	_update_intervention_info()


## Die Hinweise über der Tabelle wie im Simulator: eine Warnung als Text in holz mit „?“, ein Fehler
## als gefülltes Feld in kassenrot mit „!“ (Style-Guide, „Farbrollen“).
func _update_notices() -> void:
	_catalog_notice.visible = statistics != null and _stale
	_excluded_notice.visible = statistics != null and not _excluded.is_empty()
	if _excluded_notice.visible:
		_excluded_notice.text = ("! Ausgenommen, weil fehlerhaft: %s. Die Gründe stehen in der "
			+ "Prüfung.") % ", ".join(_excluded)


## Was das Häkchen mitnimmt, etwa „Aus dem Simulator: 1 Modifikator, 1 Einplanung. 1 Absage gilt
## nur für ihren Seed und bleibt weg.“ Die Zeile steht nur mit Häkchen da; ohne braucht sie keiner,
## und die Tabelle bekommt die Höhe.
func _update_intervention_info() -> void:
	_intervention_info.visible = _with_interventions.button_pressed
	var records := _simulator_records()
	if records.is_empty():
		_intervention_info.text = "Im Simulator ist noch kein Eingriff gesammelt."
		return
	var parts := PackedStringArray()
	var added := _count_kinds(records, [TimelineRun.INTERVENTION_ADD_MODIFIER])
	var removed := _count_kinds(records, [TimelineRun.INTERVENTION_REMOVE_MODIFIER])
	var scheduled := _count_kinds(records, [TimelineRun.INTERVENTION_SCHEDULE])
	if added > 0:
		parts.append(_counted(added, "Modifikator", "Modifikatoren"))
	if removed > 0:
		parts.append("%s entfernt" % _counted(removed, "Modifikator", "Modifikatoren"))
	if scheduled > 0:
		parts.append(_counted(scheduled, "Einplanung", "Einplanungen"))
	var ignored := PackedStringArray()
	var cancelled := _count_kinds(records, [TimelineRun.INTERVENTION_CANCEL])
	var moved := _count_kinds(records, [TimelineRun.INTERVENTION_MOVE])
	if cancelled > 0:
		ignored.append(_counted(cancelled, "Absage", "Absagen"))
	if moved > 0:
		ignored.append(_counted(moved, "Verschiebung", "Verschiebungen"))
	var text := "Aus dem Simulator: "
	if parts.is_empty():
		text += "kein Modifikator, keine Einplanung."
	else:
		text += ", ".join(parts) + "."
	if not ignored.is_empty():
		var single := cancelled + moved == 1
		text += " %s %s nur für ihren Seed und %s weg." % [" und ".join(ignored),
			"gilt" if single else "gelten", "bleibt" if single else "bleiben"]
	_intervention_info.text = text


## „Ergebnis über 1.000 Spiele, Seeds 1 bis 1.000, ohne Eingriffe; gerechnet in 8,1 s.“
func _result_text() -> String:
	if statistics == null:
		return "Noch keine Statistik. „Starten“ rechnet die Spiele mit den Seeds ab 1 durch."
	var count := statistics.game_count
	if _running:
		return "Rechnet %s Spiele mit den Seeds 1 bis %s …" % [_grouped(count), _grouped(count)]
	var done := statistics.games_done
	var with_text := "ohne Eingriffe" if _applied == 0 else "mit %s aus dem Simulator" \
		% _counted(_applied, "Eingriff", "Eingriffen")
	if _aborted:
		if done == 0:
			return "Abgebrochen, bevor ein Spiel fertig war; es gibt noch kein Ergebnis."
		return ("Abgebrochen nach %s von %s Spielen. Das Ergebnis zeigt die %s fertigen, Seeds 1 "
			+ "bis %s, %s.") % [_grouped(done), _grouped(count), _grouped(done), _grouped(done),
			with_text]
	return "Ergebnis über %s Spiele, Seeds 1 bis %s, %s; gerechnet in %s s." % [_grouped(done),
		_grouped(done), with_text, _decimal(_elapsed_msec / 1000.0, 1)]


## Fortschrittsbalken und daneben „37 % · 370 von 1.000 Spielen · 3,0 s“. Der Text steht neben
## dem Balken, nicht auf seiner Farbfläche.
func _show_progress() -> void:
	if statistics == null:
		_progress.max_value = 1
		_progress.value = 0
		_progress_label.text = ""
		return
	var count := statistics.game_count
	var done := statistics.games_done
	_progress.max_value = maxi(count, 1)
	_progress.value = done
	var percent := floori(100.0 * done / count) if count > 0 else 100
	var elapsed := _elapsed_msec
	if _running:
		elapsed = (Time.get_ticks_usec() - _started_usec) / 1000.0
	_progress_label.text = "%d %% · %s von %s Spielen · %s s" % [percent, _grouped(done),
		_grouped(count), _decimal(elapsed / 1000.0, 1)]


# --- Tabelle ----------------------------------------------------------------------------------

func _set_up_table() -> void:
	_table.columns = TITLES.size()
	_table.column_titles_visible = true
	_table.hide_root = true
	_table.hide_folding = true
	_table.select_mode = Tree.SELECT_ROW
	for column in _table.columns:
		_table.set_column_title(column, TITLES[column])
		_table.set_column_title_tooltip_text(column, TITLE_TIPS[column])
		# Zahlen stehen rechtsbündig, damit die Stellen untereinanderstehen (Style-Guide).
		var title_alignment := HORIZONTAL_ALIGNMENT_LEFT if column == Column.EVENT \
			else HORIZONTAL_ALIGNMENT_RIGHT
		_table.set_column_title_alignment(column, title_alignment)
		_table.set_column_clip_content(column, true)
		_table.set_column_expand(column, WIDTHS[column] == 0)
		if WIDTHS[column] > 0:
			_table.set_column_custom_minimum_width(column, WIDTHS[column])
	_table.create_item()


## Baut die Tabelle aus dem Ergebnis, eine Zeile je Ereignis nach Kennung: Mittelwert, kleinste
## und größte Anzahl, „ohne“ und „Obergrenze“ in Prozent, „–“ ohne Obergrenze (FR-044). Die
## gewählte Zeile bleibt gewählt, wenn es ihr Ereignis noch gibt.
func _fill_results() -> void:
	_syncing = true
	_zebra.forget()
	_table.clear()
	var root := _table.create_item()
	var selected: TreeItem = null
	for statistic in _results:
		var item := _table.create_item(root)
		item.set_text(Column.EVENT, _title_of(statistic))
		item.set_text(Column.MEAN, _decimal(statistic.mean(), 2))
		item.set_text(Column.MINIMUM, _grouped(statistic.minimum))
		item.set_text(Column.MAXIMUM, _grouped(statistic.maximum))
		item.set_text(Column.WITHOUT, _percent(statistic.share_without()))
		item.set_text(Column.AT_MAX, _percent(statistic.share_at_max())
			if statistic.games_at_max >= 0 else NO_LIMIT)
		for column in range(Column.MEAN, Column.AT_MAX + 1):
			item.set_text_alignment(column, HORIZONTAL_ALIGNMENT_RIGHT)
		_set_tooltips(item, statistic)
		item.set_metadata(Column.EVENT, statistic.event_id)
		if statistic.event_id == _selected_id:
			item.select(Column.EVENT)
			selected = item
	_zebra.paint_all()
	_syncing = false
	if selected != null:
		_table.scroll_to_item(selected)
	elif not _results.is_empty():
		_selected_id = ""
	_show_years()


func _set_tooltips(item: TreeItem, statistic: EventStatistic) -> void:
	var games := _grouped(statistic.games)
	var limit := _limit_of(statistic.event_id)
	item.set_tooltip_text(Column.EVENT, "%s (%s) · %s" % [_title_of(statistic),
		statistic.event_id, _kind_text(statistic.event_id, limit)])
	item.set_tooltip_text(Column.MEAN, "Im Schnitt %s Beginne je Spiel, zusammen %s in %s Spielen"
		% [_decimal(statistic.mean(), 2), _grouped(statistic.total), games])
	item.set_tooltip_text(Column.MINIMUM, "Die kleinste Anzahl in einem der %s Spiele" % games)
	item.set_tooltip_text(Column.MAXIMUM, "Die größte Anzahl in einem der %s Spiele" % games)
	item.set_tooltip_text(Column.WITHOUT, "In %s von %s Spielen nie begonnen" % [
		_grouped(statistic.games_without), games])
	if statistic.games_at_max >= 0:
		item.set_tooltip_text(Column.AT_MAX, "In %s von %s Spielen die Obergrenze %s erreicht"
			% [_grouped(statistic.games_at_max), games, _grouped(limit)])
	else:
		item.set_tooltip_text(Column.AT_MAX, ("Keine Obergrenze: Sie gibt es nur bei Ereignissen "
			+ "über Wahrscheinlichkeit mit Höchstzahl und bei gesetzten."))


func _on_result_selected() -> void:
	if _syncing:
		return
	var item := _table.get_selected()
	if item == null:
		return
	_selected_id = item.get_metadata(Column.EVENT)
	_show_years()


# --- Verteilung auf die Jahre -----------------------------------------------------------------

## Überschrift und Hinweis der Verteilung für die gewählte Zeile; die Balken zeichnet
## _draw_years().
func _show_years() -> void:
	var statistic := _selected_statistic()
	if statistic == null:
		_year_title.text = "Verteilung auf die Jahre: Wähle eine Zeile der Tabelle."
		_year_title.theme_type_variation = &"MutedLabel"
		_chart.tooltip_text = ""
	else:
		_year_title.text = "Verteilung auf die Jahre: %s, Beginne im Schnitt je Spiel" \
			% _title_of(statistic)
		_year_title.theme_type_variation = &""
		var lines := PackedStringArray()
		var values := _year_values(statistic)
		for index in EventStatistic.YEARS:
			lines.append("%d: %s je Spiel, %s Beginne" % [EventStatistic.FIRST_YEAR + index,
				_decimal(values[index], 2), _grouped(statistic.per_year[index])])
		_chart.tooltip_text = "\n".join(lines)
	_chart.queue_redraw()


## Zeichnet die Verteilung (FR-044): je Jahr ein Balken in der Farbe der Kategorie, darüber der
## Wert, darunter das Jahr, dazu eine Grundlinie in tusche. Text steht nur auf dem Grund, nie auf
## der Farbfläche (Style-Guide, „Kategorienfarben“). Wo was liegt, rechnet year_bars().
func _draw_years() -> void:
	var bars := year_bars()
	if bars.is_empty():
		return
	var font := _chart.get_theme_default_font()
	var font_size := _chart.get_theme_font_size(&"small", &"Werkstatt")
	var ascent := font.get_ascent(font_size)
	var base := 0.0
	for item in bars:
		var bar: Rect2 = item["bar"]
		base = bar.end.y
		if bar.size.y > 0.0:
			_chart.draw_rect(bar, item["color"])
		for key: String in ["value", "year"]:
			var text: String = item[key + "_text"]
			var rect: Rect2 = item[key + "_rect"]
			if not text.is_empty():
				_chart.draw_string(font, Vector2(rect.position.x, rect.position.y + ascent), text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiPalette.TUSCHE)
	_chart.draw_rect(Rect2(0.0, base, _chart.size.x, 1.0), UiPalette.TUSCHE)


## Beginne im Schnitt je Spiel für jedes Jahr.
static func _year_values(statistic: EventStatistic) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	for count in statistic.per_year:
		values.append(float(count) / statistic.games if statistic.games > 0 else 0.0)
	return values


## Die Farbe der Balken: die Kategorienfarbe des Ereignisses, oder kassenrot, die Rolle Fehler, wenn
## das Token keine Kategorienfarbe ist (V21), wie im Zeitstrahl.
func _bar_color(event_id: String) -> Color:
	var event := statistics.catalog.get_event(event_id) if statistics != null else null
	var category := statistics.catalog.get_category(event.category) if event != null else null
	if category != null and UiPalette.CATEGORY_TOKENS.has(category.color):
		return UiPalette.by_token(category.color)
	return UiPalette.KASSENROT


## Der Wert über einem Balken; leer bei 0, denn dann steht dort kein Balken.
static func _value_text(value: float) -> String:
	if value <= 0.0:
		return ""
	if value < 0.005:
		return "< 0,01"
	return _decimal(value, 2)


## Das Rechteck eines Texts, mittig in der Spalte ab [param left] mit der Breite [param width],
## oben bei [param top]; auf ganze Pixel gerundet, damit die Schrift scharf steht.
static func _label_rect(text: String, font: Font, font_size: int, left: float, width: float,
		top: float) -> Rect2:
	var text_width := _text_width(text, font, font_size)
	return Rect2(roundf(left + (width - text_width) / 2.0), roundf(top), text_width,
		font.get_height(font_size))


static func _text_width(text: String, font: Font, font_size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _selected_statistic() -> EventStatistic:
	for statistic in _results:
		if statistic.event_id == _selected_id:
			return statistic
	return null


# --- Katalog ----------------------------------------------------------------------------------

## Der Katalog, mit dem ein neuer Start jetzt rechnen würde, als Text: sein Inhalt
## (CatalogEditor.content_key()), dazu die Kennungen, die without_faulty() wegen Fehlern auslässt.
## Wie im Simulator: Macht Klaus eine Änderung rückgängig, ist der Text wieder derselbe, und der
## Hinweis verschwindet.
func _catalog_key() -> String:
	if not _has_catalog():
		return ""
	var faulty := PackedStringArray()
	for issue in editor.issues():
		if issue.severity == CatalogIssue.Severity.ERROR and not faulty.has(issue.event_id):
			faulty.append(issue.event_id)
	faulty.sort()
	return "%s\n%s" % [editor.content_key(), ",".join(faulty)]


## Die Titel der Ereignisse, die im Katalog der Werkstatt stehen, aber nicht in der Statistik.
func _excluded_titles() -> PackedStringArray:
	var kept := {}
	for event in statistics.catalog.events:
		kept[event.id] = true
	var titles := PackedStringArray()
	for event in editor.catalog.events:
		if not kept.has(event.id):
			titles.append("„%s“" % _event_title(event))
	return titles


func _limit_of(event_id: String) -> int:
	var event := statistics.catalog.get_event(event_id) if statistics != null else null
	return TimelineStatistics.upper_limit(event) if event != null else -1


## „über Wahrscheinlichkeit, Obergrenze 4“ oder „fix, keine Obergrenze“.
func _kind_text(event_id: String, limit: int) -> String:
	var event := statistics.catalog.get_event(event_id)
	var kind := event.kind_label() if event != null else "?"
	if limit >= 0:
		return "%s, Obergrenze %s" % [kind, _grouped(limit)]
	return "%s, keine Obergrenze" % kind


# --- Hilfen -----------------------------------------------------------------------------------

static func _count_kinds(records: Array[Dictionary], kinds: Array) -> int:
	var count := 0
	for record in records:
		if kinds.has(str(record.get("kind", ""))):
			count += 1
	return count


static func _title_of(statistic: EventStatistic) -> String:
	if not statistic.title.strip_edges().is_empty():
		return statistic.title
	return statistic.event_id


static func _event_title(event: TimelineEvent) -> String:
	if not event.title.strip_edges().is_empty():
		return event.title
	return event.id if not event.id.is_empty() else "(ohne Titel)"


## „1 Modifikator“, „2 Modifikatoren“.
static func _counted(count: int, one: String, many: String) -> String:
	return "%s %s" % [_grouped(count), one if count == 1 else many]


## Eine Anzahl mit Tausenderpunkt wie im Spiel: 1234 als „1.234“.
static func _grouped(count: int) -> String:
	var digits := str(absi(count))
	var groups := PackedStringArray()
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.insert(0, digits)
	return ("-" if count < 0 else "") + ".".join(groups)


## Eine Zahl ab 0 mit [param places] Nachkommastellen, Komma und Tausenderpunkt: 1234,5 als
## „1.234,50“. Negativ wird hier nichts: Mittelwerte, Anteile und Sekunden sind es nie.
static func _decimal(value: float, places: int) -> String:
	var parts := (("%." + str(places) + "f") % maxf(value, 0.0)).split(".")
	var text := _grouped(parts[0].to_int())
	if parts.size() > 1:
		text += "," + parts[1]
	return text


## Ein Anteil als Prozent mit einer Nachkommastelle: 0,8392 als „83,9 %“.
static func _percent(share: float) -> String:
	return "%s %%" % _decimal(share * 100.0, 1)
