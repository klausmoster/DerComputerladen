# DerComputerladen

Wirtschafts-Simulationsspiel, das in den 1990ern in Deutschland spielt. Die
Spieldaten (CPUs, Komponenten, Preise …) werden in der **game_bible** unter
`docs/game_bible/` gepflegt.

## Skills

Skills sind wiederverwendbare Claude-Code-Arbeitsanweisungen, die per Slash-Befehl
(`/<skill-name>`) aufgerufen werden. Alle Projektskills liegen zentral unter
`.claude/skills/<name>/SKILL.md` im Repo-Root und sind damit repo-weit verfügbar,
egal aus welchem Verzeichnis Claude Code gestartet wird. **Namenskonvention:**
Projekt-Skills tragen das Präfix `dcl-` (Der ComputerLaden) — das vermeidet
Kollisionen mit eingebauten/globalen Skills und gruppiert sie im Slash-Menü
(`/dcl…`).

| Skill | Aufruf | Zweck | Ort |
|---|---|---|---|
| Komponenten-Doc füllen | `/dcl-komponente` | Beliebige PC-Komponente der game_bible mit Daten befüllen (template-gesteuert) | `.claude/skills/dcl-komponente/` |

### `dcl-komponente` — Komponenten-Doc füllen

**Aufruf:** `/dcl-komponente`
**Ort:** `.claude/skills/dcl-komponente/SKILL.md`

#### Was er macht
Recherchiert und befüllt eine **beliebige** PC-Komponenten-Doc der game_bible
(`docs/game_bible/`) mit Daten — generisch für jeden Komponententyp (CPU,
Tastatur, …). Der Skill durchforstet alle Templates unter `Templates/`, fragt
welches genutzt werden soll, und füllt dann das Frontmatter sowie die
Spiel-Inhalte. **Welche Felder es gibt und wo die Datei am Ende liegt, steht im
jeweiligen Template — nicht im Skill.** Das Erzeugen der lesbaren Tabellen
(`regenerate_tables.py`) ist ein separater Schritt und nicht Teil des Skills.

#### Ablauf
1. **Template wählen** — alle `Templates/TEMPLATE_*.md` werden gelistet, der
   `typ` aus dem `SKILL-ROUTING`-Block je Template angezeigt, du wählst eins.
2. **Komponente wählen** — neue anlegen oder vorhandene Datei ergänzen/korrigieren.
   Bei neuer Komponente wird der vollständige Name erfragt; der Zielpfad ergibt
   sich aus dem Routing-Block des Templates und wird bestätigt.
3. **Recherche & Quellen-Abgleich** — zuerst feste deutsche Hardware-Fachquellen
   lesen (Wikipedia DE, heise/c't-Archiv, ComputerBase, PC-Welt, Hardwareluxx,
   Planet3DNow), **dann** allgemeine Websuche. Jeder Wert wird über mind. zwei
   unabhängige Quellen gegengeprüft; Widersprüche werden als „geschätzt / Quellen
   uneinig" markiert. Keine ungeprüften Werte aus dem Gedächtnis.
4. **Frontmatter-Felder füllen** — exakt die Felder, die das gewählte Template
   vorgibt (z.B. `grunddaten_*`, `technik_*`, `markt`, `preise_*`, `handel`,
   `lager`, `kompatibilität`, `wettbewerb`, `tags`); Preise als `von`/`bis`-Range.
5. **Spiel-Inhalte schreiben** — die `## +`-Abschnitte des Templates (z.B.
   Datenblatt, Beschreibung, Zeitungsartikel, Werbung, Hintergrund & Quellen).
6. **Verlinken** (nur bei neuer Komponente) — Wikilink in der `index_seite` des
   Templates, falls dort genannt.

#### Template-Routing
Jedes Template trägt im Body einen `SKILL-ROUTING`-Kommentarblock, der dem Skill
sagt, was es ist und wohin die Datei gehört:
```
<!-- SKILL-ROUTING (vom /dcl-komponente-Skill gelesen; NICHT in die fertige Datei kopieren)
typ: CPU
zielordner: CPUs/<hersteller>
dateiname: <name>
index_seite: CPUs/<hersteller>/<hersteller>.md
-->
```
Eine **neue Komponentenart** unterstützt man, indem man ein neues
`Templates/TEMPLATE_<TYP>.md` mit gewünschten Feldern, `## +`-Abschnitten und
diesem Routing-Block anlegt — der Skill findet es dann automatisch.

#### Datenregeln (wichtig)
- Strukturierte Daten **nur** ins Frontmatter; Skalare als `kategorie_feld`.
- Preise als Range: je Eintrag `von`/`bis` als **Zahl in DM** (kein "DM", kein
  Tausenderpunkt). Range = typische Spanne günstig…teuer.
- Freitext **nur** unter `## +`-Überschriften.
- Bezug: deutscher Markt, 1990er, DM, Datumsformat `JJJJ-MM`. Unsicheres plausibel
  schätzen und im Freitext als „geschätzt" kennzeichnen.

#### Wann nutzen
Wenn eine PC-Komponente (CPU, Tastatur, …) angelegt, befüllt, recherchiert oder
vervollständigt werden soll.
