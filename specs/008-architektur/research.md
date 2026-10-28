# Recherche: Godot- und Spielarchitektur mit Prüf-Agent

Entscheidungen aus `/speckit-plan` zu [spec.md](spec.md), jede mit Grund und verworfenen
Alternativen (Verfassung, Grundsatz III). Die Verträge unter [contracts/](contracts/) setzen sie um,
das Datenmodell steht in [data-model.md](data-model.md). Die Quellen zu Godot, Nystrom, SCUMM und
Factorio stehen in [`docs/recherche/architektur-quellen.md`](../../docs/recherche/architektur-quellen.md);
R12 fasst zusammen, was daraus für den Leitfaden folgt.

Wer entschieden hat, steht an jeder Entscheidung. „Claude, 2026-10-28“ heißt: eigene Festlegung,
eingetragen in `docs/offene-punkte.md`, Abschnitt „Feature 008, Plan“; Klaus kann sie bei der
Checkliste oder jeder Abnahme ändern.

Grundlage ist der Stand von `main` nach Feature 006 (Commit `528442e`). Gemessen am 2026-10-28
in `src/` ohne `addons/` und `test/`: 58 Skripte mit 19.662 Zeilen, 14 Szenen, 37 Signale, vier
Autoloads. 33 Skripte sind `RefCounted`, eins ist eine `Resource` (`MenuEntry`), vier sind die
Autoloads; dazu 18 Bausteine der Oberfläche, ein `StyleBox` und die Textausgabe als `SceneTree`. Autoloads werden fast nur über eine Naht erreicht,
die ein Test ersetzen kann (`session if session != null else GameSession`); ein direkter Griff nach
oben steht in `werkstatt.gd` (`/root/GameWindow`).

## R1 Der Leitfaden ist eine Markdown-Datei mit festen Regelnummern

**Entscheidung:** Der Leitfaden liegt in `docs/architektur-leitfaden.md`, eine Datei. Jede Regel
hat eine feste Nummer `AR-NN` (Architektur-Regel), die nie neu vergeben wird, und eine Überschrift
mit ihrem Kurznamen, etwa „AR-02 Signal nach oben, Aufruf nach unten“. Die Teile jeder Regel
stehen in fester Reihenfolge als Liste (Vertrag [leitfaden.md](contracts/leitfaden.md)). Gegliedert
ist er in Godot-Prinzipien, Muster, Schichten, Ausnahmen und Geschichte (Claude, 2026-10-28).

**Grund:** Im Repo liest der Prüfer ihn selbst, Git zeigt jede Änderung, und Klaus liest ihn in
Obsidian oder auf GitHub. Feste Nummern lassen Befunde, Kommentare im Code und Tests auf eine
Regel zeigen, auch wenn sich ihr Wortlaut ändert. Eine Datei reicht für die erwarteten 20 bis 30
Regeln; der Prüfer liest sie bei jedem Lauf ganz.

**Verworfen:**
- Ein Ordner mit einer Datei je Regel: mehr Dateien, ohne dass jemand nur eine Regel liest.
- Ein Artifact wie der Style-Guide: Der Prüfer könnte ihn nicht selbst lesen
  (`ki_pruefung.md`, „Maßstäbe“).
- Nummern je Gruppe wie „G1“: „G-02“ und „G-03“ heißen schon die Gehäuse des Communicators.

## R2 Klaus entscheidet jede Regel, in einer Liste statt in vielen Einzelfragen

**Entscheidung:** Claude schreibt den Leitfaden als Entwurf. Jede Regel trägt zunächst den Stand
„Vorschlag“. Klaus geht ihn durch und entscheidet je Regel: übernehmen, ändern oder streichen.
Einzeln als Auswahl fragt Claude nur dort, wo es eine echte Alternative gibt, etwa ob ein neues
System ein Autoload sein darf. Danach steht bei jeder Regel „gilt seit 2026-…, Klaus“. Gestrichenes
wandert mit Grund in den Abschnitt „Geschichte“ (Claude, 2026-10-28).

**Grund:** Bei 20 bis 30 Regeln wären 30 Einzelfragen mühsam, und die meisten Regeln folgen direkt
aus Klaus' Antworten in der Spec. FR-007 verlangt nur, dass jede Regel entschieden ist.

**Verworfen:** jede Regel als eigene Frage; den Leitfaden ohne Durchsicht gelten lassen.

## R3 Begründete Ausnahmen stehen an der Stelle und im Leitfaden

**Entscheidung:** Eine Ausnahme hat zwei Teile:
1. einen Kommentar an der Stelle: `# Ausnahme AR-NN: <Grund> (Klaus, JJJJ-MM-TT)`;
2. eine Zeile in der Tabelle „Ausnahmen“ des Leitfadens: Ort, Regel, Grund, wer freigab.

In einem Plan steht eine geplante Ausnahme unter „Ausnahmen vom Leitfaden“; Klaus gibt sie mit dem
Plan frei. Der Prüfer führt eine Stelle nur dann als begründete Ausnahme, wenn beide Teile da sind;
fehlt einer, ist es ein Befund (Claude, 2026-10-28).

**Grund:** Der Kommentar erklärt die Stelle dem, der sie liest, wie heute `@warning_ignore` mit
Grund. Die Tabelle zeigt alle Ausnahmen auf einen Blick; wachsen sie bei einer Regel, ist die Regel
zu prüfen. Die Tests lesen dieselben Stellen über ihre Liste `ERLAUBT` (R6).

**Verworfen:** nur der Kommentar (keine Übersicht); nur die Tabelle (die Stelle selbst schweigt).

## R4 Der Prüfer ist ein Subagent wie Stil- und Text-Prüfer, mit drei Aufträgen

**Entscheidung:** `.claude/agents/architektur-pruefer.md` mit `tools: Read, Grep, Glob` und
`model: inherit`. Anders als die beiden anderen liest er seinen Maßstab selbst. Claude gibt ihm
einen von drei Aufträgen:
- **Phase:** die geänderten Skripte und Szenen einer Phase, mit dem Vertrag des Features;
- **Plan:** `plan.md`, `research.md`, `data-model.md` und `contracts/` bei `/speckit-checklist`;
- **Bestand:** eine Liste von Dateien, ohne Diff.

Der Bericht hat die Abschnitte der anderen Prüfer und zusätzlich „Begründete Ausnahmen“ (Vertrag
[architektur-pruefer.md](contracts/architektur-pruefer.md); Claude, 2026-10-28).

**Grund:** Gleiche Form wie die bewährten Prüfer, damit `/dcl-phasenpruefung` sie gleich behandelt
(`ki_pruefung.md`, „Die Prüfer“). `Grep` braucht er, um zu sehen, wer eine Klasse oder ein Signal
nutzt; nur so beurteilt er „wer wen kennt“. Ein neuer Agent steht erst in einer neuen Sitzung
bereit; bis dahin nimmt Claude einen allgemeinen Agent, der die Datei liest (`ki_pruefung.md`,
„Erfahrungen“).

**Verworfen:**
- ein Skill statt eines Agents: Ein Skill läuft in Claudes Kontext und hätte keinen frischen Blick
  (`ki_pruefung.md`, „Bausteine“).
- `model: opus` fest: Die anderen Prüfer nehmen das Modell der Sitzung; nachmessen statt raten.

## R5 Die Bestandsprüfung läuft in drei Teilen gleichzeitig

**Entscheidung:** Rund 19.700 Zeilen passen nicht verlässlich in einen Lauf. Der Prüfer läuft
dreimal gleichzeitig: **Kern** (`src/core/`), **Spiel und Oberfläche** (`src/scenes/`, `src/ui/`)
und **Werkstatt** (`src/tools/werkstatt/`). Jeder Lauf bekommt seine Dateiliste und darf daneben
alles lesen, was er braucht. Tests unter `src/test/` liest er nur für die Frage, ob ein Kern ohne
Szene getestet wird; `src/addons/` nicht. Claude führt die drei Berichte zum Bestandsbericht
`specs/008-architektur/bestandsbericht.md` zusammen, prüft jede Abweichung nach und zählt
(Claude, 2026-10-28).

**Grund:** Die Werkstatt allein hat rund 9.700 Zeilen. Drei Läufe nach Schicht halten den Kontext
klein und decken sich mit den Grenzen im Code. SC-003 verlangt nur, dass jede Datei genannt wird;
das prüft Claude am zusammengeführten Bericht gegen `find`.

**Verworfen:** ein einziger Lauf (Kontext zu groß, Auslassungen wahrscheinlich); ein Lauf je Datei
(60 Läufe, teuer, kein Blick auf „wer wen kennt“).

## R6 Messbare Regeln werden Tests in einer Datei

**Entscheidung:** `src/test/test_architektur.gd` prüft, was sich zählen lässt (Vertrag
[architektur-tests.md](contracts/architektur-tests.md)):
1. **Kerne ohne Node:** Jedes Skript in `core/timeline/`, `core/save/` und in der Liste `KERNE` des
   Tests erbt von `RefCounted` oder `Resource` und nennt weder ein Autoload noch `get_tree()`.
2. **Genau diese Autoloads:** Die Autoloads in `project.godot` sind die aus dem Leitfaden, in dieser
   Reihenfolge.
3. **Kein Weg nach oben:** Kein Skript und keine Szene greift über `../` oder `/root/` nach oben,
   außer an Stellen in `ERLAUBT`.

Jede Liste `ERLAUBT` nennt je Eintrag Datei, Regel und Grund; ein eigener Test meldet Einträge, die
es nicht mehr gibt, wie in `test_texte.gd`. Abweichungen, die Phase 5 behebt, stehen bis dahin in
einer zweiten Liste `BIS_BEHEBUNG`, die mit Phase 5 leer wird. Jede Prüfung bekommt eine Fehlerprobe
(Claude, 2026-10-28; welche Regeln messbar sind, entscheidet Klaus mit dem Leitfaden).

**Grund:** Grundsatz 4 in `ki_pruefung.md`: Was messbar ist, prüft ein Test bei jedem Lauf, billiger
und sicherer als ein Prüfer. Die Prüffunktionen nehmen einen Pfad oder Text, damit die Fehlerprobe
mit denselben Funktionen an Kopien außerhalb des Repos läuft, wie bei `test_bilder.gd`.

**Verworfen:**
- „Signal nach oben“ als Test, etwa „kein Aufruf auf den Eltern-Node“: Ob ein Aufruf nach oben
  oder unten geht, hängt von der Szene ab, nicht vom Text; das bleibt Urteil des Prüfers.
- Ein Werkzeug außerhalb von Godot, etwa ein Python-Skript: Die Tests laufen ohnehin mit GUT, und
  eine zweite Prüfkette müsste jemand eigens starten.

## R7 Die Tests kommen nach der Bestandsprüfung

**Entscheidung:** Reihenfolge Leitfaden → Prüfer und Arbeitsweise → Bestandsprüfung → Tests →
Behebung (Claude, 2026-10-28).

**Grund:** Erst nach dem Bestandsbericht weiß man, welche Stellen Ausnahmen sind und welche behoben
werden. Kämen die Tests vorher, wären sie rot oder ihre Listen geraten. Danach entstehen sie mit
richtigen Listen grün, und die Behebung leert `BIS_BEHEBUNG` sichtbar Eintrag für Eintrag.

**Verworfen:** Tests zuerst (rot oder geratene Listen); Tests nach der Behebung (die Behebung liefe
ohne Netz).

## R8 Die Fehlerprobe des Prüfers liegt im Ordner des Features

**Entscheidung:** Für SC-002 legt Claude unter `specs/008-architektur/fehlerprobe/` kleine Skripte
und Szenen als Text an, eine Datei je Godot-Prinzip. Jede enthält genau einen Verstoß und daneben
eine ähnliche, erlaubte Stelle. Eine Liste `fehlerprobe/LOESUNG.md` nennt Verstöße und erlaubte
Stellen; der Prüfer bekommt sie nicht. Die Dateien liegen außerhalb von `src/`, damit Godot sie nicht
lädt (Claude, 2026-10-28).

**Grund:** Wiederholbar: Wird der Prüfer später nachgeschärft, läuft dieselbe Probe noch einmal.
Die erlaubte Stelle daneben zeigt, ob der Prüfer nach Regel oder nach Geschmack urteilt (FR-014).

**Verworfen:** Verstöße in eine Kopie des echten Codes einbauen: aufwendiger, und die Kopie läge
irgendwo, wo man sie später nicht wiederfindet.

## R9 Die Behebung bleibt verhaltensgleich und wird gemessen

**Entscheidung:** Vor Phase 5 hält Claude fest: Testzahl, Ausgabe der Startprobe, die Fahrpläne aus
`fahrplan_ausgabe.gd` für die Seeds 1, 4711 und 99999 und einen Spielstand. Nach der Phase wird
alles verglichen: Fahrpläne bytegleich, Startprobe still, Tests zweimal grün mit derselben Zahl
plus den neuen, der Spielstand lädt. In 008 wird nur behoben, was ein System betrifft
(Spec, Clarify); was mehrere Systeme umbaut, schreibt Claude als Eintrag nach
`docs/features/Feature_Ideas.md`. Wird die Phase groß, teilt sie sich in zwei Teile (ki_dev,
Punkt 4). Die Aufgaben der Phase entstehen erst nach Klaus' Entscheidungen zum Bestandsbericht
(Claude, 2026-10-28).

**Grund:** „Verhalten unverändert“ (FR-027) lässt sich nur so belegen. Die Fahrpläne sind die
empfindlichste feste Größe des Projekts.

**Verworfen:** die Aufgaben schon jetzt raten.

## R10 Wo der Prüfer in der Arbeitsweise eingebaut wird

**Entscheidung (Claude, 2026-10-28):**

| Datei | Änderung |
|---|---|
| `docs/ki_workflow/ki_pruefung.md` | dritter Prüfer in „Die Prüfer“, „Wer prüft was“, Ablauf und „Anbindung an Spec Kit“; „Nicht vorgesehen: ein eigener Code-Prüfer“ bleibt mit „bis 2026-10-28“ und dem Grund für die Änderung sichtbar; „Maßstäbe“ um den Leitfaden; Zeilen im „Nachmessen“ |
| `docs/ki_workflow/ki_dev.md` | Punkt 8 und das Schaubild „Ablauf je Feature“: Phasen mit Code bekommen den Architektur-Prüfer |
| `docs/ki_workflow/README.md` | Schaubild „Wer macht was“ |
| `.claude/skills/dcl-phasenpruefung/SKILL.md` | Auslöser auch Code; dritter Prüfer mit Auftrag; bei der Checkliste auch Plan und Vertrag |
| `.specify/templates/overrides/tasks-template.md` | „Phasenprüfung … nur wenn die Phase Sichtbares, Texte oder Code ändert“ |
| `.claude/agents/godot-entwickler.md` | den Leitfaden vor jeder Aufgabe lesen (FR-022) |
| `.specify/memory/constitution.md` | Grundsatz VI über `/speckit-constitution`, Wortlaut beschließt Klaus (FR-023) |
| `CLAUDE.md` | Zeile für den Leitfaden in der Tabelle „Aufbau“, nur mit Klaus' OK |

Die Vorlagen von Spec Kit selbst und die Skills `speckit-*` bleiben unverändert; ein Update spielt sie
neu ein (`ki_pruefung.md`, „Anbindung an Spec Kit“). Den Abschnitt „Prüfer je Phase“ schreibt Claude
weiter nach `ki_pruefung.md` in den Plan.

**Grund:** Die Stellen, an denen Stil- und Text-Prüfer heute stehen. FR-021 verlangt, dass der Prüfer
von selbst eingeplant wird; das leisten die Vorlage für die Aufgaben, der Skill und die Verfassung,
die `/speckit-plan` und `/speckit-analyze` lesen.

**Verworfen:** die Skills `speckit-plan` oder `speckit-checklist` ändern: Ein Update von Spec Kit
überschreibt sie.

## R11 Für 008 selbst gibt es keine Planprüfung durch den Architektur-Prüfer

**Entscheidung:** Bei der Checkliste von 008 gibt es den Prüfer noch nicht; er entsteht erst in
Phase 2. Stil- und Text-Prüfer laufen bei der Checkliste von 008 nicht, weil die Spec keine
Wortlaute und keine Oberfläche festlegt. Der Architektur-Prüfer prüft zum ersten Mal echt in
Phase 4 (Tests) und Phase 5 (Behebung) (Claude, 2026-10-28).

**Grund:** Ein Prüfer, der sich selbst einführt, kann seinen eigenen Plan nicht prüfen. Die
Fehlerprobe und die Bestandsprüfung ersetzen hier den Probelauf.

**Verworfen:** den Plan von 008 nach Phase 2 nachträglich prüfen lassen: Er beschreibt dann schon
Gebautes.

## R12 Was aus den Quellen für den Leitfaden folgt

**Grundlage:** [`docs/recherche/architektur-quellen.md`](../../docs/recherche/architektur-quellen.md),
2026-10-28: die Best Practices der Godot-Doku 4.7, sieben der 19 Kapitel von Nystrom im Volltext
(die übrigen nach ihrer bekannten Absicht, dort vermerkt), Ron Gilberts Blogs zu SCUMM, Thimbleweed
Park und Delores sowie die Factorio Friday Facts #36, #47, #70, #76, #108, #188, #315 und #340.

**Entscheidung (Claude, 2026-10-28), als Vorlage für den Entwurf in Phase 1:**

1. **Muster im Leitfaden:** Beobachter (= Signale, AR-02), Komponente (= Szenen-Komposition,
   AR-05), Typ-Objekt (= Daten als Resources, AR-04), Befehl (Eingriffe, später Spielerhandlungen;
   Spielstand = Seed + Grad + Eingriffe), Zustand (Seiten, später Kunden), Spielschleife mit festem
   Schritt (Spieluhr, Spielkern des Easter Eggs) und die Aktualisierungsmethode nur als Tagesschritt.
   Singleton und Dienstlocator stehen als Warnung bei AR-03. Später, mit dem passenden System:
   Ereigniswarteschlange, Prototyp, Unterklassen-Sandkasten, Schmutzflagge, Doppelpuffer. Nicht im
   Leitfaden: Bytecode, Datenlokalität, Objektpool, räumliche Aufteilung; sie lösen Probleme, die
   ein Spiel dieser Größe nicht hat (FR-003).
2. **AR-01 Kern ohne Node** steht als bewusst strenger als die Godot-Doku da, die Logik im
   Wurzelskript einer Szene für normal hält. Grund: wiederholbare Läufe und Tests ohne Szenenbaum.
   Dazu: Ein Kern bekommt Zeit und Seed von außen und greift nie auf den Szenenbaum oder globalen
   Zufall zu.
3. **AR-02** trägt den Merksatz „Call down, signal up“ (KidsCanCode); die offizielle Doku sagt es
   sinngemäß. Ein allgemeiner Event-Bus als Autoload, wie ihn GDQuest vorschlägt, wird ausdrücklich
   verworfen; das deckt sich mit AR-03 und Nystroms Warnung.
4. **AR-03** übernimmt das Kriterium der Doku: Ein Autoload verwaltet eigene Daten und ändert keine
   fremden. Strenger als die Doku ist die feste Liste: Jedes neue Autoload braucht Klaus' Freigabe;
   Hilfsfunktionen werden `static func`.
5. **AR-04** gilt für gepflegte Spieldaten; geladene Resources sind nur lesbar, weil Godot sie teilt.
   Spielstände sind ausgenommen (eigenes Format mit Version, wie Doku und Gilbert).
6. **Schichten:** Adventure nach Gilbert: Engine ohne Inhalt, Räume und Dialoge als Daten, Abläufe
   linear mit `await`, gespeichert nur an Ruhepunkten. Wirtschaft nach Factorio: fester Tick aus der
   Spieluhr, Zufall nur aus dem Seed, Geld als ganze Zahl, Simulation und Darstellung getrennt.
   Oberfläche: liest Zustand, meldet Eingriffe, ändert Kerndaten nie direkt.

**Für Klaus in Phase 1, je als Auswahl:**
- Bleibt der Ereigniskatalog JSON, weil die Werkstatt ihn pflegt und die Verfassung (Grundsatz V)
  ihn als Datei vorsieht, oder wird er eine Resource? Empfehlung: bleibt JSON, als begründete
  Ausnahme zu AR-04.
- Wird die Probe „speichern, laden, vergleichen“ (Factorio, „heavy mode“) ein vierter Test in
  Phase 4? Sie misst die Regel „Wiederholbar“ direkt. Aufwand: eine Aufgabe mehr für den Agent.
- Ob GDScript auf Windows, macOS und Linux mit Fließkomma bitgleich rechnet, ist nicht geprüft.
  Das betrifft die Wirtschaft, nicht 008; es kommt als offener Punkt in `docs/offene-punkte.md`.

**Grund:** Die Spec verlangt nur Muster mit Bezug zum Spiel (FR-003) und Regeln mit Quelle (FR-005);
die Recherche liefert beides. Wo die Doku weicher ist als Klaus' Prinzipien, nennt der Leitfaden den
Unterschied, damit der Prüfer nicht mit der Doku gegen den Leitfaden argumentiert (Spec, Edge Cases).

**Verworfen:** alle 19 Muster aufnehmen (der Prüfer bekäme Regeln ohne Gegenstand); die Godot-Doku
als alleinigen Maßstab (sie erlaubt mehr Autoloads und Logik in Szenen, als Klaus will).
