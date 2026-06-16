---
grunddaten_hersteller: AMD (Advanced Micro Devices)
grunddaten_modell: Am386DX-40
grunddaten_architektur: i386 (IA-32)
grunddaten_einführung_de: 1991-03
grunddaten_marktende_de: 1994-06
grunddaten_verkaufsform: On-Board / Mainboard
technik_takt: 40 MHz
technik_takt_mhz: 40
technik_außentakt: 40 MHz (1:1)
technik_vcore: 5.0 V
technik_cache_l1: Nein (kein On-Die-Cache)
technik_cache_l2: Extern auf Board (typ. 0–256 KB)
technik_adressbus: 32 Bit
technik_databus: 32 Bit
technik_fpu: Nein (externer 80387DX nötig)
technik_transistoren: 275000
technik_prozess: 1,0 µm
technik_gehäuse: 132-Pin PGA / PQFP
technik_tdp: 2,1 W
technik_socket: PGA132
markt:
- zeitraum: 1991-03
  marktphase: Neu-Einführung
- zeitraum: 1992-01
  marktphase: Massenmarkt
- zeitraum: 1993-01
  marktphase: Verdrängung
- zeitraum: 1994-01
  marktphase: Auslauf
- zeitraum: 1994-07
  marktphase: Marktende
preise_cpu:
- datum: 1991-03
  von: 350
  bis: 450
- datum: 1991-06
  von: 300
  bis: 400
- datum: 1991-12
  von: 250
  bis: 350
- datum: 1992-06
  von: 180
  bis: 280
- datum: 1992-12
  von: 150
  bis: 220
- datum: 1993-06
  von: 100
  bis: 160
- datum: 1993-12
  von: 60
  bis: 120
- datum: 1994-04
  von: 40
  bis: 80
handel:
- datum: 1991-06
  einkauf_von: 800
  einkauf_bis: 1100
  verkauf_von: 1200
  verkauf_bis: 1600
  marge_von: 400
  marge_bis: 500
- datum: 1991-12
  einkauf_von: 700
  einkauf_bis: 950
  verkauf_von: 1000
  verkauf_bis: 1400
  marge_von: 300
  marge_bis: 450
- datum: 1992-06
  einkauf_von: 550
  einkauf_bis: 800
  verkauf_von: 800
  verkauf_bis: 1100
  marge_von: 250
  marge_bis: 300
- datum: 1992-12
  einkauf_von: 500
  einkauf_bis: 700
  verkauf_von: 700
  verkauf_bis: 950
  marge_von: 200
  marge_bis: 250
- datum: 1993-06
  einkauf_von: 400
  einkauf_bis: 600
  verkauf_von: 550
  verkauf_bis: 800
  marge_von: 150
  marge_bis: 200
- datum: 1993-12
  einkauf_von: 300
  einkauf_bis: 500
  verkauf_von: 400
  verkauf_bis: 600
  marge_von: 100
  marge_bis: 150
- datum: 1994-04
  einkauf_von: 250
  einkauf_bis: 400
  verkauf_von: 300
  verkauf_bis: 450
  marge_von: 50
  marge_bis: 80
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
- komponente: RAM Limit
  anforderung: 16 MB (72-Pin SIMM)
- komponente: 40 MHz Board nötig
  anforderung: Ja
- komponente: Upgrade-Pfad
  anforderung: Cyrix 486DLC/DRx2, IBM 386SLC/486DLC, Intel RapidCAD
- komponente: Downgrade
  anforderung: 386DX-33, 386DX-25, 386SX-20/25
wettbewerb:
- produkt: Intel 386DX-33
  position: Selbe Liga, langsamer
- produkt: Intel 486SX-25
  position: Nachfolger, Budget
- produkt: Intel 486DX-25/33
  position: Nachfolger, Premium
- produkt: Cyrix Cx486SLC/DLC
  position: Upgrade-kompatibel
tags:
- cpu
- 386
- amd
- dx40
---
# AMD Am386DX-40, 40MHz

## + Fakten

### Datenblatt
**AMD Am386DX-40 — Technisches Datenblatt**

- Hersteller: AMD (Advanced Micro Devices)
- Typ: 32-Bit-Mikroprozessor, Architektur i386 (IA-32)
- Taktfrequenz: 40 MHz (Front-/Außentakt 40 MHz, 1:1)
- Daten-/Adressbus: 32 Bit / 32 Bit → adressierbar bis 4 GB
- On-Die-Cache: keiner; externer Board-Cache (Fast-SRAM, typ. 64–256 KB) empfohlen
- Numerik: kein integrierter Coprozessor — Aufrüstung mit 80387DX-40 (oder Kompatible)
- Transistoren: ca. 275.000, CMOS-Fertigung (≈1,0 µm, geschätzt)
- Versorgung: 5,0 V; Verlustleistung ≈ 2 W (passiv kühlbar)
- Gehäuse: 132-Pin PGA (auch PQFP), Sockel PGA132
- Mainboard: 40-MHz-fähiges 386-Board zwingend erforderlich
- RAM: bis 16 MB (30-/72-Pin-SIMM, je nach Board)

### Beschreibung
Der Am386DX-40 ist die schnellste Ausbaustufe von AMDs 386-Nachbau und mit
40 MHz höher getaktet als Intels schnellster eigener 386DX (33 MHz). Technisch
entspricht er dem Intel-Original: voll 32-bittig in Datenbus, Adressbus und
internen Registern, ohne eigenen Cache und ohne integrierte Gleitkomma-Einheit.
Für rechenintensive Anwendungen (CAD, Tabellenkalkulation mit FPU-Code) lässt er
sich um einen 80387DX-Koprozessor ergänzen; ein externer Board-Cache hebt die
effektive Leistung zusätzlich. Verkauft wurde die CPU im deutschen Handel fast
ausschließlich fest auf dem Mainboard bzw. als Board-CPU-Bundle. Sie positioniert
sich als preisgünstige Leistungsspitze der 386-Klasse und als gängige
Einsteiger- und Aufrüst-CPU, bevor die 486er-Generation ab 1993 übernimmt.

### Hintergrund & Quellen
Der Am386DX-40 war AMDs Antwort auf Intels 386er und lief mit 40 MHz schneller
als Intels schnellster 386DX (33 MHz). Möglich wurde der Nachbau erst nach einem
langen Rechtsstreit um Mikrocode-Lizenzen, den AMD gegen Intel weitgehend gewann.
Die CPU machte AMD zum ernsten x86-Konkurrenten, drückte die 386-Preise spürbar
und verkaufte sich millionenfach. Beliebt als günstige Aufrüst- und
Einsteiger-CPU, bis die 486er-Generation sie ab ~1993 verdrängte.

Hinweise zur Datenlage: Der Fertigungsprozess (~1,0 µm) ist **geschätzt** —
AMD nutzte für spätere Am386-Chargen feinere CMOS-Prozesse (teils 0,8 µm). Auch
die DM-Preise und Handelsspannen sind **plausibel geschätzte** Marktwerte für den
deutschen Markt 1991–1994; belastbare exakte Listenpreise liegen nicht vor.

- Wikipedia: AMD Am386 — https://de.wikipedia.org/wiki/AMD_Am386
- Wikipedia (EN): Am386 — https://en.wikipedia.org/wiki/AM386
- Intel/AMD-Rechtsstreit & 386-Klone: https://en.wikipedia.org/wiki/Advanced_Micro_Devices#History
- CPU-World, Am386DX-40 Spezifikationen — https://www.cpu-world.com/CPUs/80386/

## + Game Content

### Zeitungsartikel
**AMD greift an: 40-MHz-386 schlägt Intel im Preiskampf**

*Sunnyvale/München, Frühjahr 1991* — Mit dem Am386DX-40 setzt AMD ein
Ausrufezeichen: Erstmals kommt ein 386er-Prozessor nicht von Intel und ist
obendrein schneller getaktet als alles, was der Marktführer im 386-Regal hat.
40 statt 33 Megahertz — auf dem Papier rund ein Fünftel mehr Dampf, in der Praxis
je nach Speicher und Board ein spürbares Plus.

Im Testlabor zeigt sich der AMD-Chip als waschechter 386: 32 Bit breit, bis zu
4 Gigabyte adressierbar, aber ohne eigenen Cache und ohne Rechenwerk für
Fließkomma. Wer mit AutoCAD oder großen Kalkulationen hantiert, sollte den
387er-Koprozessor und einen flotten Board-Cache einplanen — dann zieht die
Maschine an manchem trägen 486SX vorbei, und das zum halben Preis.

Apropos Preis: AMDs Vorstoß bringt Bewegung in den Markt. Komplett-PCs mit
40-MHz-386 und Festplatte sind bereits ab gut 4.000 Mark zu haben, Tendenz
fallend. Für Aufrüster und Sparfüchse ist der Am386DX-40 derzeit die
interessanteste CPU überhaupt.

### Werbung
**JETZT NEU — Der schnellste 386 der Welt!**

★ **AMD Am386™DX-40** ★ — 40 echte Megahertz, volle 32-Bit-Power!

Warum für weniger Takt mehr bezahlen? Unser **40-MHz-Rechenwunder** lässt
Tabellen, Datenbanken und Windows 3.0 nur so fliegen — und schont dabei Ihren
Geldbeutel. Komplettsystem mit 40-MHz-Board, 4 MB RAM und Festplatte schon ab

**4.498,– DM** *(unverb. Richtpreis, zzgl. Monitor)*

Aufrüstbar mit 387-Koprozessor und Cache · 2 Jahre Garantie · Bundesweiter
Vor-Ort-Service. **Fragen Sie Ihren Fachhändler nach AMD!**
