# Hinweis zu diesem Lauf

Windows in Parallels, 2026-10-29, Lauf von Klaus. Gelaufen ist noch der Build aus Feature 007
(Forward+), gestartet mit einer Startoption für Compatibility mit OpenGL. Das erkennt man daran,
dass `system.grafik_api` den Treiber roh als `opengl3_angle` nennt; der Build aus Feature 009
schreibt dafür „ANGLE“ (research.md, R3).

Was der Lauf trotzdem belegt:
- Natives OpenGL reicht in Parallels nicht; Godot ist von selbst auf ANGLE über Direct3D 11
  gewechselt (`fallback_to_angle`), mit derselben Export-Vorlage 4.7.2, die auch Feature 009 nutzt.
  ANGLE steckt also im Windows-Export (R2, FR-006).
- 45 von 45 Schritten, 43 Fotos gleich den Mac-Referenzen, 2 nicht vergleichbar wie auf dem Mac.

Kein Beleg für Feature 009 ohne Startoption; dafür steht ein Lauf mit dem neuen Build aus.
