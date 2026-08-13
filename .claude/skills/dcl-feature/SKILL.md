---
name: dcl-feature
description: Legt Feature-Spezifikationen für Der Computerladen an und schiebt sie durch die Phasen spec → plan → tasks. Arbeitet template-gesteuert nach docs/features/TEMPLATE_FEATURE.md und pflegt den Index docs/features/Features.md sowie den Ideen-Backlog docs/features/Feature_Ideas.md. Nutze dies, wenn ein Feature spezifiziert, geplant, weitergeschoben oder aus dem Ideen-Backlog hochgezogen werden soll — oder wenn der Nutzer sagt „wir arbeiten jetzt an Feature xy".
---

# Feature-Spezifikation anlegen und weiterschieben

Feature-Dokumente liegen in `docs/features/`. Sie sind die Gesprächsgrundlage für
„wir arbeiten jetzt an Feature xy" — nicht Selbstzweck und keine Bürokratie.

## Verbindliche Regeln (zuerst lesen)

- **Schema:** `docs/features/TEMPLATE_FEATURE.md` ist die **alleinige** Autorität
  für Frontmatter-Felder, deren Reihenfolge und die `## +`-Struktur. Übernimm sie
  exakt — nichts weglassen, nichts erfinden. Weicht eine vorhandene Feature-Datei
  vom Template ab, ist das **kein** Vorbild, sondern etwas zu Begradigendes.
- **Rollenverteilung:** Claude schreibt Specs, beschafft Informationen, bereitet
  vor, erklärt und reviewt. Klaus arbeitet in Godot — Szenen, Nodes, GDScript.
  Das wird ihm nicht abgenommen. Einzelne Tasks gehen im Gespräch an Claude über
  (im Dokument als `[C]` markiert); das ist der Normalfall. **Nie eigenmächtig
  implementieren**, weil ein Feature-Dokument existiert — das Dokument ist eine
  Beschreibung, keine Beauftragung.
- **Code, den Claude erzeugt, ist Vorlage zum Ansehen**, nicht fertiges Ergebnis.
  Klaus prüft ihn, bevor er ins Projekt geht.
- **Phasen nicht überspringen:** In `spec` gehört noch kein Godot-Detail. Wer in
  der Spec-Phase schon Knoten und Signaturen festlegt, hat das Problem nicht
  verstanden, sondern eine Lösung geraten.
- **Ehrlichkeit vor Vollständigkeit:** Ein leerer `## + Offene Fragen`-Abschnitt
  bei einem nicht-trivialen Feature ist ein Warnzeichen, kein Erfolg.

## Schritt 1 — Feature bestimmen

1. Lies `docs/features/Features.md` (Systemliste 01–11 und Index) und
   `docs/features/Feature_Ideas.md` (Backlog).
2. Kläre per AskUserQuestion, worum es geht:
   - **Neues Feature** — noch nirgends notiert.
   - **Aus dem Backlog hochziehen** — steht in `Feature_Ideas.md`, bekommt jetzt
     ein eigenes Dokument. Häufigster Fall.
   - **Vorhandenes weiterschieben** — Phase `spec` → `plan` → `tasks`.
3. Bei neuem Feature oder Hochziehen: `feature_id` als `SS-NN` festlegen — `SS`
   ist die Systemnummer aus `Features.md`, `NN` die nächste freie laufende Nummer
   in diesem System. Wenn `Feature_Ideas.md` bereits eine ID reserviert hat, diese
   übernehmen. Bestätige den Zielpfad
   (`docs/features/<feature_id>-<slug>.md`) mit dem Nutzer.

## Schritt 2 — Phase bestimmen und nur diese füllen

Das Dokument wächst über drei Phasen. Fülle **nur** die Abschnitte der aktuellen
Phase; spätere bleiben leer stehen (nicht löschen).

| Phase | Es wird gefüllt | Leitfrage |
|---|---|---|
| `spec` | `## + Problem`, `## + Lösung`, `## + Akzeptanzkriterien` | Was tut es, und woran merken wir, dass es fertig ist? |
| `plan` | `## + Technischer Vertrag`, `## + Schritte`, `godot_*`- und `lernen_*`-Felder | Wie wird es gebaut, in welcher Reihenfolge, wer macht was? |
| `tasks` | `## + Entscheidungen`, `## + Offene Fragen`, `## + Lernnotizen` | Was haben wir währenddessen gelernt und entschieden? |

`feature_status` mitführen: `idee` → `spezifiziert` (nach spec) → `in-arbeit`
(während tasks) → `fertig`.

## Schritt 3 — Recherche (in Phase `plan`)

Bevor ein technischer Vertrag entsteht:

1. **Godot-Doku** zur betroffenen Klasse/API lesen — nicht aus dem Gedächtnis
   spezifizieren. Godot-Version ist 4.6 (siehe `src/project.godot`); Antworten
   für Godot 3 sind unbrauchbar und kursieren zahlreich.
2. **Bestehenden Code lesen**, an den das Feature andockt — vor allem
   `src/core/` und die Autoloads in `src/project.godot`.
3. **Abhängigkeiten prüfen:** Ist alles unter `bezug_haengt_ab_von` wirklich
   fertig? Wenn nicht, sag es, statt drumherum zu spezifizieren.

## Schritt 4 — Technischer Vertrag

Der Abschnitt, an dem sich das Dokument bewährt oder blamiert. Präzise genug,
dass beim Zuarbeiten nichts geraten werden muss:

- Betroffene und neue Dateien mit vollständigem Pfad
- Klassen: `class_name`, `extends`, Autoload oder Resource
- Öffentliche Methoden mit **vollständiger** GDScript-Signatur inkl. Typen
- Signale mit Parametern und Typen
- Datenformen: Dictionary-Schlüssel, Resource-Felder, Frontmatter-Felder
- **Was ausdrücklich nicht dazugehört** — die Abgrenzung ist so wichtig wie der
  Inhalt, weil sie Scope-Creep sichtbar macht

## Schritt 5 — Schritte mit Besitzer

`## + Schritte` als nummerierte Liste, jeder Schritt mit `[K]` (Klaus) oder `[C]`
(Claude). Default ist `[K]`. Typische `[C]`-Schritte: Doku zusammenfassen,
Recherche, Testdaten erzeugen, Generator-/Skript-Arbeit außerhalb von Godot,
Beispielcode zum Ansehen, Review.

Schritte klein schneiden — jeder einzeln überprüfbar. Ein Schritt, der einen
halben Tag dauert, ist zwei Schritte.

Die Aufteilung ist ein **Vorschlag**. Sag das im Dokument und im Gespräch.

## Schritt 6 — Index pflegen

- Neues Dokument → Zeile in der Tabelle `## Features` von
  `docs/features/Features.md` (ID, Wikilink, Status, Phase).
- Wurde ein Eintrag aus `Feature_Ideas.md` hochgezogen → dort als
  **spezifiziert** markieren und auf das neue Dokument verlinken, statt die
  Zeile zu löschen (die Abhängigkeiten anderer Einträge zeigen darauf).
- Status- oder Phasenwechsel → Tabelle in `Features.md` nachziehen.

## Abschluss

Fasse zusammen: welches Feature, welche Phase, was gefüllt wurde, welche Schritte
bei `[C]` liegen, und welche offenen Fragen entstanden sind. Weise ausdrücklich
auf Abhängigkeiten hin, die noch nicht fertig sind.

Frag am Ende, ob mit einem der `[C]`-Schritte begonnen werden soll — fang nicht
ungefragt an.
