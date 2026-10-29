---
grunddaten_titel: ""
grunddaten_reihenfolge: 0
grunddaten_anschrift: ""
grunddaten_viertel: ""
flaeche_qm: 0
lage_laufkundschaft: ""
lage_sichtbarkeit: ""
lage_parkplaetze: ""
preise_miete:
- datum: "1985-01"
  von: 0
  bis: 0
text_beschreibung: ""
text_kleingedrucktes: ""
quelle_miete: ""
tags:
- laden
---
# Titel des Ladens (wird beim Anlegen gesetzt)

<!-- SKILL-ROUTING (NICHT in die fertige Datei kopieren)
typ: Laden
zielordner: Läden
dateiname: <Lage>, etwa „Fußgängerzone“; aus dem Dateinamen entsteht die ID im Spiel
index_seite: Läden.md
-->

<!--
=====================  HINWEISE FÜR MENSCH & KI  =====================
Ein Laden, den der Makler in Feature 010 anbietet. Der Importer
tools/bible/importiere.py bringt das Frontmatter ins Spiel
(specs/010-ladeneroeffnung/contracts/game_bible.md).

- grunddaten_viertel: innenstadt | wohngebiet | gewerbegebiet
- lage_*: niedrig | mittel | hoch
- preise_miete: Monatsmiete in DM als Range wie überall in der game_bible.
  Für das Spiel zählt der Eintrag mit datum "1985-01"; dort ist von = bis,
  denn ein Laden hat eine Miete, keine Spanne. Spätere Einträge dürfen eine
  Spanne haben und zeigen, wie die Miete der Lage sich über die Jahre bewegt.
- text_beschreibung: zwei, drei Sätze des Maklers im Exposé, siezt.
- text_kleingedrucktes: fester Text mit Vor- und Nachteilen des Standorts,
  ohne Ereignisse der Zeitleiste (Ortsbezug kommt mit 05-03).
- quelle_miete: woher die Miete kommt, etwa die Recherche des Features.
Freitext nur unter "## +"-Überschriften; sie bleiben beim Regenerieren erhalten.
======================================================================
-->

## + Hintergrund
<!-- Wie der Laden aussieht, wer früher drin war, was die Nachbarn verkaufen. -->

## + Notizen
