# Ton

Der Computerladen klingt wie die Geräte, die im Laden stehen: kurze Piepser aus einem Lautsprecher, nicht aus einem Studio. Bis Musik kommt, gibt es nur Effekte, und die nur dort, wo ein Gerät tatsächlich piepen würde. Der Abschnitt ist der Maßstab für jeden Ton im Spiel.

## Leitsätze

- **Ein Gerät, kein Orchester.** Rechteckwelle und Rauschen, wie ein Taschengerät von 1991 oder der Lautsprecher eines PCs. Kein Hall, keine Stereobreite, keine Aufnahmen.
- **Selten und kurz.** Ein Ton bestätigt etwas, das gerade passiert ist. Er dauert so kurz wie möglich und ist eher leise.
- **Aus einer Quelle.** Alle Töne erzeugt ein Skript im Repo (`tools/ton/make_sounds.py`), bei jedem Lauf dieselben Bytes. Es gibt keine Töne aus fremden Quellen und keine aus dem Vorbild eines Spiels.
- **Die Bedienung bleibt stumm.** Menü, Liste, Hinweis und Meldung machen keinen Ton. Es klingen nur die Gehäusetasten und das Spiel auf der Anzeige.

## Format

- WAV, 22 050 Hz, 16 Bit, mono; in Godot ohne Kompression (PCM), ohne Trimmen, Normalisieren und Schleife importiert.
- Jeder Ton beginnt ohne Stille, damit er sofort klingt, und endet mit 5 ms Ausblenden gegen Knacken.
- Spitzenpegel −6 dBFS.

## Tonkanäle

| Kanal | Pegel | Ziel | Wofür |
|---|---|---|---|
| `Master` | 0 dB | Ausgang | alles zusammen; später die Gesamtlautstärke in den Einstellungen |
| `Effekte` | −10 dB | `Master` | jeder Ton dieses Abschnitts |

Musik bekommt später einen eigenen Kanal neben `Effekte`. Ein späteres „Einstellungen“ regelt nur die Kanäle, nie einen einzelnen Ton. Kein Effekt auf den Kanälen.

## Töne

| Datei | Wofür | Klang | Länge |
|---|---|---|---|
| `knopf.wav` | Gehäusetaste gedrückt (Baustein Communicator) | Rauschen, kurz abfallend: ein trockener Klick | 4 ms |
| `schuss.wav` | Schuss der Kanone | Rechteck, 1200 Hz fallend auf 600 Hz | 80 ms |
| `treffer.wav` | Außerirdischer getroffen | Rauschen mit Rechteck 200 Hz, abfallend | 120 ms |
| `kanone.wav` | Kanone getroffen | Rauschen, langsam abfallend | 600 ms |
| `marsch_1.wav` bis `marsch_4.wav` | Takt des Blocks, im Wechsel | Rechteck 98, 87, 78 und 73 Hz | je 60 ms |
| `sieg.wav` | Spiel gewonnen | Rechteck, aufsteigend C5, E5, G5, C6 | je 90 ms, 360 ms |
| `niederlage.wav` | Spiel verloren | Rechteck, absteigend G4, E4, C4 | je 160 ms, 480 ms |

- Die vier Marschtöne teilen sich eine Stimme: Ein neuer Takt schneidet den vorigen Ton ab, auch wenn die Takte kürzer werden als der Ton.
- Die anderen Töne des Spiels haben je eine eigene Stimme; derselbe Ton beginnt von vorn.
- Verliert das Fenster den Fokus, halten die Töne an. Verlässt der Spieler das Spiel, verstummen sie; das Motiv für Sieg oder Niederlage klingt in der Ergebnisanzeige aus.

## Nicht

- Kein Ton für Überfahren, Auswahl, Seitenwechsel, Hinweis oder Meldung.
- Keine Aufnahmen, keine Samples aus Bibliotheken, kein Hall, kein Stereo.
- Nichts lauter als nötig; im Zweifel leiser.
