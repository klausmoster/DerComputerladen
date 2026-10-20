# Ebenen für das App-Symbol

Erzeugt von `tools/raster/make_icon.py` aus dem gerasterten Logo
`src/assets/images/logo_ladenschild.png`. Nicht von Hand ändern: das Logo aufräumen und das Skript
neu aufrufen.

| Datei | Inhalt |
|---|---|
| `monitor.png` | der Monitor aus dem Ladenschild, freigestellt, ×32, auf 1024 × 1024 an derselben Stelle wie im Symbol |
| `grundfarbe.png` | die ganze Fläche in `nacht` (#18233b) |

Das Liquid-Glass-Symbol liegt in `src/assets/icon/app_icon.icon/`: `icon.json` mit der Füllung
`nacht` und `monitor.png` als einziger Ebene unter `Assets/`, dazu eine leere `.gdignore`, damit
Godot den Ordner nicht importiert. Angelegt nach Xcodes Dateivorlage „Icon Composer Icon“.
`make_icon.py` erneuert `Assets/monitor.png` mit, wenn es den Ordner gibt.

Ansehen ohne Icon Composer:

```bash
"/Applications/Xcode-27.1.0.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" src/assets/icon/app_icon.icon --export-image --output-file symbol.png --platform macOS --rendition Default --width 1024 --height 1024 --scale 1
```

In Icon Composer lässt sich das Symbol weiter bearbeiten, etwa die Glaseffekte der Ebene.
