# Ton

- **Worum es geht:** die Tonkanäle des Spiels, die zehn Töne, wie sie entstehen und wie Tests sie
  prüfen.
- **Laden, wenn:** ein Ton dazukommt oder sich ändert, etwas Töne spielen soll, Kanäle oder
  Lautstärke betroffen sind, oder später „Einstellungen“ und Musik kommen.
- **Code:** `src/default_bus_layout.tres`, `src/assets/sounds/` (zehn WAV mit `.import`),
  `tools/ton/make_sounds.py` und `tools/ton/README.md`; Tests `src/test/test_ton.gd` mit
  `src/test/fixtures/ton_pruefsummen.txt`
- **Herkunft:** `specs/006-easter-egg-space-invaders/` (`contracts/ton.md`, `research.md` R13 bis
  R15); Abschnitt „Ton“ im [Style-Guide](https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX), der
  Klang, Längen und Pegel regelt
- **Stand:** Feature 006, 2026-10-28
- **Nachbarn:** wer die Töne spielt in [communicator.md](communicator.md) und
  [easter-egg.md](easter-egg.md), Tests in [build-und-tests.md](build-und-tests.md)

## Kanäle

`src/default_bus_layout.tres` hat zwei Kanäle. Godot lädt die Datei unter diesem Namen von selbst;
`project.godot` nennt sie nicht.

| Kanal | Pegel | mündet in | Für |
|---|---|---|---|
| `Master` | 0 dB | – | alles zusammen |
| `Effekte` | −10 dB | `Master` | jeden Ton des Spiels |

Kein Effekt auf den Kanälen, keiner stumm. Regel für jeden Code, der Töne spielt: ein
`AudioStreamPlayer` mit `bus = &"Effekte"`. Ein Autoload für Töne gibt es nicht; jede Szene hat ihre
eigenen Player. Musik bekäme später einen eigenen Kanal neben `Effekte`, und ein späteres
„Einstellungen“ regelt nur Kanäle, keine Player.

## Die Töne

Alle unter `src/assets/sounds/`, zusammen rund 84 KB:

| Datei | Länge | Klang | Zweck | gespielt von |
|---|---|---|---|---|
| `knopf.wav` | 4 ms | Rauschen, abfallend | Gehäusetaste gedrückt, auch ein Druck, der nicht zählt | `Communicator`, Knoten `KeyClick` |
| `schuss.wav` | 80 ms | Rechteck 1200 → 600 Hz | Schuss der Kanone | `InvadersPage`, `ShotSound` |
| `treffer.wav` | 120 ms | Rauschen mit Rechteck 200 Hz, abfallend | Außerirdischer getroffen | `InvadersPage`, `HitSound` |
| `kanone.wav` | 600 ms | Rauschen, langsam abfallend | Kanone getroffen | `InvadersPage`, `CannonSound` |
| `marsch_1.wav` bis `marsch_4.wav` | je 60 ms | Rechteck 98, 87, 78, 73 Hz | Takt des Blocks, im Kreis | `InvadersPage`, `MarchSound` |
| `sieg.wav` | 360 ms | Rechteck C5 E5 G5 C6, je 90 ms | gewonnen | `InvadersPage`, `WonSound` |
| `niederlage.wav` | 480 ms | Rechteck G4 E4 C4, je 160 ms | verloren | `InvadersPage`, `LostSound` |

`play()` beginnt einen Ton, der noch klingt, von vorn. Die vier Marschtöne teilen sich einen Player;
ein neuer Takt schneidet den vorigen ab. Zu welchem Ereignis welcher Ton kommt, steht in
[easter-egg.md](easter-egg.md).

## Erzeugen: make_sounds.py

```bash
python3 -I tools/ton/make_sounds.py                 # schreibt die zehn WAV
python3 -I tools/ton/make_sounds.py --pruefsummen   # dazu die Prüfsummen
```

Vom Repo-Root, nur Python-Standardbibliothek, keine Eingabe. Die Werte stehen in der Tabelle `TOENE`
im Skript, abgeschrieben aus dem Style-Guide; geändert wird erst dort, dann hier.

- WAV, 22 050 Hz, 16 Bit, mono.
- Töne als Rechteckwelle, deren Frequenz linear gleiten kann; Rauschen aus `random.Random` mit
  festem Seed je Datei. Jeder Lauf schreibt dieselben Bytes.
- Spitzenpegel −6 dBFS. Die erste Probe ist nie null, kein Ton beginnt mit Stille. Die letzten 5 ms
  blendet das Skript linear aus, gegen Knacken.
- Ausgabe je Datei: Name, Länge in ms, Größe in Bytes.

**Import:** Die `.import` jeder WAV setzt Kompression aus (`compress/mode=0`, PCM), kein Trimmen,
kein Normalisieren, keine Schleife (`edit/loop_mode=1`). So spielt Godot die Proben unverändert. Die
`.import` werden committet wie jede andere.

## Prüfen

`src/test/fixtures/ton_pruefsummen.txt` hält je Datei eine MD5-Prüfsumme; `--pruefsummen` schreibt
sie neu. `test_ton.gd` prüft:
- genau die zehn Töne im Ordner, jeder lädt als `AudioStreamWAV` in PCM ohne Schleife; die `.import`
  stimmen;
- aus der Rohdatei: mono, 22 050 Hz, 16 Bit; erste Probe nicht null, letzte unter 1 % des
  Vollausschlags; Länge wie oben, ±1 ms;
- jede Datei bytegleich mit der Liste der Prüfsummen;
- genau zwei Kanäle, `Master` auf 0 dB, `Effekte` auf −10 dB mit Ziel `Master`, kein Effekt, keiner
  stumm.

Proben, Länge und Prüfsumme liest der Test aus der Rohdatei, nicht aus der importierten Ressource.
Ob es gut klingt, prüft kein Test, sondern Klaus mit `afplay` (Befehl in `tools/ton/README.md`).

## Verhalten

- **Ohne Tonausgang** oder bei stummem Rechner läuft alles weiter, ohne Meldung. Dafür gibt es
  keinen eigenen Code; die Player spielen auch dann. Headless laufen die Tests mit Godots
  Dummy-Treiber, dort wird `playing` true, ohne dass etwas zu hören ist. Tests prüfen deshalb,
  welcher Player auf welchem Kanal anläuft.
- **Fenster ohne Fokus:** Das Spiel auf der Anzeige hält seine Töne an (`stream_paused`) und lässt
  sie mit dem Fokus weiterklingen, wo sie standen. Für `KeyClick` gibt es keine solche Regel; der
  Klick ist 4 ms lang.
- **Esc und Weiter:** Verlässt der Spieler das Spiel auf der Anzeige, verstummen alle seine Töne
  (`stop()`); ebenso, wenn die Seite verborgen wird. Das Motiv für Sieg oder Niederlage klingt in
  der Ergebnisanzeige aus.
- Sonst ist der Titel stumm.
