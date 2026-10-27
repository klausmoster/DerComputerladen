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
  es sieht“; „Pflege“ im Einstieg `docs/ki_workflow/README.md`; Verfassung, Grundsatz IV
  (Style-Guide als einzige Quelle).
- Umsetzung: [ki_workflow/ki_pruefung.md](ki_workflow/ki_pruefung.md), in Einführung seit
  2026-10-22, mit Grundsätzen, Anbindung an Spec Kit, Beispielen und den Schritten der Einführung.
  Die beiden Konzepte dazu sind darin aufgegangen und stehen in der Git-Geschichte.
- Entschieden (Klaus, 2026-10-22): Die Prüfer gelten ab dem Pilot im nächsten Feature nach 003,
  auch für Werkzeuge. Den Maßstab für den Sprach-Prüfer gibt der Abschnitt „Sprache“ im Style-Guide.

## 2026-10-26 · Communicator aus dem jeweiligen Jahr

Das Spiel wird über einen Communicator verwaltet, und der sieht immer aus wie ein Gerät, das es im
Spieljahr gab: 1985 vielleicht ein Filofax oder Taschenrechner, später ein Psion Organiser, ab 1996
ein Palm Pilot. Ein lustiges Detail, das die Zeit spürbar macht.

- Bezug: Feature 004, Spielbildschirm (heute nur ein Knopf „Zum Hauptmenü“); 10 Präsentation & UI;
  Idee von Klaus in clarify zu Feature 004.
- Offen: Was verwaltet er (Menü, Termine, Nachrichten, Speichern)? Wechselt das Gerät von selbst
  mit dem Jahr oder kauft der Spieler ein neues? Echte Gerätenamen oder leicht verfremdet?
- Umgesetzt in Teilen: [Feature 005](../specs/005-communicator/spec.md) baut den Communicator als
  Steuerelement und stellt den ganzen Titel darauf um, fest mit dem Organizer von 1991. Welche
  Gehäuse es im Spiel gibt und wie sie wechseln, ist weiter offen.

## 2026-10-26 · Navigation über ein Taschengerät, das mit den Jahren wechselt

Recherche zur Idee „Communicator aus dem jeweiligen Jahr“ darüber, ausführlich in
[recherche/navigation-taschengeraet.md](recherche/navigation-taschengeraet.md). Das Spiel wird über ein Gerät
bedient, das von unten hinter der Bedienleiste herausfährt (Tab oder Klick). Empfohlen sind drei
Gehäuse um einen festen Inhalt: 1985 ein Zeitplaner nach Art des Filofax, ab 1991 ein
Organizer wie der Psion Series 3, ab 1996 ein Communicator wie der Nokia 9000 (2.700 DM). Dazu
kommen Pager (Cityruf 1989, Skyper 1996) als Zusatz. Neue Geräte kauft der Spieler als Ware aus
dem eigenen Laden. Sie bringen Bequemlichkeit, aber nichts, was man zum Spielen braucht. Das
Gerät steuert das Spiel; den Weg zwischen den Orten macht es nicht. Erreichbarkeit (Pager, Handy)
und Organisation (Zeitplaner, Organizer) sind zwei Stränge, die erst der Communicator vereint
(Klaus, 2026-10-26).

- Bezug: Bedienleiste im Style-Guide (ihre sechs Knöpfe würden das Gerät auf der passenden Seite
  öffnen); 10-02 Laden-Bildschirm; feste Ereignisse der Zeitleiste schalten die Geräte frei;
  Feature 004: Speichern und „Zum Hauptmenü“ wandern später auf die Seite Ablage.
- Offen: Gerät neben der Leiste oder an ihrer Stelle? Hält die Uhr an, solange es offen ist?
  LCD-Grün als neue Farbrolle? Echte Namen oder erfundene?

## 2026-10-26 · Erreichbarkeit als Spielelement: Telefon, Anrufbeantworter, Pager

Bis zum Pager klingelt nur das Telefon im Laden. Verpasst du einen Anruf, weißt du nicht, wer es
war, und eine Lieferanfrage ist weg. Der Anrufbeantworter hilft nur im Laden; mit dem Pager lassen
sich Anfragen auch unterwegs und hinterher noch lesen, ab 1992 nimmt das Handy Anrufe überall an.
Erreichbarkeit kostet Gerät und Gebühr und bringt dafür Aufträge (Klaus, 2026-10-26).

- Bezug: [recherche/navigation-taschengeraet.md](recherche/navigation-taschengeraet.md), Nebenidee
  in Abschnitt 3; Seite Nachrichten im Gerät; 03 Wirtschaftsmodell; 04 Informationssystem
  (Wissensvorsprung).
- Offen: Was genau geht verloren, wenn ein Anruf verpasst wird? Ruft jemand wieder an?

## 2026-10-26 · Zeitreise mit dem DeLorean

Irgendwo im Spiel lässt sich ein DeLorean aus „Zurück in die Zukunft“ anklicken, und damit reist
man durch die Zeit (Klaus, 2026-10-26).

- Bezug: Zeitleiste und Spieldatum (Features 002 bis 004); das Gerät, das mit der Zeit wächst
  ([recherche/navigation-taschengeraet.md](recherche/navigation-taschengeraet.md)).
- Offen: Wo kommt er vor, etwa in einer Zeitschrift, im Fernsehen oder als Spielzeug im Laden?
  Ist die Reise ein Gag, eine Abkürzung zu einem anderen Jahr oder ein Werkzeug zum Testen?
