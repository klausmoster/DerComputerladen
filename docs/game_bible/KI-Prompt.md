# KI-Prompt & Workflow

Wie eine neue Komponente entsteht — in zwei Schritten.

## Workflow 1 — Lesbare Tabellen generieren (Skript)

Das Skript liest die **Rohdaten aus dem Frontmatter** (oben in der `.md`) und baut
daraus die **lesbaren `##`-Tabellen** im Body. Es braucht kein Wissen über Felder.

```bash
# eine Datei:
python3 regenerate_tables.py "CPUs/AMD/AMD Am386DX-40, 40MHz.md"
# oder ein ganzer Ordner (alle .md darin):
python3 regenerate_tables.py "CPUs/AMD"
```

Wichtig:
- Abschnitte, deren Überschrift mit `+` beginnt (z.B. `## + Hintergrund & Quellen`),
  bleiben **unangetastet**. Alles andere im Body wird neu erzeugt.
- Dateien, deren Name mit `TEMPLATE` beginnt, werden übersprungen.

## Workflow 2 — Rohdaten von einer KI sammeln lassen

Den Block unten **komplett kopieren**, `<<KOMPONENTE>>` ersetzen (z.B.
*Intel 80486 DX-33*) und einer KI mit Web-Recherche übergeben. Die Antwort
(Frontmatter + `## +`-Abschnitte) in eine neue `.md` unter den passenden Ordner
speichern, dann **Workflow 1** laufen lassen.

---

````text
Du bist Hardware-Historiker und recherchierst Daten für ein Wirtschafts-
Simulationsspiel, das in den 1990ern in Deutschland spielt. Sammle für die
Komponente **<<KOMPONENTE>>** belastbare Daten aus dem Netz.

GRUNDREGELN
- Genauigkeit vor Vollständigkeit: Nenne nur Werte, für die es Belege gibt.
  Bist du unsicher, schätze plausibel und markiere es im Freitext als "geschätzt".
- Bezugsraum: deutscher Markt, Preise in **D-Mark (DM)**, Zeitachse als Monat
  (Format JJJJ-MM).
- Quellen sammelst du als Links und nennst sie unten im Abschnitt "## + Quellen".

AUSGABEFORMAT
Gib GENAU eine Markdown-Datei aus: zuerst YAML-Frontmatter, dann die
"## +"-Abschnitte. KEINE sonstigen Tabellen oder Überschriften erzeugen — die
baut ein Skript später selbst aus dem Frontmatter.

ZUSATZ-INHALTE (Freitext, je als eigener "## +"-Abschnitt, an den Daten verankert):
- ## + Datenblatt        kompaktes Datenblatt im Stil der Zeit (In-Game-Datenblatt)
- ## + Beschreibung      neutrale Sachbeschreibung
- ## + Zeitungsartikel   kurzer Artikel im Ton eines 90er-Computermagazins
- ## + Werbung           Werbetext/Anzeige im Stil der Zeit
- ## + Hintergrund & Quellen   Einordnung + Quellen-Links

FRONTMATTER-REGELN
- Skalare Felder heißen "kategorie_feld" (Kategorie = alles vor dem ersten "_").
  Beibehalten: grunddaten_*, technik_*. Neue sinnvolle Kategorie/Felder sind
  erlaubt (z.B. kuehlung_*), solange dem Präfix-Schema gefolgt wird.
- Preise sind RANGES: je Eintrag "von" und "bis" als reine ZAHL in DM
  (kein "DM", kein Tausenderpunkt, kein Text). Die Range ist die typische
  Marktspanne von günstig bis teuer zu diesem Zeitpunkt.
- Listen-Blöcke (markt, preise_cpu, handel, lager, kompatibilität, wettbewerb)
  als YAML-Listen wie in der Vorlage.

VORLAGE (Werte ersetzen, Struktur behalten):
---
grunddaten_hersteller: ""
grunddaten_modell: ""
grunddaten_architektur: ""
grunddaten_einführung_de: ""      # JJJJ-MM
grunddaten_marktende_de: ""       # JJJJ-MM
grunddaten_verkaufsform: ""
technik_takt: ""
technik_takt_mhz: 0
technik_außentakt: ""
technik_vcore: ""
technik_cache_l1: ""
technik_cache_l2: ""
technik_adressbus: ""
technik_databus: ""
technik_fpu: ""
technik_transistoren: ""
technik_prozess: ""
technik_gehäuse: ""
technik_tdp: ""
technik_socket: ""
markt:
- zeitraum: ""                    # JJJJ-MM
  marktphase: ""                  # z.B. Neu-Einführung / Massenmarkt / Auslauf
preise_cpu:
- datum: ""                       # JJJJ-MM
  von: 0
  bis: 0
handel:
- datum: ""
  einkauf_von: 0
  einkauf_bis: 0
  verkauf_von: 0
  verkauf_bis: 0
  marge_von: 0
  marge_bis: 0
lager:
- zeit: "0-3 Monate"
  wertverlust: "0 %"
- zeit: "3-6 Monate"
  wertverlust: "0 %"
- zeit: "6-12 Monate"
  wertverlust: "5 %"
- zeit: "12-18 Monate"
  wertverlust: "15 %"
- zeit: "18-24 Monate"
  wertverlust: "35 %"
- zeit: ">24 Monate"
  wertverlust: "60 %"
kompatibilität:
- komponente: ""
  anforderung: ""
wettbewerb:
- produkt: ""
  position: ""
tags:
- cpu
---

## + Datenblatt
<Kernspecs als kompaktes Datenblatt im Stil der Zeit.>

## + Beschreibung
<Neutrale Sachbeschreibung der Komponente.>

## + Zeitungsartikel
<Kurzer Artikel im Ton eines deutschen Computermagazins der 1990er.>

## + Werbung
<Werbetext/Anzeige im Stil der Zeit.>

## + Hintergrund & Quellen
<Einordnung, Besonderheiten, Konkurrenz, was die Komponente teuer/günstig
machte. Unsicheres als "geschätzt" kennzeichnen. Quellen als Liste.>
````

---

> Hinweis: Der Prompt ist auf CPUs ausgelegt. Für andere Komponenten (Mäuse,
> Mainboards …) die `technik_*`-Felder und Listen-Blöcke sinngemäß anpassen —
> das Präfix-Schema und die `von`/`bis`-Regel bleiben gleich.
