# Der Computerladen

Wirtschaftssimulation und Point-and-Click-Adventure, Deutschland 1985–1999. Startseite für das
Projekt in Obsidian: Vault ist der ganze Checkout, `DerComputerladen/`.

## Das Spiel

- [Game Design Document](docs/game_design.md): was das Spiel ist
- [Spielbeschreibung](docs/spielbeschreibung/README.md): der Stand im Code, nach Systemen, mit
  [Glossar](docs/spielbeschreibung/glossar.md)
- [game_bible](docs/game_bible/Der%20Computerladen.md): Spielinhalt, Komponenten, Preise, Prospekte
- [Ideensammlung](docs/Ideensammlung.md): lose Ideen, unverbindlich

## Features

- [Features](docs/features/Features.md): Systemliste 01–11 und Index der Features
- [Feature-Ideen](docs/features/Feature_Ideas.md): Backlog mit reservierten IDs
- Specs, je Feature Spec, Plan, Aufgaben und Lernnotizen:
  - [001 Hauptmenü](specs/001-hauptmenue/spec.md)
  - [002 Zeitleisten-Werkstatt](specs/002-zeitleisten-werkstatt/spec.md)
  - [003 Schwierigkeitsgrade](specs/003-schwierigkeitsgrade/spec.md)
  - [004 Neues Spiel](specs/004-neues-spiel/spec.md)
  - [005 Communicator](specs/005-communicator/spec.md)
  - [006 Easter Egg: Space Invaders](specs/006-easter-egg-space-invaders/spec.md)
  - [007 Build, Export und Selbsttest](specs/007-build-export-selbsttest/spec.md)
  - [008 Architektur](specs/008-architektur/spec.md)
  - [009 Renderer Compatibility](specs/009-renderer-compatibility/spec.md)
- [Entscheidungen](docs/entscheidungen/renderer.md): Renderer

## Aussehen und Bilder

- [Style-Guide](docs/style-guide/README.md): verbindlich für alles Sichtbare und Hörbare, mit
  [Tokens](docs/style-guide/tokens.md), [Sprache](docs/style-guide/sprache.md),
  [Ton](docs/style-guide/ton.md), [Werkzeuge](docs/style-guide/werkzeuge.md) und
  [Leonardo-Workflow](docs/style-guide/leonardo-workflow.md)
- [Bildkatalog](docs/art/bildkatalog.md): alle Bilder nach Inhalt, mit festen Prompt-Bausteinen
- [Prompt-Log](docs/art/leonardo/prompt-log.md): jedes freigegebene Bild der Reihe nach
- [Cover-Entwurf](docs/art/entwuerfe/cover.md)

## Arbeitsweise

- [Arbeitsweise mit KI](docs/ki_workflow/README.md): Abläufe, Prüfungen, Erfahrungen
- [Architektur-Leitfaden](docs/architektur-leitfaden.md): Regeln `AR-NN`
- [Offene Punkte](docs/offene-punkte.md): offene Fragen und Claudes eigene Entscheidungen
- [Tagebuch](docs/tagebuch/README.md): wichtige Entscheidungen seit Projektbeginn
- [Recherche](docs/recherche/architektur-quellen.md): Quellen zur Architektur,
  [Navigation des Taschengeräts](docs/recherche/navigation-taschengeraet.md)
- [CLAUDE.md](CLAUDE.md): Arbeitsanweisungen für Claude
- Nicht in Obsidian, weil Obsidian Ordner mit Punkt nicht zeigt: die Verfassung
  `.specify/memory/constitution.md`, die Skills unter `.claude/skills/` und die Agents unter
  `.claude/agents/`. Sie liegen im Repo und sind im Editor oder auf GitHub zu lesen.

## Zum Vault

- Ausgeblendet über Einstellungen → Dateien und Links → Ausgeschlossene Dateien: `src/`, `build/`,
  `godot_referenz/`, `res/`. Sie liegen noch im Dateibaum, fehlen aber in Suche, Graph und
  Schnellwechsler.
- Neue Links entstehen als Markdown-Links mit relativem Pfad, wie im übrigen Repo.
- `docs/game_bible/` ist zusätzlich ein eigener Vault mit eigenen Einstellungen und Wikilinks.
  Beide vertragen sich: Im großen Vault ist sie ein Ordner, ihr `.obsidian/` bleibt unsichtbar,
  und ihre Wikilinks lösen sich auch hier auf. Eine Datei nicht gleichzeitig in beiden Vaults
  bearbeiten. Neue Links in der game_bible besser in ihrem eigenen Vault setzen, damit sie
  Wikilinks bleiben.
- Versioniert sind die Einstellungen unter `.obsidian/`, nicht `workspace.json`, der Zustand von
  Fenstern und Tabs.
