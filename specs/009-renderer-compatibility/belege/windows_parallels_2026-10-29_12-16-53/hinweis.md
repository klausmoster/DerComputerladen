# Hinweis zu diesem Lauf

Windows in Parallels, 2026-10-29, Lauf von Klaus. Gelaufen ist nicht der Build aus Feature 009: Laut
Protokoll ist er um 12:15 gebaut (`selbsttest.gebaut`), vermutlich im gemeinsamen Ordner auf `main`
und damit noch mit Forward+, gestartet mit einer Startoption für Compatibility. Das zeigt auch
`system.grafik_api`: Der Treiber steht roh als `opengl3_angle` da; der Build aus Feature 009 schreibt
dafür „ANGLE“ (research.md, R3).

Was der Lauf zeigt:
- In diesem Lauf ist Godot von selbst auf ANGLE über Direct3D 11 gewechselt (`fallback_to_angle`).
  Sieben Minuten später lief der Build aus Feature 009 auf derselben Maschine mit nativem OpenGL 3.3
  (`windows_parallels_2026-10-29_12-23-57`); warum hier nicht, ist offen und für das Feature ohne
  Belang.
- 45 von 45 Schritten, 43 Fotos gleich den Mac-Referenzen, 2 nicht vergleichbar wie auf dem Mac.

Kein Beleg für Feature 009; dafür stehen die beiden Läufe von 12:23 und 12:24.
