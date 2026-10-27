# Anforderungs-Review Checklist: Easter Egg 01: Space Invaders

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: Knöpfe am Gehäuse, Folge, Spiel, Ende und Rückweg, Ton,
Style-Guide, Abnahmekriterien.
**Created**: 2026-10-27
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

Jeder Punkt hat einen Vorschlag von Claude („→ Vorschlag“). Was er an Spec oder Plan ändern würde,
steht dabei. Eingearbeitet wird erst nach Klaus' Freigabe; sie kam am 2026-10-27 für alle Punkte. Die Punkte ab „Aus der Prüfung des
Vertrags“ stammen von Stil- und Text-Prüfer, von Claude nachgeprüft (Verfassung, Grundsatz VI).

## Widersprüche zum Style-Guide

- [x] CHK001 Ist der Widerspruch zum Baustein Communicator benannt? Dort steht heute „Das Gehäuse
  ist reine Grafik: Ein Klick darauf tut nichts“. R12 nennt nur den Zeiger als Ausnahme. [Conflict,
  Spec §FR-001; Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-27): R12 Punkt 1 sagt ausdrücklich, dass der Satz im Baustein Communicator geändert wird:
  „Das Gehäuse ist Grafik bis auf seine Gehäusetasten; beim Organizer die drei grauen Tasten.“
- [x] CHK002 Deckt die Ausnahme alle Regeln für anklickbare Stellen ab? Der Abschnitt Oberfläche
  verlangt beim Überfahren Zeigerwechsel, `signalgelb` und einen Tooltip; die Spec regelt nur den
  Zeiger. [Conflict, Spec §FR-001b, §FR-005]
  → Vorschlag, freigegeben von Klaus (2026-10-27): FR-001b und R12: Über den Gehäusetasten gibt es keinen Zeigerwechsel, kein
  `signalgelb`, keinen Tooltip und keinen Hinweis; die einzige Rückmeldung ist Eindrücken und Klick.
  Grund: versteckt (FR-005).
- [x] CHK003 Ist das Eindrücken mit dem Relief der Oberfläche abgestimmt? Bedienbares hat
  `relief-gedrueckt`; die Tasten sind Bild und werden verschoben (R3). [Consistency, Plan R3]
  → Vorschlag, freigegeben von Klaus (2026-10-27): R12 hält fest, dass Gehäusetasten Teil des Bildes sind und deshalb kein
  `relief-gedrueckt` bekommen, sondern den eigenen Ausschnitt eine Zeile tiefer.
- [x] CHK004 Ist das Ende des Spiels vom Baustein Meldung abgegrenzt? Die Spec nennt es „Meldung“,
  der Baustein Meldung ist aber ein Fehlerhinweis in `papier` mit roter Kontur, ohne Ton, neben dem
  Gehäuse; das Ende des Spiels steht auf der Anzeige und spielt ein Motiv. [Terminology, Spec §FR-020, Story 3; Plan R10]
  → Vorschlag, freigegeben von Klaus (2026-10-27): In Spec, Plan, Datenmodell und Verträgen heißt es „Ergebnisanzeige“, nicht Meldung.
  Der Baustein Meldung bleibt für Fehler.
- [x] CHK005 Welche Schrift hat die Kopfzeile im Spiel? Der Style-Guide setzt Kopfzeilen auf der
  Anzeige in `drucker` (Doto), der Vertrag nennt die Schrift von `LcdRow` (Ark Pixel 12).
  [Conflict, Vertrag invaders.md „Malen“]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Kopfzeile `PUNKTE 0380` in `drucker` (Doto 10) wie die Kopfzeilen der Seiten;
  Ergebnisanzeige in `menue` (Ark Pixel 12) wie Einträge. Ins Kapitel „Spiel auf der Anzeige“.
- [x] CHK006 Wirken Vollbild und Fenster-Schließen im Spiel wie immer? R9 verbraucht jede Taste mit
  `accept_event()`; der Baustein Communicator sagt „Fenster schließen und Vollbild wirken wie immer“.
  [Conflict, Plan R9; Vertrag invaders.md „Eingabe“]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Die Seite verbraucht Pfeile, Leertaste, Esc und in der Ergebnisanzeige die Taste zum
  Weiter; Tasten mit Cmd, Strg oder Alt und `toggle_fullscreen` lässt sie durch. Ergänzen in R9,
  FR-012 und im Vertrag.

## Vollständigkeit

- [x] CHK007 Ist festgelegt, was ein Druck auf die Gehäusetasten während des Spiels tut? Steht nur in
  R5, nicht in der Spec. [Gap, Spec Randfälle]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Randfall in der Spec: Während das Spiel läuft, drücken sich die Knöpfe ein und
  klicken, starten aber nichts und stören das Spiel nicht.
- [x] CHK008 Ist festgelegt, wie der Hinweis zurückkommt, wenn beim Start der Folge eine Meldung
  (Baustein Meldung) stand, etwa „Löschen ging nicht“? Steht nur im Vertrag. [Gap, Spec §FR-022]
  → Vorschlag, freigegeben von Klaus (2026-10-27): FR-022 ergänzen: Zurück steht der Hinweis der gewählten Zeile; eine Meldung von
  vorher kommt nicht zurück, denn seitdem hat der Spieler etwas ausgelöst (Baustein Meldung).
- [x] CHK009 Was zählt als „Taste“ zum Weiter in der Ergebnisanzeige? Shift allein, ein Rechtsklick,
  das Mausrad? [Clarity, Spec §FR-020]
  → Vorschlag, freigegeben von Klaus (2026-10-27): jede Taste außer Shift, Strg, Alt, Cmd allein; von der Maus nur der Linksklick auf
  die Anzeige.
- [x] CHK010 Ist festgelegt, wann die Außerirdischen „gelandet“ sind? „Die Höhe der Kanone“ ist
  ungenau. [Clarity, Spec §FR-015]
  → Vorschlag, freigegeben von Klaus (2026-10-27): gelandet, sobald die Unterkante eines lebenden Außerirdischen die Oberkante der
  Kanone erreicht. In FR-015 und R7.
- [x] CHK011 Ist festgelegt, ob Schuss und Bombe sich gegenseitig treffen? Im Original löschen sie
  sich aus. [Gap, Spec §FR-012, §FR-013]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Nein, sie fliegen aneinander vorbei; das hält das Level einfach. Satz in FR-013.
- [x] CHK012 Sind Explosionen festgelegt: Muster, Dauer, ob sie Treffer blockieren? Das Datenmodell
  nennt sie, die Spec nicht. [Gap, data-model „Partie“; Plan R8]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Ein Treffer zeigt 0,25 s das Muster `explosion` an der Stelle; er blockiert nichts.
  Muster und Dauer in den Style-Guide (R7, R8), ein Satz in der Spec bei FR-011.
- [x] CHK013 Ist das Muster der Leben in der Kopfzeile bemessen? R7 nennt „kleine Kanonen“, R8 das
  Muster `life` ohne Größe. [Gap, Plan R7, R8]
  → Vorschlag, freigegeben von Klaus (2026-10-27): `life` 7 × 4 Bildpixel, Abstand 2, rechtsbündig 2 vor dem rechten Rand; im
  Style-Guide.
- [x] CHK014 Hält die Pause ohne Fokus auch die Sperre von 0,5 s der Ergebnisanzeige und die Pause
  nach einem Treffer an? [Edge Case, Spec §FR-016; Plan R10, R11]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Ja, alle Zeiten des Spiels laufen nur mit Fokus. Satz in R11.
- [x] CHK015 Ist geregelt, wie der Marschtakt klingt, wenn die Takte kürzer werden als der Ton
  (0,05 s Abstand, 60 ms Ton)? [Edge Case, Plan R13]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Ein neuer Takt schneidet den vorigen Ton ab; ein Player für alle vier Töne. In R13
  und im Vertrag.

## Messbarkeit

- [x] CHK016 Ist SC-002 messbar? „Ein durchschnittlicher Spieler“ lässt sich nicht testen.
  [Measurability, Spec §SC-002]
  → Vorschlag, freigegeben von Klaus (2026-10-27): SC-002 neu: „Ein gezielter Durchlauf (Probe im Test) gewinnt in höchstens 3 Minuten
  Spielzeit; ohne einen Schuss erreicht der Block die Kanone frühestens nach 1 Minute; Klaus
  bestätigt das Spielgefühl bei der Abnahme von Phase 4.“
- [x] CHK017 Ist SC-003 „flüssig, ohne sichtbares Ruckeln“ messbar? [Measurability, Spec §SC-003]
  → Vorschlag, freigegeben von Klaus (2026-10-27): SC-003 neu: „Das Spiel rechnet in festen Schritten von 1/60 s, holt nach einem langen
  Bild höchstens 4 Schritte nach und zeigt bei Klaus' Fenster 60 Bilder je Sekunde.“
- [x] CHK018 Gibt es ein Maß für die sichtbare Rückmeldung beim Drücken? Der Style-Guide verlangt
  „Rückmeldung auf einen Klick unter 100 ms“. [Gap, Spec §FR-001a]
  → Vorschlag, freigegeben von Klaus (2026-10-27): FR-001a: Die Taste ist im nächsten Bild nach dem Drücken eingedrückt.

## Abhängigkeiten und Annahmen

- [x] CHK019 Ist geprüft, dass Schließen des Fensters während des Easter Eggs nichts speichert?
  `GameSession` speichert beim Schließen, wenn ein Spiel läuft. [Assumption, Spec Randfälle]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Annahme in der Spec mit Beleg: Im Titel läuft kein Spiel des Computerladens, also
  schreibt das Schließen nichts (`docs/spielbeschreibung/spielablauf.md`). Ein Test in Phase 5.
- [x] CHK020 Ist die Lage der Knöpfe als Vorbedingung sauber gefasst? R2 ist gemessen, gilt aber erst
  nach der Montage in Phase 1. [Dependency, Plan R2]
  → Vorschlag, freigegeben von Klaus (2026-10-27): bleibt wie geplant; Phase 1 hat dafür eine eigene `[C]`-Aufgabe mit Montage ×8, die
  Klaus abnimmt.

## Aus der Prüfung des Vertrags

Stil-Prüfer: 6 Befunde und 9 Lücken; Text-Prüfer: 3 Befunde und 5 Lücken. Claude hat jeden
nachgeprüft. Bestätigt sind alle Befunde; vier davon decken sich mit Punkten oben (Stil B1 mit
CHK001 und CHK002, Stil B2 mit CHK005, Stil B6 mit CHK004, Stil B5 zum Teil mit CHK012 und
CHK013) und stehen hier nicht doppelt. Von den Lücken sind die übernommen, die vor dem Bau eine
Festlegung brauchen; die übrigen stehen in den Notes.

### Stil

- [x] CHK021 Ist geregelt, dass die Spielseite weder Menü noch Liste ist? Der Baustein Communicator
  sagt „Auf der Anzeige steht immer genau eine Seite, ein Menü oder eine Liste mit Kopfzeile“ und
  „höchstens 8 Zeilen zu 20“; die Kopfzeile im Spiel ist 16 hoch. [Conflict, Spec §FR-010; Plan
  R7, R12; Stil B3]
  → Vorschlag, freigegeben von Klaus (2026-10-27): R12 Punkt 2 ändert auch den Baustein Communicator: Eine Seite ist ein Menü, eine
  Liste oder das Spiel; das Spiel hat sein eigenes Raster (Abschnitt „Spiel auf der Anzeige“).
- [x] CHK022 Welcher Zeiger steht über der Anzeige, wenn die Ergebnisanzeige auf einen Klick wartet?
  [Gap, Spec §FR-020; Stil B4]
  → Vorschlag, freigegeben von Klaus (2026-10-27): der Pfeil, auch dort, wie in einem Spiel; die Zeile „Weiter mit Taste oder Klick.“
  sagt, was geht. Als Ausnahme im Abschnitt „Spiel auf der Anzeige“ mit Grund.
- [x] CHK023 Sind alle Lagen ganzzahlig festgelegt? Die Kanone „in der Mitte“ läge bei x 75,5; wo
  die Punkte links beginnen und wo die Leben rechts enden, fehlt. [Gap, Plan R7; Stil B5]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Innenrand des Felds 2 Bildpixel (4 Oberflächenpixel wie bei Menü und Liste); Kanone
  beginnt bei x 75; Punkte ab x 2, Leben enden bei x 157. In R7 und im Style-Guide.
- [x] CHK024 Ist die Ergebnisanzeige ganz beschrieben: Schrift je Zeile, Zeilenhöhe, Lage, und was
  vom Feld stehen bleibt? [Gap, Plan R10; Vertrag invaders.md; Stil Lücke 6, Text Lücke 4]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Zeilen 1 und 2 (Ergebnis, Punkte) in `drucker` (Doto) und Versalien wie Kopfzeilen,
  Zeile 3 in `menue` (Ark Pixel 12) wie ein Eintrag; Zeilenhöhe 20, als Block mittig in der Anzeige;
  das Feld ist dabei leer bis auf die Kopfzeile, die stehen bleibt.
- [x] CHK025 Ist festgelegt, dass die Spielseite keinen Fokusrahmen zeigt, obwohl sie den
  Tastaturfokus hat? [Gap, Plan R9; Stil Lücke 5]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Ja, kein Fokusrahmen; im Abschnitt „Spiel auf der Anzeige“.
- [x] CHK026 Gilt „Bewegung reduzieren“ für das Spiel? [Gap; Stil Lücke 4]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Nein. Marschbilder und Explosionen sind das Spiel selbst, keine Deko. Ein Satz im
  Abschnitt.
- [x] CHK027 Sind die drei grauen Tasten im Baustein Communicator und der Hinweis während des Spiels
  beschrieben? Heute nennt der Baustein bei G-03 nur „mintgrüne Funktionstasten und eine rote
  Taste“, und dass der Hinweis im Spiel verborgen ist, steht nirgends. [Gap, Spec §FR-010; Plan R12;
  Stil Lücken 7 und 8]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Beides in R12 Punkt 1 und 2 aufnehmen.
- [x] CHK028 Gelten die Abstände `raster-2` bis `raster-16` im Spielfeld? R7 hat Abstände von 3
  Bildpixeln. [Ambiguity, Plan R7; Stil Lücke 1]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Nein. Das Feld liegt auf dem Bildraster wie eine Szene; die `raster-*`-Abstände
  gelten für die Oberfläche. Ein Satz im Abschnitt.
- [x] CHK029 Was heißt „ohne Lichtkante“ beim Eindrücken: nur die oberste Zeile oder auch die linke
  Spalte? [Ambiguity, Spec §FR-001a; Plan R3; Stil Lücke 9]
  → Vorschlag, freigegeben von Klaus (2026-10-27): entscheidet die Montage ×8 in Phase 1; hat die Taste eine helle linke Kante, fällt
  auch sie weg. R3 bekommt diesen Vorbehalt.

### Text

- [x] CHK030 „SIE SIND GELANDET.“ liest sich in Versalien wie die Anrede „Sie“; das Spiel duzt.
  [Conflict, Plan R10; Spec §FR-031; Text B1, hoch]
  → Vorschlag, freigegeben von Klaus (2026-10-27): `DIE SIND GELANDET.` Trocken und gesprochen, und nicht als Anrede zu lesen.
- [x] CHK031 „ALLE ERWISCHT!“ ist das einzige Ausrufezeichen; der Leitsatz sagt „Trocken statt
  laut“. [Conflict, Plan R10; Text B2]
  → Vorschlag, freigegeben von Klaus (2026-10-27): `ALLE ERWISCHT.`
- [x] CHK032 „Weiter mit einer Taste.“ verschweigt den Klick, den FR-020 erlaubt. [Consistency, Spec
  §FR-020; Plan R10; Text B3]
  → Vorschlag, freigegeben von Klaus (2026-10-27): `Weiter mit Taste oder Klick.`
- [x] CHK033 Wie stehen Punkte da? Kopfzeile `PUNKTE 0380`, Ergebnis `380 PUNKTE`; zu führenden
  Nullen sagt der Style-Guide nichts. [Ambiguity, Plan R10; Text Lücke 3]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Führende Nullen nur in Anzeigen mit fester Stellenzahl, also in der Kopfzeile; im
  Ergebnis ohne. Regel in den Abschnitt „Spiel auf der Anzeige“.
- [x] CHK034 Darf das Ergebnis witzig sein, und gilt „ein Satz pro Meldung“? Ein Spiel im Spiel kennt
  der Abschnitt Sprache nicht. [Gap, Spec §FR-031; Text Lücken 1 und 2]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Das Ergebnis zählt als Meldung (Witz im Nachsatz erlaubt), „Weiter …“ als Bedienung
  (ohne Witz). Je Zeile ein Satz. In den Abschnitt „Spiel auf der Anzeige“, mit Verweis aus
  „Sprache“.

## Notes

- Eingearbeitet wird nach Klaus' Freigabe in Spec, research.md, Datenmodell, Verträge und Quickstart.
- Nicht als eigener Punkt übernommen: Leben als Symbol 16 × 16 (Stil Lücke 3; die Leben sind
  Spielmuster, kein Symbol, das sagt CHK013); Satzzeichen am Ende von Versalzeilen (Text Lücke 5;
  folgt aus CHK030 und CHK031); Unsicherheiten der Prüfer zu Pixeln des Gehäuses (klärt die Montage
  in Phase 1, CHK020, CHK029).
