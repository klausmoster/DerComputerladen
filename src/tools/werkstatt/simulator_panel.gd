class_name SimulatorPanel
extends VBoxContainer

## Der Simulator der Werkstatt (FR-040 bis FR-042; contracts/werkstatt.md, „Simulator
## (SimulatorPanel)“): Klaus erzeugt aus einem Seed und dem Katalog einen Fahrplan und spielt ihn
## ab, ohne das Spiel zu starten. Oben stehen Seed, „Würfeln“, „Fahrplan erzeugen“ und die Schalter
## für die Zeit mit dem Stand des Laufs. Links steht der Fahrplan als Tabelle, darunter die
## Begründung des gewählten Termins, rechts das Protokoll.
##
## Gerechnet wird mit einem eigenen TimelineRun auf einer Kopie des Katalogs, wie er gerade in der
## Werkstatt steht, auch ungespeichert, und ohne die Ereignisse mit Fehlern (without_faulty()). Der
## Simulator kennt weder die Spieluhr noch das Autoload Timeline, und den Katalog liest er über den
## CatalogEditor nur.
##
## Ändert sich der Katalog während eines Laufs, rechnet der Lauf mit seiner Kopie weiter, und ein
## Hinweis sagt „Katalog geändert, neu starten“. Die Werkstatt ruft dafür nach catalog_changed und
## nach issues_changed refresh() auf: Beides kann den Katalog ändern, mit dem ein neuer Lauf
## rechnen würde.
##
## Platz für Phase 8: Die Knöpfe für Neustarts und Proben kommen in die Zeile mit dem Seed, die
## Eingriffe rechts unter das Protokoll, in die noch leere InterventionBox.

## Klaus hat im Fahrplan einen Termin gewählt; [param id] ist die Kennung seines Ereignisses. Die
## Werkstatt wählt das Ereignis dann auch in Liste, Formular und Zeitstrahl.
signal event_selected(id: String)

enum PlanColumn { DATE, EVENT, ORIGIN, STATE }

## Der größte Seed (FR-014, FR-040), wie im Autoload Timeline und in der Textausgabe.
const MAX_SEED := 2147483647
const PLAN_TITLES: Array[String] = ["Datum", "Ereignis", "Herkunft", "Zustand"]
## Breite der schmalen Spalten; das Ereignis nimmt den Rest.
const PLAN_WIDTHS: Array[int] = [100, 0, 160, 100]
const PROTOCOL_TITLES: Array[String] = ["Protokoll"]
const PROTOCOL_WIDTHS: Array[int] = [0]

## Der einzige, der den Katalog ändert; der Simulator liest nur daraus. Die Werkstatt setzt ihn.
var editor: CatalogEditor
## Der aktuelle Lauf; null, bis „Fahrplan erzeugen“ einen anlegt.
var run: TimelineRun

## Der Katalog, mit dem der Lauf rechnet, als Text (_catalog_key()). Daran erkennt refresh(), dass
## sich der Katalog seitdem geändert hat.
var _run_key := ""
## Ob ein neuer Lauf jetzt mit einem anderen Katalog rechnen würde als der aktuelle.
var _stale := false
## Die Titel der Ereignisse, die der Lauf wegen Fehlern auslässt.
var _excluded := PackedStringArray()
## Die laufende Nummer des gewählten Termins; −1 heißt keiner.
var _selected_serial := -1
var _refresh_queued := false
## Ob der Simulator die Tabelle gerade selbst füllt; ihre Signale zählen dann nicht.
var _syncing := false
## Streifen, Auswahl und Überfahren der beiden Tabellen, wie in Liste und Prüfung (Zebra).
var _plan_zebra: Zebra
var _protocol_zebra: Zebra

@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _roll_button: Button = %RollButton
@onready var _generate_button: Button = %GenerateButton
@onready var _day_button: Button = %DayButton
@onready var _month_button: Button = %MonthButton
@onready var _year_button: Button = %YearButton
@onready var _until_button: Button = %UntilButton
@onready var _until_edit: LineEdit = %UntilEdit
@onready var _end_button: Button = %EndButton
@onready var _date_label: Label = %DateLabel
@onready var _input_hint: Label = %InputHint
@onready var _catalog_notice: Label = %CatalogNotice
@onready var _excluded_notice: Label = %ExcludedNotice
@onready var _state_filter: OptionButton = %StateFilter
@onready var _plan_count: Label = %PlanCount
@onready var _plan_table: Tree = %PlanTable
@onready var _detail_title: Label = %DetailTitle
@onready var _detail_text: Label = %DetailText
@onready var _protocol: Tree = %Protocol


func _ready() -> void:
	_set_up_table(_plan_table, PLAN_TITLES, PLAN_WIDTHS)
	_set_up_table(_protocol, PROTOCOL_TITLES, PROTOCOL_WIDTHS)
	_plan_zebra = Zebra.new(_plan_table)
	_protocol_zebra = Zebra.new(_protocol)
	_state_filter.add_item("Alle Zustände")
	# Die Namen der Zustände kennt ScheduleEntry; ein Termin ohne Lauf liefert sie.
	var probe := ScheduleEntry.new()
	for state: int in ScheduleEntry.State.values():
		probe.state = state as ScheduleEntry.State
		_state_filter.add_item(probe.state_label())
	_seed_edit.text_changed.connect(_on_seed_changed)
	_seed_edit.text_submitted.connect(func(_text: String) -> void: generate_plan())
	_roll_button.pressed.connect(roll_seed)
	_generate_button.pressed.connect(generate_plan)
	_day_button.pressed.connect(func() -> void: play_until(_today() + 1))
	_month_button.pressed.connect(func() -> void: play_until(_first_of_next_month(_today())))
	_year_button.pressed.connect(func() -> void: play_until(_first_of_next_year(_today())))
	_until_button.pressed.connect(_on_until_pressed)
	_until_edit.text_submitted.connect(func(_text: String) -> void: _on_until_pressed())
	_end_button.pressed.connect(func() -> void: play_until(TimelineRun.LAST_DAY))
	_state_filter.item_selected.connect(func(_index: int) -> void: _fill_plan())
	_plan_table.item_selected.connect(_on_plan_item_selected)
	_fill_plan()
	_show_detail()
	_update_notices()
	_update_controls()


# --- Für die Werkstatt ------------------------------------------------------------------------

## Nach catalog_changed und issues_changed: prüft am Ende des Bilds, ob ein neuer Lauf jetzt mit
## einem anderen Katalog rechnen würde als der aktuelle, und zeigt dann „Katalog geändert, neu
## starten“. Der Lauf selbst behält seinen Stand (FR-042). Am Ende des Bilds, weil beide Signale
## nach jeder Änderung kommen; so wird nur einmal verglichen.
func refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_apply_refresh.call_deferred()


## „Würfeln“: ein zufälliger Seed von 0 bis 2.147.483.647 ins Feld. Erzeugt wird erst mit
## „Fahrplan erzeugen“.
func roll_seed() -> void:
	_seed_edit.text = str(randi_range(0, MAX_SEED))
	_update_controls()


## „Fahrplan erzeugen“ (FR-040, FR-042): ein neuer Lauf mit dem Seed aus dem Feld, auf einer Kopie
## des Katalogs, wie er gerade in der Werkstatt steht, ohne die Ereignisse mit Fehlern. Der Lauf
## steht vor dem 01.01.1985; im Fahrplan stehen alle Termine, die schon feststehen, als „geplant“
## (US5, Szenario 1).
func generate_plan() -> void:
	if not _can_generate():
		return
	run = TimelineRun.new(editor.catalog.without_faulty(editor.issues()), _seed_edit.text.to_int())
	_run_key = _catalog_key()
	_stale = false
	_excluded = _excluded_titles()
	_selected_serial = -1
	_show_input_problem("")
	_protocol_zebra.forget()
	_protocol.clear()
	_protocol.create_item()
	_fill_plan()
	_show_detail()
	_update_notices()
	_update_controls()


## Spielt den Lauf bis einschließlich [param day] ab, höchstens bis zum 31.12.1999 (FR-041). Der
## erste Schritt nach „Fahrplan erzeugen“ spielt den 01.01.1985 ab; Tage, die schon abgespielt
## sind, ändern nichts. Danach stehen die neuen Meldungen im Protokoll und die Zustände im Fahrplan.
func play_until(day: int) -> void:
	if run == null:
		return
	var target := mini(day, TimelineRun.LAST_DAY)
	if target <= run.today:
		return
	_add_to_protocol(run.advance_to(target))
	_show_input_problem("")
	_fill_plan()
	_show_detail()
	_update_controls()


# --- Seed und Schalter ------------------------------------------------------------------------

## Das Seed-Feld nimmt nur Ziffern an, höchstens 2.147.483.647 (FR-040). Ein LineEdit meldet
## text_changed erst am Ende des Bilds, gesammelt für alles, was in diesem Bild getippt oder
## eingefügt wurde; gezeichnet ist da noch nichts. Was keine Ziffer ist, fällt also weg, bevor
## Klaus es sieht. Eine größere Zahl wird zum größten Seed.
func _on_seed_changed(text: String) -> void:
	var digits := ""
	for character in text:
		if character >= "0" and character <= "9":
			digits += character
	# Der Cursor stand hinter dem Getippten; was wegfällt, stand davor.
	var caret := _seed_edit.caret_column - (text.length() - digits.length())
	# Die Länge zuerst, ohne führende Nullen: Eine sehr lange Zahl liefe in to_int() über.
	if digits.lstrip("0").length() > 10 or digits.to_int() > MAX_SEED:
		digits = str(MAX_SEED)
		caret = digits.length()
	if digits != text:
		_seed_edit.text = digits
		_seed_edit.caret_column = clampi(caret, 0, digits.length())
	_update_controls()


## „Bis“ mit dem Datum aus dem Feld daneben, auch ohne führende Nullen wie „1.3.1993“. Ein
## Datum, das nicht passt, spielt nichts ab; ein Hinweis sagt, warum.
func _on_until_pressed() -> void:
	if run == null:
		return
	var parsed := EventForm.parse_date(_until_edit.text)
	var day: int = parsed[1] if parsed[0] else -1
	var problem := ""
	if _until_edit.text.strip_edges().is_empty():
		problem = "Gib ein Datum ein, etwa 31.12.1990."
	elif not parsed[0]:
		problem = parsed[1]
	elif day < TimelineRun.FIRST_DAY or day > TimelineRun.LAST_DAY:
		problem = "Der Simulator spielt vom 01.01.1985 bis zum 31.12.1999."
	elif day <= run.today:
		problem = "Der %s ist schon abgespielt." % EventForm.format_date(day)
	_show_input_problem(problem)
	if problem.is_empty():
		_until_edit.text = EventForm.format_date(day)
		play_until(day)


## Zeigt [param problem] unter den Schaltern; das Datumsfeld bekommt dann die rote Kontur des
## Fehlers (Style-Guide, „Bedienelemente“). Ein leerer Text nimmt beides weg.
func _show_input_problem(problem: String) -> void:
	_input_hint.text = problem
	_input_hint.visible = not problem.is_empty()
	_until_edit.theme_type_variation = &"" if problem.is_empty() else &"ErrorLineEdit"


func _today() -> int:
	return run.today if run != null else TimelineRun.FIRST_DAY - 1


## Der Erste des Monats nach [param day], wie GameClock.advance_one_month(). Vor dem Spielbeginn
## steht der Lauf auf −1, dem 31.12.1984, und der nächste Erste ist der 01.01.1985.
static func _first_of_next_month(day: int) -> int:
	var date := GameDate.from_day_index(day)
	if date.month == 12:
		return GameDate.new(date.year + 1, 1, 1).to_day_index()
	return GameDate.new(date.year, date.month + 1, 1).to_day_index()


## Der 1. Januar des Jahres nach [param day], wie GameClock.advance_one_year(); vor dem
## Spielbeginn also der 01.01.1985.
static func _first_of_next_year(day: int) -> int:
	return GameDate.new(GameDate.from_day_index(day).year + 1, 1, 1).to_day_index()


func _can_generate() -> bool:
	return editor != null and editor.catalog != null and not _seed_edit.text.is_empty()


## Sperrt, was gerade nicht geht, und schreibt den Stand des Laufs.
func _update_controls() -> void:
	_generate_button.disabled = not _can_generate()
	if editor == null or editor.catalog == null:
		_generate_button.tooltip_text = "Ohne lesbaren Katalog gibt es keinen Fahrplan."
	elif _seed_edit.text.is_empty():
		_generate_button.tooltip_text = "Gib zuerst einen Seed ein oder würfle einen."
	else:
		_generate_button.tooltip_text = ("Neuer Lauf mit diesem Seed und dem Katalog, wie er "
			+ "gerade dasteht, auch ungespeichert. Die Spieluhr bleibt, wie sie ist.")
	var can_play := run != null and not run.is_finished()
	for button: Button in [_day_button, _month_button, _year_button, _until_button, _end_button]:
		button.disabled = not can_play
	_date_label.text = _date_text()


## „Stand: 22.03.1993 · Seed 4711“; vor dem ersten Schritt „vor dem 01.01.1985“.
func _date_text() -> String:
	if run == null:
		return "Kein Katalog geladen" if editor == null or editor.catalog == null \
			else "Noch kein Fahrplan"
	var when := "vor dem 01.01.1985"
	if run.is_finished():
		when = "%s, Spielende" % EventForm.format_date(run.today)
	elif run.today >= TimelineRun.FIRST_DAY:
		when = EventForm.format_date(run.today)
	return "Stand: %s · Seed %d" % [when, run.seed]


# --- Katalog ----------------------------------------------------------------------------------

func _apply_refresh() -> void:
	_refresh_queued = false
	_stale = run != null and _catalog_key() != _run_key
	_update_notices()
	_update_controls()


## Der Katalog, mit dem ein neuer Lauf jetzt rechnen würde, als Text: der Katalog in seiner
## kanonischen Form und die Kennungen, die without_faulty() wegen Fehlern auslässt. Ist beides
## gleich, rechnete ein neuer Lauf mit demselben Katalog. So verschwindet der Hinweis auch wieder,
## wenn Klaus eine Änderung rückgängig macht.
func _catalog_key() -> String:
	if editor == null or editor.catalog == null:
		return ""
	var faulty := PackedStringArray()
	for issue in editor.issues():
		if issue.severity == CatalogIssue.Severity.ERROR and not faulty.has(issue.event_id):
			faulty.append(issue.event_id)
	faulty.sort()
	return "%s\n%s" % [editor.catalog.to_json(), ",".join(faulty)]


## Die Titel der Ereignisse, die im Katalog der Werkstatt stehen, aber nicht im Lauf: Sie haben
## Fehler, und without_faulty() hat sie ausgenommen.
func _excluded_titles() -> PackedStringArray:
	var kept := {}
	for event in run.catalog.events:
		kept[event.id] = true
	var titles := PackedStringArray()
	for event in editor.catalog.events:
		if not kept.has(event.id):
			titles.append("„%s“" % _title_of(event))
	return titles


## Die Hinweise über der Tabelle: eine Warnung als Text in holz mit „?“, ein Fehler als gefülltes
## Feld in kassenrot mit „!“ (Style-Guide, „Farbrollen“).
func _update_notices() -> void:
	_catalog_notice.visible = run != null and _stale
	_excluded_notice.visible = run != null and not _excluded.is_empty()
	if _excluded_notice.visible:
		_excluded_notice.text = ("! Ausgenommen, weil fehlerhaft: %s. Die Gründe stehen in der "
			+ "Prüfung.") % ", ".join(_excluded)


# --- Fahrplan ---------------------------------------------------------------------------------

## Baut die Tabelle neu: je Termin eine Zeile, nach dem Filter für den Zustand. Der gewählte
## Termin bleibt gewählt und zu sehen; ohne Auswahl rollt die Tabelle zum ersten Termin nach dem
## Stand des Laufs, am Spielende ans Ende.
func _fill_plan() -> void:
	_syncing = true
	_plan_zebra.forget()
	_plan_table.clear()
	var root := _plan_table.create_item()
	var wanted := _state_filter.selected - 1
	var shown := 0
	var selected: TreeItem = null
	var upcoming: TreeItem = null
	var last: TreeItem = null
	if run != null:
		for entry in run.entries:
			if wanted >= 0 and entry.state != wanted:
				continue
			last = _add_plan_row(root, entry)
			shown += 1
			if entry.serial == _selected_serial:
				last.select(PlanColumn.DATE)
				selected = last
			if upcoming == null and entry.day > run.today:
				upcoming = last
	_plan_zebra.paint_all()
	_syncing = false
	_plan_count.text = _count_text(shown, run.entries.size() if run != null else 0)
	if selected != null:
		_plan_table.scroll_to_item(selected)
	elif upcoming != null:
		_plan_table.scroll_to_item(upcoming, true)
	elif last != null:
		_plan_table.scroll_to_item(last)


func _add_plan_row(root: TreeItem, entry: ScheduleEntry) -> TreeItem:
	var item := _plan_table.create_item(root)
	item.set_text(PlanColumn.DATE, EventForm.format_date(entry.day))
	item.set_text(PlanColumn.EVENT, _title_of(entry.event))
	item.set_text(PlanColumn.ORIGIN, entry.origin_label())
	item.set_text(PlanColumn.STATE, entry.state_label())
	item.set_metadata(PlanColumn.DATE, entry.serial)
	var tooltip := "%s\n%s · %s · %s" % [_title_of(entry.event), _period(entry),
		entry.origin_label(), entry.state_label()]
	for column in PlanColumn.size():
		item.set_tooltip_text(column, tooltip)
	return item


## „152 Termine“; mit Filter „37 von 152 Terminen“.
static func _count_text(shown: int, total: int) -> String:
	if shown == total:
		return "%s %s" % [_grouped(total), "Termin" if total == 1 else "Termine"]
	return "%s von %s %s" % [_grouped(shown), _grouped(total),
		"Termin" if total == 1 else "Terminen"]


func _on_plan_item_selected() -> void:
	if _syncing or run == null:
		return
	var item := _plan_table.get_selected()
	if item == null:
		return
	_selected_serial = item.get_metadata(PlanColumn.DATE)
	_show_detail()
	var entry := run.get_entry(_selected_serial)
	if entry != null:
		event_selected.emit(entry.event.id)


## Unter der Tabelle: warum der gewählte Termin dort steht (SC-007), und seine verzögerten
## Wirkungen (FR-013, FR-041).
func _show_detail() -> void:
	var entry: ScheduleEntry = run.get_entry(_selected_serial) if run != null else null
	_detail_title.visible = entry != null
	_detail_text.theme_type_variation = &"" if entry != null else &"MutedLabel"
	if entry == null:
		_detail_text.text = "Wähle einen Termin; hier steht dann, warum er dort steht." \
			if run != null else "Erzeuge einen Fahrplan und wähle einen Termin."
		return
	_detail_title.text = "%s (%s)" % [_title_of(entry.event), entry.event.id]
	_detail_text.text = _explanation(entry)


## Zeitraum, Herkunft und Zustand, die Begründung aus explain() und die verzögerten Wirkungen mit
## ihrem Tag. Bei einem gewürfelten Termin nennt die Begründung Würfelwert, Grundchance,
## Modifikatoren und Schwelle (US5, Szenario 3).
static func _explanation(entry: ScheduleEntry) -> String:
	var when := _period(entry)
	if entry.end_day > entry.day and entry.end_day > TimelineRun.LAST_DAY:
		when += " (Ende nach Spielende)"
	var lines := PackedStringArray([
		"%s · %s · %s" % [when, entry.origin_label(), entry.state_label()],
		"Begründung: %s" % entry.explain(),
	])
	var due := entry.due_effects()
	if due.is_empty():
		lines.append("Verzögerte Wirkungen: keine")
	elif entry.state == ScheduleEntry.State.SKIPPED or entry.state == ScheduleEntry.State.CANCELLED:
		lines.append("Verzögerte Wirkungen: entfallen mit dem Termin")
	else:
		lines.append("Verzögerte Wirkungen:")
		for item in due:
			var effect: EventEffect = item["effect"]
			var day: int = item["day"]
			var line := "%s  %s" % [EventForm.format_date(day), effect.describe()]
			if day > TimelineRun.LAST_DAY:
				line += " (nach Spielende, wird nicht gemeldet)"
			lines.append(line)
	return "\n".join(lines)


## „22.03.1993“, mit Dauer „01.11.1993 bis 31.12.1993“: Der letzte Tag ist der vor end_day, denn
## das Ende wird am Tag danach gemeldet.
static func _period(entry: ScheduleEntry) -> String:
	var start := EventForm.format_date(entry.day)
	if entry.end_day <= entry.day:
		return start
	return "%s bis %s" % [start, EventForm.format_date(entry.end_day - 1)]


# --- Protokoll --------------------------------------------------------------------------------

## Hängt die Meldungen eines Schritts an, je eine Zeile mit TimelineMessage.to_line(), genau wie
## in der Textausgabe mit --protokoll, und rollt zur letzten. Eine zu lange Zeile endet mit „…“;
## ganz steht sie im Hinweis. Umbrechen ginge auch (TreeItem.set_autowrap_mode()), aber dann kennt
## der Tree die Höhe einer Zeile erst, wenn er sie einmal gezeichnet hat, und scroll_to_item()
## landete mitten im Protokoll.
func _add_to_protocol(messages: Array[TimelineMessage]) -> void:
	var root := _protocol.get_root()
	var index := root.get_child_count()
	var last: TreeItem = null
	for message in messages:
		var line := message.to_line()
		last = _protocol.create_item(root)
		last.set_text(0, line)
		last.set_tooltip_text(0, line)
		_protocol_zebra.paint(last, index)
		index += 1
	if last != null:
		_protocol.scroll_to_item(last)


# --- Hilfen -----------------------------------------------------------------------------------

## Spalten mit Köpfen, eine Zeile je Eintrag ohne Klapp-Pfeil, Auswahl der ganzen Zeile; wie in
## der Prüfung (IssuesPanel).
static func _set_up_table(tree: Tree, titles: Array[String], widths: Array[int]) -> void:
	tree.columns = titles.size()
	tree.column_titles_visible = true
	tree.hide_root = true
	tree.hide_folding = true
	tree.select_mode = Tree.SELECT_ROW
	for column in tree.columns:
		tree.set_column_title(column, titles[column])
		tree.set_column_title_alignment(column, HORIZONTAL_ALIGNMENT_LEFT)
		tree.set_column_clip_content(column, true)
		tree.set_column_expand(column, widths[column] == 0)
		if widths[column] > 0:
			tree.set_column_custom_minimum_width(column, widths[column])
	tree.create_item()


static func _title_of(event: TimelineEvent) -> String:
	if not event.title.strip_edges().is_empty():
		return event.title
	return event.id if not event.id.is_empty() else "(ohne Titel)"


## Eine Anzahl mit Tausenderpunkt wie im Spiel: 1234 als „1.234“.
static func _grouped(count: int) -> String:
	var digits := str(count)
	var groups := PackedStringArray()
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.insert(0, digits)
	return ".".join(groups)
