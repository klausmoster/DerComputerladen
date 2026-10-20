# Anforderungs-Review Checklist: Zeitleisten-Werkstatt

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: Kern (Fahrplan, Zufall, Eingriffe), Werkstatt (Bearbeiten,
Zeitstrahl, Simulator, Statistik), Katalog und Übernahme, nicht-funktionale Anforderungen.
**Created**: 2026-10-20
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

## Vollständigkeit

- [x] CHK001 Ist festgelegt, ob und wie Kategorien gelöscht werden: Was geschieht mit den
  Ereignissen einer gelöschten Kategorie, welche Farbe bekommt eine neue Kategorie, und kann sich
  die Kennung einer Kategorie ändern? [Gap, Spec §FR-009, §FR-031]
  → Vorschlag, freigegeben von Klaus: Löschen nur, wenn keine Ereignisse mehr dazugehören. Eine neue
  Kategorie bekommt die erste freie Farbe der Palette. Die Kennung entsteht aus dem Namen und bleibt
  fest, Umbenennen ändert nur den Namen. FR-031, Datenmodell, Vertrag (`delete_category()`).
- [x] CHK002 Ist beschrieben, was die Werkstatt tut, wenn es noch gar keine Katalogdatei gibt? Darf
  sie dann einen leeren Katalog anlegen? Der Edge Case behandelt nur „fehlt oder ist nicht lesbar“
  fürs Spiel. [Gap, Spec Edge Cases, §FR-028]
  → Vorschlag, freigegeben von Klaus: Die Werkstatt bietet einen leeren Katalog mit den zehn
  Kategorien an; geschrieben wird er erst beim Speichern. Edge Cases, Vertrag (`new_catalog()`).
- [x] CHK003 Ist festgelegt, was mit den Verweisen geschieht, wenn Klaus ein Ereignis trotz
  Verweisen löscht: Bleiben sie als Fehler stehen, oder werden sie mit entfernt?
  [Gap, Spec §FR-036]
  → Vorschlag, freigegeben von Klaus: Die Verweise werden mit entfernt, alles in einem Schritt, den
  Cmd+Z zurücknimmt. FR-036, Vertrag.
- [x] CHK004 Ist festgelegt, was beim Wechsel der Art mit den Werten der alten Art geschieht,
  etwa mit Zeitfenster und Chance, wenn ein Ereignis von „über Wahrscheinlichkeit“ zu „fix“
  wechselt und zurück? [Gap, Spec §FR-031]
  → Vorschlag, freigegeben von Klaus: Werte, die beide Arten haben, bleiben (Zeitfenster,
  Mindestabstand, Dauer). Die übrigen Felder der neuen Art bekommen Vorgaben, die der alten fallen
  weg; Cmd+Z holt sie zurück. FR-031, Vertrag (`set_event_kind()`).
- [x] CHK005 Ist beschrieben, was das Ziehen eines jährlichen Ereignisses auf dem Zeitstrahl
  bewirkt: Verschiebt es den Tag im Jahr für alle Jahre, oder geht das gar nicht?
  [Gap, Spec §FR-039]
  → Vorschlag, freigegeben von Klaus: Jährliche Ereignisse lassen sich nicht ziehen, nur im Formular
  ändern; der Hinweis sagt das. Ein Ziehen müsste alle 15 Jahre und das „Monatsende“ mitbewegen.
  FR-039, Vertrag.
- [x] CHK006 Ist festgelegt, wie der Zeitstrahl Ereignisse darstellt, die in einer Zeile dicht
  beieinander liegen oder sich überlappen, mit welcher Beschriftung, und wie Ereignisse ohne
  eigenes Datum („nur als Folge“) erscheinen? [Gap, Spec §FR-037]
  → Vorschlag, freigegeben von Klaus: Überlappende Marken werden in Unterzeilen gestapelt, Titel
  stehen nur bei Platz, sonst im Hinweis. „Nur als Folge“ hat keine Marke auf der Achse, steht aber
  in der Liste und erscheint im Simulator, sobald geplant. FR-037, Vertrag.
- [x] CHK007 Ist festgelegt, wie lange Eingriffe im Simulator gelten: über einen Neustart, über
  eine Änderung am Katalog, über das Schließen der Werkstatt hinaus? Und lassen sie sich als
  wiederverwendbares Szenario speichern, etwa „windiger Händler ab 1990“? [Gap, Spec §FR-043]
  → Entschieden (Klaus): Was-wäre-wenn-Proben lassen sich unter einem Namen speichern, laden und
  löschen. Ohne Speichern bleiben Eingriffe erhalten, solange die Werkstatt offen ist; nicht
  anwendbare Eingriffe nennt sie beim Laden. US6 (Szenarien 7 und 8), FR-043, FR-051, Datenmodell
  (WhatIfProbe), R22, Vertrag.
- [x] CHK008 Ist beschrieben, wie Simulator und Statistik mit einem Katalog umgehen, der Fehler
  hat? Sie können verweigern, die fehlerhaften Ereignisse ausnehmen wie das Spiel (FR-049) oder
  trotzdem rechnen. [Gap, Spec §FR-042, §FR-044, §FR-049]
  → Vorschlag, freigegeben von Klaus: Beide nehmen fehlerhafte Ereignisse aus wie das Spiel und
  nennen sie. FR-042, Vertrag.
- [x] CHK009 Sind der erlaubte Wertebereich eines Seeds und seine Eingabe in der Werkstatt
  festgelegt, etwa nur positive ganze Zahlen? [Gap, Spec §FR-014, §FR-040]
  → Vorschlag, freigegeben von Klaus: ganze Zahl von 0 bis 2.147.483.647, gewürfelt wird aus diesem
  Bereich. FR-014, Vertrag.
- [x] CHK010 Ist festgelegt, in welchem Format die Werkstatt Zahlen und Daten annimmt, etwa
  Dezimalkomma, Prozentzeichen, `TT.MM.JJJJ`? Bisher steht das nur im Vertrag, nicht in der Spec.
  [Gap, Spec §FR-031, contracts/werkstatt.md]
  → Vorschlag, freigegeben von Klaus: Komma oder Punkt, angezeigt mit Komma. Wahrscheinlichkeiten
  und Stärken in Prozent, Daten als `TT.MM.JJJJ`, auch ohne führende Nullen. Ungültiges wird nicht
  übernommen, das Feld zeigt einen Hinweis. FR-031, Vertrag.
- [x] CHK011 Ist festgelegt, was nach einem Absturz der Werkstatt mit ungespeicherten Änderungen
  geschieht: Gibt es eine Wiederherstellung, oder ist der Verlust bewusst hingenommen?
  [Gap, Recovery, Spec §FR-034]
  → Entschieden (Klaus): Sicherungskopie spätestens alle 2 Minuten unter `user://`. Beim nächsten
  Start fragt die Werkstatt, ob sie die Kopie übernehmen oder verwerfen soll; nach dem Speichern und
  nach regulärem Schließen löscht sie sie. FR-050, Edge Cases, R23, Vertrag.

## Klarheit

- [x] CHK012 Sind die Regeln der Würfelrunde in der Spec eindeutig, oder stehen sie nur im Plan?
  Drei Punkte sind offen: Zählt der Mindestabstand ab Beginn oder ab Ende des letzten Eintretens?
  Zählen entfallene und abgesagte Termine bei der Höchstzahl mit? Wie werden Monate behandelt, die
  das Zeitfenster nur teilweise überdecken? [Ambiguity, Spec §FR-004, §FR-005, Plan R8]
  → Vorschlag, freigegeben von Klaus: in die Spec übernommen:
  - Der Mindestabstand zählt ab dem Beginn des letzten Termins.
  - Die Höchstzahl zählt alle Termine außer entfallenen und abgesagten.
  - Teilmonate werden gewürfelt, der Tag aber nur im Fenster.

  FR-004, FR-005.
- [x] CHK013 Ist bei Bedingungen klar, was „schon eingetreten“ heißt: Zählt ein Ereignis, das noch
  läuft, und eines, das am selben Tag begonnen hat? [Ambiguity, Spec §FR-006]
  → Vorschlag, freigegeben von Klaus: Eingetreten heißt „hat begonnen“, auch wenn es noch läuft. Was
  am selben Tag beginnt, zählt erst ab dem Folgetag; so entscheidet die Reihenfolge innerhalb eines
  Tages nichts. FR-006, Datenmodell.
- [x] CHK014 Ist klar, was „mit erreichter Höchstzahl“ bei Ereignissen „beim Start gesetzt“ heißt?
  Diese haben keine Höchstzahl, sondern eine Spanne von–bis. [Ambiguity, Spec §FR-044, US7]
  → Vorschlag, freigegeben von Klaus: Die Spalte heißt „Obergrenze“: Höchstzahl bei
  Wahrscheinlichkeit, höchste Anzahl bei gesetzten Ereignissen, sonst „–“. FR-044, Datenmodell,
  Vertrag.
- [x] CHK015 Ist bei FR-014 klar, wo und für wen sich der Seed „jederzeit ablesen“ lässt:
  in der Werkstatt, im Protokoll, später für den Spieler? [Ambiguity, Spec §FR-014]
  → Vorschlag, freigegeben von Klaus: in der Werkstatt, in der Textausgabe und für andere Spielteile
  über die Zeitleiste. Eine Anzeige für den Spieler gehört nicht zu diesem Feature. FR-014.
- [x] CHK016 Verlangt US6, Szenario 2 („vergleicht“), dass die Werkstatt zwei Durchläufe
  gegenüberstellt, oder vergleicht Klaus von Hand? [Ambiguity, Spec US6, §FR-043]
  → Entschieden (Klaus): Der Fahrplan markiert die Unterschiede zum selben Seed ohne Eingriffe: neu,
  weggefallen, verschoben, anderer Zustand. US6 (Szenario 2), FR-043, R24, Vertrag (`ScheduleDiff`).
- [x] CHK017 Ist festgelegt, ob ein laufender Durchlauf im Simulator Änderungen am Katalog sofort
  übernimmt oder erst nach einem Neustart? [Ambiguity, Spec §FR-042, US5]
  → Vorschlag, freigegeben von Klaus: Der Lauf behält seinen Stand, und ein Hinweis „Katalog
  geändert, neu starten“ erscheint; die Änderung gilt ab dem Neustart. FR-042, Vertrag.

## Widerspruchsfreiheit

- [x] CHK018 Passt FR-035 („ein Feld, eine Zeile“) zu den Schreibregeln des Plans? Die Ereignisse
  sind nach Kennung sortiert: Ändert Klaus eine Kennung, wandert der ganze Block. Ein Wechsel der
  Art ändert mehrere Schlüssel. [Conflict, Spec §FR-035, Plan R3, contracts/ereigniskatalog.md]
  → Vorschlag, freigegeben von Klaus: Die Sortierung nach Kennung bleibt, damit gleicher Inhalt
  dieselbe Datei ergibt. FR-035 nimmt Kennung und Art ausdrücklich aus.
- [x] CHK019 Stimmt „Die bisherigen Meldungen behalten Inhalt und Bedeutung“ (FR-017), obwohl
  sich die Felder von `TimelineEvent` ändern und die Wirkungsart `SPAWN` wegfällt? Sollte die
  Spec nur Namen und Bedeutung der Meldungen zusagen? [Conflict, Spec §FR-017,
  contracts/zeitleiste.md]
  → Vorschlag, freigegeben von Klaus: FR-017 sagt jetzt „Namen und Bedeutung“, die Felder folgen dem
  neuen Katalog.
- [x] CHK020 Wird „eingetreten“ überall gleich verwendet? Als Zustand eines Termins (FR-012) heißt
  es „vorbei“, in Bedingungen (FR-006) heißt es „hat begonnen“. [Consistency, Spec §FR-006,
  §FR-012, data-model.md]
  → Vorschlag, freigegeben von Klaus: Zustände sind geplant, läuft, eingetreten (ohne Dauer),
  beendet (mit Dauer, nach dem Ende), entfallen und abgesagt. In Bedingungen heißt „eingetreten“
  „hat begonnen“. FR-012, FR-006, Datenmodell (`ENDED`), Vertrag.
- [x] CHK021 Sind Prozent und Prozentpunkte einheitlich? US6, Szenario 3 spricht von „Summe
  −3 %“, FR-025 von Prozentpunkten. [Consistency, Spec US6, §FR-025]
  → Vorschlag, freigegeben von Klaus: Kein Widerspruch, denn die Summe aus Grundchance und
  Modifikatoren ist eine Chance und steht deshalb in Prozent. FR-025 sagt jetzt ausdrücklich:
  Chancen in Prozent, Modifikatoren in Prozentpunkten.

## Abnahmekriterien

- [x] CHK022 Hat SC-001 („höchstens 10 Minuten“) eine Messmethode? Offen sind: wer misst, ab wann
  die Uhr läuft, ob Übung mit der Werkstatt vorausgesetzt ist. [Measurability, Spec §SC-001]
  → Vorschlag, freigegeben von Klaus: Klaus misst, nachdem er den Quickstart einmal durchgegangen
  ist; die Uhr läuft vom ersten „Neu“, bis das vierte Ereignis im Simulator steht. SC-001,
  Quickstart.
- [x] CHK023 Ist bei SC-004 festgelegt, wo gemessen wird: am Knopf „Bis zum Ende“ der Werkstatt,
  in der Textausgabe oder im Test, und mit welchem Katalog? [Measurability, Spec §SC-004]
  → Vorschlag, freigegeben von Klaus: in der Werkstatt mit dem übernommenen Katalog samt Kalender:
  „Bis zum Ende“, bis das Protokoll steht, und die Statistik vom Start bis 100 %. SC-004,
  Quickstart.
- [x] CHK024 Ist bei SC-003 festgelegt, mit welchem Modifikator, über welche Zeit und mit welchen
  100 Seeds geprüft wird, damit das Kriterium wiederholbar ist? [Measurability, Spec §SC-003]
  → Vorschlag, freigegeben von Klaus: Seeds 1 bis 100 mit dem Modifikator aus US6, Szenario 1.
  SC-003.
- [x] CHK025 Lässt sich FR-029 abnehmen, solange der Style-Guide-Abschnitt „Werkzeuge“ fehlt?
  Welche Kriterien gelten dort, etwa Schriftgröße, Kontrast, Farbrollen? [Measurability,
  Spec §FR-029, Plan Vorarbeit 1]
  → Vorschlag, freigegeben von Klaus: FR-029 verlangt zusätzlich mindestens 4,5 : 1 Kontrast.
  Schrift und Farbrollen legt der Abschnitt „Werkzeuge“ fest; abgenommen wird nach seiner Freigabe
  in Phase 1. FR-029, Plan, Vorarbeit 1.

## Abläufe und Randfälle

- [x] CHK026 Ist festgelegt, ob Eingriffe schon vor Spielbeginn möglich sind, also bevor der
  01.01.1985 abgespielt ist, und ab welchem Tag sie dann wirken? [Coverage, Spec §FR-026,
  §FR-027]
  → Vorschlag, freigegeben von Klaus: Ja, ab dem 01.01.1985. FR-027, R11, Vertrag.
- [x] CHK027 Sind Kreise aus Folgeereignissen mit Verzögerung ausdrücklich erlaubt, etwa A → B → A
  im Abstand von je einem Tag? Ist bedacht, dass sie bis Spielende laufen können? Die Kettenbremse
  gilt nur am selben Tag. [Coverage, Spec §FR-018, Edge Cases]
  → Vorschlag, freigegeben von Klaus: erlaubt, etwa für regelmäßig wiederkehrende Ereignisse, aber
  mit der Warnung V23, wenn der Kreis mit 100 % bis Spielende läuft. Edge Cases, Datenmodell.
- [x] CHK028 Sind Randfälle bei Modifikatoren festgelegt: Ende vor Beginn, Beginn in der
  Vergangenheit, Wert 0, zwei Modifikatoren mit gleicher Kennung? [Edge Case, Spec §FR-025]
  → Vorschlag, freigegeben von Klaus: Ende vor Beginn und doppelte Kennung werden abgelehnt; ein
  Beginn in der Vergangenheit und der Wert 0 sind erlaubt. Edge Cases, Datenmodell, R11.
- [x] CHK029 Ist festgelegt, was gilt, wenn ein gesetztes oder gewürfeltes Ereignis mit Dauer
  länger läuft als sein Mindestabstand oder über sein Zeitfenster hinaus? Gerade bei gesetzten
  Terminen widerspricht sich das mit „läuft nie zweimal gleichzeitig“. [Edge Case, Spec §FR-004,
  §FR-022]
  → Vorschlag, freigegeben von Klaus: Bei gesetzten Ereignissen ist ein Mindestabstand unter der
  Dauer ein Fehler (V24), damit kein gesetzter Termin entfällt. Über das Zeitfenster hinaus zu
  laufen ist erlaubt, das Fenster gilt für die Beginne. Edge Cases, Datenmodell.
- [x] CHK030 Sind Kalender-Randfälle für alle Arten geklärt? Etwa ein einmaliges Ereignis am
  29.02. eines Schaltjahrs, ein fixes Ereignis mit Dauer über den Jahreswechsel, ein Zeitfenster
  mitten im Monat. [Edge Case, Spec Edge Cases, §FR-020]
  → Vorschlag, freigegeben von Klaus: Der 29.02. ist bei einmaligen Ereignissen erlaubt, eine Dauer
  über den Jahreswechsel auch. Bei einem Zeitfenster mitten im Monat wird der Tag nur im Fenster
  gewürfelt. Edge Cases, FR-005.

## Nicht-funktionale Anforderungen

- [x] CHK031 Fehlen in der Spec Leistungsziele für einen größeren Katalog? Der Plan legt bis zu
  500 Ereignisse aus (R21), SC-004 gilt nur für den übernommenen. [Gap, Spec §SC-004, Plan R21]
  → Vorschlag, freigegeben von Klaus: neues SC-011 für 500 Ereignisse: ein Spiel unter 2 s,
  Statistik unter 5 Minuten, Werkstatt unter 100 ms. Geprüft mit `catalog_500.json` und
  `test_large_catalog.gd`. SC-011, R21, Quickstart.
- [x] CHK032 Ist festgehalten, dass gleiche Ergebnisse nur bei gleicher Godot-Version zugesagt
  sind (R5)? Ist das für spätere Spielstände (11-01) akzeptabel? [Assumption, Spec §FR-014,
  Plan R5]
  → Entschieden (Klaus): Die gleiche Godot-Version reicht. Das steht als Annahme in der Spec; einen
  eigenen Zufallsgenerator gibt es nicht. Assumptions, R5.
- [x] CHK033 Gibt es eine Anforderung an die Antwortzeit der Werkstatt, also Prüfung nach jeder
  Änderung und Ziehen auf dem Zeitstrahl? Bisher steht das nur im Technical Context des Plans.
  [Gap, Spec §FR-033, §FR-039, Plan Technical Context]
  → Vorschlag, freigegeben von Klaus: aufgenommen in SC-011: unter 100 ms für eine Änderung und beim
  Ziehen.

## Abhängigkeiten und Annahmen

- [x] CHK034 Ist die Annahme abgesichert, dass die exportierte App den Katalog als Datei lesen
  kann (R4)? Oder ist sie als Risiko mit Ausweichweg in den Tasks verankert?
  [Assumption, Plan R4, quickstart.md]
  → Vorschlag, freigegeben von Klaus: Ein Probe-Export ist eine eigene Aufgabe in Phase 3. Der
  Ausweichweg ist `*.json` im Include-Filter. R4, Plan Phase 3.
- [x] CHK035 Ist die Änderung am Verhalten aus Feature 001 dokumentiert? Die Werkstatt schaltet
  `GameWindow` ab, und es soll belegt sein, dass das Spiel davon nicht berührt wird.
  [Dependency, Plan R13, contracts/werkstatt.md]
  → Vorschlag, freigegeben von Klaus: Das Abschalten gilt nur im Prozess der Werkstatt. Das Spiel
  lädt sie nie, `GameWindow` und sein Test bleiben unverändert. Assumptions, Vertrag.
- [x] CHK036 Sind alle Nutzer der Teile bedacht, die wegfallen? Das sind `fast_forward_to()` (Idee
  01-05), `GameDate.season()` und `is_holiday_season()`, `season_changed` und `timeline_demo`
  (01-01 und 01-02 nennen sie in ihren Abnahmen). [Dependency, Plan, contracts/zeitleiste.md]
  → Vorschlag, freigegeben von Klaus: Der Plan hat jetzt die Tabelle „Was wegfällt und wer es
  nutzte“, und bei 01-05 steht ein Vermerk in Feature_Ideas. 01-01 und 01-02 bleiben als Historie.
  Plan, Feature_Ideas.

## Notes

- `[x]` erst, wenn Klaus den Punkt für erledigt hält; offene Punkte bleiben leer, bis sie geklärt
  oder korrigiert sind.
- Antworten und Entscheidungen werden wie bei Feature 001 unter dem Punkt eingetragen
  („→ Entschieden (Klaus): …“ oder „→ Vorschlag, freigegeben von Klaus: …“).
- Stand 2026-10-20: Alle 36 Punkte sind erledigt. Vier hat Klaus entschieden, 32 Vorschläge von
  Claude hat er freigegeben. Eingearbeitet sind alle in Spec, Datenmodell, Verträge, research.md,
  Plan und Quickstart.
- `/speckit-implement` wird in diesem Projekt nicht verwendet (Verfassung, Grundsatz II).
- `checklists/requirements.md` hat einen eigenen Ablauf über `/speckit-specify` und
  `/speckit-clarify`.
