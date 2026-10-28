extends GutTest

## Prüft die Projekteinstellungen aus Feature 007 (contracts/export.md, „Projekteinstellungen in
## src/project.godot“): den Renderer ohne Ausweichen auf OpenGL (R13), die drei Vollbild-Kürzel
## (R15) und die Overrides der Selbsttest-App (R3).
##
## Gelesen wird über ProjectSettings und InputMap, also so, wie das Spiel die Werte beim Start
## bekommt. Nur „nicht eingetragen“ prüft der Test an der Datei selbst: ProjectSettings liefert
## für eine fehlende Einstellung ihre Vorgabe, und der Unterschied wäre sonst nicht zu sehen.

const PROJEKT_DATEI := "res://project.godot"


# --- Renderer -------------------------------------------------------------

func test_kein_ausweichen_auf_opengl() -> void:
	assert_false(ProjectSettings.get_setting("rendering/rendering_device/fallback_to_opengl3"),
		"Ohne Vulkan oder Direct3D 12 endet das Spiel mit Godots Meldung, statt mit OpenGL zu laufen.")


func test_wechsel_zwischen_vulkan_und_direct3d_12_bleibt_erlaubt() -> void:
	assert_true(ProjectSettings.get_setting("rendering/rendering_device/fallback_to_vulkan"))
	assert_true(ProjectSettings.get_setting("rendering/rendering_device/fallback_to_d3d12"))


func test_wechsel_zwischen_vulkan_und_direct3d_12_ist_die_vorgabe() -> void:
	# Act
	var text := FileAccess.get_file_as_string(PROJEKT_DATEI)

	# Assert
	assert_false(text.is_empty(), "project.godot ist lesbar.")
	assert_false(text.contains("fallback_to_vulkan"), "Vorgabe, nicht eingetragen.")
	assert_false(text.contains("fallback_to_d3d12"), "Vorgabe, nicht eingetragen.")


# --- Vollbild-Kürzel ------------------------------------------------------

func test_vollbild_hat_genau_drei_kuerzel() -> void:
	assert_eq(InputMap.action_get_events(&"toggle_fullscreen").size(), 3,
		"Ctrl+Cmd+F, F11 und Alt+Enter.")


func test_ctrl_cmd_f_ist_vollbild() -> void:
	assert_true(_ist_vollbild(KEY_F, {"ctrl": true, "meta": true}))


func test_f11_ist_vollbild() -> void:
	assert_true(_ist_vollbild(KEY_F11, {}))


func test_alt_enter_ist_vollbild() -> void:
	assert_true(_ist_vollbild(KEY_ENTER, {"alt": true}))


func test_enter_allein_ist_kein_vollbild() -> void:
	assert_false(_ist_vollbild(KEY_ENTER, {}), "Enter allein bleibt beim Menü.")


# --- Overrides der Selbsttest-App -----------------------------------------

func test_selbsttest_hat_eigenen_namen() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name.selbsttest"),
		"Der Computerladen Selbsttest")


func test_selbsttest_startet_eigene_szene() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene.selbsttest"),
		"res://tools/selbsttest/selbsttest_start.tscn")


# --- Helfer ---------------------------------------------------------------

## Ob ein Druck auf [param taste] mit genau den Zusatztasten aus [param mods] (alt, shift, ctrl,
## meta) die Aktion toggle_fullscreen trifft, mit genauem Vergleich wie in GameWindow._input().
func _ist_vollbild(taste: Key, mods: Dictionary) -> bool:
	var ereignis := InputEventKey.new()
	ereignis.keycode = taste
	ereignis.physical_keycode = taste
	ereignis.alt_pressed = mods.get("alt", false)
	ereignis.shift_pressed = mods.get("shift", false)
	ereignis.ctrl_pressed = mods.get("ctrl", false)
	ereignis.meta_pressed = mods.get("meta", false)
	ereignis.pressed = true
	return InputMap.event_is_action(ereignis, &"toggle_fullscreen", true)
