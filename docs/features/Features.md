# Features

Arbeitsverzeichnis für Feature-Spezifikationen. Ein Dokument pro Feature, angelegt
und weitergeschoben mit `/dcl-feature`. Struktur gibt `TEMPLATE_FEATURE.md` vor.

**So wird gearbeitet:** „Wir arbeiten an Feature xy" — das Dokument ist die
Gesprächsgrundlage. Claude schreibt Specs, beschafft Informationen, bereitet vor,
erklärt und reviewt; Klaus baut in Godot. Einzelne Tasks gehen im Gespräch an
Claude über (in `## + Schritte` mit `[C]` markiert), und Code, den Claude
erzeugt, sieht Klaus sich vorher an — er ist Lernmaterial und Vorlage, kein
ungesehenes Ergebnis.

**Abgrenzung:** `docs/game_design.md` ist das Visionsdokument — *was* das Spiel ist,
ändert sich selten. Die Feature-Docs hier sind der Bauplan — *wie* es funktioniert,
und hier werden die „Offenen Fragen" des GDD einzeln abgearbeitet.
`docs/game_bible/` ist davon getrennt: dort liegt Spielinhalt (Komponenten, Preise,
Texte), nicht Technik.

## Systeme

Die Nummer ist Teil der `feature_id` (`SS-NN`) und stabil.

| SS | System | Stand |
|---|---|---|
| 01 | Zeitleiste | Umgesetzt (Spieluhr, Ereignis-Engine) |
| 02 | Produktdatenbank | Als nächstes — Brücke game_bible → Engine |
| 03 | Wirtschaftsmodell | Idee |
| 04 | Informationssystem | Idee |
| 05 | Standortsystem | Idee |
| 06 | Marketingsystem | Idee |
| 07 | Handelsnetzwerk | Idee |
| 08 | Qualität & Risiko | Idee |
| 09 | Adventure-Layer | Idee (Orte, Dialoge, Interaktion) |
| 10 | Präsentation & UI | Idee |
| 11 | Infrastruktur | Idee (Speichern, Build, Sound) |

01–08 entsprechen den Kernsystemen aus dem GDD. 09–11 stehen dort verstreut bzw.
unter „Offene Fragen", sind aber eigene Systeme.

## Features

| ID | Feature | Status | Phase |
|---|---|---|---|
| 01-01 | [[01-01-spieluhr]] | fertig | tasks |
| 01-02 | [[01-02-ereignis-engine]] | fertig | tasks |
| 02-01 | [[02-01-bible-importer]] | spezifiziert | plan |

Diese Tabelle wird derzeit von Hand gepflegt. Ab etwa zehn Features lohnt ein
Generator, der sie aus dem Frontmatter baut — gleiches Prinzip wie
`docs/game_bible/regenerate_tables.py`.

## Vorgemerkt

Alles, was noch kein eigenes Dokument hat, steht in [[Feature_Ideas]] — nach
Systemen gruppiert, mit Abhängigkeiten. Unverbindlich: IDs dort sind reserviert,
nicht vergeben.
