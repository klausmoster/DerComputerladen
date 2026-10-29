---
name: dcl-phasenpruefung
description: Führt die Phasenprüfung für „Der Computerladen“ durch. Stil- und Text-Prüfer prüfen eine Phase gegen den Style-Guide, der Architektur-Prüfer gegen den Architektur-Leitfaden; Claude prüft jeden Befund nach, zählt und schreibt den Bericht für die Abnahme. Nutze dies am Ende jeder Phase, die Sichtbares, Texte oder Code ändert, bei der [C]-Aufgabe „Phasenprüfung“, für einen Probelauf an einem fertigen Feature oder wenn Klaus /dcl-phasenpruefung aufruft.
argument-hint: "[Feature und Phase, etwa 004 Phase 4, oder: Probelauf <Bereich>]"
---

# Phasenprüfung

Die Phasenprüfung ist der Schritt zwischen dem Bau einer Phase und Klaus' Abnahme. Warum es sie
gibt und wie sie allgemein abläuft, steht in `docs/ki_workflow/blaupause.md`, Abschnitt 6; wie sie
hier entstanden ist, in `docs/ki_workflow/ki_pruefung.md`. Lies vorher Abschnitt 6 der Blaupause
und in `ki_pruefung.md` „Die Prüfer“, „Erfahrungen“ und „Nachmessen“.

Prüfer lesen nur und melden. Repariert wird nur, was Claude bestätigt hat, vom Godot-Agent und in
der freigegebenen Phase. Ein Probelauf an einem fertigen Feature repariert nichts.

## Vorab: Prüfung des Vertrags bei der Checkliste

Bei `/speckit-checklist` laufen Text- und Stil-Prüfer einmal über die Wortlaute und Zustände, die
Spec und Vertrag festlegen, noch bevor gebaut wird (Klaus, 2026-10-27). Plant das Feature Code, liest
der Architektur-Prüfer im Auftrag „Plan“ `plan.md`, `research.md`, `data-model.md` und `contracts/`
gegen den Leitfaden: wer wen kennt, Signale, Autoloads, wo Logik und Daten liegen (Klaus,
2026-10-28). Vorgehen wie unten in den Schritten 2 bis 4, nur mit Spec und `contracts/` statt Code
und Fotos. Bestätigte Befunde ändern
den Vertrag, mit Klaus' OK. Gezählt wird unter „Nachmessen“ als eigener Lauf.

## 1. Klären, was geprüft wird

1. Feature und Phase aus dem Aufruf, sonst nachfragen (als Auswahl, Empfehlung zuerst).
2. In `specs/<nummer>-<kurzname>/plan.md` unter „Prüfer je Phase“ nachsehen, welche Prüfer gelten.
   Fehlt der Abschnitt: Stil, wenn die Phase Sichtbares ändert; Text, wenn sie Texte ändert;
   Architektur, wenn sie Skripte, Szenen oder Resources unter `src/` ändert. Tests und `src/addons/`
   allein lösen den Architektur-Prüfer nicht aus.
3. Den Umfang festhalten: geänderte Dateien (`git diff --stat` gegen den Stand vor der Phase),
   betroffene Szenen, betroffene Texte.

## 2. Vorbereiten

- **Tests und Startprobe** zweimal, wie in `docs/ki_workflow/ki_dev.md`, „Prüfen, bevor Klaus es
  sieht“. Sind sie rot, erst das klären; geprüft wird ein grüner Stand.
- **Maßstab:** die Abschnitte des Style-Guides unter `docs/style-guide/` auswählen:
  - Stil: `README.md` und die Bausteine der betroffenen Oberfläche unter `bausteine/`, bei
    Werkzeugen `werkzeuge.md`, dazu `tokens.md`.
  - Text: `sprache.md`, bei Werkzeugen zusätzlich `werkzeuge.md`.
  - **Auch, worauf ein Abschnitt verweist**, etwa „Lochränder wie beim Bildrahmen“. Sonst meldet
    der Prüfer Lücken, die keine sind.
  Ihre Pfade gehen in den Auftrag; der Prüfer liest sie selbst.
- **Bildschirmfotos** für den Stil-Prüfer mit `scripts/fotos.gd` (Raster 640 × 360 und dreifach).
  Für Zustände wie Überfahren, Auswahl oder einen offenen Dialog das Skript in den Scratchpad
  kopieren und in `_zustaende()` ergänzen. Werkzeuge zusätzlich im echten Fenster bei Klaus'
  Fenstergröße (1920 × 925 logisch). Ins Repo kommt kein Foto.
- **Textliste** für den Text-Prüfer mit `scripts/texte_ziehen.py`, je Gruppe die betroffenen
  Ordner unter `src/`. Bei großen Listen ist sie die Arbeitsgrundlage, die Dateien liest der
  Prüfer nur an den Stellen.
- **Für den Architektur-Prüfer** die Liste der geänderten `.gd`, `.tscn` und `.tres` aus dem Diff,
  ohne `src/test/` und `src/addons/`, dazu `contracts/` des Features. Den Leitfaden
  (`docs/architektur-leitfaden.md`) liest er selbst. Hat eine Schicht wie Wirtschaft oder Adventure
  begonnen, steht das im Auftrag.
- **Was Tests schon messen**, aus `src/test/` heraussuchen, beim Architektur-Prüfer aus
  `test_architektur.gd`. Das lässt der Prüfer aus.

## 3. Prüfer starten

Alle Prüfer der Phase in **einer** Nachricht, damit sie gleichzeitig laufen. Jeder Auftrag nennt:
Repo-Wurzel, Maßstab mit Pfaden, Dateien, Fotos oder Textliste, was Tests schon messen und was
ausdrücklich nicht dazugehört.

- Stehen die Agent-Typen `stil-pruefer`, `text-pruefer` und `architektur-pruefer` bereit, diese
  nehmen.
- Sonst, etwa in der Sitzung, in der ein Prüfer neu entstanden ist, einen allgemeinen Agent mit
  diesem Anfang:

  > Du arbeitest als Stil-Prüfer von „Der Computerladen“. Lies zuerst deine Anweisung:
  > `<Repo>/.claude/agents/stil-pruefer.md` und arbeite genau danach. Du darfst nur lesen:
  > Benutze ausschließlich Read, Grep und Glob. Kein Bash, kein Edit, kein Write, keine weiteren
  > Agents, keine Webzugriffe. Du änderst keine Datei.

  Für den Architektur-Prüfer ebenso, mit `architektur-pruefer.md` und „Architektur-Prüfer“. Sein
  Auftrag nennt die Art: Phase, Plan oder Bestand.

## 4. Jeden Befund nachprüfen

Kein Befund geht ungeprüft an Klaus. Je Befund die Stelle im Code oder im Bild selbst ansehen und
entscheiden:

- **bestätigt:** Die Regel gilt, und die Stelle verstößt dagegen. Schwere übernehmen oder mit Grund
  ändern.
- **verworfen:** mit Grund, etwa „der Abschnitt Logo verlangt `papier` ausdrücklich“ oder „das
  Beispiel zeigt bewusst die kurze Eingabe“.
- **Widerspruch zum Vertrag:** Steht die Stelle so in Spec, Vertrag oder `research.md`, ist das
  kein Baufehler. Bestätigen und Klaus entscheiden lassen, ob Vertrag oder Style-Guide gilt.
- **Lücke statt Fehler:** Regelt der Style-Guide oder der Leitfaden etwas nicht oder widerspricht
  er sich, wird es eine Lücke.
- **Begründete Ausnahme:** Meldet der Architektur-Prüfer eine Stelle als Ausnahme, prüfen, ob
  Kommentar und Zeile in der Tabelle „Ausnahmen“ des Leitfadens da sind.

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
2. Lücken im Style-Guide oder im Leitfaden und Entscheidungen für Klaus in `docs/offene-punkte.md`,
   je mit Empfehlung.
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
Architektur-Prüfer: 1 Befund, 1 bestätigt
  hoch       Regal ruft get_parent().kasse_aktualisieren() (AR-02)
  Ausnahmen  keine neuen; werkstatt.gd, _set_up_window() (AR-02): Kommentar und Zeile in der Tabelle da
Für dich: Der Style-Guide regelt Preisschilder noch nicht. Wie sollen sie aussehen?
```

Fragen an Klaus kommen einzeln, als Auswahl, die Empfehlung zuerst.
