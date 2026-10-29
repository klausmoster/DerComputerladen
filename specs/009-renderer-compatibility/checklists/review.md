# Anforderungs-Review Checklist: Renderer Compatibility

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: Renderer und Treiber, Bild, Selbsttest und Belege, Regeln und
Doku.
**Created**: 2026-10-29
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

Jeder Punkt hat einen Vorschlag von Claude („→ Vorschlag“). Was er an Spec oder Plan ändern würde,
steht dabei. Eingearbeitet wird erst nach Klaus' Freigabe; sie kam am 2026-10-29 für alle Punkte,
und alle sind eingearbeitet. Die Punkte ab „Aus der Prüfung des
Vertrags“ stammen von Stil-, Text- und Architektur-Prüfer, von Claude nachgeprüft (Verfassung,
Grundsatz VI).

## Klarheit

- [x] CHK001 Woran misst sich „das Bild bleibt gleich“? FR-004 nennt als feste Größe nur „das Bild
  des Titels“, SC-002 und SC-003 dagegen alle Fotos des Selbsttests. [Clarity, Conflict, Spec §FR-004,
  §SC-002]
  → Vorschlag: FR-004 endet mit „Maßstab sind die Fotos des Selbsttests gegen die Referenzbilder
  (SC-002, SC-003)“; „das Bild des Titels“ entfällt.
- [x] CHK002 Ist „alle Schritte“ eindeutig, obwohl der Selbsttest seit Feature 007 von 37 auf 45
  Schritte gewachsen ist und die Spec unter „Begriffe“ die 37 aus dem Boot-Camp-Lauf nennt?
  [Clarity, Spec §Begriffe, §SC-001]
  → Vorschlag: Unter „Begriffe“ nach „37 Schritte“ ergänzen: „(damals; heute hat der Selbsttest 45)“.
  SC-001 bleibt bei „alle Schritte“, weil die Zahl mit jedem Feature wachsen kann.

## Vollständigkeit

- [x] CHK003 Deckt die Spec die Zeitleisten-Werkstatt ab? Sie läuft im selben Projekt und damit auch
  mit Compatibility, zeigt Open Sans mit Kantenglättung und ist vom Selbsttest nicht erfasst. Kein FR
  und kein Schritt im Quickstart verlangt einen Blick darauf. [Gap, Coverage]
  → Vorschlag: FR-004 bekommt einen Satz: „Auch die Werkstatt startet und zeigt ihre Schrift wie
  bisher; das prüft Claude im echten Fenster bei 1920 × 925.“ Dazu ein Schritt im Quickstart.
- [x] CHK004 Ist festgelegt, wie der automatische Rückfall auf ANGLE unter Windows belegt wird? Der
  Quickstart erzwingt ANGLE per Startoption; ob Godot auf einem Rechner mit schlechtem Treiber von
  selbst wechselt, lässt sich ohne so einen Rechner nicht zeigen. [Gap, Measurability, Spec §FR-006]
  → Vorschlag: Unter „Assumptions“: „Der selbsttätige Rückfall auf ANGLE ist Godots Verhalten und
  wird nicht eigens belegt; belegt wird, dass ANGLE im Export steckt und läuft (Start mit
  `opengl3_angle`).“
- [x] CHK005 Ist die Meldung bei fehlender Grafik belegt? Die Spec sagt unter „Edge Cases“, Godot
  zeige ohne OpenGL 3.3 und Direct3D 11 „seine eigene Fehlermeldung“. Für Forward+ war das in 007
  belegt (R13), für Compatibility steht es nirgends. [Assumption, Spec §Edge Cases]
  → Vorschlag: In research.md als Vermutung kennzeichnen und beim Plan nachsehen, was der Quelltext
  von 4.7.2 dazu tut; die Spec sagt dann „Godot beendet sich, laut Quelltext mit Meldung“ oder „ohne
  Meldung“.
- [x] CHK006 Gibt es eine Anforderung an die Dauer? Compatibility könnte auf dem Mac langsamer oder
  schneller zeichnen; 007 misst nur, dass `titel` schneller ist als `titel_echtzeit`. [Gap,
  Non-Functional]
  → Vorschlag: keine neue Anforderung. Unter „Assumptions“: „Die Dauer eines Laufs steht im Beleg und
  wird mit dem Lauf aus 007 verglichen; ein Unterschied über das Doppelte geht an Klaus.“

## Widerspruchsfreiheit

- [x] CHK007 Passt die Versionsangabe zusammen? FR-009 sagt „mit neuer Version“, research.md R6 und
  plan.md legen 3.0.0 (MAJOR) fest. [Consistency, Spec §FR-009, Plan R6]
  → Vorschlag: kein Eingriff in die Spec; die Version ist Plan. Klaus bestätigt MAJOR beim Beschluss
  in Phase 2.
- [x] CHK008 Ist die Reihenfolge „erst Regel, dann Einstellung“ (R7) in der Spec gedeckt? Ablauf 3
  hat Priorität P2 und klingt nach „am Ende“. [Consistency, Spec §User Story 3, Plan R7]
  → Vorschlag: In Ablauf 3 unter „Why this priority“ ergänzen: „Die Regel ändert sich trotzdem zuerst,
  vor der Einstellung (plan.md, R7).“

## Abdeckung

- [x] CHK009 Nennt die Spec, dass sich der Godot-Editor beim Öffnen mit umstellt? Klaus arbeitet im
  Editor; er startet danach mit Compatibility neu. Das steht nur im Quickstart. [Coverage, Assumption]
  → Vorschlag: so lassen; es betrifft die Arbeit, nicht den Spieler. Der Quickstart reicht.
- [x] CHK010 Nennen Plan, R3 und Vertrag alle Beispieldaten, die noch `forward_plus` und Metal
  tragen? Genannt ist nur `kopieren_erwartet.txt`; dazu kommen `protokoll_erwartet.txt`,
  `kopieren_nicht_beschreibbar.txt` und `test_selbsttest_protokoll.gd:261`. [Completeness, Plan R3;
  contracts/renderer.md] (vom Architektur-Prüfer unter „Unsicher“, von Claude nachgezählt)
  → Vorschlag: Die Liste in R3, Vertrag und plan.md um die drei Stellen ergänzen.
- [x] CHK011 Stimmt die Phasennummer in R7? R7 sagt „in der ersten Phase“, im Plan ist es Phase 2
  (Phase 1 ist die Vorbereitung). [Consistency, Plan R7] (Architektur-Prüfer, „Unsicher“)
  → Vorschlag: R7: „in Phase 2, vor der Einstellung in Phase 3“.

## Aus der Prüfung des Vertrags: Architektur

- [x] CHK012 Gehören die neuen Anzeigenamen „ANGLE“ und „OpenGL ES“ in die Textklasse des
  Selbsttests? Der Plan nennt sie selbst Texte, legt sie aber in `SelbsttestSystem.GRAFIK_API` ab;
  der Leitfaden, Abschnitt „Werkzeuge“, gibt dem Selbsttest „eine eigene Textklasse
  (`SelbsttestTexte`)“, und deren Kopf sagt „Alle Texte des Selbsttests an einer Stelle“.
  [Consistency, Leitfaden „Werkzeuge“, AR-04; Plan R3] (Architektur-Prüfer B1, bestätigt: Die Namen
  gehen über `SelbsttestTexte.systemzeile()` auf die Zusammenfassung.)
  → Vorschlag: `GRAFIK_API` zieht in Phase 3 ganz nach `SelbsttestTexte`, `SelbsttestSystem` liest
  sie dort. Aufwand: klein, Teil der Aufgabe für den Agent. Die Lücke L1 im Leitfaden (ob übersetzte
  Produktnamen Texte sind) kommt nach `docs/offene-punkte.md`.

## Aus der Prüfung des Vertrags: Text

- [x] CHK013 Ist „Kantenglättung“ eindeutig? FR-009 und FR-009a meinen die Glättung des ganzen
  Bildes durch den Renderer; der Style-Guide verlangt unter „Werkzeuge“, „Schrift“, Open Sans „mit
  Kantenglättung“ und im README, „Schrift“, Ark Pixel und Doto „ohne Kantenglättung“. Derselbe
  Style-Guide hätte dann ein Wort für zwei Dinge (Sprache, „Nicht“). [Ambiguity, Spec §FR-009,
  §FR-009a] (Text-Prüfer A, bestätigt.)
  → Vorschlag: In FR-009 und FR-009a „Kantenglättung des Bildes (MSAA, FXAA)“; im Satz für den
  Style-Guide dazu: „Die Kantenglättung der Schrift regelt der Abschnitt Schrift.“ Der Stil-Prüfer
  fand dasselbe (B3).
- [x] CHK014 Stimmt die Liste der Mittel zwischen Verfassung und Style-Guide überein? FR-009 nennt
  „HDR, Kantenglättung, Compute“, FR-009a „HDR, Kantenglättung und Glühen über Weiß“ mit Verweis auf
  die Verfassung, die das Glühen nicht nennt. [Consistency, Spec §FR-009, §FR-009a] (Text-Prüfer B,
  bestätigt.) Nachgeprüft in `godot_referenz/handbuch/tutorials/rendering/renderers.rst`: In
  Compatibility fehlen 2D-HDR, MSAA in 2D, FXAA und SMAA; Glühen gibt es dort, nur ohne HDR nicht über
  Weiß. Die Klammer in FR-009 stimmt also, „Kantenglättung“ allein wäre ungenau (MSAA in 3D gibt es
  in Compatibility).
  → Vorschlag: FR-009a: „Glühen über Weiß, eine Folge von HDR“ und „Farbwerte über 1,0“ statt „über
  Weiß“, weil die Palette kein Weiß kennt; die Klammer in FR-009 wird „(HDR, Kantenglättung des
  Bildes in 2D, Compute)“.
- [x] CHK015 Ist klar, was aus dem Satz „Keine Rücksicht auf Compatibility/Mobile oder
  GLES-Beschränkungen“ in CLAUDE.md wird? FR-009 sagt nur „Die Verbote für Mobile und Android
  bleiben“; Compatibility und der Rückfall auf OpenGL ES unter Linux sind nach dem Wechsel gewollt.
  [Clarity, Spec §FR-009; CLAUDE.md „Harte Rahmenbedingungen“] (Text-Prüfer C, bestätigt.)
  → Vorschlag: FR-009 ergänzen: „Aus ‚Keine Rücksicht auf Compatibility/Mobile oder
  GLES-Beschränkungen‘ wird ‚Keine Rücksicht auf den Renderer Mobile‘; Compatibility und der Rückfall
  auf OpenGL ES sind gewollt.“

## Aus der Prüfung des Vertrags: Stil

- [x] CHK016 Nennt FR-004 alles, was der Renderer selbst malt? Es fehlen der Startgrund in
  `anzeige-grund` ohne Logo der Engine und die schwarzen Ränder der ganzzahligen Skalierung (README,
  „Bildaufbau“, „Startgrund“; „Raster und Auflösung“). Der Vertrag sagt nur „Hintergrundfarbe“ und
  lässt offen, ob `default_clear_color` oder `boot_splash/bg_color` gemeint ist. [Completeness, Spec
  §FR-004; contracts/renderer.md] (Stil-Prüfer B1, bestätigt.)
  → Vorschlag: FR-004 um „Startgrund in `anzeige-grund` ohne Logo der Engine, schwarze Ränder bei
  krummen Fenstergrößen“ ergänzen; der Vertrag nennt beide Schlüssel als unverändert.
- [x] CHK017 Können die Referenzbilder FR-004 überhaupt belegen? Der Selbsttest fotografiert das Bild
  des Viewports, „immer 640 × 360“ (`selbsttest_laeufer.gd:295`). Vergrößerung ins Fenster, schwarze
  Ränder und Startgrund sind auf keinem Foto. [Measurability, Spec §FR-004, §SC-002, §SC-003]
  (Stil-Prüfer B2, bestätigt.)
  → Vorschlag: SC-002 und SC-003 sagen offen, dass die Fotos das Bild in 640 × 360 belegen. Dazu ein
  Blick ins echte Fenster je System: auf dem Mac ein Bildschirmfoto durch Claude beim Start und bei
  einer krummen Fenstergröße; unter Windows und Linux ein kurzer Blick durch Klaus, im Quickstart als
  Prüfliste. Aufwand: klein, je System eine Minute. Zusammen mit CHK003 (Werkstatt).
- [x] CHK018 Ist die Zeile mit den Godot-Einstellungen im Style-Guide noch vollständig? Sie nennt
  `snap_2d_transforms_to_pixel`, nicht `snap_2d_vertices_to_pixel`, das das Projekt auch setzt; den
  Renderer nennt sie nicht. [Completeness, Style-Guide README „Raster und Auflösung“; Spec §FR-009a]
  (Stil-Prüfer B4, bestätigt.)
  → Vorschlag: Der Satz aus FR-009a kommt ans Ende dieser Zeile, mit „Renderer Compatibility (Verfassung,
  Grundsatz I)“ und dem fehlenden `snap_2d_vertices_to_pixel`. Damit ist auch geklärt, wohin der Satz
  gehört (Lücke aus dem Text-Prüfer).

## Lücken im Maßstab

Eingetragen in `docs/offene-punkte.md` (2026-10-29), nicht Teil dieses Features:
- Leitfaden, „Werkzeuge“: Sind übersetzte Produktnamen wie „Metal“ oder „ANGLE“ Texte oder Daten?
  (Architektur-Prüfer L1)
- Style-Guide, „Bewegung“: Womit Leuchtschrift und Monitorflimmern gemacht werden, Phasenbilder oder
  Effekte; ob `modulate` über 1,0 erlaubt ist. (Stil-Prüfer)
- Style-Guide, „Startgrund“: Ob die Ränder auch während des Startgrunds schwarz sind. (Stil-Prüfer)
- Style-Guide: ob Anzeigenamen in Werkzeugen der Kurzform der Engine folgen („D3D12“) oder
  ausgeschrieben werden („Direct3D 12“). (Text-Prüfer)

## Ergebnis

18 Punkte: 9 von Claude, 2 vom Architektur-Prüfer unter „Unsicher“ (nachgezählt), 1 Befund vom
Architektur-Prüfer, 3 vom Text-Prüfer, 3 vom Stil-Prüfer; dazu 4 Lücken im Maßstab. Alle Befunde der
Prüfer hat Claude nachgeprüft, keiner war falsch; zusammengelegt sind Text A und Stil B3
(Kantenglättung). Klaus hat am 2026-10-29 alle 18 Vorschläge freigegeben; sie sind in Spec, Plan,
`research.md`, Vertrag und Quickstart eingearbeitet, die Lücken stehen in `docs/offene-punkte.md`.
