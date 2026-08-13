---
feature_id: ""
feature_name: ""
feature_system: ""
feature_status: "idee"
feature_phase: "spec"
godot_knoten: []
godot_dateien: []
godot_signale_raus: []
godot_signale_rein: []
lernen_ziele: []
lernen_neue_konzepte: []
bezug_haengt_ab_von: []
bezug_blockiert: []
tags:
- feature
---
# <feature_id> <feature_name>

<!-- SKILL-ROUTING (vom /dcl-feature-Skill gelesen; NICHT in die fertige Feature-Datei kopieren)
typ: Feature
zielordner: docs/features
dateiname: <feature_id>-<slug>
index_seite: docs/features/Features.md
hinweis: "<feature_id> = SS-NN (System-Nummer 01–11, laufende Nummer), <slug> = kurzer kebab-case-Name. Beispiel: 02-01-bible-importer"
-->

<!--
=====================  HINWEISE FÜR MENSCH & KI  =====================

WOZU DIESES DOKUMENT DA IST
Es ist die Gesprächsgrundlage für „wir arbeiten jetzt an Feature xy". Es hat
zwei Leser, und beide brauchen etwas anderes:
  1. Klaus, der im Godot-Editor baut — braucht Klarheit über das Ziel, die
     Schritte und die Godot-Konzepte, die dabei vorkommen.
  2. Claude, der Vorarbeit leistet — braucht einen eindeutigen technischen
     Vertrag, um beim Zuarbeiten nicht zu raten.
Deshalb ist "## + Technischer Vertrag" nicht optional.

ROLLENVERTEILUNG
  Claude  schreibt Specs, beschafft Informationen (Recherche, Godot-Doku,
          Fachquellen), bereitet den Weg vor, erklärt Konzepte, gibt Review
          und erstellt auf Wunsch Beispielcode zum Lernen.
  Klaus   arbeitet in Godot — Szenen, Nodes, GDScript. Das ist ausdrücklich
          seine Arbeit und wird ihm nicht abgenommen.

  Alles, was Claude an Code erzeugt, sieht Klaus sich VORHER an. Es ist
  Lern-/Vorlagenmaterial, das er prüft und übernimmt — kein fertiges Ergebnis,
  das ungesehen ins Projekt wandert.

  Die Grenze ist fließend: Einzelne Tasks gehen im Gespräch an Claude über.
  Das ist der Normalfall, nicht die Ausnahme. Claude schlägt bei unklarer Lage
  eine Aufteilung vor, setzt sie aber nicht eigenmächtig um.

FRONTMATTER-FELDER
- feature_id      "SS-NN" — SS = System (01–11, siehe Features.md), NN = laufend.
                  Stabil, wird nie geändert; Wikilinks und Commits verweisen darauf.
- feature_status  idee | spezifiziert | in-arbeit | fertig
- feature_phase   spec | plan | tasks  (siehe Phasen unten)
- godot_*         Bauteile: Knoten/Autoloads, betroffene Dateien, Signale raus/rein.
                  In Phase "spec" noch leer, wird in "plan" gefüllt.
- lernen_ziele    Was Klaus an diesem Feature lernen will.
- lernen_neue_konzepte  Godot-Konzepte, die hier zum ersten Mal vorkommen —
                  die gehören vor dem Bauen erklärt, nicht mittendrin.
- bezug_*         feature_id-Listen. haengt_ab_von = muss vorher fertig sein.

DIE DREI PHASEN — das Dokument wächst, es wird nicht auf einmal geschrieben:
  spec   Problem, Lösung, Akzeptanzkriterien. Noch KEIN Godot-Detail.
         Frage: WAS tut das Feature und woran merken wir, dass es fertig ist?
  plan   Technischer Vertrag, godot_*-Felder, Schritte, Lernkonzepte.
         Frage: WIE wird es gebaut und in welcher Reihenfolge?
  tasks  Umsetzung. Entscheidungen und Lernnotizen wandern WÄHREND der Arbeit
         hier hinein, nicht danach.

FREITEXT gehört unter "## +"-Überschriften (Konvention wie in der game_bible).
Nicht benötigte Abschnitte leer lassen, nicht löschen.
======================================================================
-->

## + Problem
<!-- Was fehlt, was geht nicht, was nervt? Aus Sicht des Spiels, nicht des Codes.
     Ein bis zwei Absätze. Wenn hier nichts Konkretes steht, ist das Feature
     noch nicht spezifiziert. -->

## + Lösung
<!-- Wie sieht es aus, wenn es da ist — fachlich, nicht technisch. Was kann der
     Spieler danach, oder was kann die Simulation danach abbilden? -->

## + Technischer Vertrag
<!-- Genug Präzision, dass niemand raten muss — weder Klaus im Editor noch
     Claude beim Zuarbeiten. Gehört hier hinein:
       - Betroffene/neue Dateien mit Pfad
       - Klassen: class_name, extends, ob Autoload oder Resource
       - Öffentliche Methoden mit vollständiger GDScript-Signatur inkl. Typen
       - Signale mit Parametern
       - Datenformen (Dictionary-Schlüssel, Resource-Felder, Frontmatter-Felder)
       - Was ausdrücklich NICHT dazugehört (Abgrenzung gegen Scope-Creep)
     In Phase "spec" bleibt der Abschnitt leer. -->

## + Schritte
<!-- Die Reihenfolge, in der gebaut wird — kleine, einzeln überprüfbare Schritte.
     Je Schritt in eckigen Klammern, wer ihn übernimmt: [K] Klaus, [C] Claude.
     Default ist [K]; [C] sind Zuarbeiten (Recherche, Gerüst, Testdaten,
     Beispielcode zum Ansehen). Besitzer dürfen im Gespräch wechseln.
     Beispiel:
       1. [C] Godot-Doku zu ResourceLoader zusammenfassen
       2. [K] Resource-Klasse anlegen und Felder definieren
       3. [C] zehn Testdatensätze aus der game_bible ziehen
       4. [K] Loader schreiben
       5. [C] Review -->

## + Akzeptanzkriterien
<!-- Prüfbare Aussagen, keine Absichten. Gut: "advance_one_month() vom 31.01.
     landet auf dem 01.02." Schlecht: "Kalender funktioniert korrekt".
     Wenn möglich als Kommandozeile, die es zeigt. -->

## + Entscheidungen
<!-- Was wurde erwogen und verworfen, und warum. Das ist in sechs Monaten der
     wertvollste Teil des Dokuments — nicht was gebaut wurde, sondern warum
     nicht anders. Format: Entscheidung, Alternative, Grund. -->

## + Offene Fragen
<!-- Bekannte Lücken, Verdachtsmomente, Dinge die später beißen werden.
     Auch bewusst in Kauf genommene Schwächen — dann als solche benennen. -->

## + Lernnotizen
<!-- Was Klaus beim Bauen über Godot gelernt hat. Stichpunkte genügen.
     Auch: was unklar blieb — das ist der Stoff fürs nächste Gespräch. -->
