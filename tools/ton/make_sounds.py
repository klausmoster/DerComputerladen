"""Erzeugt alle Töne von „Der Computerladen“ als WAV nach src/assets/sounds/.

Klang, Tonhöhen, Längen und Pegel stehen im Style-Guide, Abschnitt „Ton“; hier stehen sie als
Zahlen, damit jeder Lauf dieselben Bytes schreibt. Ändert sich der Style-Guide, ändert sich die
Tabelle TOENE und danach die Prüfsummen (--pruefsummen).

Aufruf vom Repo-Root:
    python3 -I tools/ton/make_sounds.py
    python3 -I tools/ton/make_sounds.py --pruefsummen

Nur Standardbibliothek. Rechteckwelle für Töne, Rauschen aus festem Seed je Datei. Jeder Ton
beginnt ohne Stille und endet mit 5 ms Ausblenden; Spitzenpegel -6 dBFS.
"""

import hashlib
import math
import os
import random
import struct
import sys
import wave

RATE = 22050
PEGEL = 10 ** (-6 / 20) * 32767  # Spitzenpegel -6 dBFS
AUSBLENDEN = int(RATE * 0.005)  # 5 ms

ZIEL = os.path.join("src", "assets", "sounds")
PRUEFSUMMEN = os.path.join("src", "test", "fixtures", "ton_pruefsummen.txt")


def samples(ms):
    return round(RATE * ms / 1000)


def rechteck(frequenz_von, frequenz_bis, ms):
    """Rechteckwelle, deren Frequenz linear von frequenz_von nach frequenz_bis läuft.

    Die Phase beginnt bei 0, die erste Probe ist also +PEGEL: kein stiller Anfang.
    """
    n = samples(ms)
    werte = []
    phase = 0.0
    for i in range(n):
        frequenz = frequenz_von + (frequenz_bis - frequenz_von) * i / max(n - 1, 1)
        werte.append(1.0 if phase % 1.0 < 0.5 else -1.0)
        phase += frequenz / RATE
    return werte


def rauschen(ms, seed):
    """Weißes Rauschen aus festem Seed; die erste Probe ist nie null."""
    zufall = random.Random(seed)
    werte = [zufall.uniform(-1.0, 1.0) for _ in range(samples(ms))]
    werte[0] = 1.0
    return werte


def abfallend(werte, steilheit):
    """Hüllkurve, die exponentiell abfällt; steilheit 0 heißt gleichbleibend."""
    n = len(werte)
    return [w * math.exp(-steilheit * i / n) for i, w in enumerate(werte)]


def mischen(a, b, anteil_b):
    return [x * (1 - anteil_b) + y * anteil_b for x, y in zip(a, b)]


def folge(noten_hz, ms_je_note):
    werte = []
    for hz in noten_hz:
        werte += rechteck(hz, hz, ms_je_note)
    return werte


def ausblenden(werte):
    """Die letzten 5 ms linear auf null; bei kürzeren Tönen der ganze Ton."""
    n = len(werte)
    laenge = min(AUSBLENDEN, n)
    for k in range(laenge):
        i = n - laenge + k
        werte[i] *= (laenge - 1 - k) / laenge
    return werte


def als_bytes(werte):
    return b"".join(struct.pack("<h", int(round(w * PEGEL))) for w in werte)


# Name, Erzeuger. Werte aus dem Style-Guide, Abschnitt „Ton“.
TOENE = [
    ("knopf.wav", lambda: abfallend(rauschen(4, 1), 4)),
    ("schuss.wav", lambda: rechteck(1200, 600, 80)),
    ("treffer.wav", lambda: abfallend(mischen(rauschen(120, 2), rechteck(200, 200, 120), 0.5), 3)),
    ("kanone.wav", lambda: abfallend(rauschen(600, 3), 2)),
    ("marsch_1.wav", lambda: rechteck(98, 98, 60)),
    ("marsch_2.wav", lambda: rechteck(87, 87, 60)),
    ("marsch_3.wav", lambda: rechteck(78, 78, 60)),
    ("marsch_4.wav", lambda: rechteck(73, 73, 60)),
    ("sieg.wav", lambda: folge([523.25, 659.25, 783.99, 1046.50], 90)),
    ("niederlage.wav", lambda: folge([392.00, 329.63, 261.63], 160)),
]


def schreiben(pfad, werte):
    with wave.open(pfad, "wb") as datei:
        datei.setnchannels(1)
        datei.setsampwidth(2)
        datei.setframerate(RATE)
        datei.writeframes(als_bytes(werte))


def main():
    pruefsummen = "--pruefsummen" in sys.argv[1:]
    os.makedirs(ZIEL, exist_ok=True)
    zeilen = []
    for name, erzeuger in TOENE:
        werte = ausblenden(erzeuger())
        pfad = os.path.join(ZIEL, name)
        schreiben(pfad, werte)
        groesse = os.path.getsize(pfad)
        print(f"{name:16} {len(werte) * 1000 / RATE:6.1f} ms {groesse:7} Bytes")
        with open(pfad, "rb") as datei:
            zeilen.append(f"{name} {hashlib.md5(datei.read()).hexdigest()}")
    if pruefsummen:
        with open(PRUEFSUMMEN, "w", encoding="utf-8") as datei:
            datei.write("\n".join(zeilen) + "\n")
        print(f"Prüfsummen nach {PRUEFSUMMEN}")


if __name__ == "__main__":
    main()
