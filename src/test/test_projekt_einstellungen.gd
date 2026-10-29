extends GutTest

## Prüft die Projekteinstellungen. Aus Feature 009 (contracts/renderer.md; R4): den Renderer
## Compatibility, Treiber und Rückfälle nach Vorgabe, nichts mehr für Forward+. Aus Feature 007
## (contracts/export.md, „Projekteinstellungen in src/project.godot“): die drei Vollbild-Kürzel
## (R15), das Symbol des Fensters unter Windows (T059) und die Overrides der Selbsttest-App (R3).
##
## Gelesen wird über ProjectSettings und InputMap, also so, wie das Spiel die Werte beim Start
## bekommt. Nur „nicht eingetragen“ prüft der Test an der Datei selbst: ProjectSettings liefert
## für eine fehlende Einstellung ihre Vorgabe, und der Unterschied wäre sonst nicht zu sehen.

const PROJEKT_DATEI := "res://project.godot"


# --- Renderer -------------------------------------------------------------

func test_renderer_ist_compatibility() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")


func test_keine_einstellung_fuer_forward_plus_eingetragen() -> void:
	# Act
	var text := FileAccess.get_file_as_string(PROJEKT_DATEI)

	# Assert: driver.windows und fallback_to_opengl3 wirkten nur auf Forward+ und sind gestrichen.
	assert_false(text.is_empty(), "project.godot ist lesbar.")
	assert_false(text.contains("rendering_device/"), "Nichts unter rendering_device/.")


func test_rueckfaelle_von_compatibility_sind_an() -> void:
	# Act und Assert: ANGLE unter Windows, OpenGL ES unter X11, natives OpenGL ohne ANGLE.
	assert_true(ProjectSettings.get_setting("rendering/gl_compatibility/fallback_to_angle"))
	assert_true(ProjectSettings.get_setting("rendering/gl_compatibility/fallback_to_gles"))
	assert_true(ProjectSettings.get_setting("rendering/gl_compatibility/fallback_to_native"))


func test_unter_macos_ist_der_treiber_opengl() -> void:
	# Act und Assert (FR-002): Apples OpenGL, nicht ANGLE.
	assert_eq(ProjectSettings.get_setting("rendering/gl_compatibility/driver.macos"), "opengl3")


func test_treiber_und_rueckfaelle_sind_die_vorgabe() -> void:
	# Act
	var text := FileAccess.get_file_as_string(PROJEKT_DATEI)

	# Assert
	assert_false(text.is_empty(), "project.godot ist lesbar.")
	assert_false(text.contains("fallback_to_angle"), "Vorgabe, nicht eingetragen.")
	assert_false(text.contains("fallback_to_gles"), "Vorgabe, nicht eingetragen.")
	assert_false(text.contains("fallback_to_native"), "Vorgabe, nicht eingetragen.")
	assert_false(text.contains("gl_compatibility/driver"), "Vorgabe, nicht eingetragen.")


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


# --- App-Symbol -----------------------------------------------------------

func test_unter_windows_hat_das_fenster_das_symbol_aus_der_ico() -> void:
	# Act
	var pfad: String = ProjectSettings.get_setting("application/config/windows_native_icon")

	# Assert (FR-022, Style-Guide „App-Symbol“; T059): dieselbe ICO wie im Export, mit jeder Größe
	# eigens gerastert, statt dass Windows die PNG für Titelleiste und Taskleiste herunterrechnet.
	assert_eq(pfad, "res://assets/icon/app_icon.ico")
	assert_true(FileAccess.file_exists(pfad), "Die ICO liegt im Projekt.")


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
