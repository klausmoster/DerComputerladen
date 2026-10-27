# Features

Systemliste und Index der Features. Gebaut wird mit Spec Kit: Jedes Feature hat eine
Nummer `NNN` und einen Ordner `specs/NNN-kurzname/` mit Spec, Plan und Aufgaben. Die Feature-Docs
aus der Zeit davor liegen in `archiv/`.

**Abgrenzung:** `docs/game_design.md` ist das Visionsdokument — *was* das Spiel ist.
`specs/` ist der Bauplan — *wie* es funktioniert, dort werden die „Offenen Fragen" des GDD
einzeln abgearbeitet. `docs/spielbeschreibung/` beschreibt den Stand im Code, `docs/game_bible/`
den Spielinhalt (Komponenten, Preise, Texte).

## Systeme

Die Nummer ist Teil der `feature_id` (`SS-NN`) und stabil.

| SS | System | Stand |
|---|---|---|
| 01 | Zeitleiste | Umgesetzt (Spieluhr, Ereignis-Engine); in Feature 002 umgebaut zum Fahrplan-Modell mit Zeitleisten-Werkstatt; Feature 003 bringt die Schwierigkeitsgrade Leicht, Mittel, Schwer |
| 02 | Produktdatenbank | Als nächstes — Brücke game_bible → Engine |
| 03 | Wirtschaftsmodell | Idee |
| 04 | Informationssystem | Idee |
| 05 | Standortsystem | Idee |
| 06 | Marketingsystem | Idee |
| 07 | Handelsnetzwerk | Idee |
| 08 | Qualität & Risiko | Idee |
| 09 | Adventure-Layer | Idee (Orte, Dialoge, Interaktion) |
| 10 | Präsentation & UI | In Arbeit (Feature 001: Start bis zum Hauptmenü; Feature 004: Blätter im Titel, Liste der Spielstände, leerer Spielbildschirm) |
| 11 | Infrastruktur | In Arbeit (Feature 004: Spielstände anlegen, fortsetzen, löschen); Build und Sound Idee |

01–08 entsprechen den Kernsystemen aus dem GDD. 09–11 stehen dort verstreut bzw.
unter „Offene Fragen", sind aber eigene Systeme.

## Features

| ID | Feature | Status | Phase |
|---|---|---|---|
| 01-01 | [Spieluhr](archiv/01-01-spieluhr.md), vor Spec Kit, überholt durch 002 | fertig | tasks |
| 01-02 | [Ereignis-Engine](archiv/01-02-ereignis-engine.md), vor Spec Kit, überholt durch 002 | fertig | tasks |
| 02-01 | [Bible-Importer](archiv/02-01-bible-importer.md), Entwurf vor Spec Kit, Vorlage für `/speckit-specify` | Entwurf | — |
| 001 | [Start bis zum Hauptmenü](../../specs/001-hauptmenue/spec.md), Spec-Kit-Pilot, System 10 | fertig | tasks |
| 002 | [Zeitleisten-Werkstatt](../../specs/002-zeitleisten-werkstatt/spec.md), System 01 | fertig | tasks |
| 003 | [Schwierigkeitsgrade der Zeitleiste](../../specs/003-schwierigkeitsgrade/spec.md), System 01 | fertig | tasks |
| 004 | [Neues Spiel starten](../../specs/004-neues-spiel/spec.md), System 11 und 01, Pilot der Prüf-Agents | fertig | tasks |
| 005 | [Communicator als Steuerelement](../../specs/005-communicator/spec.md), System 10, Titel auf dem Communicator | fertig | tasks |

Diese Tabelle wird derzeit von Hand gepflegt. Ab etwa zehn Features lohnt ein
Generator, der sie aus dem Frontmatter baut — gleiches Prinzip wie
`docs/game_bible/regenerate_tables.py`.

## Vorgemerkt

Alles, was noch kein eigenes Dokument hat, steht in [[Feature_Ideas]] — nach
Systemen gruppiert, mit Abhängigkeiten. Unverbindlich: IDs dort sind reserviert,
nicht vergeben.
