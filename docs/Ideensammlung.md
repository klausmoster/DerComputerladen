# Ideensammlung

Lose Ideen, so wie sie kommen: unsortiert, unverbindlich, ohne ID. Neue Ideen kommen unten dazu,
je Idee das Datum, der Kern in ein, zwei Sätzen und bei Bedarf Bezug und offene Fragen.

Wird eine Idee konkret, wird sie zu einem Eintrag in [Feature_Ideas](features/Feature_Ideas.md)
mit reservierter ID oder zu einem Abschnitt im [Game Design Document](game_design.md). Hier steht
dann ein Verweis darauf.

## 2026-10-19 · Zeitgeschehen in der Zeitung

Neben den Meldungen zum Computermarkt zeigt die Zeitung auch echte Ereignisse der Zeit, etwa
„Neuer Ford Mondeo“ (1993). Das gibt Atmosphäre und verortet den Spielmonat auf einen Blick.

- Bezug: 10-04 Ereignis-Anzeige als Zeitungsmeldung, 01-02 Ereignis-Engine; die Meldungen selbst
  wären Spielinhalt für die game_bible
- Offen: nur Atmosphäre oder auch mit Wirkung aufs Geschäft (WM-Abend, der Laden bleibt leer)?
  Echte Namen oder leicht verfremdet?

## 2026-10-20 · Zeitstrahl unten über die ganze Breite, Durchläufe darauf zeigen

Der Zeitstrahl der Werkstatt liegt am unteren Rand über die ganze Breite, zeigt alle Jahre 1985
bis 1999 und lässt sich durchscrollen. Er zeigt nicht nur den Katalog, sondern auf Wunsch auch
einen Beispiel-Durchlauf nach Spiellogik: die Termine eines Seeds, so wie ein Spiel sie erlebt.

- Bezug: Feature 002, Phase 6 (Zeitstrahl, FR-037 bis FR-039) und Phase 7 (Simulator, FR-040 bis
  FR-043). Geplant ist der Zeitstrahl bisher in der Mitte über den Reitern, der Durchlauf nur als
  Liste im Reiter „Simulator“.
- Offen: zwischen Katalog und Durchlauf umschalten oder beides übereinander? Vor Phase 6 in Spec
  und Vertrag übernehmen?

## 2026-10-21 · Produkte und Grafiken in der Werkstatt

Die Werkstatt zeigt neben den Ereignissen auch die Produkte der game_bible und ihre Grafiken, damit
Ereignisse, Produkte und Bilder an einer Stelle zusammenkommen.

- Bezug: 02-01 game_bible-Importer, 02-02 Warengruppen (Ziele der Ereignisse wie `cpu_486` auf
  echte Produkte abbilden), 10-03 Pixel-Art-Pipeline; Verfassung, Grundsatz V (Spielinhalt in der
  game_bible).
- Offen: in der Werkstatt nur lesen und verknüpfen, oder dort auch bearbeiten? Was bleibt dann die
  Quelle für Produkte?

## 2026-10-21 · Start-Szenarien und Verläufe für Tests

Aus der Werkstatt mehrere Spielstarts und Verläufe erzeugen und als Testszenarien nutzen, auch für
automatisierte Tests.

- Bezug: Proben aus Feature 002, Phase 8 (Seed und Eingriffe als Datei); 01-05 Spielstart zu einem
  späteren Datum.
- Offen: gespeicherte Verläufe als feste Erwartung in Tests („Golden Files“)? Spielstarts mit
  Startkapital und Ort erst mit Wirtschaft (03) und Standort (05)?

## 2026-10-21 · Schwierigkeitsgrade in der Werkstatt einstellen

Leicht, Mittel und Schwer werden in der Werkstatt eingestellt und dort ausprobiert.

- Bezug: 11-05 Spielziel und Schwierigkeitsgrade, offene Frage im GDD. Für die Zeitleiste ließe sich
  je Grad ein Satz Modifikatoren aus Phase 8 nutzen, die Statistik aus Phase 9 zeigt die Folgen.
- Offen: Was ändert ein Grad außer Chancen, etwa Preise, Startkapital, Kundenstrom?

## 2026-10-22 · Spezialisierte Prüf-Agents fürs eigentliche Spiel

Neben dem Godot-Agent eigene Prüfer, die am Ende einer Phase unabhängig und nur lesend prüfen: Stil
gegen den Style-Guide, Sprache (du, Ton, Wortschatz 1985–1999) und später Fakten wie Daten und
Preise gegen die game_bible. Was sich messen lässt, prüfen Tests.

- Bezug: `.claude/agents/godot-entwickler.md`; `docs/ki_workflow/ki_dev.md`, „Prüfen, bevor Klaus
  es sieht“ und „Pflege“; Verfassung, Grundsatz IV (Style-Guide als einzige Quelle).
- Konzept: [konzept-pruef-agents.md](konzept-pruef-agents.md) mit Grundsätzen, Anbindung an
  Spec Kit, Beispielen und Stufen zur Einführung (2026-10-22).
- Offen: Für den Sprach-Prüfer fehlt ein Text-Leitfaden als Maßstab. Ab wann, etwa mit dem ersten
  echten Spielbildschirm?
