# Ebenen für das App-Symbol

Erzeugt von `tools/raster/make_icon.py` aus dem gerasterten Logo
`src/assets/images/logo_ladenschild.png`. Nicht von Hand ändern: das Logo aufräumen und das Skript
neu aufrufen.

| Datei | Inhalt |
|---|---|
| `monitor.png` | der Monitor aus dem Ladenschild, freigestellt, ×32, auf 1024 × 1024 an derselben Stelle wie im Symbol |
| `grundfarbe.png` | die ganze Fläche in `nacht` (#18233b) |

Für Icon Composer (T022): als Hintergrund die Farbe `nacht` #18233b oder `grundfarbe.png`, darüber
`monitor.png` als einzige Ebene. Ablage als `src/assets/icon/app_icon.icon/`, darin eine leere
Datei `.gdignore`, damit Godot den Ordner nicht importiert.
