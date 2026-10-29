# Datenmodell: Renderer Compatibility

Das Feature legt keine neuen Daten an. Es ändert nur Werte in zwei vorhandenen Dingen.

## Protokoll eines Laufs (aus Feature 007)

Schlüssel und Format bleiben, siehe `specs/007-build-export-selbsttest/data-model.md`. Anders sind:
- `system.renderer`: nach dem Wechsel `gl_compatibility` statt `forward_plus`.
- `system.grafik_api`: zwei neue Anzeigenamen, „ANGLE“ und „OpenGL ES“
  ([contracts/renderer.md](contracts/renderer.md)).
- `system.grafik_api_version`: so, wie Godot sie liefert, auf dem Mac etwa „4.1 Metal - 91.7“.

## Referenzbild (aus Feature 007)

Unverändert, solange der Mac-Lauf keine Abweichung zeigt. Sonst ersetzt Klaus nach seiner Abnahme
einzelne Bilder unter `tools/selbsttest/referenz/macos/` (FR-008); der Beleg zum Lauf nennt, welche.
