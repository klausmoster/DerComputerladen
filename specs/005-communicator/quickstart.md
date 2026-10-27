# Quickstart: Communicator als Steuerelement prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was gebaut wird, steht in den Verträgen
[communicator.md](contracts/communicator.md) und [titelbildschirm.md](contracts/titelbildschirm.md);
hier steht nur, wie man es prüft. Alle Befehle laufen vom Repo-Root aus. Der Quickstart von Feature
004 gilt weiter für Wege, Spielstände und Texte; geändert hat sich nur, worauf die Seiten stehen.

## Voraussetzungen

- Godot 4.7.2 unter `/Applications/Godot.app/Contents/MacOS/Godot`, GUT 9.7.1 im Projekt.
- Nur ein Testlauf zur selben Zeit: Alle Sitzungen teilen sich `user://`.
- Für „ohne Spielstände“ den Ordner beiseitelegen wie im Quickstart von Feature 004, nicht löschen.

## Automatisch

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün, zweimal mit derselben Zahl. Darunter `test_communicator.gd` mit Fahrt,
Umkehr, Probeseite und gesperrter Eingabe (SC-002, SC-003, SC-005) und `test_title_screen.gd` mit
Platz und Überschneidungen (SC-004, SC-006).

Startprobe, erwartet: Exit 0 und keine Ausgabe:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -d --path src --quit-after 60
```

## Von Hand im echten Fenster

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src
```

1. **Erscheinen** (US1): Titelbild T-02, der Organizer gleitet rechts unten herein, ohne zu federn;
   auf dem LCD steht HAUPTMENÜ, vorgewählt „Weiterspielen“ oder „Neues Spiel“ als dunkler Balken mit
   heller Schrift. Logo, Untertitel und Versionszeile frei, kein Endlospapier.
2. **Sofort Enter** gleich nach dem Start, mit Spielständen: „Weiterspielen“ wirkt, das Gerät fährt
   hinaus, dann der Spielbildschirm.
3. **Auswahl**: Maus über die Zeilen, Pfeiltasten, Tab, Rechtsklick. Der Hinweis steht links neben
   dem Gerät auf Höhe der Zeile; nicht verfügbare Einträge gedämpft, auch gewählt.
4. **Wege** (US2): „Neues Spiel“ → SCHWIERIGKEIT auf demselben LCD, das Gerät steht still; Esc
   zurück. „Spiel laden“ → SPIELSTÄNDE mit vier Spalten; mit mehr als sechs Spielständen scrollen
   mit Mausrad und Pfeilen; „Löschen …“ → WELCHES LÖSCHEN?; eine Zeile → LÖSCHEN?; „Abbrechen“.
5. **Spiel beginnen**: einen Grad wählen. Das Gerät fährt hinaus, dann der Spielbildschirm. Ein
   zweites Enter während der Fahrt tut nichts; in der Liste der Spielstände steht danach nur ein
   neues Spiel.
6. **Rückkehr**: „Zum Hauptmenü“ im Spiel; der Titel erscheint, das Gerät fährt wieder herein.
   Sofort Esc drücken: Im Hauptmenü tut Esc nichts, auch während der Fahrt.
7. **Beenden**: schließt sofort, ohne Fahrt.
8. **Vollbild** mit Ctrl+Cmd+F während der Fahrt herein: Das Gerät kommt sauber in seiner Endlage an.
9. **Kleinstes Fenster**: Fenster auf 640 × 360 ziehen (Faktor 1); jede Zeile lesbar, die Anordnung
   wie bei jedem anderen Faktor.
10. **Liste mit Rollmarke**: mehr als sechs Spielstände, „Löschen …“ wählen; die Rollmarke nach
    unten ist im dunklen Balken hell zu sehen.

## Zuordnung zu den Phasen

| Phase | Abschnitte |
|---|---|
| 1 Style-Guide | Abnahme des Style-Guides durch Klaus, kein Quickstart |
| 2 Grafik | G-02 und T-02 als Bild ansehen, gerastert ×4 zum Prüfen |
| 3 Kern Communicator | Automatisch: `test_communicator.gd`; Bildschirmfoto der Probeszene |
| 4 Seiten auf der Anzeige | Automatisch: `test_main_menu.gd`, `test_save_list.gd`; Bildschirmfotos |
| 5 Titel | alles unter „Von Hand“, dazu alle Tests |
| 6 Abschluss | alles noch einmal, Gesamtabnahme |
