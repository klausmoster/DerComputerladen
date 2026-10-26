---
name: dcl-phasenpruefung
description: Führt die Phasenprüfung für „Der Computerladen“ durch. Stil-Prüfer und Text-Prüfer prüfen eine Phase gegen den Style-Guide, Claude prüft jeden Befund nach, zählt und schreibt den Bericht für die Abnahme. Nutze dies am Ende jeder Phase, die Sichtbares oder Texte ändert, bei der [C]-Aufgabe „Phasenprüfung“, für einen Probelauf an einem fertigen Feature oder wenn Klaus /dcl-phasenpruefung aufruft.
argument-hint: "[Feature und Phase, etwa 004 Phase 4, oder: Probelauf <Bereich>]"
---

# Phasenprüfung

Die Phasenprüfung ist der Schritt zwischen dem Bau einer Phase und Klaus' Abnahme. Warum es sie
gibt und wie sie entstanden ist, steht in `docs/ki_workflow/ki_pruefung.md`; lies dort vorher
„Grundsätze“, „Erfahrungen“ und „Nachmessen“.

Prüfer lesen nur und melden. Repariert wird nur, was Claude bestätigt hat, vom Godot-Agent und in
der freigegebenen Phase. Ein Probelauf an einem fertigen Feature repariert nichts.

## 1. Klären, was geprüft wird

1. Feature und Phase aus dem Aufruf, sonst nachfragen (als Auswahl, Empfehlung zuerst).
2. In `specs/<nummer>-<kurzname>/plan.md` unter „Prüfer je Phase“ nachsehen, welche Prüfer gelten.
   Fehlt der Abschnitt: Stil, wenn die Phase Sichtbares ändert; Text, wenn sie Texte ändert.
3. Den Umfang festhalten: geänderte Dateien (`git diff --stat` gegen den Stand vor der Phase),
   betroffene Szenen, betroffene Texte.

## 2. Vorbereiten

- **Tests und Startprobe** zweimal, wie in `docs/ki_workflow/ki_dev.md`, „Prüfen, bevor Klaus es
  sieht“. Sind sie rot, erst das klären; geprüft wird ein grüner Stand.
- **Maßstab:** die Abschnitte des Style-Guides mit dem Artifact-Tool lesen
  (https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX, Dateien unter `project/`):
  - Stil: `README.md` und die Bausteine der betroffenen Oberfläche unter `components/`, bei
    Werkzeugen `Werkzeuge.md`, dazu `tokens.json`.
  - Text: `Sprache.md`, bei Werkzeugen zusätzlich `Werkzeuge.md`.
  - **Auch, worauf ein Abschnitt verweist**, etwa „Lochränder wie beim Bildrahmen“. Sonst meldet
    der Prüfer Lücken, die keine sind.
  Die Dateien liegen danach im Scratchpad; ihre Pfade gehen in den Auftrag.
- **Bildschirmfotos** für den Stil-Prüfer mit `scripts/fotos.gd` (Raster 640 × 360 und dreifach).
  Für Zustände wie Überfahren, Auswahl oder einen offenen Dialog das Skript in den Scratchpad
  kopieren und in `_zustaende()` ergänzen. Werkzeuge zusätzlich im echten Fenster bei Klaus'
  Fenstergröße (1920 × 925 logisch). Ins Repo kommt kein Foto.
- **Textliste** für den Text-Prüfer mit `scripts/texte_ziehen.py`, je Gruppe die betroffenen
  Ordner unter `src/`. Bei großen Listen ist sie die Arbeitsgrundlage, die Dateien liest der
  Prüfer nur an den Stellen.
- **Was Tests schon messen**, aus `src/test/` heraussuchen. Das lässt der Prüfer aus.

## 3. Prüfer starten

Alle Prüfer der Phase in **einer** Nachricht, damit sie gleichzeitig laufen. Jeder Auftrag nennt:
Repo-Wurzel, Maßstab mit Pfaden, Dateien, Fotos oder Textliste, was Tests schon messen und was
ausdrücklich nicht dazugehört.

- Stehen die Agent-Typen `stil-pruefer` und `text-pruefer` bereit, diese nehmen.
- Sonst, etwa in der Sitzung, in der ein Prüfer neu entstanden ist, einen allgemeinen Agent mit
  diesem Anfang:

  > Du arbeitest als Stil-Prüfer von „Der Computerladen“. Lies zuerst deine Anweisung:
  > `<Repo>/.claude/agents/stil-pruefer.md` und arbeite genau danach. Du darfst nur lesen:
  > Benutze ausschließlich Read, Grep und Glob. Kein Bash, kein Edit, kein Write, keine weiteren
  > Agents, keine Webzugriffe. Du änderst keine Datei.

## 4. Jeden Befund nachprüfen

Kein Befund geht ungeprüft an Klaus. Je Befund die Stelle im Code oder im Bild selbst ansehen und
entscheiden:

- **bestätigt:** Die Regel gilt, und die Stelle verstößt dagegen. Schwere übernehmen oder mit Grund
  ändern.
- **verworfen:** mit Grund, etwa „der Abschnitt Logo verlangt `papier` ausdrücklich“ oder „das
  Beispiel zeigt bewusst die kurze Eingabe“.
- **Widerspruch zum Vertrag:** Steht die Stelle so in Spec, Vertrag oder `research.md`, ist das
  kein Baufehler. Bestätigen und Klaus entscheiden lassen, ob Vertrag oder Style-Guide gilt.
- **Lücke statt Fehler:** Regelt der Style-Guide etwas nicht oder widerspricht er sich, wird es
  eine Lücke.

Auch die Lücken der Prüfer nachprüfen: Fehlte dem Prüfer nur ein Abschnitt, ist es keine Lücke.

## 5. Reparieren lassen

Nur in einer freigegebenen Phase, nicht im Probelauf.
1. Bestätigte Befunde als Auftrag an den Godot-Agent, nach `ki_dev.md`, „Aufträge an den Agent“.
   Widersprüche zum Vertrag und Lücken erst nach Klaus' Entscheidung.
2. Danach dieselben Prüfer noch einmal, nur über das Geänderte.

## 6. Zählen und berichten

1. In `docs/ki_workflow/ki_pruefung.md` unter „Nachmessen“ eine Zeile je Prüfer: Lauf, Befunde,
   bestätigt, verworfen, Lücken, nur er fand. „Nur er fand“ heißt: Claudes eigene Prüfung hatte es
   nicht gefunden.
2. Lücken im Style-Guide und Entscheidungen für Klaus in `docs/offene-punkte.md`, je mit
   Empfehlung.
3. Was sich am Ablauf neu gezeigt hat, als Vorschlag für „Erfahrungen“, mit Anlass. Eingetragen
   wird erst nach Klaus' OK (Pflege, `docs/ki_workflow/README.md`).
4. Den Bericht in die Bitte um Abnahme unter „was geprüft ist“:

```
Phasenprüfung Phase 4, Ladenansicht (T031–T037)
Tests: 512 grün, zweimal gleich; Startprobe still
Stil-Prüfer: 3 Befunde, 2 bestätigt
  hoch       Knopf „Bestellen“ ohne Hover-Zustand (Oberfläche)
  verworfen  Schatten unter dem Tresen: in wenigen Stufen gesetzt, nicht weich
Text-Prüfer: 2 Befunde, 2 bestätigt
  hoch       „Bitte wählen Sie eine Ware“ → „Wähl eine Ware“ (Sprache, Anrede)
Für dich: Der Style-Guide regelt Preisschilder noch nicht. Wie sollen sie aussehen?
```

Fragen an Klaus kommen einzeln, als Auswahl, die Empfehlung zuerst.
