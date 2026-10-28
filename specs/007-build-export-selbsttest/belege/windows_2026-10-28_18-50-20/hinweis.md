# Hinweis zu diesem Lauf

Gelaufen auf einem MacBook Pro mit Boot Camp, Windows 10 (10.0.19045), AMD Radeon R9 M370X mit
Treiber 22.19.170.1536, **mit Compatibility und OpenGL statt Forward+**, von Hand gestartet mit
`--rendering-method gl_compatibility --rendering-driver opengl3`.

Mit Forward+ startet das Spiel auf diesem Rechner nicht: Der Treiber kann kein Vulkan, und Direct3D 12
läuft nur auf Stufe 11_0, wo jeder Shader beim Anlegen scheitert
(„Create(Compute)PipelineState failed with error 0x80070057“). Godot zeigt dabei keine Meldung, das
Fenster schließt sich oder hängt.

Der Lauf belegt deshalb Eingaben, Menüs, Spielstände, Fenster und Zusammenfassung unter Windows,
nicht aber die Darstellung mit Forward+. Die 35 vergleichbaren Fotos sind trotzdem Pixel für Pixel
gleich den Referenzbildern vom Mac. Ein Lauf mit Vulkan oder Direct3D 12 unter Windows steht aus.
