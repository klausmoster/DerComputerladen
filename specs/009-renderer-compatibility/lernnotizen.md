# Lernnotizen: Renderer Compatibility

Zu jeder umgesetzten Task die Godot-Konzepte und warum es so gebaut ist, an den Stellen im
Projekt. Bei `[A]`-Tasks schreibt der Agent die Notizen, Claude trägt sie je Phase hier ein; baut
Klaus eine Task selbst, schreibt Claude die Notiz beim Review. Abnahmen und Phasenprüfungen bauen
nichts und haben deshalb keine Notiz.

## Phase 3

### T010 `rendering_method` und die Treiber darunter

- **Zwei Ebenen: Renderer und Treiber.** `rendering/renderer/rendering_method` in
  `src/project.godot` wählt den Renderer, also wie Godot zeichnet: `forward_plus`, `mobile` oder
  `gl_compatibility`. Darunter liegt der Treiber, die Grafikschnittstelle des Systems. Forward+
  und Mobile sprechen über das RenderingDevice mit Vulkan, Direct3D 12 oder Metal; ihre
  Einstellungen heißen `rendering/rendering_device/…`. Compatibility spricht OpenGL; seine heißen
  `rendering/gl_compatibility/…`. Deshalb fallen `rendering_device/driver.windows = "d3d12"` und
  `rendering_device/fallback_to_opengl3 = false` weg: Unter Compatibility liest sie niemand mehr.
- **Gelesen wird einmal beim Start.** Godot wählt Renderer und Treiber, bevor das erste Fenster
  aufgeht; im laufenden Spiel lässt sich nichts umschalten. Die Startoptionen
  `--rendering-method` und `--rendering-driver` übersteuern die Datei für einen Start, so bleibt
  ein Vergleich mit Forward+ ohne Änderung am Projekt möglich.
- **Overrides mit Feature-Tag.** `rendering/gl_compatibility/driver.macos` ist kein eigener
  Schalter, sondern eine Variante von `…/driver`, die nur gilt, wenn das Tag `macos` aktiv ist;
  dasselbe Muster wie `application/config/name.selbsttest` aus Feature 007. Jedes System hat so
  seinen eigenen Treiber, und alle drei stehen auf der Vorgabe `opengl3`.
- **Die Rückfälle.** Klappt `opengl3` nicht, versucht Godot unter Windows ANGLE über Direct3D 11
  (`fallback_to_angle`), unter Linux mit X11 OpenGL ES 3.0 (`fallback_to_gles`); fehlt ANGLE,
  geht es auf natives OpenGL zurück (`fallback_to_native`). Alle drei sind von Haus aus an.
- **`config/features` ist ein Etikett für den Editor**, kein Schalter: Projektmanager und Editor
  zeigen damit, wofür das Projekt eingerichtet ist. Der Editor schreibt beim Umschalten selbst
  „GL Compatibility“ hinein; von Hand steht dort dasselbe.
- **Von Hand statt im Editor.** Der Editor kann beim Umschalten weitere Schlüssel schreiben und
  sortiert manches um. Von Hand ändern sich genau die Zeilen aus dem Vertrag; der Diff zeigt drei
  Zeilen weniger, zwei mehr, Startgrund, Texturfilter und Einrasten bleiben byte-gleich.

### T011 Vorgaben nicht eintragen, und wie man das testet

- **Was in `project.godot` steht, ist eine Abweichung von der Vorgabe.** Godot schreibt eine
  Einstellung nur hinein, wenn sie von der Vorgabe abweicht. Trägt man eine Vorgabe trotzdem ein,
  sieht die Datei aus, als habe jemand bewusst entschieden, und eine spätere Änderung der Vorgabe
  in Godot käme nicht mehr an (research.md, R1).
- **Zwei Arten zu prüfen** in `src/test/test_projekt_einstellungen.gd`:
  `ProjectSettings.get_setting()` sagt, welcher Wert gilt; für eine fehlende Einstellung liefert
  es die Vorgabe. Ob sie eingetragen ist, sieht man daran nicht, deshalb lesen
  `test_keine_einstellung_fuer_forward_plus_eingetragen` und
  `test_treiber_und_rueckfaelle_sind_die_vorgabe` den Text der Datei. Beides zusammen heißt:
  Der Wert stimmt, und er stimmt, weil Godot es so vorgibt.
- **Headless läuft kein Renderer**, die Tests lesen nur Einstellungen. Sie laufen deshalb auf
  jedem System gleich; ob der Rückfall wirklich greift, zeigen erst die Läufe in Phase 4.

### T012 Der Stand nach dem Rückfall, und Namen in der Textklasse

- **Einstellung und Wirklichkeit.** `ProjectSettings` sagt, was gewünscht ist;
  `RenderingServer.get_current_rendering_method()` und `get_current_rendering_driver_name()` sagen,
  was tatsächlich läuft, nach Startoption und nach jedem Rückfall (so steht es in
  `RenderingServer.xml`). Deshalb liest `SelbsttestSystem.erhebe()` den RenderingServer und nicht
  die Einstellungen: Fällt ein Windows-Rechner auf ANGLE zurück, steht im Protokoll ANGLE, nicht
  das, was `project.godot` wollte. Daran musste sich nichts ändern.
- **Lesbare Namen.** Der Treiber heißt bei Godot `opengl3_angle` oder `opengl3_es`.
  `SelbsttestTexte.GRAFIK_API` bildet sie auf „ANGLE“ und „OpenGL ES“ ab,
  `SelbsttestTexte.grafik_api_name()` schlägt nach und gibt einen unbekannten Schlüssel
  unverändert zurück (`Dictionary.get(schluessel, schluessel)`). So verschwindet ein neuer Treiber
  einer späteren Godot-Version nicht, er steht nur roh da.
- **Warum in der Textklasse.** Die Namen erscheinen auf der Zusammenfassung über
  `SelbsttestTexte.systemzeile()`; der Leitfaden gibt dem Selbsttest eine Stelle für seine
  Wortlaute (Abschnitt „Werkzeuge“, AR-04: Texte an einer Stelle als Konstanten, wie
  `TitleTexts`). `SelbsttestSystem` erhebt nur noch Werte und fragt nach dem Namen. Die kleine
  statische Funktion macht die Abbildung testbar, genau so, wie `erhebe()` sie benutzt
  (`test_selbsttest_system.gd`), und folgt dem Muster von `ablauf_name()`.

### T013 Beispieldaten, die nicht wie der Stand aussehen

- Die Beispiele unter `src/test/fixtures/selbsttest/` und in `test_selbsttest_protokoll.gd` und
  `test_selbsttest_ergebnis.gd` prüfen das Format des Protokolls, nicht den Rechner. Sie nennen
  jetzt `gl_compatibility` und OpenGL, damit niemand beim Lesen meint, das Spiel liefe noch mit
  Metal. Geändert sind nur die beiden Werte; Schlüssel, Reihenfolge und Form bleiben, sonst
  prüften die Tests etwas anderes als vorher.
