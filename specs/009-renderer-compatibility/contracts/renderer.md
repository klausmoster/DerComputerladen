# Vertrag: Renderer und Protokoll

Was nach Feature 009 gilt und woran die Tests es messen. Gründe in [research.md](../research.md).

## Projekteinstellungen in `src/project.godot`

| Schlüssel | Wert | Prüft |
|---|---|---|
| `application/config/features` | enthält `"GL Compatibility"`, nicht `"Forward Plus"` | `test_projekt_einstellungen.gd` |
| `rendering/renderer/rendering_method` | `"gl_compatibility"` | `test_projekt_einstellungen.gd` |
| alles unter `rendering/rendering_device/` | nicht eingetragen | Text der Datei |
| `rendering/gl_compatibility/driver.macos` | Vorgabe `opengl3`, nicht eingetragen (FR-002) | `test_projekt_einstellungen.gd` |
| `rendering/gl_compatibility/fallback_to_angle`, `fallback_to_gles`, `fallback_to_native` | Vorgabe true, nicht eingetragen | `test_projekt_einstellungen.gd`, Text der Datei |

Unverändert und nicht Teil dieses Features, aber bildwirksam (FR-004, SC-007): Texturfilter,
Einrasten von Transformationen und Ecken, Viewport, Skalierung, `boot_splash/bg_color` (Startgrund
in `anzeige-grund`), `boot_splash/show_image = false`, `environment/defaults/default_clear_color`.
Ebenfalls unverändert: `textures/vram_compression/import_etc2_astc`.

Die Tests aus R13 von Feature 007 (`test_kein_ausweichen_auf_opengl`,
`test_wechsel_zwischen_vulkan_und_direct3d_12_bleibt_erlaubt`,
`test_wechsel_zwischen_vulkan_und_direct3d_12_ist_die_vorgabe`) entfallen.

## Export-Presets in `src/export_presets.cfg`

Keine Änderung. `application/export_angle = 0` bleibt für macOS und Windows, weil ANGLE in den
Vorlagen fest eingebaut ist (R2). Belegt wird das mit dem Windows-Lauf mit `opengl3_angle`; scheitert
er, entscheidet Klaus über `export_angle = 1`.

## Protokoll des Selbsttests

Die Schlüssel bleiben. Die Anzeigenamen stehen künftig in `SelbsttestTexte.GRAFIK_API`
(`selbsttest_texte.gd`); `SelbsttestSystem` liest sie dort (research.md, R3). Neu sind zwei Namen:

| Treiber laut Godot | `system.grafik_api` |
|---|---|
| `opengl3` | OpenGL (wie bisher) |
| `opengl3_angle` | ANGLE (neu) |
| `opengl3_es` | OpenGL ES (neu) |
| `metal`, `vulkan`, `d3d12` | Metal, Vulkan, D3D12 (bleiben für Starts mit `--rendering-method forward_plus`) |
| jeder andere | der Name, wie Godot ihn liefert (wie bisher) |

Erwartet nach dem Wechsel, ohne Startoption:

| System | `system.renderer` | `system.grafik_api` |
|---|---|---|
| macOS | `gl_compatibility` | OpenGL |
| Linux | `gl_compatibility` | OpenGL, bei Rückfall unter X11 OpenGL ES |
| Windows | `gl_compatibility` | OpenGL, auf schwachen Treibern ANGLE |

Die Beispieldaten der Tests nennen danach `gl_compatibility` und OpenGL statt `forward_plus` und
Metal: unter `src/test/fixtures/selbsttest/` `kopieren_erwartet.txt`, `protokoll_erwartet.txt` und
`kopieren_nicht_beschreibbar.txt`, dazu `test_selbsttest_protokoll.gd` und
`test_selbsttest_ergebnis.gd`.
