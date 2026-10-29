#!/bin/zsh
# Erzeugt die Klassenreferenz der installierten Godot als XML, offline und in genau dieser Version.
#
# Feature 008, T039a (Klaus, 2026-10-29). Aufruf vom Repo-Root:
#
#   tools/godot_referenz/erzeuge.sh
#
# Ergebnis: godot_referenz/klassen/<Klasse>.xml, etwa Node.xml, RegEx.xml, @GDScript.xml, dazu
# godot_referenz/version.txt mit der Ausgabe von `Godot --version`. Der Ordner steht in .gitignore
# und wird bei jedem Lauf neu gefüllt.
#
# Die Dateien enthalten die Signaturen: Klassen mit Erbfolge, Methoden mit Parametern und
# Standardwerten, Eigenschaften, Signale, Konstanten und Enums. Beschreibungstexte fehlen; die stehen
# nur im Quellcode von Godot (Klaus, 2026-10-29: erst Signaturen, Texte später).
#
# Godot legt die Dateien unter doc/classes/, modules/*/doc_classes/ und platform/*/doc_classes/
# ab; das Skript legt sie flach in klassen/ zusammen, die Namen sind eindeutig. --doctool endet
# auch bei einem Fehler mit Exit 0, deshalb prüft das Skript das Ergebnis selbst. Nebenbei löscht
# --doctool den Hilfe-Cache des Editors; der Editor baut ihn beim nächsten Start neu.
#
# Exit 0: erzeugt. Exit 1: Godot lieferte nichts Brauchbares. Exit 2: Godot fehlt, die Version passt
# nicht zum Projekt oder der Aufruf stimmt nicht. Godot liegt in $GODOT oder unter /Applications.

set -u
cd "$(dirname "$0")/../.." || exit 2

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ZIEL="godot_referenz"
ROH="$ZIEL/.roh"

if [[ $# -gt 0 ]]; then
    echo "Aufruf: tools/godot_referenz/erzeuge.sh" >&2
    exit 2
fi
if [[ ! -x "$GODOT" ]]; then
    echo "Godot fehlt unter $GODOT. Pfad über die Umgebungsvariable GODOT angeben." >&2
    exit 2
fi

# Die Version muss zum Projekt passen: config/features in src/project.godot nennt Haupt- und
# Nebenversion, etwa „4.7“; `Godot --version` beginnt mit „4.7.2.stable…“.
VERSION="$("$GODOT" --version 2>/dev/null | tail -1)"
PROJEKT="$(sed -n 's/^config\/features=PackedStringArray("\([0-9.]*\)".*/\1/p' src/project.godot)"
if [[ -z "$PROJEKT" || "$VERSION" != "$PROJEKT".* ]]; then
    echo "Godot $VERSION passt nicht zum Projekt (src/project.godot nennt ${PROJEKT:-keine Version})." >&2
    exit 2
fi

rm -rf "$ZIEL"
mkdir -p "$ROH" "$ZIEL/klassen"
"$GODOT" --headless --doctool "$PWD/$ROH" > "$ZIEL/doctool.txt" 2>&1
find "$ROH" -name "*.xml" -exec mv {} "$ZIEL/klassen/" \;
rm -rf "$ROH"

ANZAHL=$(find "$ZIEL/klassen" -name "*.xml" | wc -l | tr -d ' ')
for probe in Node RegEx @GDScript; do
    if [[ ! -s "$ZIEL/klassen/$probe.xml" ]]; then
        echo "Fehler: $probe.xml fehlt; Godot meldete: $(grep -m1 ERROR "$ZIEL/doctool.txt")" >&2
        exit 1
    fi
done
echo "$VERSION" > "$ZIEL/version.txt"
rm -f "$ZIEL/doctool.txt"
echo "erzeugt: $ANZAHL Klassen von Godot $VERSION in $ZIEL/klassen/"
