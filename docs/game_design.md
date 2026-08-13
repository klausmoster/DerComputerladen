# Der Computerladen — Game Design Document

## Überblick

**Genre:** Point-and-Click Adventure / Wirtschaftssimulation
**Zeitraum:** 1985–1999
**Engine:** Godot (GDScript)
**Grafikstil:** Pixel-Art, 90er-Jahre PC-Ästhetik (320×200 oder 640×480)

Der Spieler eröffnet und betreibt einen Computerladen in Deutschland. Das Spiel verbindet klassische Adventure-Elemente (Dialoge, Orte erkunden, Entscheidungen treffen) mit einer Wirtschaftssimulation (Einkauf, Verkauf, Marktentwicklung, Kundenmanagement).

---

## Kernsysteme

### 1. Zeitleiste (Timeline-Engine)

Die Zeitleiste ist das Herzstück der Simulation. Beim Spielstart wird eine Zeitachse von 1985–1999 angelegt und mit Ereignissen befüllt.

**Fixe Ereignisse** (immer gleich):
- Hardware-Releases (z.B. Intel 386, 486, Pentium, Pentium II)
- Software-Releases (z.B. Windows 3.1, Windows 95, MS-DOS 6)
- Technologie-Meilensteine (z.B. Internet für Privatkunden, CD-ROM-Laufwerke, USB)
- Wirtschaftliche Rahmenbedingungen (z.B. Wiedervereinigung, Rezession)

**Variable Ereignisse** (abhängig von Zufall und Spieleraktionen):
- Neubaugebiet entsteht in der Nähe → mehr Laufkundschaft
- Konkurrent eröffnet/schließt
- Großkunde meldet sich (z.B. Schule, Büro)
- Reklamationswellen bei schlechter Ware
- Lieferengpässe

**Kettenreaktionen:**
Jedes Ereignis hat gewichtete Auswirkungen auf andere Systeme. Beispiele:
- Pentium erscheint → 486-Preise fallen 30%, RAM-Nachfrage steigt, Fachzeitschriften berichten
- Windows 95 erscheint → Nachfrage nach Mäusen steigt, CD-ROM wird Pflicht, mehr RAM nötig
- Internet wird verfügbar → Modems werden nachgefragt, neue Kundenschicht (Technik-Enthusiasten)

### 2. Produktdatenbank

Basiert auf echten Daten aus historischen Prospekten.

**Kategorien:**
- Komplett-PCs
- Prozessoren (CPUs)
- Arbeitsspeicher (RAM)
- Grafikkarten
- Festplatten
- CD-ROM-Laufwerke
- Monitore
- Tastaturen
- Mäuse
- Modems
- Drucker
- Software
- Zubehör/Kabel

**Felder pro Produkt:**
- Name/Bezeichnung
- Kategorie
- Erscheinungsjahr / Erscheinungsmonat
- End-of-Life (wann nicht mehr verfügbar)
- UVP (Unverbindliche Preisempfehlung)
- EK-Preis (Einkauf beim Großhändler)
- Technische Specs (kategorie-abhängig)
- Qualitätsfaktor (0.0–1.0, beeinflusst Ausfallrate)
- Kompatibilitäts-Tags (welche Komponenten zusammenpassen)
- Abhängigkeiten (z.B. "benötigt ISA-Slot" oder "nur mit Pentium-Board")

**Preismodell:**
- Produkte starten beim UVP
- Preis fällt über Zeit (Preiskurve pro Produkt)
- Nachfolgeprodukte beschleunigen den Preisverfall
- Restposten sind billig aber evtl. schwer verkäuflich

### 3. Wirtschaftsmodell

**Faktoren die Kaufkraft beeinflussen:**
- Standort des Ladens
- Jahreszeit (Weihnachtsgeschäft!)
- Lokale Ereignisse (Neubaugebiet, Firmenschließung)
- Allgemeine Wirtschaftslage
- Reputation des Ladens

**Nachfrage-Simulation:**
- Verschiedene Kundentypen mit unterschiedlichen Bedürfnissen
  - Privatkundschaft (Familie will Heim-PC)
  - Gamer (wollen das Neueste)
  - Geschäftskunden (brauchen zuverlässig und günstig)
  - Bastler (kaufen Einzelteile)
- Nachfrage hängt ab von: Trends, Werbung, Reputation, Preis, Verfügbarkeit

### 4. Informationssystem

**Zeitschriften/Magazine:**
Der Spieler muss aktiv Informationsquellen abonnieren um über den Markt informiert zu sein.
- Hardware-Magazin (neue Produkte, Tests, Benchmarks)
- Software-Magazin (neue Programme, Spiele)
- Branchen-Magazin (Geschäftstipps, Markttrends)
- Ohne Abo verpasst man Trends und reagiert zu spät

**Wissensvorsprung:**
- Wer früh von einem Trend erfährt, kann sich rechtzeitig eindecken
- Wer spät dran ist, zahlt höhere EK-Preise oder bekommt keine Ware

### 5. Standortsystem

**Ladenwahl zu Spielbeginn:**
- Verschiedene Standorte zur Auswahl
- Faktoren: Miete, Fläche, Laufkundschaft, Parkplätze, Sichtbarkeit
- Innenstadtlage: teuer, viel Laufkundschaft
- Gewerbegebiet: günstig, braucht mehr Werbung
- Wohngebiet: mittel, Stammkunden-Potenzial

**Ladenausbau:**
- Größere Fläche anmieten
- Werkstatt einrichten (Reparaturen, Aufrüstung)
- Schaufenster gestalten
- Lager erweitern

### 6. Marketingsystem

**Werbekanäle:**
- Zeitungsanzeigen (regional, verschiedene Zeitungen)
- Flyer / Handzettel
- Schaufensterwerbung
- Mundpropaganda (ergibt sich aus Reputation)
- Später: eigene Webseite (ab ca. 1995–1997)

**Wirkung:**
- Verschiedene Kanäle erreichen verschiedene Kundengruppen
- Kosten-Nutzen-Verhältnis variiert
- Werbung braucht Zeit um zu wirken

### 7. Handelsnetzwerk / Bezugsquellen

**Seriöser Großhändler:**
- Stabile Preise
- Zuverlässige Qualität
- Garantie und Rücknahme
- Mindestbestellmengen

**Computermarkt / Messe:**
- Günstigere Preise
- Höheres Risiko (Fake-RAM, defekte Ware)
- Schnäppchen möglich
- Keine Garantie

**Restposten-Händler:**
- Alte Ware sehr günstig
- Begrenzte Stückzahlen
- Kann Nische bedienen (günstige Einsteiger-PCs)

**Windiger Händler:**
- Sehr günstig
- Hohe Ausfallrate
- Gefälschte Markenware möglich
- Risiko: Kunde reklamiert, Ruf leidet

### 8. Qualitäts- und Risikosystem

**Ausfallraten:**
- Jedes Produkt hat einen Qualitätsfaktor
- Billige Quellen = niedrigerer Qualitätsfaktor
- Bei Verkauf wird gewürfelt ob Produkt ausfällt (innerhalb Gewährleistung)

**Konsequenzen bei Ausfall:**
- Kunde kommt mit Reklamation
- Kosten für Ersatz/Reparatur
- Reputation sinkt
- Bei Häufung: negativer Zeitungsartikel möglich

**Gegenmaßnahmen:**
- Qualitätsprüfung vor Verkauf (kostet Zeit, findet aber defekte Ware)
- Versicherung gegen Ausfälle abschließen
- Nur bei seriösen Händlern kaufen (teurer aber sicherer)
- Garantieverlängerung anbieten (zusätzliche Einnahme, aber auch Risiko)

---

## Spielorte

- **Der eigene Laden** — Hauptschauplatz, hier passiert der Verkauf
- **Großhändler** — Ware bestellen, Katalog durchblättern
- **Computermarkt/Messe** — Schnäppchen jagen, aber Vorsicht
- **Bank** — Kredit aufnehmen, Kontostand prüfen
- **Zeitschriftenladen/Kiosk** — Magazine kaufen für Informationsvorsprung
- **Konkurrenz** — Preise vergleichen, Ideen klauen
- **Post/Telefon** — Bestellungen aufgeben, Kundenkontakt

---

## Offene Fragen / Noch zu klären

- [ ] Genaue Zeitperiode festlegen (Start- und Endjahr)
- [ ] Detaillierte Produktliste aus Prospekten erstellen
- [ ] Preiskurven-Modell definieren (wie schnell fallen Preise?)
- [ ] Kundentypen und ihr Verhalten ausarbeiten
- [ ] Dialogsystem-Design (wie berät man Kunden?)
- [ ] Gewinn/Verlust-Bedingungen (wann hat man gewonnen/verloren?)
- [ ] Schwierigkeitsgrade?
- [ ] Tutorial / Einstieg ins Spiel
- [ ] Sound und Musik (MIDI-Stil? AdLib/SoundBlaster?)
- [ ] Speichersystem

---

## Technische Architektur

```
┌─────────────────────────────────────────────┐
│              Präsentation                   │
│   (Pixel-Art Szenen, UI, Dialoge, Sound)    │
├─────────────────────────────────────────────┤
│              Spiellogik                      │
│   (Adventure: Orte, Dialoge, Interaktion)   │
│   (Simulation: Kauf, Verkauf, Management)   │
├─────────────────────────────────────────────┤
│           Simulations-Engine                 │
│   (Zeitleiste, Ereignisse, Wirkungsnetz)    │
│   (Wirtschaftsmodell, Preise, Nachfrage)    │
├─────────────────────────────────────────────┤
│              Daten                           │
│   (Produktdatenbank, Ereignis-Definitionen) │
│   (Spielstände, Konfiguration)              │
└─────────────────────────────────────────────┘
```

## Referenzen / Inspirationen

- **Das Amt** — Dialogstil, Humor, Pixel-Art-Ästhetik
- **Monkey Island** — Point-and-Click-Mechanik, Puzzle-Design
- **Theme Park** — Wechselwirkungen zwischen Faktoren (Salz → Durst → Getränkeverkauf)
- **Der Patrizier** — Handelssimulation, Wirtschaftsmodell
- **Pizza Connection** — Geschäftssimulation mit Humor
