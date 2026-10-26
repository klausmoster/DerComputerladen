# Anforderungs-Review Checklist: Neues Spiel starten

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: Spielstand und sicheres Speichern, Spielablauf mit Zeitleiste
und Uhr, Oberfläche auf dem Titelbildschirm und dem Spielbildschirm, Randfälle und Fehlerwege,
Abnahmekriterien, dazu für den Pilot der Prüfer ein Abschnitt „Stil und Texte“
(`docs/ki_workflow/ki_pruefung.md`, „Anbindung an Spec Kit“).
**Created**: 2026-10-26
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

Jeder Punkt hat einen Vorschlag von Claude („→ Vorschlag“). Was er an Spec oder Plan ändern würde,
steht dabei. Eingearbeitet wird erst nach Klaus' Freigabe; sie kam am 2026-10-26 für alle Punkte.

## Vollständigkeit

- [x] CHK001 Ist festgelegt, was geschieht, wenn eine Datei sich zwischen dem Anzeigen der Liste
  und dem Fortsetzen ändert oder verschwindet, etwa weil Klaus sie im Finder löscht?
  [Gap, Spec §FR-016; Plan R7]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Fortsetzen nimmt den Stand, den die Liste gelesen hat, und das Speichern beim
  Fortsetzen schreibt ihn wieder. Die Liste liest den Ordner jedes Mal neu, wenn der
  Titelbildschirm erscheint und wenn „Spiel laden“ sie öffnet. Neuer Edge Case „Datei ändert sich
  von außen“.
- [x] CHK002 Ist festgelegt, was geschieht, wenn das Spiel zweimal gleichzeitig läuft und beide ein
  neues Spiel anlegen? Beide fänden dieselbe nächste Nummer, und das zweite überschriebe das erste;
  FR-009 verbietet das. [Gap, Spec §FR-009; Plan R3, R4]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Ein neues Spiel schreibt nur, wenn es zu seiner Nummer noch keine Datei gibt; sonst
  nimmt es die nächste. Beim Schreiben eines vorhandenen Spielstands gewinnt das letzte Speichern;
  zwei Fenster mit demselben Spiel sind kein Fall für dieses Feature. Neuer Edge Case, ergänzt in
  R4 und im Vertrag `SaveStore.write()`.
- [x] CHK003 Ist festgelegt, was der Spieler sieht, wenn Löschen scheitert, etwa weil die Datei
  gesperrt ist? Die Edge Cases nennen nur das Scheitern beim Speichern. [Gap, Spec §FR-017]
  → Vorschlag, freigegeben von Klaus (2026-10-26): eine Meldung „Löschen ging nicht. Der Spielstand ist noch da.“; die Liste bleibt
  im Löschmodus nicht hängen, sondern zeigt den Stand neu. Steht im Vertrag; neuer Edge Case in der
  Spec.
- [x] CHK004 Ist festgelegt, was beim Fortsetzen geschieht, wenn das Speichern dabei scheitert?
  FR-010 nennt das Fortsetzen nicht als Anlass zum Speichern, der Plan schon (R9).
  [Gap, Conflict, Spec §FR-010, §FR-016; Plan R9]
  → Vorschlag, freigegeben von Klaus (2026-10-26): FR-010 nennt das Fortsetzen mit. Scheitert das Speichern dabei, läuft das Spiel,
  und der Spielbildschirm zeigt beim Erscheinen die Meldung.
- [x] CHK005 Ist festgelegt, wie sich die Liste bei vielen Spielständen verhält? FR-009 erlaubt
  beliebig viele, FR-015 sagt nichts über ein Blatt, das nicht alle fasst. [Gap, Spec §FR-015;
  Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-26): FR-015 bekommt den Satz „Passen nicht alle aufs Blatt, rollt die Liste mit der
  Auswahl und dem Mausrad; ‚Löschen …‘ und ‚Zurück‘ bleiben immer zu sehen.“ Die Zahl sechs bleibt
  im Plan und im Style-Guide.
- [x] CHK006 Ist festgelegt, wo nicht fortsetzbare Spielstände in der Liste stehen? Sie haben kein
  lesbares „zuletzt gespielt“, nach dem FR-015 ordnet. [Gap, Spec §FR-015; Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-26): unter den fortsetzbaren, nach Nummer absteigend. Ergänzt in FR-015.
- [x] CHK007 Ist festgelegt, was „Löschen …“ im Löschmodus tut? [Gap, Spec §FR-017a; Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Er ist dann nicht verfügbar; sein Hinweis sagt „Wähl oben den Spielstand, der weg
  soll. Esc bricht ab.“ Ergänzt in FR-017a.
- [x] CHK008 Nennt die Rückfrage bei einem nicht fortsetzbaren Spielstand Grad und Spieldatum, die
  sich nicht lesen lassen? FR-017 verlangt beides. [Gap, Spec §FR-017]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Statt Grad und Spieldatum nennt sie den Zustand: „Spiel 3, beschädigt, ist danach
  weg. Für immer.“ Ergänzt in FR-017.
- [x] CHK009 Ist festgelegt, was ein Spielstand mit falschen Werten außer Grad und Seed ist, etwa
  ein Spieldatum im Jahr 2000 oder ein Eingriff mit einem Datum, das es nicht gibt?
  [Gap, Spec §FR-013, Edge Cases; Plan R10]
  → Vorschlag, freigegeben von Klaus (2026-10-26): beides beschädigt, wie in R10. Der Edge Case „Unbekannter Grad oder Seed außerhalb“
  wird „Werte außerhalb ihres Bereichs“ und nennt Spieldatum und Eingriffe mit.
- [x] CHK010 Ist festgelegt, ob Esc im Hauptmenü etwas tut, jetzt, da Esc in jedem Blatt eine
  Ebene zurückführt? [Gap, Spec §FR-023]
  → Vorschlag, freigegeben von Klaus (2026-10-26): nichts, wie in Feature 001 (dort Edge Cases). Ergänzt in FR-023.

## Klarheit

- [x] CHK011 Heißt „Zu jedem Grad steht ein Satz“ in FR-004, dass alle drei gleichzeitig zu sehen
  sind? Der Plan zeigt nur den Satz des gewählten Grads im Hinweis (R13). [Ambiguity, Spec §FR-004;
  Plan R13]
  → Vorschlag, freigegeben von Klaus (2026-10-26): FR-004 sagt: „Der Hinweis der gewählten Zeile nennt den Satz zu ihrem Grad.“ Mittel
  ist vorgewählt, sein Satz steht also sofort da.
- [x] CHK012 Was genau gehört zu einem Spielstand, wenn FR-018 verlangt, nur „den gewählten
  Spielstand“ zu entfernen? Der Plan löscht auch übrig gebliebene Zwischendateien derselben Nummer
  (R3). [Ambiguity, Spec §FR-018; Plan R3]
  → Vorschlag, freigegeben von Klaus (2026-10-26): FR-018 sagt „den gewählten Spielstand samt den Zwischendateien, die beim Speichern
  zu ihm entstehen, und keine anderen Dateien“.
- [x] CHK013 Ist klar, welche Zeit „zuletzt gespielt“ zeigt und in welcher Form? [Clarity,
  Spec §FR-015, Key Entities; Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-26): die Ortszeit des Rechners, in der Liste „26.10.2026 21:40“, im Hinweis „am
  26.10.2026 um 21:40 Uhr“. Ergänzt in FR-015; gespeichert wird UTC (Datenmodell).
- [x] CHK014 Ist „Meldung“ in FR-011 so beschrieben, dass klar ist, wo sie steht und wie lange?
  [Clarity, Spec §FR-011; Plan R17]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Die Spec sagt nur „an der Stelle des Hinweises, bis der Spieler etwas anderes wählt
  oder auslöst“; Aussehen regelt der Style-Guide (neuer Baustein Meldung, Phase 1).
- [x] CHK015 Ist „Spiel laden“ als Name noch treffend, wenn dort auch gelöscht wird, und ist
  „Weiterspielen“ eindeutig, wenn der zuletzt gespielte Spielstand beschädigt ist?
  [Clarity, Spec §FR-001, §FR-002]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Beide bleiben. FR-001 sagt schon „zuletzt gespielte, fortsetzbare Spiel“;
  „Weiterspielen“ nimmt also das jüngste fortsetzbare, auch wenn darüber ein beschädigtes steht.
  Keine Änderung.

## Widersprüche

- [x] CHK016 FR-023 verlangt in jedem Blatt einen Eintrag „Zurück“, FR-017 in der Rückfrage
  „Abbrechen“ vorgewählt. Der Plan nimmt „Abbrechen“ als „Zurück“ der Rückfrage (R14). Ist das in
  der Spec aufgelöst? [Conflict, Spec §FR-017, §FR-023; Plan R14]
  → Vorschlag, freigegeben von Klaus (2026-10-26): FR-023 sagt „Jedes Blatt hat einen Eintrag, der eine Ebene zurückführt: ‚Zurück‘, in
  der Rückfrage ‚Abbrechen‘.“
- [x] CHK017 Der Baustein Knopf im Style-Guide erklärt sich beim Überfahren mit einem Tooltip,
  FR-020 verlangt einen Hinweis wie im Hauptmenü, der auch bei Auswahl per Tastatur steht. Welche
  Regel gilt? [Conflict, Spec §FR-020; Style-Guide, Knopf; Plan R15]
  → Vorschlag, freigegeben von Klaus (2026-10-26): In Phase 1 kommt in den Style-Guide: Ein Knopf, der allein auf einem Bildschirm
  steht und den Fokus hat, zeigt seinen Hinweis wie ein Menüeintrag, ohne Verzögerung. Knöpfe in
  Fenstern behalten den Tooltip. FR-020 bleibt.
- [x] CHK018 Der Edge Case „Geänderter Ereigniskatalog“ sagt „erst ein neues Spiel nutzt den
  geänderten“. Der Plan liest den Katalog nur beim Start der App (R6). Ist die Spec damit genau
  genug? [Consistency, Spec Edge Cases, §FR-022; Plan R6]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Annahme ergänzen: „Den Katalog liest das Spiel beim Start; eine Änderung aus der
  Werkstatt gilt für neue Spiele nach dem nächsten Start.“
- [x] CHK019 SC-006 verlangt, dass der Titelbildschirm ohne Spielstände aussieht wie in Feature
  001 „bis auf die geänderten Einträge des Menüs“. Auch die Hinweise ändern sich, und das Menü wird
  eine Zeile höher. Ist das gemeint? [Consistency, Spec §SC-006]
  → Vorschlag, freigegeben von Klaus (2026-10-26): SC-006 sagt „bis auf Einträge, Hinweise und Höhe des Menüs“.

## Randfälle und Fehlerwege

- [x] CHK020 Ist festgelegt, was geschieht, wenn das Speichern beim Schließen des Fensters oder bei
  Cmd+Q scheitert? FR-011 sagt „das Spiel läuft weiter“, FR-010 verlangt Beenden.
  [Gap, Conflict, Spec §FR-010, §FR-011; Plan R8]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Das Fenster bleibt offen, die Meldung sagt „Speichern ging nicht. Schließt du noch
  einmal, dann ohne.“; ein zweites Schließen beendet ohne Speichern. Neuer Edge Case.
- [x] CHK021 Ist festgelegt, was der Spieler nach einem Absturz beim Speichern sieht, wenn das
  Spiel den Stand aus einer Zwischendatei liest? [Gap, Spec Edge Cases; Plan R3]
  → Vorschlag, freigegeben von Klaus (2026-10-26): nichts Besonderes. Die Liste zeigt den Spielstand wie immer, das Protokoll nennt die
  Zwischendatei mit `push_warning()`, und das nächste Speichern räumt auf. Ergänzt im Edge Case
  „Absturz oder Stromausfall“.
- [x] CHK022 Ist festgelegt, was geschieht, wenn das erste Speichern eines neuen Spiels scheitert?
  [Coverage, Spec §FR-006, §FR-011]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Es entsteht kein Spielstand und kein laufendes Spiel; die Gradwahl bleibt stehen
  und zeigt „Speichern ging nicht. Es ist kein Spiel angelegt.“ Ergänzt im Edge Case „Speichern
  scheitert“.
- [x] CHK023 Ist festgelegt, wie mit einer Uhr des Rechners umgegangen wird, die zurückgestellt
  wurde, so dass „zuletzt gespielt“ in der Zukunft liegt? [Edge Case, Gap, Spec §FR-015]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Die Liste ordnet nach dem gespeicherten Wert, wie er ist; das Spiel prüft ihn nicht.
  Keine Änderung, Annahme ergänzen: „Die Uhr des Rechners geht richtig.“

## Abnahmekriterien

- [x] CHK024 Ist SC-002 messbar? „Laden und Anzeigen höchstens 1 Sekunde“ nennt weder die Zahl der
  Spielstände noch die Größe des Katalogs, und „Laden“ kann die Liste oder das Fortsetzen meinen.
  [Measurability, Spec §SC-002; Plan R16]
  → Vorschlag, freigegeben von Klaus (2026-10-26): SC-002 sagt: „Die Liste mit 20 Spielständen, je mit einem Katalog von 500
  Ereignissen, erscheint in höchstens 1 Sekunde; ein Spielstand vom 31.12.1999 ist in höchstens 1
  Sekunde fortgesetzt.“
- [x] CHK025 Ist US1, Szenario 4 („verschiedene Seeds“) objektiv prüfbar, obwohl der Seed gewürfelt
  wird? [Measurability, Spec US1]
  → Vorschlag, freigegeben von Klaus (2026-10-26): ja. Zwei gleiche Seeds hätten eine Wahrscheinlichkeit von 1 zu 2,1 Milliarden; der
  Test prüft außerdem mit vorgegebenen Würfeln, dass jedes Spiel neu würfelt. Keine Änderung.
- [x] CHK026 Ist FR-012 („Updates des Spiels überstehen“) in diesem Feature prüfbar? Es gibt noch
  keinen Export und kein Update. [Measurability, Spec §FR-012]
  → Vorschlag, freigegeben von Klaus (2026-10-26): belegt durch den Ort: Der Ordner liegt unter `user://`, außerhalb der App, und der
  Quickstart nennt ihn. Ein echter Test kommt mit dem ersten Export. Keine Änderung, Hinweis im
  Quickstart.
- [x] CHK027 Ist FR-014 (ältere Formatversion fortsetzen) in diesem Feature prüfbar? Es gibt nur
  Format 1. [Measurability, Spec §FR-014]
  → Vorschlag, freigegeben von Klaus (2026-10-26): nein, und das sagt FR-014 schon. Der Plan sieht die Stelle für Umwandlungen vor; ein
  Test kommt mit Format 2. Keine Änderung.

## Stil und Texte

Für den Pilot der Prüfer (`ki_pruefung.md`): Beschreiben Spec und Plan Sichtbares und Texte genau
genug, dass Stil- und Text-Prüfer einen Maßstab haben?

- [x] CHK028 Steht jeder neue Baustein und jede neue Regel, die die Oberfläche braucht, vor dem
  Bauen im Style-Guide oder ist dafür vorgemerkt? [Completeness, Spec §FR-021; Plan R17]
  → Vorschlag, freigegeben von Klaus (2026-10-26): erfüllt mit den fünf Abschnitten aus R17 in Phase 1; dazu kommt die Regel aus
  CHK017 zum Hinweis am Knopf. Sonst keine Änderung.
- [x] CHK029 Sind Lage und Größe aller Blätter, der Liste und des Knopfs gemessen und gegen das
  Raster 640 × 360 geprüft, einschließlich der Hinweise mit zwei Zeilen am unteren Rand?
  [Measurability, Spec §FR-023; Plan R11, R12, R15]
  → Vorschlag, freigegeben von Klaus (2026-10-26): erfüllt, in R11, R12 und R15 mit gemessenen Breiten. Keine Änderung.
- [x] CHK030 Stehen alle sichtbaren Texte mit Ort an einer Stelle, und passt jeder in sein Feld?
  [Completeness, Spec §FR-021; Vertrag titelbildschirm.md, „Texte“; Datenmodell, „SaveSlot“]
  → Vorschlag, freigegeben von Klaus (2026-10-26): erfüllt. Gemessen: jeder Hinweis höchstens zwei Zeilen in Ark Pixel 10, jeder
  Eintrag in die Breite seines Blatts. Die Gründe für nicht fortsetzbare Spielstände stehen im
  Datenmodell. Keine Änderung.
- [x] CHK031 Nennen die Hinweise Tastenkürzel, wo es welche gibt? Der Style-Guide verlangt das
  (Baustein Hinweis), und Esc führt in jedem Blatt zurück. [Consistency, Style-Guide, Hinweis;
  Vertrag titelbildschirm.md]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Ja, mit drei Änderungen am Vertrag, alle gemessen auf zwei Zeilen: „Zurück zum
  Hauptmenü. Esc geht auch.“; in der Rückfrage bei „Abbrechen“ „Spiel 2, Schwer, 14.03.1986,
  bleibt. Esc geht auch.“; der Hinweis im Löschmodus nennt Esc schon. Enter wird nirgends
  genannt, denn es löst überall die gewählte Zeile aus.
- [x] CHK032 Ist für jede Phase festgelegt, welcher Prüfer mit welchem Maßstab prüft, und ist die
  Zählung für „Nachmessen“ eingeplant? [Completeness, Plan „Prüfer je Phase“; ki_pruefung.md]
  → Vorschlag, freigegeben von Klaus (2026-10-26): erfüllt im Plan, „Prüfer je Phase“, und in Phase 6. Keine Änderung.
- [x] CHK033 Ist festgelegt, wie die gedämpften Zeilen nicht fortsetzbarer Spielstände aussehen,
  auch gewählt auf `signalgelb`? [Clarity, Spec Edge Cases; Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-26): wie ein nicht verfügbarer Eintrag im Baustein Menü, dessen Regel schon
  `signalgelb` abdeckt (3,31 : 1). Der Baustein Liste verweist darauf. Keine Änderung an der Spec.

## Abhängigkeiten und Annahmen

- [x] CHK034 Ist festgehalten, welche Teile von Feature 001 bis 003 sich ändern und welche Tests
  davon betroffen sind? [Dependency, Plan „Was sich an Feature 001 bis 003 ändert“]
  → Vorschlag, freigegeben von Klaus (2026-10-26): erfüllt im Plan. Die Spec nennt die geänderten FR von Feature 001 (FR-006, FR-010)
  schon. Keine Änderung.
- [x] CHK035 Ist die Annahme festgehalten, dass Spielstände nur Daten sind und beim Lesen nichts
  ausführen, auch wenn jemand sie von Hand verändert? [Assumption, Gap, Spec Edge Cases; Plan R1]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Annahme ergänzen: „Ein Spielstand enthält nur Daten; eine veränderte Datei kann
  höchstens beschädigt sein.“ R1 begründet es mit JSON statt Resource.
- [x] CHK036 Ist festgehalten, bis zu wie vielen Spielständen die Liste geprüft ist?
  [Assumption, Spec §FR-009, §SC-002]
  → Vorschlag, freigegeben von Klaus (2026-10-26): Mit CHK024 sind es 20 mit großem Katalog. Mehr Spielstände sind erlaubt und dauern
  länger; eine Grenze gibt es nicht. Annahme ergänzen.

## Notes

- Durchgang 1 (2026-10-26): 36 Punkte. Die meisten sind kleine Präzisierungen der Spec, die der
  Plan schon beantwortet. Echte Lücken: CHK001 bis CHK004, CHK020 und CHK022 zu Fehlerwegen,
  CHK017 als Widerspruch zum Style-Guide, CHK024 zur Messbarkeit von SC-002.
- Durchgang 2 (2026-10-26): Klaus hat alle 36 Vorschläge freigegeben. Eingearbeitet in Spec
  (Clarifications „Review 2026-10-26“, FR-004, FR-010, FR-011, FR-015, FR-017, FR-017a, FR-018,
  FR-023, SC-002, SC-006, Edge Cases, Annahmen), research.md (R4, R14, R16, R17), Datenmodell,
  Verträge, Quickstart und Plan („Änderungen nach der Checkliste“).
- `/speckit-implement` wird nicht verwendet (Verfassung, Grundsatz II); die Markierungen setzt
  Klaus.
