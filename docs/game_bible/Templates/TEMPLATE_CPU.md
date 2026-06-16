---
grunddaten_hersteller: ""
grunddaten_modell: ""
grunddaten_architektur: ""
grunddaten_einführung_de: ""
grunddaten_marktende_de: ""
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
- zeitraum: ""
  marktphase: ""
preise_cpu:
- datum: ""
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
# Titel der Komponente (wird beim Anlegen gesetzt)

<!-- SKILL-ROUTING (vom /dcl-komponente-Skill gelesen; NICHT in die fertige Komponenten-Datei kopieren)
typ: CPU
zielordner: CPUs/<hersteller>
dateiname: <name>
index_seite: CPUs/<hersteller>/<hersteller>.md
hinweis: "<hersteller> = Ordner-Kurzform (z.B. Intel, AMD); <name> = voller Anzeigename, z.B. 'Intel 80486 DX-33, 33MHz'"
-->

<!--
=====================  HINWEISE FÜR MENSCH & KI  =====================
Vollständige Anleitung + KI-Prompt: siehe [[KI-Prompt]] im Vault-Wurzelordner.

KURZFASSUNG:
1. STRUKTURIERTE DATEN gehören NUR ins Frontmatter oben.
   - Skalare Felder als "kategorie_feld" (z.B. technik_socket). Die Kategorie
     ist alles vor dem ersten "_". Neue Kategorie? Einfach neues Präfix nutzen.
   - Preise sind RANGES: pro Datum "von"/"bis" als ZAHL in DM (keine Strings,
     keine "DM"-Endung, kein Tausenderpunkt). Range = typische Marktspanne
     (günstig … teuer); je breiter, desto mehr Spielraum im Spiel.
2. FREITEXT / RECHERCHE-WISSEN gehört NICHT ins Frontmatter, sondern in den
   Body unter eine Überschrift, deren Titel mit "+" beginnt:
       ## + Fakten   bzw.   ## + Game Content
   Solche "+"-Abschnitte (inkl. ihrer "###"-Rubriken) sind geschützt und
   bleiben unverändert erhalten.
   Alle Abschnitte OHNE "+" werden automatisch erzeugt (also dort nichts von
   Hand eintragen – geht verloren).
======================================================================
-->

<!-- Zusatz-Inhalte als geschützte Abschnitte. Struktur: zwei Gruppen als
     "## +"-Überschriften (bleiben geschützt erhalten), die Rubriken darunter
     als "###". Nicht benötigte Rubriken leer lassen/löschen. -->

## + Fakten

### Datenblatt
<!-- Kompaktes Datenblatt im Stil der Zeit – nutzbar als In-Game-Datenblatt. -->

### Beschreibung
<!-- Sachbeschreibung des Produkts. NUR Wahrheit, keine Ausschmückung. Gibt es
     wenig zu sagen, bleibt es kurz; gibt es mehr, höchstens 2 Absätze. -->

### Hintergrund & Quellen
<!-- Allgemeinere Einordnung: Besonderheiten, Marktgeschehen, Konkurrenz – darf
     ruhig ausführlicher/ausschweifender sein. Hier ALLE Quellen-Links hinterlegen. -->

## + Game Content

### Zeitungsartikel
<!-- In-Game-Zeitungsartikel: knapp, im Stil einer 90er-Wirtschaftssimulation
     (z.B. Transport Tycoon), typische 90er-Spiele-Sprache. Direkt im Spiel nutzbar. -->

### Werbung
<!-- In-Game-Werbung im Stil von "Mad TV" – gern leicht verrückt/überdreht,
     reißerisch. Direkt im Spiel nutzbar. -->
