extends Control

## Test-/Demo-Oberfläche für die Timeline-Engine.
## Zeigt das aktuelle Datum, lässt die Zeit schrittweise oder automatisch laufen
## und protokolliert jedes ausgelöste Ereignis samt seiner Kettenreaktionen.

var _date_label: Label
var _season_label: Label
var _play_button: Button
var _speed_label: Label
var _log: RichTextLabel


func _ready() -> void:
	_build_ui()

	GameClock.day_passed.connect(_on_day_passed)
	GameClock.season_changed.connect(_on_season_changed)
	GameClock.reached_end.connect(_on_reached_end)
	Timeline.event_fired.connect(_on_event_fired)
	Timeline.effect_applied.connect(_on_effect_applied)

	_refresh_date(GameClock.date)
	_log_line("[i][color=#888888]Bereit – Januar 1985. Mit den Buttons oder ▶ die Zeit laufen lassen.[/color][/i]")


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_date_label = Label.new()
	_date_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_date_label)

	_season_label = Label.new()
	_season_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(_season_label)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	vbox.add_child(controls)

	_add_button(controls, "+1 Tag", func() -> void: GameClock.advance_day())
	_add_button(controls, "+1 Monat", func() -> void: GameClock.advance_one_month())
	_add_button(controls, "+1 Jahr", func() -> void: GameClock.advance_one_year())

	_play_button = Button.new()
	_play_button.text = "▶ Play"
	_play_button.pressed.connect(_on_play_pressed)
	controls.add_child(_play_button)

	controls.add_child(VSeparator.new())

	var speed_caption := Label.new()
	speed_caption.text = "Tempo:"
	speed_caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	controls.add_child(speed_caption)

	var speed_slider := HSlider.new()
	speed_slider.min_value = 1
	speed_slider.max_value = 60
	speed_slider.step = 1
	speed_slider.value = GameClock.days_per_second
	speed_slider.custom_minimum_size = Vector2(120, 0)
	speed_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speed_slider.value_changed.connect(_on_speed_changed)
	controls.add_child(speed_slider)

	_speed_label = Label.new()
	_speed_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	controls.add_child(_speed_label)
	_on_speed_changed(GameClock.days_per_second)

	var log_panel := PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(log_panel)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.selection_enabled = true
	log_panel.add_child(_log)


func _add_button(parent: Node, text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(on_pressed)
	parent.add_child(button)


# --- Signale ------------------------------------------------------------

func _on_day_passed(date: GameDate) -> void:
	_refresh_date(date)


func _on_season_changed(is_holiday: bool) -> void:
	if is_holiday:
		_log_line("[color=#e0a030]★ Weihnachtsgeschäft beginnt – Hochsaison![/color]")


func _on_reached_end() -> void:
	_log_line("[b][color=#ff6060]— Ende der Zeitleiste (1999) —[/color][/b]")
	_update_play_button()


func _on_event_fired(event: TimelineEvent, date: GameDate) -> void:
	_log_line("[b]%s[/b]  [color=#%s]%s[/color]  [color=#888888](%s)[/color]" % [
		str(date), _category_color(event.category), event.title, event.category_label(),
	])
	if not event.description.is_empty():
		_log_line("    [color=#9aa0a6]%s[/color]" % event.description)


func _on_effect_applied(effect: EventEffect, _source: TimelineEvent, _date: GameDate) -> void:
	_log_line("        [color=#88bbff]→ %s[/color]" % effect.describe())


# --- UI-Reaktionen ------------------------------------------------------

func _on_play_pressed() -> void:
	GameClock.toggle_paused()
	_update_play_button()


func _update_play_button() -> void:
	if GameClock.is_finished():
		_play_button.text = "⏹ Ende"
		_play_button.disabled = true
	else:
		_play_button.text = "⏸ Pause" if not GameClock.paused else "▶ Play"


func _on_speed_changed(value: float) -> void:
	GameClock.days_per_second = value
	_speed_label.text = "%d Tage/s" % int(value)


func _refresh_date(date: GameDate) -> void:
	_date_label.text = "%s   ·   %s" % [date.to_label(), str(date)]
	var holiday := "   ★ Weihnachtsgeschäft" if date.is_holiday_season() else ""
	_season_label.text = "%s%s" % [date.season(), holiday]


func _log_line(bbcode: String) -> void:
	_log.append_text(bbcode + "\n")


func _category_color(category: TimelineEvent.Category) -> String:
	match category:
		TimelineEvent.Category.HARDWARE:
			return "6fcf97"
		TimelineEvent.Category.SOFTWARE:
			return "56ccf2"
		TimelineEvent.Category.TECH:
			return "bb6bd9"
		TimelineEvent.Category.WIRTSCHAFT:
			return "f2c94c"
		TimelineEvent.Category.LOKAL:
			return "f2994a"
		TimelineEvent.Category.KONKURRENZ:
			return "eb5757"
		TimelineEvent.Category.KUNDE:
			return "27ae60"
		TimelineEvent.Category.REKLAMATION:
			return "eb5757"
		TimelineEvent.Category.LIEFERUNG:
			return "f2994a"
	return "ffffff"
