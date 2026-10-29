# Entscheidung: Renderer Forward+ oder Compatibility

- **Stand:** 2026-10-28, Vorschlag von Claude, **von Klaus entschieden** (siehe „Entscheidung“ am
  Ende). Umgesetzt ist noch nichts; bis das eigene Feature fertig ist, gilt CLAUDE.md: Der Renderer
  bleibt Forward+.
- **Umgesetzt:** in Feature 009 „Renderer Compatibility“ (`specs/009-renderer-compatibility/`),
  2026-10-29; seitdem gelten CLAUDE.md und Verfassung 3.0.0 mit Compatibility. Der Text darunter
  bleibt als Stand der Entscheidung.
- **Anlass:** Feature 007, Läufe auf anderen Rechnern (T047, T048), `docs/offene-punkte.md`,
  „Feature 007, Phase 6“.
- **Quellen:** Godot-Doku Zweig 4.7 (`renderers.rst`, `system_requirements.rst`,
  `class_projectsettings.rst`, `command_line_tutorial.rst`), Godot-Quelltext Zweig 4.7, Steam-Umfrage
  September 2026. „Belegt“ heißt: so steht es dort oder so lief es im Selbsttest. „Vermutung“ heißt:
  nicht nachgeprüft.

## Kurz

**Empfehlung: auf Compatibility wechseln, auf allen drei Systemen.** Das Spiel braucht nichts, was
nur Forward+ kann, und auch für das, was `game_design.md` plant, fehlt Compatibility nichts
Wesentliches. Dafür läuft es dann auf Windows-Rechnern, auf denen es heute still abstürzt, und es
gibt nur einen Renderer zu prüfen. Der Lauf in Boot Camp zeigt schon heute: Mit OpenGL ist das Bild
Pixel für Pixel gleich (35 von 35 Fotos).

## Befund

- **macOS und Linux** laufen mit Forward+ ohne Probleme (Mac M1 mit Metal, Linux AMD R7 200 mit
  Vulkan; belegt).
- **Windows in Boot Camp** (MacBook Pro 2015, AMD R9 M370X, Treiber von 2017): Forward+ startet
  nicht und zeigt keine Meldung. Mit `--rendering-method gl_compatibility` liefen 37 von 37
  Schritten (belegt).
- **Windows in Parallels** macht laut Klaus dieselben Probleme, mit OpenGL keine.
  Parallels nennt DirectX 11 und 12; im Forum fehlt Stufe 12_0 (Vermutung: dasselbe Muster wie
  Boot Camp).

**Warum Godot nicht ausweicht, auch nicht mit `fallback_to_opengl3 = true`:** Godot fordert
Direct3D 12 schon auf Stufe 11_0 an (`rendering_device_driver_d3d12.cpp`,
`requested_feature_level = D3D_FEATURE_LEVEL_11_0`; belegt). Das Gerät entsteht also, erst die Shader
scheitern danach. Ausweichen gibt es aber nur, wenn das Gerät gar nicht entsteht
(`display_server_windows.cpp`; belegt). Die Doku verlangt für Forward+ Stufe 12_0
(`system_requirements.rst`; belegt). Zwischen 11_0 und 12_0 liegt die Lücke, in die Boot Camp
fällt. Auch FR-017 gilt dort nicht: Godot zeigt keine eigene Meldung.

## 1. Was Compatibility einem 2D-Pixel-Spiel nimmt

Die Doku: Was nicht in der Vergleichstabelle steht, gibt es in allen Renderern. 2D-Licht,
2D-Schatten, Canvas-Shader und GPU-Partikel stehen nicht darin; es gibt sie also auch in
Compatibility (belegt). Für 2D heißt es dort zweimal: Compatibility reicht meist aus.

| Was fehlt in Compatibility (belegt) | Braucht das Spiel es? |
|---|---|
| Compute-Shader, Zugriff auf `RenderingDevice` | Nein. Die Simulation rechnet in GDScript auf dem Prozessor. |
| HDR für 2D (`hdr_2d`), Farbtiefe nur RGBA8 statt RGBA16F | Nein. Die Palette hat 8 Bit je Kanal; HDR erzeugte Zwischenfarben außerhalb der Palette. |
| MSAA in 2D, FXAA, SMAA | Nein. Kantenglättung widerspricht dem Pixelraster (Texturfilter Nearest, Einrasten). |
| Partikelspuren, Partikel mit SDF-Kollision | Kaum. Schnee, Rauch aus einem kaputten PC und Funken gehen ohne Spur. |
| Debanding, Tiefenunschärfe, Decals, HDR-Ausgabe | Nein, das sind 3D-Mittel oder Mittel für Verläufe. |
| CompositorEffects (eigene Nachbearbeitung) | Nein. Ein Vollbild-Shader auf einem Rechteck geht auch in Compatibility. |

Glow, Bildschirm-Textur (für einen CRT-Effekt) und Vollbild-Shader gibt es in beiden (belegt). Glow
greift ohne HDR nur unter Weiß, also schwächer. Für einen Laden mit Röhrenmonitor und Neonschild
reicht das; nach dem Style-Guide wäre ein weicher Schein ohnehin eine Ausnahme.

`game_design.md` plant 2D-Szenen, Oberfläche, Dialoge und Ton. Nichts davon braucht Forward+.
Heute nutzt das Spiel keinen einzigen Shader, kein Licht und keine Partikel; den Pixelschatten
rechnet `title_screen.gd` absichtlich ohne Shader.

## 2. Wo Forward+ nicht läuft, Compatibility aber schon

Mindestens (belegt, `system_requirements.rst`): Forward+ braucht Vulkan 1.0, Direct3D 12 auf Stufe
12_0 oder Metal 3, als Beispiel Intel HD 510 (Skylake, 2015). Compatibility braucht OpenGL 3.3 oder
unter Windows Direct3D 11, als Beispiel Intel HD 2500 (Ivy Bridge, 2012).

Dazwischen liegen etwa (Vermutung, allgemein bekannte Treiberstände):

- Windows-Notebooks und Büro-PCs mit Intel HD 2500, 4000 und 4600 (2012 bis 2014): kein Vulkan
  unter Windows, Direct3D 12 nur Stufe 11.
- AMD GCN 1.0 mit alten Treibern, wie die R9 M370X in Boot Camp, und NVIDIA Fermi (GTX 400 und 500).
- Windows in virtuellen Maschinen: Parallels, VirtualBox, VMware, Fernsitzungen.

**Wie häufig:** In der Steam-Umfrage haben rund 92 % der Systeme eine Grafikkarte mit DirectX 12
(Juli 2026 91,74 %, Februar 94,14 %; Zweitquellen, Valves Seite gibt die Summe nicht maschinell
heraus). Windows hat 95 % der Steam-Nutzer, macOS 1,9 %, Linux 3,1 % (September 2026; belegt). Steam
misst Spieler mit aktueller Hardware. Die Zielgruppe hier, Leute, die den Computerladen der 90er
erlebt haben, spielt eher auf älteren Notebooks, Büro-PCs und Macs mit Windows. Bei ihr liegt der
Anteil vermutlich höher. Der Fehler trifft also eine kleine, aber genau passende Gruppe. Und er ist
still: kein Hinweis, das Fenster geht zu oder hängt.

## 3. Compatibility unter macOS und Linux

- **macOS:** Vorgabe ist `opengl3`, Apples eigenes OpenGL. Apple führt es seit macOS 10.14 als
  veraltet, es läuft aber weiter, auf Apple Silicon über Metal. Wahlweise `opengl3_angle`: ANGLE
  übersetzt in Metal (Quelltext `gl_manager_macos_angle.mm`,
  `EGL_PLATFORM_ANGLE_TYPE_METAL_ANGLE`; belegt). Die Doku schreibt „über natives OpenGL“; das
  widerspricht dem Quelltext. Fehlt ANGLE, nimmt Godot natives OpenGL (`fallback_to_native`, belegt).
  Ein Lauf mit Compatibility auf dem Mac fehlt noch.
- **Linux:** `opengl3` über Mesa oder den NVIDIA-Treiber, unter X11 mit Rückfall auf OpenGL ES
  (`fallback_to_gles`, belegt). OpenGL 3.3 haben dort auch Karten ohne Vulkan. Ein Lauf auf Linux
  mit Compatibility fehlt noch.
- **Windows:** `opengl3`. Bei fehlendem OpenGL 3.3 oder bekannt schlechten Treibern nimmt Godot ANGLE
  über Direct3D 11 (`fallback_to_angle`, `force_angle_on_devices`; belegt). Das deckt die Fälle mit
  Direct3D 11 ohne gutes OpenGL ab.

## 4. Zwischenwege

| Weg | Hilft in Boot Camp? | Aufwand | Haken |
|---|---|---|---|
| `fallback_to_opengl3 = true` | **Nein**: Das Gerät entsteht auf Stufe 11_0, nichts scheitert früh genug (belegt). | eine Zeile | Hilft nur, wo gar kein Direct3D 12 und kein Vulkan da ist. |
| Startoption `--rendering-method gl_compatibility` | Ja, belegt. | eine Verknüpfung oder ein Satz in der Anleitung | Der Spieler muss erst wissen, dass er sie braucht. Unter macOS umständlich. |
| `override.cfg` neben der `.exe` (belegt: wirkt in Exporten) | Ja, vermutlich wie die Startoption. | eine Datei | Wie oben: Der Spieler muss sie anlegen. |
| Override je System: `rendering/renderer/rendering_method.windows = "gl_compatibility"` | Ja, vermutlich. Feature-Tag-Overrides wirken in diesem Projekt früh genug (R3, belegt für Name und Startszene); für den Renderer ist es eine Probe wert. | eine Zeile | Zwei Renderer im Spiel. Windows hat 95 % der Spieler, also muss jedes Mittel ohnehin in Compatibility gehen. |
| Eigene Prüfung beim Start: Merker vor dem ersten Bild; findet der nächste Start ihn, schreibt das Spiel eine Datei nach `user://`, auf die `application/config/project_settings_override` zeigt (belegt: Pfad in `user://` erlaubt) | Ja, beim zweiten Start. | ein eigenes Feature | Erster Start stürzt weiter still ab. Der Merker kann auch bei anderen Abstürzen anschlagen. |

## 5. Was ein Wechsel kostet

- **Einstellungen:** in `src/project.godot` eine Zeile `rendering/renderer/rendering_method =
  "gl_compatibility"`. `driver.windows = "d3d12"` und `fallback_to_opengl3` werden bedeutungslos und
  fliegen raus. Damit erledigt sich auch die offene Frage nach den fehlenden Direct3D-12-Dateien
  (Agility SDK).
- **Tests:** `test_projekt_einstellungen.gd`, drei Tests zum Renderer neu. Die Vorlagen unter
  `src/test/fixtures/selbsttest/` und `test_selbsttest_protokoll.gd` nennen `forward_plus`; ob sie
  sich ändern, hängt davon ab, ob sie den laufenden Renderer lesen (prüfen).
- **Referenzbilder:** voraussichtlich keine neuen; Windows mit OpenGL ergab dieselben 35 Bilder wie
  der Mac mit Metal (belegt). Nötig ist ein Lauf des Selbsttests auf dem Mac mit Compatibility als
  Beleg, dazu je ein Lauf unter Linux und Windows. Das sind die Läufe, die T048 ohnehin offen hat.
- **Selbsttest:** kein Code. Er protokolliert Renderer und Schnittstelle schon (`system.renderer`,
  `system.grafik_api`).
- **Presets:** `export_presets.cfg` braucht nichts, außer ANGLE fehlt in den Vorlagen; das zeigt ein
  Start mit `--rendering-driver opengl3_angle` (prüfen).
- **Style-Guide:** nichts; Farben, Raster, Schriften und Einrasten hängen nicht am Renderer. Nach
  dem Wechsel gehören HDR, MSAA und Glow über Weiß nicht mehr zu den Mitteln; das könnte ein Satz im
  Style-Guide festhalten.
- **Doku und Regeln:** CLAUDE.md („Harte Rahmenbedingungen“), Verfassung Grundsatz I
  (`.specify/memory/constitution.md`, über `/speckit-constitution` mit neuer Version),
  `docs/spielbeschreibung/darstellung.md` und `architektur.md`; in Feature 007 FR-017, die Klärung
  „Was passiert ohne Forward+?“, R13, `quickstart.md`, `lernnotizen.md`; ein Eintrag im Tagebuch.
  Ältere Pläne (001 bis 006) bleiben als Geschichte stehen.

Alles zusammen ist eine kleine Phase: eine Zeile Einstellung, drei Tests, Doku, drei Läufe.

## Abwägung

| | Forward+ bleibt | Compatibility überall (Empfehlung) | Windows Compatibility, sonst Forward+ |
|---|---|---|---|
| Läuft in Boot Camp und Parallels | nein, still | ja, belegt | ja, vermutlich |
| Ältere Windows-Rechner | nein | ja | ja |
| Gestaltung | alle Mittel | ohne HDR, MSAA, Compute; für Pixelkunst nichts Wesentliches | praktisch wie Compatibility, weil Windows mitmuss |
| Prüfen | ein Renderer | ein Renderer | zwei Renderer |
| Risiko | stille Abstürze bei der Zielgruppe | Apples OpenGL ist veraltet; Ausweg ANGLE über Metal | Unterschiede zwischen den Systemen |

Klaus' Grund für Forward+ war: Rücksicht kostet Gestaltungsfreiheit. Für ein Spiel mit fester
Palette auf 640 × 360, ganzzahlig skaliert, ist diese Freiheit fast leer. Was Forward+ zusätzlich
kann, würde das Pixelbild eher verletzen.

## Fragen an Klaus

1. Welcher Renderer? Empfehlung: Compatibility auf allen Systemen.
2. Wann umsetzen? Empfehlung: als Nachtrag in Feature 007, weil FR-017, R13 und der offene
   Windows-Lauf dort liegen.
3. Welcher Treiber unter macOS? Empfehlung: Godots Vorgabe (Apples OpenGL), ANGLE über Metal nur,
   wenn der Lauf auf dem Mac Abweichungen zeigt.

## Entscheidung (Klaus, 2026-10-28)

1. **Compatibility auf allen Systemen**, wie empfohlen.
2. **Als eigenes Feature**, gegen die Empfehlung. Feature 007 wird mit Forward+ abgeschlossen; der
   Wechsel bekommt eine eigene Nummer mit Spec und Phasen und ändert dabei CLAUDE.md, die Verfassung
   (Grundsatz I), FR-017 und R13.
3. **Unter macOS Godots Vorgabe `opengl3`**, wie empfohlen; ANGLE über Metal nur, wenn der Lauf
   auf dem Mac Abweichungen zeigt.
