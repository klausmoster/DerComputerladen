# Vertrag: Ton

Die Töne dieses Features und die Tonkanäle des Spiels (Spec, FR-040 bis FR-044, SC-007).
Entscheidungen in [research.md](../research.md) R13 bis R15.

**Vorbedingung:** Der Abschnitt „Ton“ steht im Style-Guide mit Klang, Tönen und Pegeln, und Klaus hat
ihn freigegeben (R12). Die Tabelle in R13 ist der Vorschlag dafür; gültig ist der Style-Guide.

## Dateien

```text
tools/ton/
├── make_sounds.py                       # neu [C]: erzeugt alle WAV, bytegleich bei jedem Lauf
└── README.md                            # neu [C]: Aufruf, Töne, wo der Style-Guide sie regelt
src/
├── default_bus_layout.tres              # neu [A]: Master, Effekte
├── assets/sounds/                       # neu, von make_sounds.py; .import committet
│   ├── knopf.wav
│   ├── schuss.wav, treffer.wav, kanone.wav
│   ├── marsch_1.wav … marsch_4.wav
│   └── sieg.wav, niederlage.wav
└── test/test_ton.gd                     # neu [A]
```

## Skript

```bash
python3 -I tools/ton/make_sounds.py
```

- Nur Standardbibliothek (`wave`, `struct`, `math`, `random` mit festem Seed). Keine Eingabe, kein
  Download.
- Schreibt nach `src/assets/sounds/`, 22 050 Hz, 16 Bit, mono. Ein zweiter Lauf ergibt dieselben
  Bytes.
- Rechteckwelle für Töne, Rauschen aus festem Seed; jeder Ton beginnt ohne Stille und endet mit
  5 ms Ausblenden; Spitzenpegel aus dem Style-Guide (Analyse, V1).
- Je WAV eine `.import` mit Kompression aus (PCM), ohne Trimmen, Normalisieren und Schleife
  (Analyse, U6).
- Gibt je Datei Name, Länge in ms und Größe aus.

## Tonkanäle

`src/default_bus_layout.tres`: `Master` und `Effekte` (Ziel `Master`), Pegel aus dem Style-Guide. Godot lädt die
Datei von selbst; `project.godot` bleibt unverändert. Kein Effekt auf den Kanälen.

Regel für jeden Code, der Töne spielt: `AudioStreamPlayer` mit `bus = &"Effekte"`. Musik kommt später
als eigener Kanal neben `Effekte`; ein späteres „Einstellungen“ ändert nur Kanäle, keine Player.

## Tests (`test_ton.gd`)

- Alle zehn Dateien sind als `AudioStreamWAV` ladbar, mono, 22 050 Hz.
- Bei jeder Datei ist die erste Probe nicht null (kein stiller Anfang, SC-007), und die letzte liegt
  nahe null (Ausblenden).
- Länge je Datei wie im Style-Guide, ±1 ms.
- Der Kanal `Effekte` existiert, mündet in `Master` und steht auf dem Wert aus dem Style-Guide.
- Das Skript erzeugt bytegleich: Der Test vergleicht Prüfsummen der Dateien mit einer gespeicherten
  Liste in `src/test/fixtures/ton_pruefsummen.txt`, die `make_sounds.py --pruefsummen` schreibt.
