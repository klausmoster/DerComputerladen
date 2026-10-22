# Recherche: Schwierigkeitsgrade der Zeitleiste

Grundlage: [spec.md](spec.md) mit den Klärungen vom 2026-10-21,
[Verfassung 2.1.1](../../.specify/memory/constitution.md), Feature 002 mit
[research.md](../002-zeitleisten-werkstatt/research.md) (R1 bis R24),
[data-model.md](../002-zeitleisten-werkstatt/data-model.md) und den Verträgen dort, dazu der Code
unter `src/core/timeline/`, `src/core/timeline.gd` und `src/tools/werkstatt/` auf dem Stand von
`72b743a`. Godot-Stand: 4.7.2.

Die Entscheidungen hier sind R1 bis R19 von Feature 003. Verweise auf Feature 002 tragen immer
den Zusatz, etwa „R5 von Feature 002“. Die Prüfregeln dagegen zählen weiter, V25 bis V30, weil
es ein einziger Prüfer mit einer Tabelle bleibt.

Die drei Fragen, die der Plan klären sollte, beantworten R2 (Aufbau des Abschnitts), R4 (Profil
für einen unbekannten Grad oder für „Mittel“) und R5 (Kennungen von Start-Modifikatoren und
Eingriffen). Klaus' Entscheidung im Plan steht in R9. Aus dem Review der Checkliste
[review.md](checklists/review.md) am 2026-10-22 kommen V31 in R8, die gefüllten Profile in R17
und R18 und R19; die übrigen Vorschläge sind in die Entscheidungen eingearbeitet, auf die sie sich
beziehen.

## R1 Der Grad als Aufzählung

*Claude, 2026-10-21*

- **Entscheidung:** Eine kleine Klasse `Difficulty` ohne Instanzen hält die Aufzählung
  `enum Level { LEICHT, MITTEL, SCHWER }` und die Vorgabe `DEFAULT = MITTEL`. Dazu kommen
  statische Hilfen:
  - `key()` liefert den Namen in Dateien und Argumenten: `"leicht"`, `"mittel"`, `"schwer"`;
  - `label()` liefert den Namen in Texten: „Leicht“, „Mittel“, „Schwer“;
  - `from_key()` macht aus dem Namen den Grad, −1 bei einem unbekannten;
  - `is_valid()` sagt, ob eine Zahl ein Grad ist.

  Profile haben nur `LEICHT` und `SCHWER` (`Difficulty.WITH_PROFILE`, FR-004). Die Namen der
  Werte sind deutsch, wie bei `EventEffect.Kind` mit `PREIS` und `NACHFRAGE`, denn es sind die
  Namen im Spiel.
- **Begründung:** `Timeline.start_game()`, `TimelineRun.new()`, Proben und Statistik bekommen
  einen typisierten Parameter, und die Namen stehen an einer Stelle. Eine Aufzählung ist in
  GDScript zur Laufzeit eine ganze Zahl; `start_game(4711, 7)` ginge also durch. Deshalb prüft
  `is_valid()` vor jedem Spielstart (FR-011).
- **Probe** (2026-10-21, Godot 4.7.2 headless mit `-d`, in einem Wegwerf-Projekt):
  - Ein Parameter vom Typ `Level` nimmt `7 as Level` an und behält die 7.
  - Ein `int` ohne Umwandlung geht ebenfalls durch, ohne Ausgabe beim Start.
  - `Array[int] = []` als Vorgabe eines Parameters geht, ebenso eine Konstante `Array[int]` aus
    Werten der Aufzählung.
- **Alternativen:**
  - Englische Namen `EASY`, `MEDIUM`, `HARD`: Zwischen Spec und Code läge eine Übersetzung, und
    `EventEffect.Kind` macht es schon deutsch vor.
  - Der Grad als Text, `start_game(4711, "schwer")`: Ein Tippfehler fiele erst zur Laufzeit auf,
    und der Editor böte keine Vervollständigung an.
  - Die Aufzählung in `TimelineRun`: Der Katalog müsste dann für das Lesen der Profile den Lauf
    kennen, bisher ist es umgekehrt.

## R2 Aufbau des Abschnitts „profiles“

*Claude, 2026-10-21; beantwortet Frage 1 des Plans*

- **Entscheidung:** Die Katalogdatei bekommt einen Schlüssel `"profiles"` auf oberster Ebene.
  Darin stehen genau `"leicht"` und `"schwer"`, jedes mit einer Liste von Start-Modifikatoren.
  Ein Start-Modifikator hat dieselben Schlüssel wie ein Modifikator in einer
  Was-wäre-wenn-Probe, also die Felder von `ChanceModifier`: `event_id`, `from_day`, `id`,
  `reason`, `to_day`, `value`.

  ```json
  	"profiles": {
  		"leicht": [],
  		"schwer": [
  			{
  				"event_id": "reklamationswelle",
  				"from_day": "1985-01-01",
  				"id": "reklamationswelle",
  				"reason": "Anspruchsvolle Kunden",
  				"to_day": "1999-12-31",
  				"value": 0.05
  			}
  		]
  	}
  ```

  - Tage stehen als `"JJJJ-MM-TT"` in der Datei, wie überall im Katalog.
  - Der Wert ist ein Anteil wie alle Anteile im Katalog: `0.05` heißt +5 Prozentpunkte. Er wird
    auf vier Nachkommastellen gerundet (Schreibregel 3 von Feature 002).
  - Geschrieben wird nach den Regeln des Katalogs: Tabs, Schlüssel alphabetisch, jeder Schlüssel
    auf einer eigenen Zeile. Ändert Klaus einen Wert, ändert sich genau eine Zeile (SC-006).
  - Die Listen behalten ihre Reihenfolge wie die Wirkungen eines Ereignisses: Neue kommen ans
    Ende, ein Duplikat direkt hinter sein Original. Sortiert wird nicht. Sonst wanderte ein Block,
    wenn Klaus die Kennung ändert, und SC-006 bräche.
  - Beide Grade und der Abschnitt selbst werden immer geschrieben, leere Listen als `[]`
    (Schreibregel 4 von Feature 002).
  - Fehlt der Abschnitt oder fehlt darin ein Grad, ist das betreffende Profil leer, ohne Meldung
    (FR-005, Edge Case „Ältere Katalogdatei“).
  - Weil die Schlüssel alphabetisch stehen, kommt der Abschnitt ans Ende der Datei, hinter
    `"format"`.
- **Begründung:**
  - Die Datei ist ohne Werkzeug lesbar: „profiles, schwer, ein Modifikator auf die
    Reklamationswelle, +0,05 vom 01.01.1985 bis 31.12.1999, Grund Anspruchsvolle Kunden“.
  - Ein Modifikator sieht im Katalog genauso aus wie in einer Probe, es gibt also nur eine Form.
- **Alternativen:**
  - Eine flache Liste `"start_modifiers"` mit einem Schlüssel `"grade"` je Eintrag: Der Grad
    stünde in jedem Eintrag, und wer „Schwer“ lesen will, muss die ganze Liste durchgehen.
  - Eine Liste von Profilen `[{"grade": "schwer", "modifiers": […]}]`: eine Ebene mehr, und die
    Reihenfolge der Profile bräuchte eine eigene Regel.
  - Eine Zeile Text je Modifikator, etwa `"reklamationswelle +5 1985-01-01 1999-12-31
    Anspruchsvolle Kunden"`: Sie bräuchte einen eigenen Leser und wäre im Diff schwerer zu lesen.
  - Prozentpunkte statt Anteil (`5` statt `0.05`): lesbarer, aber anders als `monthly_chance` und
    als die Proben; R3 von Feature 002 hat das schon einmal verworfen.
  - `from` und `to` wie bei `window`: Derselbe Modifikator hätte dann im Katalog andere
    Schlüssel als in einer Probe.

## R3 Die Formatnummer bleibt 1

*Claude, 2026-10-21*

- **Entscheidung:** `"format": 1` bleibt. Der Abschnitt ist beim Lesen freiwillig und wird beim
  Schreiben immer angelegt.
- **Folge:**
  - Speichert die Werkstatt einen Katalog aus Feature 002 zum ersten Mal, bekommt die Zeile
    `"format": 1` ein Komma. Dazu kommen vier Zeilen: `"profiles": {`, `"leicht": [],`,
    `"schwer": []` und die schließende Klammer.
  - Tests, die eine geschriebene Datei mit einer Fixture vergleichen, ändern sich entsprechend
    (R17).
  - Damit die Prüfung „eine Änderung, eine Zeile“ aus dem Quickstart von Feature 002 auch am
    echten Katalog weiter gilt, speichert Klaus ihn zur Abnahme von Phase 1 einmal in der
    Werkstatt. Danach hat er den leeren Abschnitt, und Claude committet ihn mit der Phase. So
    schreibt weiter nur die Werkstatt den Katalog.
- **Begründung:** Ältere Dateien muss der Katalog ohnehin lesen (Edge Case). Eine neue Nummer
  schützte nur älteren Code vor neuen Dateien, und Code und Daten liegen im selben Repository.
- **Alternativen:**
  - `"format": 2`, und beide Nummern werden gelesen: mehr Code ohne Nutzen.
  - Den Abschnitt nur schreiben, wenn ein Profil Einträge hat: Ältere Dateien blieben beim
    Speichern gleich. Die Spec verlangt aber, dass der Abschnitt beim Speichern dazukommt, und
    „leer“ hätte dann zwei Formen.

## R4 Profil für einen unbekannten Grad oder für „Mittel“

*Claude, 2026-10-21; beantwortet Frage 2 des Plans*

- **Entscheidung:** Beides ist ein Strukturfehler V22, wie jeder unbekannte Schlüssel
  (Schreibregel 5 von Feature 002). Der Katalog behält solche Einträge nicht. Die Meldung beim
  Lesen steht in der Werkstatt bis zum Speichern, und vor dem Speichern fragt die Werkstatt
  „Der Katalog hat N Fehler. Trotzdem speichern?“. So geht nichts still verloren. Die Meldungen
  lauten:
  - für `"mittel"`: „Für „Mittel“ gibt es kein Profil: Mittel ist der Katalog ohne
    Start-Modifikatoren.“
  - für einen unbekannten Grad, etwa `"extrem"` oder `"Schwer"` mit großem S: „Den
    Schwierigkeitsgrad „extrem“ gibt es nicht; Profile gibt es nur für „leicht“ und „schwer“.“

  Beim Spielstart meldet die Zeitleiste sie über `push_error()` wie jeden Fehler. Ausgenommen
  wird dadurch nichts, denn das Profil wurde gar nicht erst gelesen.
- **Begründung:** Nach FR-004 hat „Mittel“ kein Profil. Ein Eintrag dafür ist ein Widerspruch in
  den Daten und keine Spielart. Als Fehler fängt `test_shipped_catalog.gd` (FR-014) auch einen
  Tippfehler wie `"schwerr"`. Als Warnung käme er durch die Tests, und im Spiel fehlte das
  Profil einfach.
- **Alternativen:**
  - Eine Warnung: Tippfehler kämen durch die Tests.
  - Still übergehen: Daten gingen ohne Hinweis verloren.
  - Behalten und zurückschreiben: widerspricht FR-004 und Schreibregel 5.
  - Eine eigene Regelnummer: V22 deckt unbekannte Schlüssel schon ab, und eine Sache bekäme
    sonst zwei Regeln.

## R5 Start-Modifikatoren und Eingriffe im selben Lauf

*Claude, 2026-10-21; beantwortet Frage 3 des Plans*

- **Entscheidung:** Start-Modifikatoren und Eingriffe unterscheiden sich durch die Liste, in der
  sie stehen, nicht durch ihre Kennung.
  - `TimelineRun.start_modifiers` ist neu. Die Liste hält die Start-Modifikatoren des Grads.
    `_init()` füllt sie einmal, danach ändert sie sich nie.
  - `TimelineRun.modifiers` bleibt die Liste der Modifikatoren aus Eingriffen, wie in Feature
    002.
  - Die Kennung eines Start-Modifikators ist in seinem Profil eindeutig (V30), die eines Eingriffs
    unter den Eingriffen des Laufs, wie bisher. Haben ein Start-Modifikator und ein Eingriff
    dieselbe Kennung, schadet das nicht.
  - `remove_modifier()` sucht nur unter den Eingriffen. Trägt nur ein Start-Modifikator die
    Kennung, lehnt es mit `ERR_UNAVAILABLE` ab: „„reklamationswelle“ ist ein Start-Modifikator
    von Schwer und lässt sich im laufenden Spiel nicht entfernen.“ (FR-010)
  - `add_modifier()` prüft die Kennung nur gegen die Eingriffe. Ein Eingriff wird deshalb in jedem
    Grad gleich angenommen oder abgelehnt. Das braucht die Statistik, wenn sie die Grade mit
    denselben Eingriffen vergleicht (FR-020), und eine Probe lässt sich unter jedem Grad laden.
  - Start-Modifikatoren kommen nie ins Eingriffsprotokoll `interventions`. Eine Probe speichert
    den Grad, nicht seine Start-Modifikatoren (FR-019), und die Statistik zählt sie nicht als
    Eingriffe.
  - Wo ein Start-Modifikator erscheint, steht der Grad davor: im Protokoll, in der Begründung
    eines gewürfelten Termins („Schwer: Anspruchsvolle Kunden +5“) und in der Liste der
    Modifikatoren im Simulator (R6, R13).
- **Begründung:** Die Spec verlangt, dass Start-Modifikatoren von Eingriffen zu unterscheiden
  sind und sich im Spiel nicht entfernen lassen (FR-010). Mit zwei Listen folgt beides aus dem
  Aufbau statt aus einer Namensregel.
- **Alternativen:**
  - Eine gemeinsame Liste und eine Vorsilbe in der Kennung, etwa `"schwer/reklamationswelle"`:
    Die Prüfung auf doppelte Kennungen mischte beide Arten, `remove_modifier()` bräuchte eine
    Sperre, und eine Probe mit der Kennung `schwer/x` würde nur unter „Schwer“ abgelehnt.
  - Eine gemeinsame Liste und ein neues Feld `grade` in `ChanceModifier`: Jeder, der die Liste
    liest, müsste filtern, und die Datenklasse trüge Wissen über den Lauf.
  - Start-Modifikatoren als Eingriffe mit `at_day` −1: Sie landeten in Proben und in der
    Statistik als Eingriffe und ließen sich entfernen. Das widerspricht FR-010, und beim Laden
    einer Probe gälten sie doppelt.

## R6 Start-Modifikatoren im Lauf

*Claude, 2026-10-21*

- **Entscheidung:**
  - **Wann:** `TimelineRun.new(catalog, seed, difficulty)` mit der Vorgabe `MITTEL`. `_init()`
    legt wie bisher die fixen, jährlichen und gesetzten Termine an und die Würfel der Ereignisse
    über Wahrscheinlichkeit. Danach setzt es die Start-Modifikatoren des Profils, also bevor
    `begin()` zum ersten Mal würfelt (FR-007). Gesetzte Termine nutzen keine Chance, nur ihren
    eigenen Würfel (FR-003); für sie ist die Reihenfolge gleich.
  - **Prüfen:** Der Lauf prüft jeden Start-Modifikator wie `add_modifier()`: Das Ereignis gibt es
    und es kommt über Wahrscheinlichkeit, Kennung und Grund sind nicht leer, das Ende ist gesetzt
    und liegt nicht vor dem Beginn, die Kennung kommt im Profil nur einmal vor. Was durchfällt,
    setzt er nicht und schreibt dazu einen Satz in `start_refusals`. Im Normalfall bleibt die
    Liste leer, denn Spiel, Werkstatt und Textausgabe rechnen mit `without_faulty()` (R8).
  - **Wirkung:** `chance_info()` rechnet Grundchance plus alle Start-Modifikatoren und Eingriffe,
    die an dem Tag gelten, begrenzt auf 0 bis 1 (FR-007). Beispiel aus US1, Szenario 7: 3 % mit
    „Schwer +5“ und einem Eingriff −6 ergibt 2 %. Das Ergebnis bekommt den neuen Schlüssel
    `"start_modifiers"` mit den geltenden Start-Modifikatoren. `"modifiers"` bleiben die
    Eingriffe; wer bisher fragt, bekommt also dasselbe wie bisher.
  - **Protokoll:** Je Start-Modifikator gibt es eine Meldung der neuen Art
    `TimelineMessage.Kind.START_MODIFIER` mit der Spalte „Grad“, am Tag −1. Das ist wie bei
    Eingriffen vor Spielbeginn der 31.12.1984:
    „31.12.1984  Grad  Reklamationswelle: Start-Modifikator „Anspruchsvolle Kunden“ (Schwer) +5
    Prozentpunkte vom 01.01.1985 bis 31.12.1999“.
    - Die neue Art kommt ans Ende der Aufzählung, damit die übrigen Arten ihre Nummern behalten.
    - Die Meldung steht nur im Protokoll, in keiner Rückgabe von `begin()` oder `advance_to()`.
      Sie wird deshalb kein Signal, wie `INTERVENTION`.
  - **Begründung eines Termins:** `modifier_notes` eines gewürfelten Termins nennt zuerst die
    Start-Modifikatoren mit ihrem Grad, dann die Eingriffe: „Würfel 0,0213 < Schwelle 0,0800 (3 %
    + Schwer: Anspruchsvolle Kunden +5)“.
  - **Mittel:** Es gibt keine Start-Modifikatoren und keine Zeile im Protokoll. Fahrplan und
    Protokoll bleiben Zeichen für Zeichen wie in Feature 002. Das ist die feste Größe dieses
    Features (R17).
- **Begründung:** Es ist derselbe Mechanismus wie in Feature 002 (FR-007 verweist auf FR-025).
  Ein Modifikator ändert nur die Schwelle, nie den Wurf (R5 von Feature 002). Deshalb gilt FR-009,
  ohne dass die Würfel sich ändern.
- **Alternativen:**
  - Eine eigene Methode `apply_profile()` nach `new()`: Ein Lauf ließe sich benutzen, bevor das
    Profil gesetzt ist, und jeder Aufrufer bräuchte einen Schritt mehr.
  - Start-Modifikatoren als Meldung `INTERVENTION`: An der Art ließen sie sich nicht von
    Eingriffen unterscheiden (FR-010).
  - Das Profil in die Grundchancen der Kopie einrechnen: FR-025 von Feature 002 verbietet, die
    Grundchance zu ändern, und die Begründung nennte 8 % als Grundchance.

## R7 Seed und Grad sind unabhängig

*Claude, 2026-10-21*

- **Entscheidung:** Der Seed wird gewürfelt wie bisher, unabhängig vom Grad (FR-008). Die Würfel
  hängen nur an Seed, Zweck und Kennung (R5 von Feature 002). Zwei Grade mit demselben Seed
  unterscheiden sich deshalb nur in zwei Fällen (FR-009):
  - bei den Ereignissen, deren Schwelle ein Start-Modifikator verschiebt;
  - bei dem, was von diesen Ereignissen abhängt: ihre Folgeereignisse, deren Würfel an Quelle und
    Tag hängt, Ereignisse mit Bedingungen auf sie, und so weiter.

  Der echte Katalog hat heute weder Folgeereignisse noch Bedingungen. Ein Grad verändert dort
  also nur die Termine der sechs Ereignisse über Wahrscheinlichkeit.
- **Prüfung (SC-002):** Ein Test vergleicht für 100 Seeds „Mittel“ und „Schwer“ mit
  `ScheduleDiff`. Sein Test-Katalog hat ein verändertes Ereignis, eine Folge davon, ein Ereignis
  mit Bedingung darauf und eins, das nichts damit zu tun hat. Jede Markierung muss bei einem
  Ereignis aus der Hülle der Abhängigen liegen. Das Muster gibt es schon:
  `VON_REKLAMATION` in `test_schedule_diff.gd`.
- **Alternative:** Ein Seed je Grad, etwa ein Hash aus Seed und Grad: Derselbe Seed ergäbe je
  Grad ein ganz anderes Spiel, und der Vergleich der Grade wäre Rauschen. Die Spec verlangt
  denselben Seed.

## R8 Prüfregeln V25 bis V31 für Profile

*Claude, 2026-10-21; V31 Klaus, 2026-10-22, im Review nach Empfehlung (CHK013)*

- **Entscheidung:** `CatalogValidator.validate()` prüft nach den Ereignissen und Kategorien die
  Profile, mit neuen Regeln im Anschluss an V01 bis V24 aus Feature 002:

  | Regel | Prüft | Stufe |
  |---|---|---|
  | V25 | Start-Modifikator verweist auf ein unbekanntes Ereignis, auch ein leeres | Fehler |
  | V26 | Start-Modifikator auf ein Ereignis, das nicht über Wahrscheinlichkeit kommt: fix, jährlich, beim Start gesetzt oder nur als Folge | Fehler |
  | V27 | Ende vor dem Beginn | Fehler |
  | V28 | Beginn oder Ende außerhalb 01.01.1985 bis 31.12.1999 | Fehler |
  | V29 | Grund leer oder nur Leerzeichen | Fehler |
  | V30 | Kennung leer, mit anderen Zeichen als a–z, 0–9 und _, oder im Profil doppelt | Fehler |
  | V31 | Beginn kein Monatserster oder Ende kein Monatsletzter | Warnung |

  - **V31:** Gewürfelt wird am Monatsersten. Die Warnung nennt deshalb die Würfelrunde, in der der
    Start-Modifikator wirklich zuerst bzw. zuletzt wirkt:
    - am Beginn: „Der Beginn 15.03.1990 ist kein Monatserster; der Start-Modifikator wirkt ab der
      Würfelrunde am 01.04.1990.“
    - am Ende: „Das Ende 15.06.1994 ist kein Monatsletzter; der Start-Modifikator wirkt noch in der
      Würfelrunde am 01.06.1994.“

    Eine Warnung hält weder Speichern noch Tests auf. Ein Beginn nach dem letzten Monatsersten des
    Zeitraums, etwa vom 02.03. bis 31.03., wirkt in keiner Würfelrunde; das sagt die Warnung dann
    so. Verworfen hat Klaus, es nur zu beschreiben, und nur ganze Monate zu erlauben. Das Erste
    ließe „ab 15.03.1990“ im Formular unerklärt stehen. Das Zweite wiche von den tagesgenauen Daten
    aus Feature 002 ab.

  Dazu kommen Strukturfehler V22 beim Lesen, etwa ein Wert, der keine Zahl ist, ein Datum, das
  kein Kalendertag ist, ein fehlender oder unbekannter Schlüssel und Profile nach R4.
  - **Ort einer Meldung:** Meldungen zu Start-Modifikatoren haben ein leeres `event_id`. Das Feld
    heißt wie in der Datei, etwa `profiles.schwer[2].reason`. Der Text nennt Grad und
    Start-Modifikator: „Profil „Schwer“, Start-Modifikator „reklamationswelle“, Feld „reason“:
    Der Grund ist leer.“ Ohne Kennung heißt es „Start-Modifikator Nr. 3 ohne Kennung“.
  - **Ausnehmen:** `without_faulty()` lässt zwei Arten von Start-Modifikatoren weg. Zum einen die,
    zu deren Stelle eine Meldung der Stufe `ERROR` gehört, deren Feld also mit
    `profiles.<grad>[<i>].` beginnt. Zum anderen die, deren Ereignis in der Kopie nicht als
    Ereignis über Wahrscheinlichkeit steht, etwa weil es wegen eigener Fehler ausgenommen ist. So
    hält es Feature 002 schon mit Folgeereignissen.
  - **Im Spiel:** Die Zeitleiste meldet jeden ausgenommenen Start-Modifikator mit Grad, Kennung und
    Grund über `push_error()` (FR-013). Auch einen, der nur wegen seines Ereignisses wegfällt,
    nennt sie.
  - **Eigene Festlegung:** V30 prüft auch eine leere Kennung und falsche Zeichen, wie V01, V03 und
    V21. FR-012 nennt nur die doppelte Kennung. Ohne gültige Kennung ließe sich ein
    Start-Modifikator aber beim Spielstart nicht benennen.
- **Begründung:** Werkstatt, Spielstart und Tests prüfen mit denselben Regeln (FR-012, FR-014).
  `test_shipped_catalog.gd` erfasst die Profile damit über `validate()`. Das leere `event_id` hat
  einen Grund: Ein Fehler im Profil darf kein richtiges Ereignis aus dem Spiel nehmen.
- **Alternativen:**
  - Ein eigener Prüfer für Profile: Zwei Stellen müssten zusammenpassen, etwa für die Zahl der
    Fehler in der Werkstatt.
  - Die Meldung trägt die Kennung des Ereignisses, auf das der Start-Modifikator zeigt: Dann nähme
    `without_faulty()` das Ereignis heraus, und ein Tippfehler im Profil „Schwer“ striche die
    Reklamationswelle aus dem Spiel.
  - Neue Felder in `CatalogIssue` für Grad und Stelle: Das Feld nennt die Stelle schon. Das
    Formular liest Felder wie `effects[1].delay_days` genauso aus.

## R9 Verweise beim Löschen und Umbenennen

*Klaus, 2026-10-21, im Plan entschieden, nach Empfehlung*

- **Entscheidung:** Start-Modifikatoren sind Verweise auf Ereignisse wie Folgeereignisse und
  Bedingungen:
  - Löscht Klaus ein Ereignis, nennt der Dialog vorher die Start-Modifikatoren, die darauf
    verweisen, etwa „Im Profil „Schwer“: Anspruchsvolle Kunden“. Sie werden im selben Schritt mit
    entfernt, und Cmd+Z holt alles zurück (FR-036 von Feature 002).
  - Benennt er es um, ziehen sie still mit. Aus `konkurrent_eroeffnet` wird in „Schwer +2 auf
    Konkurrent eröffnet“ also `konkurrent_kommt`, im selben Schritt wie das Umbenennen.

  FR-017 und der Edge Case „Kaputter Verweis“ sind entsprechend präzisiert. Ein Verweis ins Leere
  entsteht so nur noch, wenn jemand die Datei von Hand ändert. Dann zeigt die Prüfung V25, und
  der Spielstart überspringt den Start-Modifikator.
- **Begründung:** Die Werkstatt behandelt alle Verweise gleich.
- **Alternativen (von Klaus verworfen):**
  - Nachziehen mit einem Hinweis am Feld „Kennung“, welche Start-Modifikatoren mitgezogen sind.
  - Vor dem Umbenennen nachfragen. Folgen und Bedingungen blieben dabei still, die Werkstatt
    behandelte Verweise also zweierlei.

## R10 Katalog und `CatalogEditor` mit Profilen

*Claude, 2026-10-21*

- **Entscheidung:**
  - `EventCatalog.profiles` hält immer zwei Profile, Leicht und Schwer, in dieser Reihenfolge,
    auch leer. Neu sind `get_profile()` und `to_dict()`. `to_dict()` ist die einzige Stelle, die
    die Schlüssel der obersten Ebene zusammenstellt. Es dient `to_json()` und der
    Sicherungskopie, die das Dictionary bisher selbst baute (`CatalogEditor._catalog_dict()`).
    `duplicate_catalog()` kopiert die Profile mit, `without_faulty()` nimmt aus wie in R8.
  - Der `CatalogEditor` bekommt Methoden, um Start-Modifikatoren anzulegen, zu duplizieren, zu
    löschen und Felder zu setzen. Jede ist eine Aktion im selben `UndoRedo` wie der übrige
    Katalog. Damit gelten Cmd+Z, „ungespeichert“, die Rückfrage beim Schließen und die
    Sicherungskopie ohne Zusatzarbeit (FR-016).
  - **Ganze Profile ersetzen:** Jede Änderung an einem Start-Modifikator ersetzt das ganze
    `DifficultyProfile` durch eine geänderte Kopie. Im Verlauf ist das ein Schritt „ersetzen“ in
    der Liste `catalog.profiles`. Einfügen und Entfernen einzelner Start-Modifikatoren gibt es im
    Verlauf nicht. Das hat drei Gründe:
    - Der Verlauf merkt sich bei „entfernen“ die Stelle und setzt beim Rückgängigmachen in
      umgekehrter Reihenfolge wieder ein (`_inverse()`). Löscht Klaus ein Ereignis, auf das zwei
      Start-Modifikatoren eines Profils zeigen, stimmten die gemerkten Stellen nach dem ersten
      Entfernen nicht mehr.
    - `content_key()` merkt sich den Text je Objekt. Ein neues Profil-Objekt ist eine Änderung, die
      Simulator und Statistik sicher sehen.
    - `_run()` muss nur eine Liste mehr kennen.
  - **Sicherungskopie:** Sie baut ihren Katalog ab Phase 1 aus `EventCatalog.to_dict()`. Sonst
    fehlten ihr die Profile, und der Test, der den Katalog Zeichen für Zeichen in der Kopie sucht,
    schlüge fehl.
  - `content_key()` nimmt die Profile auf. Sonst merkten Simulator und Statistik nicht, dass sich
    ein Profil geändert hat, und zeigten „Katalog geändert, neu starten“ nicht (FR-042 von
    Feature 002).
  - Ändert Klaus die Art eines Ereignisses, auf das ein Start-Modifikator zeigt, bleibt der
    Start-Modifikator stehen, und V26 zeigt ihn. Ob er ihn löscht oder die Art zurückstellt,
    entscheidet Klaus; still verschwindet nichts.
- **Begründung:** Ein Verlauf, eine Datei, eine Sicherung: Profile verhalten sich in der
  Werkstatt wie jeder andere Teil des Katalogs.
- **Alternativen:**
  - Ein eigener Editor für Profile mit eigenem `UndoRedo`: Cmd+Z hätte zwei Verläufe, und
    „ungespeichert“ und die Sicherung gäbe es doppelt.
  - Einzelne Start-Modifikatoren einfügen und entfernen wie Ereignisse: Das bräuchte einen
    eigenen Schritt mit dem Grad, und mehrere Entfernungen in einem Profil müssten nach
    absteigender Stelle geordnet werden. Ein ganzes Profil zu kopieren kostet bei einer Handvoll
    Einträgen nichts.

## R11 Der Reiter „Schwierigkeitsgrade“

*Claude, 2026-10-21; Reiter und Formular hat Klaus in der Klärung entschieden*

- **Entscheidung:**
  - **Ort:** ein neues Panel `DifficultyPanel` als vierter Reiter hinter „Statistik“. Die übrigen
    Reiter behalten ihren Platz, und neben der Statistik liegt er dort, wo Klaus Profile
    nachstellt und vergleicht.
  - **Oben** die Auswahl „Grad“ als `OptionButton` mit Leicht, Mittel und Schwer, Vorgabe Leicht.
  - **Darunter** die Start-Modifikatoren des Profils als Tabelle mit den Spalten Ereignis (Titel),
    Wert (in Prozentpunkten, etwa „+5“), von, bis, Grund und Kennung, mit Zeichen für Fehler und
    Warnung wie in der Liste der Ereignisse. Darunter stehen „Neu“, „Duplizieren“ und „Löschen“.
  - **Neben der Tabelle** die Felder des gewählten Start-Modifikators, getrennt durch einen
    Teiler. Unter dem Zeitstrahl hat der Reiter wenig Höhe, deshalb nebeneinander:
    - Ereignis: die Ereignisse über Wahrscheinlichkeit nach Titel. Ein kaputtes Ziel bleibt als
      eigener Eintrag sichtbar, damit V25 und V26 ein Feld haben.
    - Wert in Prozentpunkten, Beginn, Ende, Grund, Kennung.

    Ein Feld übernimmt seinen Wert beim Verlassen oder mit Enter, mit Fehlerkontur und Hinweis
    wie im Formular (R15 und T081 von Feature 002). Die Felder entstehen einmal. Nach einer
    Änderung setzt das Panel nur ihre Werte neu, außer im Feld mit dem Fokus.
  - **„Mittel“** zeigt statt Tabelle und Feldern: „Mittel ist der Katalog ohne
    Start-Modifikatoren. Seine Chancen sind die Grundchancen der Ereignisse.“ (FR-015)
  - **„Neu“** legt in einem Schritt einen Start-Modifikator an:
    - Ereignis: das gewählte Ereignis der Werkstatt, wenn es über Wahrscheinlichkeit kommt, sonst
      das erste solche nach Kennung;
    - Wert 0, Zeitraum das ganze Spiel (FR-002), Grund leer;
    - Kennung aus der Kennung des Ereignisses, im Profil eindeutig gemacht wie bei Ereignissen
      (`CatalogEditor.unique_id()`).

    Der Fokus springt in „Wert“. Bis ein Grund dasteht, zeigt V29 den Fehler. Hat der Katalog kein
    Ereignis über Wahrscheinlichkeit, ist „Neu“ gesperrt.
  - **„Duplizieren“** legt die Kopie direkt dahinter, mit der Kennung `_2`, `_3` und so weiter.
  - **„Löschen“** fragt nicht nach, wie „−“ bei den Wirkungen; Cmd+Z holt den Start-Modifikator
    zurück.
  - **Prüfmeldungen:** Ein Klick auf eine Meldung mit einem Feld `profiles…` wechselt in den
    Reiter, wählt Grad und Zeile und setzt den Fokus ins Feld (FR-016). In der Spalte „Ereignis“
    der Prüfung steht bei solchen Meldungen „Profil Schwer“ statt „–“ (Review, CHK009).
  - **Platz:** Bei Klaus' Fenstergröße 1920 × 925 zeigt der Reiter in der Vorgabe-Teilung
    mindestens vier Zeilen der Tabelle und alle Felder ohne Rollen. Der Agent belegt es mit einem
    Bildschirmfoto (Review, CHK028).
  - **Look:** Es gibt nur Bausteine, die die Werkstatt schon hat: Tabelle mit Zebra,
    `OptionButton`, Eingabefeld mit Fehlerkontur, gedämpfter Text, Fehlerhinweis. Der Style-Guide
    braucht deshalb nichts Neues (Grundsatz IV). Braucht der Agent doch einen neuen Baustein, etwa
    Farben für die Grade, hält er an und fragt; der Baustein kommt dann zuerst in den Style-Guide
    (Review, CHK023).
- **Alternativen:**
  - In den Zellen der Tabelle bearbeiten: Godots `Tree` macht das bei Datum und Prüfhinweisen
    umständlich, und eine Fehlerkontur je Zelle gibt es nicht.
  - Drei Umschaltknöpfe für den Grad: ein neuer Baustein für den Style-Guide. Ein `OptionButton`
    passt zu Simulator und Statistik.
  - Ein Dialog für „Neu“ wie beim Ereignis: Für sechs kurze Felder ist ein Klick und Losschreiben
    schneller (SC-005).

## R12 Die Chance je Grad im Formular

*Claude, 2026-10-21; die Form hat Claude in der Klärung gewählt (`docs/offene-punkte.md`)*

- **Entscheidung:** Bei einem Ereignis über Wahrscheinlichkeit steht unter „Chance“ eine Zeile
  „Je Grad“ mit drei gedämpften Zeilen, nur zum Lesen:

  ```text
  Je Grad   Leicht 1 %
            Mittel 3 %
            Schwer 3 % bis 31.12.1994, 6 % ab 01.01.1995
  ```

  Der Hinweis beim Überfahren sagt „Ändern im Reiter „Schwierigkeitsgrade““.
  - Gerechnet wird im Kern, in `DifficultyProfile.chance_periods()`. Die wirksame Chance ist über
    das ganze Spiel stückweise gleich. Grenzen liegen am Beginn jedes Start-Modifikators auf das
    Ereignis und am Tag nach seinem Ende. Gleiche Nachbarn werden zusammengelegt.
  - Mit drei Abschnitten heißt es etwa „3 % bis 31.12.1989, 5 % vom 01.01.1990 bis 31.12.1994,
    3 % ab 01.01.1995“.
  - Start-Modifikatoren mit einem Fehler zählen nicht mit, wie im Spiel (FR-015).
  - Das Zeitfenster des Ereignisses schneidet die Anzeige nicht zu. So steht es auch in US2,
    Szenario 7.
  - Viele Abschnitte haben keine Grenze; die Zeile eines Grads bricht dann um. Weil gleiche
    Nachbarn zusammengelegt werden, erscheinen nur echte Wechsel (Review, CHK032).
  - Die Anzeige nennt die Tage, wie sie im Profil stehen. Beginnt ein Start-Modifikator mitten im
    Monat, sagt die Warnung V31, ab welcher Würfelrunde er wirkt (R8).
- **Alternativen:**
  - Eine Zeile „Leicht 1 % · Mittel 3 % · Schwer 8 %“: Mit Zeitabschnitten würde sie zu lang.
  - Nur innerhalb des Zeitfensters: Das wiche vom Beispiel in US2, Szenario 7 ab und von den Daten
    im Reiter.

## R13 Simulator: Grad, Neustart beim Wechsel, Vergleich

*Claude, 2026-10-21*

- **Entscheidung:**
  - **Grad:** Hinter dem Seed steht eine Auswahl `%DifficultyOption` mit Leicht, Mittel und
    Schwer, Vorgabe Mittel. „Fahrplan erzeugen“ nimmt den gewählten Grad.
  - **Wechsel des Grads:** Gibt es einen Lauf, baut der Simulator ihn so neu, wie er war, nur mit
    dem neuen Grad:
    - derselbe Seed;
    - derselbe Tag, mindestens aber der Tag des letzten angewandten Eingriffs, wie beim Neustart
      mit Eingriffen in Feature 002;
    - dieselben angewandten Eingriffe (`run.interventions`) in der Reihenfolge des Nachspielens.

    War der Lauf „ohne Eingriffe“ gestartet, ist es der neue auch. Die gesammelten Eingriffe
    bleiben in jedem Fall erhalten (FR-018). Was im neuen Lauf nicht anwendbar ist, etwa die
    Absage eines gewürfelten Termins, den es im neuen Grad nicht gibt, nennt der Hinweis wie nach
    „Neu starten mit Eingriffen“. Eingriffe, die schon im alten Lauf nicht anwendbar waren,
    versucht ein Wechsel nicht neu; das tut „Neu starten mit Eingriffen“ (Review, CHK029). Gebaut
    wird mit dem aktuellen Katalog wie bei jedem Neustart; der Hinweis „Katalog geändert“
    verschwindet danach (Review, CHK033).
  - **Vergleich:** Neben „nur Unterschiede“ steht `%CompareMittel`, ein Häkchen „mit Mittel
    vergleichen“. Ohne Häkchen gilt die Vorgabe aus Feature 002: derselbe Seed und Grad ohne
    Eingriffe. Ein Text `%CompareLabel` nennt den Vergleichslauf: „Vergleich: Schwer ohne
    Eingriffe“ oder „Vergleich: Mittel ohne Eingriffe“ (FR-018).
    - Gerechnet wird der Vergleichslauf, wenn er sich vom Lauf unterscheiden kann: mit Eingriffen,
      wie bisher, oder mit Häkchen und einem anderen Grad als Mittel (US3, Szenario 5).
    - Bei Mittel sind beide Vergleiche gleich, das Häkchen ändert dann nichts (Edge Case).
  - **Texte:** Beim Vergleich mit demselben Grad bleiben die Texte der Markierungen wie in
    Feature 002, denn dort kommt jeder Unterschied von den Eingriffen. Beim Vergleich mit Mittel
    nennen sie den Vergleichslauf, etwa beim Überfahren von „+ neu“: „Neu gegenüber Mittel ohne
    Eingriffe; dort gibt es den Termin nicht.“
  - **Protokoll und Modifikatoren:**
    - Das Protokoll zeigt die Zeilen „Grad“ (R6).
    - Die Liste der Modifikatoren zeigt zuerst die Start-Modifikatoren, gedämpft und mit dem Grad
      vor dem Grund, etwa „Schwer: Anspruchsvolle Kunden“. Sind sie gewählt, ist „Entfernen“
      gesperrt.
    - Die Zeile zur Chance nennt den Anteil des Grads: „Reklamationswelle: Grundchance 3 %, Schwer
      +5, Summe 8 % → 8 %“.
  - **Stand:** Der Text „Stand: 01.01.1990 · Seed 4711“ bleibt, wie er ist. Den Grad zeigt die
    Auswahl daneben, und sie stimmt mit dem Lauf immer überein, denn ein Wechsel baut ihn neu.
  - **Probe des Panels:** Vor jedem Neubau mit `build_run()` setzt das Panel den Grad seiner
    Probe auf den des neuen Laufs. Der Wechsel des Grads baut aus einer eigenen, kurzlebigen Probe
    mit `run.interventions`; die gesammelten Eingriffe bleiben so unberührt.
  - **Ausgenommen:** Der Hinweis auf ausgenommene Ereignisse nennt auch Start-Modifikatoren, die
    wegen eines Fehlers fehlen.
- **Eigene Festlegung:** Ob ein Wechsel des Grads die gesammelten Eingriffe anwendet, lässt die
  Spec offen. „So, wie er war“ ändert genau eine Sache, den Grad.
- **Alternativen:**
  - Beim Wechsel immer mit Eingriffen neu starten: Das wendete Eingriffe an, die Klaus mit „Neu
    starten ohne Eingriffe“ gerade bewusst weggelassen hat.
  - Beim Wechsel zurück auf den 01.01.1985 wie „Fahrplan erzeugen“: Klaus verlöre seinen Stand im
    Spiel.
  - Den Vergleich als Auswahl mit zwei Einträgen: ein Klick mehr; für zwei Zustände reicht ein
    Häkchen wie „nur Unterschiede“.

## R14 Proben mit Grad

*Claude, 2026-10-21*

- **Entscheidung:** `WhatIfProbe` bekommt `difficulty`. In der Datei steht der Schlüssel
  `"difficulty"` mit `"leicht"`, `"mittel"` oder `"schwer"`, immer, auch bei Mittel.
  - Fehlt er, gilt Mittel (FR-019, US3, Szenario 4). So laden auch Proben aus Feature 002.
  - Ein unbekannter Wert macht die Probe unlesbar: `read_file()` gibt `null` zurück und meldet es
    mit `push_error()`, wie bei einem Seed außerhalb des Bereichs (T099 von Feature 002). Unter
    einem geratenen Grad zeigte sie ein anderes Spiel als das gespeicherte.
  - `build_run()` legt den Lauf mit dem Grad an, `from_run()` übernimmt ihn aus dem Lauf, und die
    Liste beim Laden bekommt eine Spalte „Grad“.
- **Alternativen:**
  - Ein unbekannter Grad gilt als Mittel, mit Hinweis: Die Probe zeigte still ein anderes Spiel.
  - Den Schlüssel nur schreiben, wenn der Grad nicht Mittel ist: Mittel hätte zwei Formen in den
    Dateien.

## R15 Statistik: Grade Seed für Seed vergleichen

*Claude, 2026-10-21*

- **Entscheidung:**
  - **Rechnung:** `TimelineStatistics` bekommt eine Liste von Graden, `difficulties`, Vorgabe nur
    Mittel. Ein Spiel ist ein Seed:
    - Die Statistik spielt den Seed in jedem Grad der Liste nacheinander, jeden mit denselben
      Eingriffen (FR-020).
    - Gezählt wird der Seed erst, wenn alle Grade fertig sind. `games_done` zählt solche Seeds.
    - Nach einem Abbruch zählen nur fertige Seeds. Jeder Grad hat also gleich viele Spiele mit
      denselben Seeds.
  - **Ergebnis:** `results()` liefert wie bisher den ersten Grad der Liste, `results_for()` einen
    bestimmten. `accepted` und `refused` stammen aus dem ersten Seed im ersten Grad. Sie sind in
    jedem Grad gleich, weil Eingriffe eine eigene Liste haben (R5).
  - **Oberfläche:** Neben „Anzahl der Spiele“ steht eine Auswahl `%DifficultyOption` mit Leicht,
    Mittel, Schwer und „Alle drei vergleichen“, Vorgabe Mittel wie bisher.
    - Bei einem Grad bleibt die Tabelle, wie sie ist.
    - Der Text über der Tabelle nennt den Grad immer, auch Mittel, an seiner bisherigen Stelle:
      „Ergebnis über 1.000 Spiele, Seeds 1 bis 1.000, Mittel, ohne Eingriffe; gerechnet in 7,9 s.“
      Die Auswahl kann nach der Rechnung schon auf einem anderen Grad stehen. Der Text sagt dann,
      wozu das Ergebnis gehört.
    - Beim Vergleich hat die Tabelle je Ereignis neun Werte, nach Kennzahl gruppiert:
      „Ø Leicht“, „Ø Mittel“, „Ø Schwer“, „Spanne Leicht“ (kleinste bis größte Anzahl, etwa
      „0–14“), „Spanne Mittel“, „Spanne Schwer“, „ohne Leicht“, „ohne Mittel“, „ohne Schwer“.
      Jede Spalte erklärt sich beim Überfahren. So stehen die Werte, die Klaus vergleicht, direkt
      nebeneinander (FR-020).
    - Die Verteilung auf die Jahre zeigt die Statistik beim Vergleich nicht. An ihrer Stelle steht:
      „Die Verteilung auf die Jahre zeigt die Statistik für einen einzelnen Grad.“
- **Laufzeit:** 1.000 Spiele mit dem echten Katalog brauchten in Feature 002 headless 7,9 s
  (Lernnotizen, Phase 9). Drei Grade brauchen damit rund 24 s; SC-004 erlaubt 90 s.
- **Eigene Festlegungen:**
  - Kleinste und größte Anzahl stehen beim Vergleich als „Spanne“ in einer Spalte. Mit zwölf
    Spalten würde es neben Liste und Formular zu eng.
  - Die Verteilung auf die Jahre fehlt beim Vergleich, denn FR-020 verlangt sie nicht. Drei
    Verteilungen nebeneinander bräuchten einen neuen Baustein im Style-Guide.
- **Alternativen:**
  - Drei Statistiken nacheinander: Nach einem Abbruch hätten die Grade verschieden viele Spiele,
    und Leicht wäre lange fertig, bevor Schwer beginnt.
  - Drei Statistiken im Wechsel über einen Koordinator: Er bräuchte einen Schritt je Spiel oder
    müsste beim Abbruch Spiele zurückrechnen.
  - Threads: schon in R17 von Feature 002 verworfen.
  - Die Tabelle nach Grad gruppiert (Leicht: Ø, Spanne, ohne | Mittel: …): Die Werte, die Klaus
    vergleicht, stünden drei Spalten auseinander.

## R16 Textausgabe mit Grad

*Claude, 2026-10-21*

- **Entscheidung:**
  - **Argument:** `--grad leicht`, `--grad mittel` oder `--grad schwer`, Vorgabe mittel. Ein
    anderer Wert ist ein falsches Argument: Meldung und Aufrufhilfe auf stderr, Exit-Code 1, wie
    bei `--seed abc`.
  - **Kopfzeile:** Sie nennt den Grad immer, auch bei Mittel: „# Seed 4711, Grad Schwer, bis
    31.12.1999“ (FR-021).
  - **Zeilen:** Die Zeilen darunter bleiben bei Mittel Zeichen für Zeichen wie in Feature 002.
  - **Woher:** `ScheduleText.plan_lines()` liest den Grad aus dem Lauf.
- **Folge:** In `test_schedule_text.gd` ändern sich die drei Erwartungen an die Kopfzeile.
- **Alternativen:**
  - Den Grad nur nennen, wenn er nicht Mittel ist: Alte Ausgaben blieben gleich, aber eine
    Kopfzeile ohne Grad wäre zweideutig, sobald es Grade gibt.
  - Eine zweite Kopfzeile: Wer Ausgaben vergleicht, müsste zwei Zeilen überspringen.

## R17 Tests

*Claude, 2026-10-21*

- **Entscheidung:**
  - **Grundlinie zuerst:** Bevor sich der Lauf ändert, friert der Agent Fahrplan und Protokoll der
    eingefrorenen Übernahme für die Seeds 1, 4711 und 99999 als Fixtures ein. Der Fahrplan steht
    ohne Kopfzeile darin. Ein Test vergleicht „Mittel“ Zeichen für Zeichen damit. Das ist die feste
    Größe dieses Features: Ohne Profil ist alles wie in Feature 002. Ändert ein Godot-Update die
    Würfel, werden die Fixtures neu erzeugt (R5 von Feature 002).
  - **Dateien aus Feature 002:** Tests, die geschriebenen Text mit einer Fixture vergleichen,
    schlagen fehl, sobald `to_json()` den Abschnitt schreibt. Deshalb in Phase 1:
    - Die eingefrorene Übernahme bleibt Byte für Byte, wie sie ist. Ihre Rundreise ergibt jetzt
      sie selbst mit Komma hinter `"format": 1` und den vier Zeilen des leeren Abschnitts. Eine
      zweite Rundreise ändert nichts mehr.
    - `catalog_minimal.json` und `catalog_500.json` bekommen den leeren Abschnitt. Sie sind keine
      eingefrorenen Belege. An ihnen vergleichen `test_catalog_editor.gd` (Speichern ohne
      Änderung, eine Zeile je Feld, Verwerfen), `test_werkstatt_scene.gd` (Verwerfen) und
      `test_large_catalog.gd` (kanonisch geschrieben) Zeichen für Zeichen. Bei `catalog_500.json`
      ändert sich damit eine Datei, die bisher nie geändert wurde, nur um diese fünf Zeilen.
    - `catalog_alle_arten.json` bekommt einen Abschnitt mit je einem Start-Modifikator. Dann ist
      seine Rundreise wieder bytegleich und deckt den Abschnitt ab.
    - Die Sicherungskopie baut ihren Katalog aus `to_dict()` (R10), sonst fände
      `test_catalog_editor.gd` den Katalog nicht Zeichen für Zeichen darin.
    - Findet der Agent weitere Tests dieser Art, behandelt er sie genauso und nennt sie.
  - **Sichtbare Texte aus Feature 002:** Wo sie sich ändern, ändern sich ihre Tests mit:
    - die Kopfzeile der Textausgabe (`test_schedule_text.gd`, R16);
    - der Ergebnistext der Statistik mit dem Grad (`test_statistics_panel.gd`, R15);
    - die Datei einer Probe mit `"difficulty"` (`test_what_if_probe.gd`, R14);
    - die Liste der Teiler mit dem neuen im Reiter (`test_werkstatt_settings.gd`).

    Gleich bleiben der Stand im Simulator und die Texte der Markierungen beim Vergleich mit
    demselben Grad (R13).
  - **Fixtures:** Test-Kataloge liegen unter `src/test/fixtures/` und tragen ihren Zweck im Namen:
    - je Regel eine kaputte Fixture, `catalog_v25_…` bis `catalog_v31_…` (wie SC-006 von Feature
      002); bei V31 eine Warnung, keine Fehler;
    - je Strukturfehler eine, etwa `catalog_v22_profil_mittel.json`;
    - Kataloge für die Szenarien, etwa `catalog_us1_grade.json` mit 3 % pro Monat, „Schwer +5“,
      „Leicht −2“ und abhängigen Ereignissen für SC-002.
  - **Messbar:**
    - SC-001 mit 100 Wiederholungen;
    - SC-002 mit 100 Seeds und `ScheduleDiff`: Jede Markierung gehört zur Hülle der abhängigen
      Ereignisse nach FR-009;
    - SC-003 über die Statistik mit 1.000 Seeds;
    - SC-006 über den Diff einer gespeicherten Datei, die den Abschnitt schon hat;
    - SC-007 an der Grundlinie.
  - **Eigener Seed (US1, Szenario 2):** Ein gewürfelter Seed hängt am globalen Zufall. Der Test
    setzt ihn mit `seed()` fest, startet zweimal ohne Seed und erwartet zwei verschiedene Seeds
    zwischen 0 und 2.147.483.647. So ist er wiederholbar (Review, CHK027).
  - **Echter Katalog:** Weil `validate()` die Profile prüft, deckt `test_shipped_catalog.gd` FR-014
    ohne Änderung ab. Dazu prüft er ab Phase 3, dass Leicht und Schwer nicht leer sind (Klaus,
    2026-10-22, CHK008). Der Test kommt erst, nachdem Klaus die Profile angelegt hat, denn bis
    dahin ist der echte Katalog ohne Profile, und die Phasen 1 und 2 müssen grün enden.
- **Begründung:** `docs/ki_dev.md`, Abschnitt „Tests“: feste Seeds, nie echte Daten, Ausgaben als
  Ganzes vergleichen.

## R18 Startwerte der Profile

*Vorschlag von Claude, 2026-10-21; Klaus entscheidet in der Werkstatt. Dass die Profile zur
Gesamtabnahme gefüllt sind, hat Klaus am 2026-10-22 im Review entschieden (CHK008).*

Die Profile im echten Katalog legt Klaus selbst in der Werkstatt an, zur Abnahme von Phase 3. Das
ist zugleich die Probe für SC-005. Zur Gesamtabnahme haben Leicht und Schwer je mindestens einen
Start-Modifikator; `test_shipped_catalog.gd` prüft das, aber keine Werte. Als Ausgangspunkt
schlägt Claude vor: Unangenehmes kommt bei „Leicht“ seltener und bei „Schwer“ öfter, Erfreuliches
umgekehrt. Jeder Start-Modifikator gilt das ganze Spiel.

| Ereignis | Grundchance (Mittel) | Leicht | Schwer |
|---|---|---|---|
| Großkunde meldet sich | 6 % | +1 → 7 % | −2 → 4 % |
| Konkurrent eröffnet | 3 % | −1 → 2 % | +2 → 5 % |
| Konkurrent gibt auf | 2,5 % | +1 → 3,5 % | −1 → 1,5 % |
| Lieferengpass | 4 % | −2 → 2 % | +2 → 6 % |
| Neubaugebiet in der Nähe | 4 % | +1 → 5 % | −1 → 3 % |
| Reklamationswelle | 3 % | −1 → 2 % | +2 → 5 % |

Das blockiert nichts: Die Werte ändert Klaus jederzeit und prüft sie mit dem Vergleich in der
Statistik (US4).

## R19 Wohin die Auswahl des Grads gehört

*Klaus, 2026-10-22, im Review nach Empfehlung (CHK021)*

- **Entscheidung:** Den Bildschirm, auf dem der Spieler den Grad wählt, bringt 01-05. Es heißt
  dann „Neues Spiel: Startdatum, Seed und Grad“ und übergibt alles mit
  `Timeline.start_game(seed, difficulty)`. In Phase 6 bekommt der Eintrag in
  `docs/features/Feature_Ideas.md` diesen Hinweis; die Spec bleibt, wie sie ist.
- **Begründung:** Startdatum, Seed und Grad stehen alle beim Start fest. Ein Bildschirm dafür
  reicht.
- **Alternativen (von Klaus verworfen):**
  - Die Auswahl kommt mit 11-05 „Spielziel und Schwierigkeitsgrade“.
  - Der Bildschirm bekommt eine eigene Nummer im Backlog.
