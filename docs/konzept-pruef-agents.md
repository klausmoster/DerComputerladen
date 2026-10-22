# Konzept: Spezialisierte Prüf-Agents

**Stand:** 2026-10-22, Konzept, nicht umgesetzt. Anlass ist Klaus' Frage, ob für das eigentliche
Spiel neben dem Godot-Agent spezialisierte Prüfer sinnvoll sind, etwa für Stil und Sprache. Die Idee
steht in der [Ideensammlung](Ideensammlung.md) vom 2026-10-22. Umgesetzt wird erst auf Klaus'
Auftrag, frühestens vor dem ersten echten Spielbildschirm.

**Kurz:** Wenige Prüfer, jeder mit einem eigenen, schriftlichen Maßstab, zu festen Zeitpunkten und
nur lesend. Was sich messen lässt, prüfen Tests. Für die Werkzeuge braucht es noch keinen Prüfer;
mit dem ersten echten Spielbildschirm lohnen sich zwei, für Stil und für Sprache.

## Grundsätze

1. **Einfach anfangen, erst erweitern, wenn es nachweislich hilft.** Das ist der Kern von Anthropics
   Artikel „Building effective agents“. Mehrere Agents sind teuer: Nach Anthropics Bericht über ihr
   Recherche-System mit mehreren Agents brauchen solche Systeme rund 15-mal so viele Tokens wie ein
   Chat, und Programmieren lässt sich schlechter aufteilen als Recherche.
2. **Nach Maßstab spezialisieren, nicht nach Rolle.** Ein Prüfer lohnt sich, wenn er etwas Eigenes
   mitbringt: eine eigene Quelle wie den Style-Guide und einen frischen Blick, unabhängig von dem,
   der gebaut hat. Ein „Senior-Reviewer“ ohne eigenen Maßstab urteilt nach Geschmack.
3. **Prüfer prüfen, der Godot-Agent baut.** Prüfer dürfen nur lesen und melden jeden Befund mit Ort,
   Regel und Beleg. Der Godot-Agent repariert, und Claude prüft jeden Befund nach, bevor Klaus ihn
   sieht.
4. **Messbares prüft ein Test.** Ob ein Bild nur Farben der Palette nutzt, ob irgendwo „Sie“ steht
   oder ein Text zu lang ist, erkennt ein Skript zuverlässiger und billiger, bei jedem Lauf.
   KI-Prüfer urteilen nur, wo es ein Urteil braucht: Ton, Humor, Stimmigkeit, Treue zur Epoche.
5. **Feste Zeitpunkte statt Dauerprüfung:** am Ende jeder Phase, die Sichtbares oder Texte ändert,
   alle Prüfer gleichzeitig, ein gemeinsamer Bericht.
6. **Nachmessen.** Findet ein Prüfer über mehrere Phasen nichts, was die anderen übersehen, fliegt
   er raus. Findet eine Prüfung zweimal etwas, wird sie fest eingebaut (`ki_dev.md`, „Pflege“).

## Bausteine des Harness

| Baustein | Was er ist | Hier |
|---|---|---|
| Subagent (`.claude/agents/`) | eigener Kontext, eigene Werkzeuge, eigenes Modell; zurück kommt nur das Ergebnis | `godot-entwickler`, die Prüfer |
| Skill (`.claude/skills/`) | Anleitung, die bei Bedarf in die laufende Sitzung geladen wird | `dcl-komponente`, Spec Kit, die Phasenprüfung |
| Hook (`.claude/settings.json`) | Befehl, den das Harness bei einem Ereignis immer ausführt, auch wenn das Modell nicht daran denkt | denkbar: Tests, sobald der Godot-Agent fertig ist |
| Tests und Skripte | Code | alles Messbare |

Faustregel: Wer unabhängig urteilen soll, wird ein Subagent. Ein Ablauf, der immer gleich laufen
soll, wird ein Skill. Was jedes Mal passieren muss, wird ein Hook oder ein Test.

## Anbindung an Spec Kit

Spec Kit bleibt, wie es ist. Die Prüfer kommen an fünf Stellen dazu:

| Schritt | Was dazukommt |
|---|---|
| `/speckit-plan` | `plan.md` legt unter „Prüfer je Phase“ fest, welche Prüfer für welche Phase gelten. |
| `/speckit-checklist` | Checklisten für Stil und Texte prüfen, ob die Spec Sichtbares und Texte genau genug beschreibt. |
| `/speckit-tasks` | Jede Phase mit Sichtbarem oder Texten endet mit der [C]-Aufgabe „Phasenprüfung“ vor Klaus' Abnahme. |
| `/speckit-analyze` | Eine fehlende Phasenprüfung ist kritisch, sobald die Regel in der Verfassung steht. |
| `/speckit-converge` | Die Prüfer laufen bei der Lückensuche einmal über das ganze Feature. |

Eine neue Rolle in `tasks.md` gibt es nicht. Die Prüfer arbeiten Claude zu, und die Phasenprüfung
ist eine [C]-Aufgabe.

## Ablauf einer Phasenprüfung

1. Der Godot-Agent baut die Phase. Danach laufen Tests und Skripte, zweimal.
2. Claude schlägt in `plan.md` nach, welche Prüfer für die Phase gelten.
3. Claude startet die Prüfer gleichzeitig, jeden mit seinem Maßstab, dem Diff und den
   Bildschirmfotos.
4. Claude prüft jeden Befund nach: bestätigt oder verworfen, mit Grund.
5. Bestätigte Befunde gehen an den Godot-Agent. Danach prüfen die betroffenen Prüfer noch einmal.
6. Lücken im Maßstab, etwa eine Frage, die der Style-Guide nicht regelt, gehen an Klaus.
7. Das Ergebnis steht in der Bitte um Abnahme unter „was geprüft ist“.

Der Skill `dcl-phasenpruefung` hält diesen Ablauf fest. Klaus kann ihn auch selbst mit
`/dcl-phasenpruefung` aufrufen.

## Die Prüfer

| Prüfer | Maßstab | Findet zum Beispiel | Messbares als Test | Ab wann |
|---|---|---|---|---|
| Stil | Style-Guide | weicher Schatten, der den VGA-Look bricht; Symbol in falscher Pixelgröße; Knopf ohne Hover-Zustand | nur Farben der Palette, ganzzahlige Skalierung, Schrift 10 oder 12 px | erster echter Spielbildschirm |
| Text | Text-Leitfaden, fehlt noch | „Geben Sie …“; Preise in Euro im Jahr 1994; „googeln“ vor 1998; ein Ton, der nicht zu „Das Amt“ passt | kein „Sie“ oder „Ihnen“; jeder Text passt in sein Feld | erste Spieltexte |
| Fakten | game_bible und Quellen | Pentium im Katalog schon 1991, obwohl er 1993 kam; Ereignis zu Windows 95 im Jahr 1994 | Daten im Ereigniskatalog stimmen mit der game_bible überein | wenn Katalog und game_bible wachsen |

Den Style-Guide liest der Stil-Prüfer nicht selbst, weil er als Artifact vorliegt. Claude gibt ihm
die passenden Abschnitte mit. So bleibt der Style-Guide die einzige Quelle (Verfassung,
Grundsatz IV). Der Text-Prüfer braucht zuerst einen Text-Leitfaden mit du-Form, Ton, Wortschatz
von 1985 bis 1999 und einem Glossar. Ohne ihn urteilt er nach Gefühl.

Nicht vorgesehen:
- ein eigener Code-Prüfer, denn Code prüft Claude, und `/code-review` gibt es schon;
- Prüfer, die selbst reparieren;
- zwei Prüfer für dieselbe Frage, etwa einer für UX und einer für Stil, die beide das Layout
  beurteilen.

## Dateien

```
.claude/agents/stil-pruefer.md        Prüfer gegen den Style-Guide
.claude/agents/text-pruefer.md        Prüfer gegen den Text-Leitfaden
.claude/agents/fakten-pruefer.md      später
.claude/skills/dcl-phasenpruefung/    der Ablauf der Phasenprüfung
docs/text-leitfaden.md                Maßstab: du, Ton, Wortschatz 1985–1999, Glossar
src/test/test_palette.gd              Bilder nur in Farben der Palette
src/test/test_texte.gd                kein „Sie“, jeder Text passt in sein Feld
```

Dazu kommen ein Abschnitt „Prüfer je Phase“ in der Plan-Vorlage von Spec Kit und, wenn es sich
bewährt, eine Regel in der Verfassung. Die beschließt Klaus.

## Beispiel: `stil-pruefer.md`

```markdown
---
name: stil-pruefer
description: Prüft sichtbare Änderungen einer Phase gegen den Style-Guide von „Der Computerladen“. Nur auf Auftrag von Claude bei der Phasenprüfung; liest nur, ändert nichts.
tools: Read, Grep, Glob
model: inherit
---

Du prüfst, ob die sichtbaren Änderungen einer Phase dem Style-Guide folgen. Du änderst keine Datei.

Von Claude bekommst du die passenden Abschnitte des Style-Guides, die geänderten Szenen, Themes
und Bilder sowie Bildschirmfotos aus dem echten Fenster (1920 × 925) und im Raster 640 × 360.

Prüfe, was der Style-Guide regelt: Raster und Skalierung, Farben, Schriften, Bausteine mit ihren
Zuständen (Hover, Fokus, gedrückt, gesperrt), Abstände, Symbole, Bewegung. Palette und
Schriftgrößen prüfen die Tests, die lässt du aus. Regelt der Style-Guide etwas nicht, meldest du
eine Lücke im Style-Guide, keinen Fehler.

Jeder Befund nennt Ort (Datei und Node oder Bildausschnitt), Regel (Abschnitt im Style-Guide),
Beleg (was du siehst, was die Regel verlangt) und Schwere (kritisch, hoch, mittel, niedrig).
Findest du nichts, schreib „keine Befunde“ und welche Abschnitte du geprüft hast.
```

`tools` erlaubt nur Lesen und Suchen, der Prüfer kann also nichts kaputt machen. `model: inherit`
nimmt dasselbe Modell wie die Sitzung.

## Beispiel: Plan und Aufgaben

Ein gedachtes späteres Feature „Ladenansicht“, der erste echte Spielbildschirm. In `plan.md`:

| Phase | Ändert | Prüfer |
|---|---|---|
| 3: Kern der Ladenansicht | Daten, keine Oberfläche | keine |
| 4: Oberfläche der Ladenansicht | Szene, Knöpfe, Texte | Stil, Text |

In `tasks.md`:

```
- [ ] T037 [A] [US2] Texte der Ladenansicht in src/scenes/laden/laden_texte.gd
- [ ] T038 [C] Phasenprüfung Phase 4 mit /dcl-phasenpruefung: Stil- und Text-Prüfer, Befunde nachprüfen
- [ ] T039 [K] Abnahme Phase 4
```

## Beispiel: Bericht

Ausgedacht. So stünde es in der Bitte um Abnahme unter „was geprüft ist“:

```
Phasenprüfung Phase 4, Ladenansicht (T031–T037)
Tests: 512 grün, zweimal gleich; Startprobe still
Stil-Prüfer: 3 Befunde, 2 bestätigt
  hoch       Knopf „Bestellen“ ohne Hover-Zustand (Bausteine › Knopf)
  niedrig    Preisschild 2 px vom Rand statt 4 px (Abstände)
  verworfen  Schatten unter dem Tresen: gehört zur Szene, dort erlaubt
Text-Prüfer: 2 Befunde, 2 bestätigt
  hoch       „Bitte wählen Sie eine Ware“ → „Wähl eine Ware“ (du-Form)
  mittel     „Das kostet 499 Euro“ im Jahr 1987 → „499 DM“ (Wortschatz)
Für dich: Der Style-Guide regelt Preisschilder noch nicht. Wie sollen sie aussehen?
```

Der verworfene Befund zeigt, warum Claude nachprüft: Auch Prüfer liegen mal daneben.

## Einführen in Stufen

1. Jetzt nichts. In den Werkzeugen gibt es wenig Text, und Claudes Prüfung reicht dort aus.
2. Vor dem ersten Spielbildschirm als Vorarbeit, so wie der Style-Guide in Feature 001:
   - Claude schreibt den Text-Leitfaden, Klaus entscheidet den Ton.
   - Claude legt die beiden Prüfer und den Skill an.
   - Der Godot-Agent schreibt die beiden Tests.
3. Eine Phase als Pilot. Claude zählt bestätigte und verworfene Befunde. Danach werden die Prüfer
   behalten, nachgeschärft oder gestrichen.
4. Bewährt es sich, kommt die Regel auf Klaus' Beschluss in die Verfassung.
5. Später kommt der Fakten-Prüfer dazu, wenn Katalog und game_bible wachsen.

Jede Phasenprüfung kostet zwei bis drei Prüfer-Läufe und läuft nur in Phasen, die Sichtbares oder
Texte ändern. Sitzt der Ablauf, lässt er sich als gespeicherter Workflow fest einrichten.

## Offen

- Der Text-Leitfaden fehlt: Steht er als Abschnitt im Style-Guide oder als eigene Datei?
- Ab wann genau: mit dem ersten Spielbildschirm oder schon mit den ersten Spieltexten?
- Startet ein Hook die Tests nach jedem Lauf des Godot-Agents?
