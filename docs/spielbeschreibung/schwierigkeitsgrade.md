# Schwierigkeitsgrade

- **Worum es geht:** die Grade Leicht, Mittel und Schwer und wie sie über Profile aus
  Start-Modifikatoren die Zeitleiste verändern.
- **Laden, wenn:** ein Spiel mit Grad startet, ein Grad gespeichert oder angezeigt wird, Balance
  der Grade, oder wenn ein Grad künftig auch Wirtschaft, Startkapital oder Kunden ändern soll.
- **Code:** `src/core/timeline/difficulty.gd`, `difficulty_profile.gd`, `chance_modifier.gd`;
  Grad im Lauf `timeline_run.gd`; Reiter der Werkstatt `src/tools/werkstatt/difficulty_panel.gd`
- **Herkunft:** `specs/003-schwierigkeitsgrade/`
- **Stand:** Feature 004, 2026-10-27
- **Nachbarn:** Mechanik der Chancen und Modifikatoren in [zeitleiste.md](zeitleiste.md), Format
  und Prüfregeln V25–V31 in [ereigniskatalog.md](ereigniskatalog.md)

## Idee

Es gibt **einen** Katalog. Ein Grad verschiebt nur die Chancen von Ereignissen über
Wahrscheinlichkeit, mit demselben Mechanismus wie die Modifikatoren aus Eingriffen. Ausgedachtes
Beispiel: Schwer setzt „Anspruchsvolle Kunden: Reklamationswelle +5 Prozentpunkte, ganzes Spiel“. Fixe und
jährliche Ereignisse, Würfel und Seed bleiben unberührt.

| Grad | Profil | Wirkung |
|---|---|---|
| Leicht | ja | Start-Modifikatoren aus dem Profil „leicht“ |
| **Mittel** | nein | der Katalog allein; Vorgabe überall, wo kein Grad genannt ist |
| Schwer | ja | Start-Modifikatoren aus dem Profil „schwer“ |

Mit Mittel sind Fahrplan und Protokoll Zeichen für Zeichen wie vor Feature 003; ein Test hält das
an einer eingefrorenen Grundlinie fest. Ein leeres Profil verhält sich wie Mittel.

## Difficulty

Eine Klasse ohne Instanzen mit der Aufzählung `Level { LEICHT, MITTEL, SCHWER }` und den Namen an
einer Stelle:
- `key(level)` → `"leicht"`, `"mittel"`, `"schwer"` für Dateien und Argumente;
  `from_key(text)` zurück, −1 bei Unbekanntem; Groß- und Kleinschreibung zählt.
- `label(level)` → „Leicht“, „Mittel“, „Schwer“ für Texte.
- `DEFAULT` = Mittel, `WITH_PROFILE` = `[LEICHT, SCHWER]`.
- `is_valid(level)` prüft eine Zahl, denn ein Parameter vom Typ `Difficulty.Level` nimmt auch 7 an.

## Profile und Start-Modifikatoren

Der Katalog hält immer zwei Profile (`DifficultyProfile`), `[0]` Leicht und `[1]` Schwer, auch
leer; `catalog.get_profile(level)` gibt für Mittel `null`. Ein Profil ist eine Liste von
**Start-Modifikatoren**: `ChanceModifier`s mit Kennung, Ereignis, Wert, Grund und Zeitraum, als
Vorgabe das ganze Spiel. Mehrere auf dasselbe Ereignis addieren sich.

Wird ein Ereignis in der Werkstatt gelöscht, verschwinden seine Start-Modifikatoren mit; wird es
umbenannt, ziehen sie mit. Eine Kopie des Ereignisses bekommt keine.

**Wann er wirkt:** Gewürfelt wird am Monatsersten. Ein Start-Modifikator wirkt in jeder
Würfelrunde, deren Tag in seinem Zeitraum liegt. Beginnt er am 15.03.1990, wirkt er ab dem
01.04.1990; deshalb warnt V31 bei Tagen mitten im Monat.

## Im Spiel

Der Spieler wählt den Grad bei „Neues Spiel“, vorgewählt ist Mittel. Die Hinweise versprechen nur,
was ein Grad tut: „Das Glück ist eher auf deiner Seite.“ (Leicht), „Das Glück hält sich raus.“
(Mittel), „Das Glück ist eher auf der Seite der anderen.“ (Schwer). Der Grad steht im Spielstand;
fortgesetzt wird mit demselben Grad und dem Profil aus der Katalogkopie des Spielstands (siehe
[spielstaende.md](spielstaende.md)).

`Timeline.start_game(seed, difficulty)` → `TimelineRun.new(catalog, seed, difficulty)`:
1. Fahrplan und Würfel anlegen wie immer; der Grad ändert daran nichts.
2. Die Start-Modifikatoren des Profils prüfen wie einen Eingriff und als Kopien in
   `run.start_modifiers` setzen, je mit einer Meldung `START_MODIFIER` am Tag −1 im Protokoll.
   Was nicht geht, steht in `run.start_refusals`; meist leer, denn das Spiel rechnet schon mit
   dem Katalog ohne fehlerhafte Start-Modifikatoren.
3. Erst dann würfelt `begin()` zum ersten Mal.

Der Grad steht in `run.difficulty` und ist fürs ganze Spiel fest. Start-Modifikatoren stehen
getrennt von den Modifikatoren aus Eingriffen (`run.modifiers`):
- Sie lassen sich nicht entfernen.
- Sie kommen nie ins Eingriffsprotokoll und nie in Proben.
- Eingriffe wirken in jedem Grad gleich.

Ein gewürfelter Termin nennt in seiner Begründung zuerst die Start-Modifikatoren mit Grad, dann
die Eingriffe, etwa „3 % + Schwer: Anspruchsvolle Kunden +5“.

**Seed und Grad sind unabhängig:** Derselbe Seed mit demselben Grad ergibt dasselbe Spiel. Zwei
Grade mit demselben Seed unterscheiden sich nur bei Ereignissen, auf die ein Start-Modifikator
zeigt, und bei allen, die davon über Folgen oder Bedingungen abhängen.

## Chance je Zeitabschnitt

`DifficultyProfile.chance_periods(event, profile, …)` gibt die wirksame Chance über das ganze
Spiel als Abschnitte zurück, je `{from_day, to_day, chance}`; gleiche Nachbarn werden
zusammengelegt. `describe_periods()` macht daraus „8 %“ oder „3 % bis 31.12.1994, 6 % ab
01.01.1995“. Das Formular der Werkstatt zeigt so die Chance je Grad.

## Heutiger Stand der Profile

Beide Profile haben je drei vorläufige Start-Modifikatoren, alle auf „Großkunde meldet sich“
(Leicht zusammen −2, Schwer +3 Prozentpunkte). Die endgültigen Werte stellt Klaus mit der
Statistik der Werkstatt ein (`docs/offene-punkte.md`).

Ein Grad wirkt bisher nur auf die Zeitleiste. Was er an Wirtschaft, Startkapital, Preisen oder
Kunden ändert, ist offen (Feature-Idee 11-05).
