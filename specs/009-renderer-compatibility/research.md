# Research: Renderer Compatibility

Grundlage ist [`docs/entscheidungen/renderer.md`](../../docs/entscheidungen/renderer.md) mit Befund,
Abwägung und Klaus' Entscheidung vom 2026-10-28. Hier steht nur, was der Plan darüber hinaus klärt.
Quellen: Klassenreferenz und Handbuch von Godot 4.7.2 unter `godot_referenz/`, die Export-Vorlagen
unter `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`, Probestarts auf Klaus'
Mac (Apple M1). „Belegt“ heißt: so steht es dort oder so lief es; „Vermutung“: nicht nachgeprüft.

## R1 Einstellung: nur der Renderer, alle Treiber nach Vorgabe

**Entscheidung (Claude, 2026-10-29, nach FR-001 bis FR-003):** In `src/project.godot` steht
`rendering/renderer/rendering_method = "gl_compatibility"`; `config/features` nennt
`"GL Compatibility"` statt `"Forward Plus"`, wie es der Editor beim Wechsel selbst schreibt. Es
entfallen `rendering_device/driver.windows = "d3d12"` und `rendering_device/fallback_to_opengl3 =
false`; beide wirken nur auf Forward+ (`ProjectSettings.xml`; belegt).

Für Compatibility wird nichts eingetragen, die Vorgaben passen (alle belegt in `ProjectSettings.xml`):

| Einstellung | Vorgabe | Wirkung |
|---|---|---|
| `gl_compatibility/driver.macos` | `opengl3` | Apples OpenGL, nach FR-002 |
| `gl_compatibility/driver.windows` | `opengl3` | natives OpenGL 3.3; auf Geräten aus `force_angle_on_devices` ANGLE |
| `gl_compatibility/driver.linuxbsd` | `opengl3` | OpenGL 3.3 über Mesa oder NVIDIA |
| `gl_compatibility/fallback_to_angle` | true | nur Windows: ohne OpenGL 3.3 ANGLE über Direct3D 11 |
| `gl_compatibility/fallback_to_gles` | true | nur Linux/X11: ohne OpenGL 3.3 OpenGL ES 3.0 |
| `gl_compatibility/fallback_to_native` | true | macOS und Windows: fehlt ANGLE, natives OpenGL |

Verworfen: die Vorgaben ausdrücklich eintragen. Sie stünden dann doppelt, und ein Test könnte nicht
mehr unterscheiden, ob jemand sie bewusst geändert hat. So hält es schon R13 aus Feature 007 mit
`fallback_to_vulkan`.

Was für das Bild zählt, hängt nicht am Renderer und bleibt: Texturfilter Nearest, Einrasten von
Transformationen und Ecken, Viewport 640 × 360 mit ganzzahliger Skalierung, Hintergrundfarbe.

## R2 ANGLE steckt in Godot selbst, nicht in einer Datei daneben

**Befund (belegt, 2026-10-29):**
- Die Windows-Vorlage `windows_release_x86_64.exe` enthält Quelltextpfade aus ANGLE
  (`angle\src\libANGLE\Context.cpp` und weitere, 25 Fundstellen) und die Kennung
  `EGL_ANGLE_platform_angle_d3d`. Die macOS-Vorlage `godot_macos_release.universal` enthält 22
  Fundstellen und `EGL_ANGLE_platform_angle_metal`. ANGLE ist also fest eingebaut. Eigene Dateien wie
  `libEGL.dll` liegen nicht bei den Vorlagen.
- Die Linux-Vorlage enthält kein ANGLE; unter Linux gibt es ANGLE in Godot auch nicht.
- Probestart auf dem Mac mit dem Editor-Programm, in dem ANGLE ebenso fest eingebaut ist
  (22 Fundstellen); Befehl in [quickstart.md](quickstart.md), „Probestart auf dem Mac“:
  - `--rendering-driver opengl3`: „OpenGL API 4.1 Metal - 91.7 - Compatibility - Using Device:
    Apple - Apple M1“. Apples OpenGL läuft auf Apple Silicon selbst über Metal.
  - `--rendering-driver opengl3_angle`: „OpenGL ES 3.0 (ANGLE 2.1.1 …) - Compatibility - Using
    Device: … ANGLE Metal Renderer: Apple M1“.

**Folgerungen:**
- **ANGLE unter macOS läuft über Metal**, wie der Quelltext sagt (`renderer.md`, 3). Die Klassenreferenz
  schreibt „over native OpenGL“; das ist für Godot 4.7.2 falsch. Damit ist der letzte ungeprüfte
  Punkt aus `renderer.md` belegt.
- **`application/export_angle = 0` in `export_presets.cfg` bleibt.** Laut Referenz kopiert der Export
  die ANGLE-Bibliotheken nur bei `1` oder beim Treiber `opengl3_angle`; da sie fest eingebaut sind,
  gibt es nichts zu kopieren. Vermutung bis zum Lauf: Der Rückfall auf ANGLE unter Windows klappt
  damit. Beleg ist ein Start des Selbsttests in Boot Camp mit `--rendering-driver opengl3_angle`
  (quickstart, Schritt „Windows“). Scheitert er, legt Claude Klaus vor, `export_angle = 1` zu setzen
  (FR-006).

## R3 Das Protokoll liest, was läuft

**Befund (belegt, Code):** `selbsttest_system.gd` schreibt `system.renderer` aus
`RenderingServer.get_current_rendering_method()` und `system.grafik_api` aus
`get_current_rendering_driver_name()`. Beides ist der Stand nach jedem Rückfall; die Referenz sagt
das ausdrücklich für beide Methoden. FR-005 ist für den Lauf also schon erfüllt.

**Entscheidung (Claude, 2026-10-29):** Die Anzeigenamen in `GRAFIK_API` kennen bisher `metal`,
`vulkan`, `d3d12` und `opengl3`. Dazu kommen `opengl3_angle` → „ANGLE“ und `opengl3_es` → „OpenGL
ES“, damit ein Rückfall im Protokoll und auf der Zusammenfassung lesbar ist statt als Schlüssel.
`metal`, `vulkan` und `d3d12` bleiben, denn ein Start mit `--rendering-method forward_plus` bleibt
möglich und soll dann richtig heißen.

Die Beispieldaten der Tests (`src/test/fixtures/selbsttest/kopieren_erwartet.txt`,
`test_selbsttest_protokoll.gd`, `test_selbsttest_ergebnis.gd`) nennen `forward_plus` und Metal. Sie
prüfen das Format, nicht den Rechner; sie bekommen trotzdem `gl_compatibility` und OpenGL, damit
niemand sie für den Stand des Spiels hält (FR-005).

## R4 Tests der Projekteinstellungen

**Entscheidung (Claude, 2026-10-29):** `test_projekt_einstellungen.gd` verliert die drei Tests zu
Forward+ aus R13 von Feature 007 und bekommt:
- der Renderer ist `gl_compatibility`;
- `project.godot` enthält keine Einstellung unter `rendering_device/` mehr (am Text der Datei, wie
  bisher bei „nicht eingetragen“);
- die drei Rückfälle `fallback_to_angle`, `fallback_to_gles`, `fallback_to_native` sind true und
  nicht eingetragen;
- unter macOS ist der Treiber `opengl3` (FR-002).

Headless läuft Godot ohne Renderer; die Tests lesen nur Einstellungen und laufen also auf allen
Systemen gleich (belegt durch die Tests aus 007).

## R5 Belege und Referenzbilder

**Entscheidung (Klaus, 2026-10-29, Spec und Klärung):** Pflicht sind drei Läufe des Selbsttests:
Mac, Linux (AMD R7 200), Boot-Camp-Rechner; Parallels ist willkommen. Der Mac-Lauf ist der Maßstab.
Vergleich mit `tools/selbsttest/vergleich.py` gegen `tools/selbsttest/referenz/macos/`.

- Sind alle Fotos gleich, bleiben die Referenzbilder.
- Weichen Fotos ab, legt Claude jede mit Bild vor. Klaus entscheidet je Fall: ANGLE über Metal
  versuchen (FR-002; der Probestart in R2 zeigt, dass es geht) oder neue Referenzbilder abnehmen.
  Neue Bilder kommen nur nach seiner Abnahme (FR-008).

Vermutung: Die Fotos bleiben gleich. In 007 ergab Windows mit OpenGL dieselben 35 Fotos wie der Mac
mit Metal, und das Spiel nutzt keinen Shader, kein Licht und keine Partikel.

## R6 Regeln, Style-Guide und Doku

**Entscheidung (Klaus, 2026-10-29, Klärung):** Der Wortlaut der Regel steht in FR-009. Die
Verfassung ändert sich über `/speckit-constitution`; nach den Regeln der Verfassung ist das MAJOR,
weil Grundsatz I neu definiert wird: 2.3.0 → 3.0.0. Verworfen: MINOR, weil eine endgültige Regel in
ihr Gegenteil umschlägt.

Der Style-Guide ist ein Artifact (`https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX`). Claude
liest ihn, legt Klaus den Satz vor und veröffentlicht erst nach seinem OK (FR-009a).

Zu ändern sind, mit „bis 2026-10-29“ für die alte Fassung, wo sie Geschichte ist:
- `CLAUDE.md`, „Harte Rahmenbedingungen“; `.specify/memory/constitution.md`, Grundsatz I.
- Feature 007: `spec.md` (FR-017, Klärung „Was passiert ohne Forward+?“, Begriff „Renderer“),
  `research.md` (R13), `quickstart.md` (Schritt 5 unter „Windows und Linux“), `lernnotizen.md`
  (T043).
- `docs/spielbeschreibung/`: `darstellung.md`, `architektur.md`, `build-und-tests.md`,
  `selbsttest.md` (Abschnitt „Grenzen“ und „Belegte Läufe“). Das gleicht die feste Aufgabe
  „Spielbeschreibung prüfen“ ab; hier steht es, damit nichts vergessen wird.
- `docs/offene-punkte.md`: Punkte „Renderer“ und „Abweichung von FR-017“ schließen, ebenso die Frage
  nach den Direct3D-12-Dateien (FR-012).
- `docs/entscheidungen/renderer.md`: ein Vermerk „umgesetzt in Feature 009“ (FR-013).

Nicht geändert werden ältere Specs (001 bis 006, 008) und `docs/tagebuch/`.

## R7 Reihenfolge: erst die Regel, dann die Einstellung

**Entscheidung (Claude, 2026-10-29):** Die Regel ändert sich in der ersten Phase, vor der Einstellung.
Sonst stünde zwischen den Phasen ein Commit, der gegen die geltende Verfassung verstößt, und der
Architektur-Prüfer müsste ihn melden. Verworfen: Regel zuletzt, mit der Doku; das spart nichts, weil
Klaus' Beschluss ohnehin vorliegt.
