# Rasterfassung

Werkzeuge, die freigegebene Bilder aus Leonardo aufs Bildraster des Style-Guides bringen. Nur
Python 3 mit Standardbibliothek; JPEG liest `sips` (macOS). Aufruf immer vom Repo-Root und mit
`python3 -I`, weil die Bilder aus dem Netz stammen.

| Datei | Zweck |
|---|---|
| `make_palette.py` | erzeugt einmalig die Hauptpalette `docs/art/hauptpalette.gpl` und die Farbtafel `docs/art/hauptpalette.png` |
| `rasterize.py` | verkleinert ein Bild per Flächenmittel auf die Endgröße und rechnet es ohne Dithering auf die Hauptpalette |
| `cleanup.py` | räumt ein gerastertes Bild grob auf: Farbreste und Einzelpixel nach festen Regeln |
| `make_icon.py` | baut das App-Symbol 1024 × 1024 und die Ebenen für Icon Composer aus dem Monitor im gerasterten Logo |
| `pngio.py` | gemeinsamer Teil: PNG lesen (auch indiziert) und schreiben, Flächenmittel, Farbabstand in OKLab |

## Reihenfolge

1. **Hauptpalette** (einmal, dann eingefroren):

   ```bash
   python3 -I tools/raster/make_palette.py
   ```

   Index 0 ist die Transparenz, 1–15 sind die Oberflächenfarben des Style-Guides, 16–255 die
   Szenenfarben per Median-Cut aus Stilanker C2, Titelbild T-01 und Cover C-01. Jedes Bild wird
   dafür erst auf seine Endgröße verkleinert und zählt gleich viel. Eine vorhandene Palette
   überschreibt das Skript nur mit `--neu`; danach müssten alle gerasterten Bilder neu gerechnet
   werden.

2. **Bild rastern**, mit Endgröße oder mit Faktor:

   ```bash
   python3 -I tools/raster/rasterize.py docs/art/leonardo/t-01-titelbild.jpg src/assets/images/title_t01.png --groesse 320x180
   python3 -I tools/raster/rasterize.py docs/art/leonardo/logo-ladenschild.png src/assets/images/logo_ladenschild.png --faktor 6
   ```

   Ausgeschnitten wird mittig, damit der Faktor ganzzahlig bleibt (T-01: 1920 × 1088 wird zu
   1920 × 1080, dann ÷ 6). Pixel mit gemitteltem Alpha unter 128 werden transparent. Mit
   `--vorschau datei.png --zoom 3` entsteht zusätzlich eine vergrößerte Ansicht zum Prüfen.

3. **Aufräumen**, erst per Regel, danach bei Bedarf von Hand:

   ```bash
   python3 -I tools/raster/cleanup.py src/assets/images/title_t01.png --vorschau vorher-nachher.png
   ```

   Farben mit höchstens 3 Pixeln gehen auf die nächste häufige Farbe (OKLab-Abstand bis 0,10),
   Einzelpixel auf die häufigste Farbe ihrer Nachbarn, wenn sie ihr ähnlich sind (unter 0,05).
   Lichter, Kanten und Schrift bleiben stehen. Von Hand geht es in Pixelorama oder Aseprite
   weiter, nur mit Farben der Hauptpalette (Palette `docs/art/hauptpalette.gpl` laden).

4. **App-Symbol** aus dem gerasterten Logo, nach jedem Aufräumen am Logo neu:

   ```bash
   python3 -I tools/raster/make_icon.py
   ```

   Der Monitor (Bildpixel 6 bis 24 × 6 bis 21 des Logos) kommt ×32 mittig auf ein abgerundetes
   Quadrat in `nacht` nach Apples Symbolraster. Freigestellt wird per Füllung vom Rand: Was über
   rötliche Pixel mit dem Schildfeld zusammenhängt, fällt weg, auch der Schatten des Monitors.
   Ergebnis: `src/assets/icon/app_icon.png` und die Ebenen für Icon Composer in
   `docs/art/app_icon/`. Gibt es das Liquid-Glass-Symbol `src/assets/icon/app_icon.icon/`
   schon, bekommt es die neue Ebene `monitor.png` mit.

Warum Flächenmittel statt Nearest Neighbor: Die gemalten Pixel in den Leonardo-Bildern sind
ungleich groß, Nearest Neighbor würde zufällige Pixel herausgreifen (Style-Guide,
Leonardo-Workflow, Nachbearbeitung Schritt 2).
