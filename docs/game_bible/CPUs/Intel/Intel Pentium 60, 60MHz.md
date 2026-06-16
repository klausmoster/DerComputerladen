---
grunddaten_hersteller: Intel
grunddaten_modell: Pentium 60 (P5, 80501)
grunddaten_architektur: P5 (IA-32, superskalar)
grunddaten_einführung_de: 1993-03
grunddaten_marktende_de: 1996-06
grunddaten_verkaufsform: Boxed / Tray, On-Board (Sockel 4)
technik_takt: 60 MHz
technik_takt_mhz: 60
technik_außentakt: 60 MHz (1:1, kein Multiplikator)
technik_vcore: 5,0 V
technik_cache_l1: 16 KB (8 KB Code + 8 KB Daten)
technik_cache_l2: Extern auf Board (typ. 256–512 KB)
technik_adressbus: 32 Bit (bis 4 GB)
technik_databus: 64 Bit (extern)
technik_fpu: Ja (integriert; FDIV-Bug bei Steppings vor D1)
technik_transistoren: 3100000
technik_prozess: 0,8 µm BiCMOS
technik_gehäuse: 273-Pin PGA (CPGA)
technik_tdp: 14,6 W (typ. ~15 W)
technik_socket: Sockel 4 (273-Pin)
markt:
- zeitraum: 1993-03
  marktphase: Neu-Einführung (High-End)
- zeitraum: 1993-09
  marktphase: High-End-Markt
- zeitraum: 1994-06
  marktphase: Verdrängung (P54C kommt)
- zeitraum: 1994-12
  marktphase: Auslauf (FDIV-Rückruf)
- zeitraum: 1995-12
  marktphase: Restmarkt
- zeitraum: 1996-06
  marktphase: Marktende
preise_cpu:
- datum: 1993-03
  von: 1800
  bis: 2500
- datum: 1993-06
  von: 1500
  bis: 2200
- datum: 1993-12
  von: 1100
  bis: 1700
- datum: 1994-06
  von: 700
  bis: 1200
- datum: 1994-12
  von: 400
  bis: 800
- datum: 1995-06
  von: 250
  bis: 500
- datum: 1995-12
  von: 150
  bis: 350
- datum: 1996-06
  von: 100
  bis: 250
handel:
- datum: 1993-06
  einkauf_von: 1300
  einkauf_bis: 1900
  verkauf_von: 1700
  verkauf_bis: 2400
  marge_von: 400
  marge_bis: 500
- datum: 1993-12
  einkauf_von: 1000
  einkauf_bis: 1500
  verkauf_von: 1300
  verkauf_bis: 1900
  marge_von: 300
  marge_bis: 400
- datum: 1994-06
  einkauf_von: 650
  einkauf_bis: 1100
  verkauf_von: 850
  verkauf_bis: 1400
  marge_von: 200
  marge_bis: 300
- datum: 1994-12
  einkauf_von: 380
  einkauf_bis: 750
  verkauf_von: 500
  verkauf_bis: 1000
  marge_von: 120
  marge_bis: 250
- datum: 1995-06
  einkauf_von: 230
  einkauf_bis: 470
  verkauf_von: 320
  verkauf_bis: 620
  marge_von: 90
  marge_bis: 150
- datum: 1995-12
  einkauf_von: 140
  einkauf_bis: 330
  verkauf_von: 200
  verkauf_bis: 450
  marge_von: 60
  marge_bis: 120
lager:
- zeit: 0-3 Monate
  wertverlust: 0 %
- zeit: 3-6 Monate
  wertverlust: 0 %
- zeit: 6-12 Monate
  wertverlust: 5 %
- zeit: 12-18 Monate
  wertverlust: 15 %
- zeit: 18-24 Monate
  wertverlust: 35 %
- zeit: '>24 Monate'
  wertverlust: 60 %
kompatibilität:
- komponente: Mainboard
  anforderung: Sockel 4 (273-Pin) zwingend – eigene Plattform
- komponente: RAM
  anforderung: 72-Pin-SIMM paarweise (64-Bit-Bus); typ. 8–32 MB
- komponente: Cache L2
  anforderung: Extern auf Board, typ. 256–512 KB Fast-SRAM
- komponente: Kühlung
  anforderung: Aktiver Kühlkörper + Lüfter nötig (5 V, läuft heiß)
- komponente: FPU
  anforderung: Integriert – kein Koprozessor nötig
- komponente: Upgrade-Pfad
  anforderung: Pentium 66 / Pentium OverDrive (P24T); P54C nur mit neuem Board (Sockel 5)
- komponente: Downgrade
  anforderung: 486DX2-66, 486DX4-100
wettbewerb:
- produkt: Intel 486DX2-66
  position: Günstigerer Vorgänger, in der Praxis oft fast gleich schnell
- produkt: AMD Am486DX2-66/DX4-100
  position: Deutlich günstigere Alternative
- produkt: Intel Pentium 66
  position: Schnelleres Schwestermodell, gleiche Plattform
- produkt: Intel Pentium 75/90/100 (P54C)
  position: Nachfolger ab Ende 1994 – kühler (3,3 V), schneller, neuer Sockel
tags:
- cpu
- pentium
- intel
- p5
- sockel4
---
# Intel Pentium 60, 60MHz

## + Fakten

### Datenblatt
**Intel Pentium™ 60 — Technisches Datenblatt**

- Hersteller: Intel
- Typ: superskalarer 32-Bit-Mikroprozessor, Architektur P5 (IA-32), erster Pentium
- Taktfrequenz: 60 MHz (Außen-/Bustakt 60 MHz, 1:1 – kein Taktmultiplikator)
- Recheneinheiten: zwei Integer-Pipelines (U/V) + integrierte Gleitkomma-Einheit
- Daten-/Adressbus: 64 Bit / 32 Bit → adressierbar bis 4 GB
- On-Die-Cache: 16 KB L1 (8 KB Code + 8 KB Daten, getrennt)
- Board-Cache: externer L2-Cache empfohlen (Fast-SRAM, typ. 256–512 KB)
- Transistoren: ca. 3,1 Millionen, 0,8-µm-BiCMOS-Fertigung
- Versorgung: 5,0 V; Verlustleistung ≈ 14,6 W → aktive Kühlung zwingend
- Gehäuse: 273-Pin-PGA (CPGA), Sockel 4
- Mainboard: spezielles Sockel-4-Board erforderlich (eigene Plattform)

### Beschreibung
Der Pentium 60 ist der allererste Vertreter von Intels Pentium-Familie und löst
die 486er-Generation an der Leistungsspitze ab. Als erster superskalarer x86-
Prozessor verarbeitet er über zwei parallele Integer-Pipelines unter günstigen
Bedingungen zwei Befehle pro Takt und besitzt eine fest integrierte, gegenüber
dem 486 stark beschleunigte Gleitkomma-Einheit. Der getrennte L1-Cache (je 8 KB
für Code und Daten) und der 64 Bit breite externe Datenbus heben ihn deutlich
über die 486-Klasse.

Verkauft wird die CPU mit 5 Volt Betriebsspannung und einer Verlustleistung um
15 Watt – für 1993 ungewöhnlich viel, weshalb ein aktiver Kühlkörper Pflicht ist.
Der Pentium 60 benötigt ein eigenes Sockel-4-Board (273 Pins) und lässt sich nicht
auf die späteren, sparsameren P54C-Modelle (ab 75 MHz, 3,3 V) aufrüsten. Frühe
Steppings (vor D1) sind vom Pentium-FDIV-Bug betroffen, der bei bestimmten
Divisionen falsche Fließkomma-Ergebnisse liefert.

### Hintergrund & Quellen
Der Pentium 60 (Codename P5, Intel-Nummer 80501) wurde am 22. März 1993 zusammen
mit dem Pentium 66 als erster Vertreter der Pentium-Familie vorgestellt – Intels
erster superskalarer x86-Prozessor und der Urahn aller modernen x86-CPUs. Beide
P5-Modelle liefen mit 5 Volt, einer für die Zeit hohen Verlustleistung (~15 W) und
auf der eigenen Plattform Sockel 4 (273 Pins). Schon im Oktober 1994 folgte die
sparsamere, höher getaktete P54C-Generation (Pentium 75/90/100) mit 3,3 V und
Sockel 5, die den 60/66er rasch verdrängte.

Besonderheit: Frühe Steppings (vor D1) des Pentium 60/66 sind vom berühmten
**FDIV-Bug** betroffen – einem Fehler in der Divisionstabelle der FPU, der bei
bestimmten hochgenauen Divisionen falsche Ergebnisse liefert. Nach öffentlichem
Druck rief Intel im Dezember 1994 alle betroffenen Pentiums zurück; die Aktion
kostete rund 475 Mio. US-Dollar.

Hinweise zur Datenlage: Technische Werte sind durch mehrere Quellen belegt
(siehe unten). Die **DM-Preise und Handelsspannen sind plausibel geschätzt** für
den deutschen Markt 1993–1996 – belastbare zeitgenössische Listenpreise in D-Mark
ließen sich nicht auffinden; bekannt ist nur Intels US-Einführungspreis von rund
878 USD (Pentium 60, 1000-Stück-Abnahme). Auch das **Marktende DE (1996-06)** ist
geschätzt. Die TDP variiert je nach Quelle zwischen 14,6 W (Pentium 60) und 16 W
(Pentium 66).

- Wikipedia (DE): Intel Pentium — https://de.wikipedia.org/wiki/Intel_Pentium
- Wikipedia (EN): Pentium (original) — https://en.wikipedia.org/wiki/Pentium_(original)
- Wikipedia (EN): Pentium FDIV bug — https://en.wikipedia.org/wiki/Pentium_FDIV_bug
- ComputerBase, „Der erste Intel Pentium" — https://www.computerbase.de/2020-01/intel-pentium-prozessor/
- heise online, „30 Jahre Intel Pentium" — https://www.heise.de/news/30-Jahre-Intel-Pentium-Urahn-der-modernen-x86-CPUs-7627807.html
- Tom's Hardware, „30 years since the Pentium FDIV bug" — https://www.tomshardware.com/pc-components/cpus/its-been-30-years-since-intels-infamous-pentium-fdiv-bug-reared-its-ugly-head-a-math-bug-caused-intels-first-cpu-recall

## + Game Content

### Zeitungsartikel
**Der „Pentium" ist da — Intels 64-Bit-Bolide sprengt die 486-Klasse**

*Hannover, CeBIT 1993* — Intel hat die Katze aus dem Sack gelassen: Der Nachfolger
des 486 heißt nicht „586", sondern **Pentium**, und er macht seinem Namen alle
Ehre. Mit 60 Megahertz, zwei parallel arbeitenden Rechenwerken und einem 64 Bit
breiten Datenbus zieht der neue Chip an allem vorbei, was die 486-Riege zu bieten
hat — bei Fließkomma-Rechnerei sogar mit großem Abstand.

Im Testlabor zeigt sich allerdings auch: Der Pentium will umsorgt werden. 5 Volt
und rund 15 Watt Abwärme verlangen nach einem kräftigen Kühlkörper samt Lüfter,
und ohne ein nagelneues Sockel-4-Board läuft gar nichts — die alte 486-Platine
darf in Rente. Wer den Sprung wagt, zahlt kräftig drauf: Komplette Pentium-
Maschinen mit Platte und Speicher beginnen jenseits der 6.000 Mark, gut
ausgestattet sind auch fünfstellige Beträge schnell erreicht.

Für Normalanwender bleibt der schnelle 486DX2 vorerst die vernünftigere Wahl. Doch
die Richtung ist klar: Der Pentium ist die Zukunft — man muss sie sich nur leisten
können.

### Werbung
**DER NEUE STERN AM PC-HIMMEL — PENTIUM™ 60!**

★ Schluss mit Schneckentempo! ★

Zwei Rechenwerke. 64 Bit. Eine eingebaute Fließkomma-Maschine, die jeden 486 alt
aussehen lässt. Der **Intel Pentium 60** ist kein Computer — er ist ein
**Düsentriebwerk für Ihren Schreibtisch!**

Tabellen? Berechnet, bevor Sie „Enter" gedacht haben. Windows? Fliegt. CAD?
Kinderspiel. Damit das Kraftpaket cool bleibt, legen wir den Profi-Kühler gratis
obendrauf!

**Komplettsystem mit Pentium 60, 8 MB RAM & Festplatte — ab 6.999,– DM**
*(unverb. Richtpreis, zzgl. Monitor)*

Die Zukunft hat 60 Megahertz. **Fragen Sie Ihren Fachhändler — heute noch!**
