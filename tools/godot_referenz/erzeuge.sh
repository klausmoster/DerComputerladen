#!/bin/zsh
# Erzeugt die Klassenreferenz der installierten Godot als XML, in genau dieser Version, und holt auf
# Wunsch die Beschreibungstexte und das Handbuch dazu.
#
# Feature 008, T039a, T039b, T039d (Klaus, 2026-10-29). Aufruf vom Repo-Root:
#
#   tools/godot_referenz/erzeuge.sh                        nur Signaturen, offline
#   tools/godot_referenz/erzeuge.sh --texte                Signaturen mit Beschreibungstexten
#   tools/godot_referenz/erzeuge.sh --texte --handbuch     dazu das Handbuch
#
# Ergebnis, alles in godot_referenz/ (steht in .gitignore):
# - klassen/<Klasse>.xml, etwa Node.xml, RegEx.xml, @GDScript.xml: Klassen mit Erbfolge, Methoden mit
#   Parametern und Standardwerten, Eigenschaften, Signale, Konstanten und Enums; mit --texte auch
#   die Beschreibungen.
# - handbuch/: die Seiten des Handbuchs als reStructuredText (.rst), ohne classes/, das dieselben
#   Klassen noch einmal enthält, und ohne Bilder.
# - version.txt: Godot-Version und die Commits, aus denen Texte und Handbuch stammen.
#
# --texte und --handbuch laden von GitHub, nur mit Klaus' Erlaubnis (2026-10-29: beides, rund
# 15 MB). Geholt wird ein Teil-Klon ohne Geschichte, der nur die nötigen Dateien überträgt:
# - Texte aus github.com/godotengine/godot, Tag <Version>-stable, etwa 4.7.2-stable, also genau der
#   Stand der installierten Godot; die Ordner doc/classes/, modules/*/doc_classes/ und
#   platform/*/doc_classes/. --doctool mischt die Texte dann in die Signaturen.
# - Handbuch aus github.com/godotengine/godot-docs, Zweig <Haupt>.<Neben>, etwa 4.7; die .rst-Dateien.
# Die Klone liegen außerhalb des Repos im Cache, ${XDG_CACHE_HOME:-~/.cache}/der-computerladen/, je
# Version ein Ordner. So lädt jeder Rechner jede Version nur einmal, auch über alle Worktrees; ein
# neuer Worktree kopiert nur. Neu geladen wird erst, wenn sich die Version ändert.
#
# Godot legt die Klassen unter doc/classes/, modules/*/doc_classes/ und platform/*/doc_classes/ ab;
# das Skript legt sie flach in klassen/ zusammen, die Namen sind eindeutig. --doctool endet auch bei
# einem Fehler mit Exit 0, deshalb prüft das Skript das Ergebnis selbst. Nebenbei löscht --doctool
# den Hilfe-Cache des Editors; der Editor baut ihn beim nächsten Start neu.
#
# Exit 0: erzeugt. Exit 1: Godot oder ein Download lieferte nichts Brauchbares. Exit 2: Godot fehlt,
# die Version passt nicht zum Projekt oder der Aufruf stimmt nicht. Godot liegt in $GODOT oder unter
# /Applications.

set -u
cd "$(dirname "$0")/../.." || exit 2

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ZIEL="godot_referenz"
ROH="$ZIEL/.roh"
HANDBUCH="$ZIEL/handbuch"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/der-computerladen"

TEXTE=0
MIT_HANDBUCH=0
for argument in "$@"; do
    case "$argument" in
        --texte) TEXTE=1 ;;
        --handbuch) MIT_HANDBUCH=1 ;;
        *)
            echo "Aufruf: tools/godot_referenz/erzeuge.sh [--texte] [--handbuch]" >&2
            exit 2
            ;;
    esac
done
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
# „4.7.2.stable.official.ed1daf0bf“ → Tag „4.7.2-stable“.
TAG="${VERSION%%.stable*}-stable"
QUELLE_GODOT="$CACHE/godot-$TAG"
QUELLE_HANDBUCH="$CACHE/godot-docs-$PROJEKT"

# Holt [ref] aus [url] als Teil-Klon nach [ordner]: ohne Geschichte, und von den Dateien nur die, die
# die Muster danach nennen (Schreibweise wie .gitignore). Ist der Ordner schon auf diesem Stand, lädt
# es nichts.
hole() {
    local url="$1" ref="$2" ordner="$3"
    shift 3
    if [[ -f "$ordner/.git/geholt" && "$(cat "$ordner/.git/geholt")" == "$ref" ]]; then
        # Die Muster trotzdem neu setzen: Was sie ausschließen, verschwindet ohne Download.
        git -C "$ordner" sparse-checkout set --no-cone "$@"
        return 0
    fi
    rm -rf "$ordner"
    mkdir -p "$ordner"
    git -C "$ordner" init -q
    git -C "$ordner" remote add origin "$url"
    git -C "$ordner" sparse-checkout set --no-cone "$@"
    if ! git -C "$ordner" fetch -q --depth 1 --filter=blob:none origin "$ref" \
            || ! git -C "$ordner" checkout -q FETCH_HEAD; then
        echo "Fehler: $ref ließ sich nicht von $url laden." >&2
        rm -rf "$ordner"
        return 1
    fi
    echo "$ref" > "$ordner/.git/geholt"
}

rm -rf "$ZIEL/klassen" "$ZIEL/version.txt" "$ZIEL/handbuch" "$ROH"
mkdir -p "$ZIEL/klassen"

if (( TEXTE )); then
    hole https://github.com/godotengine/godot.git "refs/tags/$TAG" "$QUELLE_GODOT" \
        '/doc/classes/*.xml' '/modules/*/doc_classes/*.xml' '/platform/*/doc_classes/*.xml' || exit 1
    # --doctool liest die Texte aus dem Klon, gleicht sie mit der Engine ab und schreibt sie dorthin
    # zurück; von dort kommen sie nach klassen/.
    DOKU="$QUELLE_GODOT"
else
    mkdir -p "$ROH"
    DOKU="$ROH"
fi
"$GODOT" --headless --doctool "$PWD/$DOKU" > "$ZIEL/doctool.txt" 2>&1
find "$DOKU" -path "$DOKU/.git" -prune -o -name "*.xml" -print -exec cp {} "$ZIEL/klassen/" \; \
    > /dev/null
rm -rf "$ROH"

ANZAHL=$(find "$ZIEL/klassen" -name "*.xml" | wc -l | tr -d ' ')
for probe in Node RegEx @GDScript; do
    if [[ ! -s "$ZIEL/klassen/$probe.xml" ]]; then
        echo "Fehler: $probe.xml fehlt; Godot meldete: $(grep -m1 ERROR "$ZIEL/doctool.txt")" >&2
        exit 1
    fi
done
# Mit Texten hat schon die Kurzbeschreibung von Node einen Satz.
if (( TEXTE )) && ! grep -A1 "<brief_description>" "$ZIEL/klassen/Node.xml" | grep -q "[a-z]"; then
    echo "Fehler: Node.xml hat keine Beschreibung; die Texte kamen nicht an." >&2
    exit 1
fi
rm -f "$ZIEL/doctool.txt"
{
    echo "godot: $VERSION"
    (( TEXTE )) && echo "texte: godotengine/godot $TAG $(git -C "$QUELLE_GODOT" rev-parse HEAD)"
} > "$ZIEL/version.txt"
echo "erzeugt: $ANZAHL Klassen von Godot $VERSION in $ZIEL/klassen/$( (( TEXTE )) && echo ', mit Texten')"

if (( MIT_HANDBUCH )); then
    hole https://github.com/godotengine/godot-docs.git "refs/heads/$PROJEKT" "$QUELLE_HANDBUCH" \
        '*.rst' '!/classes/**' || exit 1
    rsync -a --exclude .git "$QUELLE_HANDBUCH/" "$HANDBUCH/"
    SEITEN=$(find "$HANDBUCH" -name "*.rst" | wc -l | tr -d ' ')
    if (( SEITEN == 0 )); then
        echo "Fehler: Das Handbuch hat keine Seiten." >&2
        exit 1
    fi
    echo "handbuch: godotengine/godot-docs $PROJEKT $(git -C "$QUELLE_HANDBUCH" rev-parse HEAD)" \
        >> "$ZIEL/version.txt"
    echo "geholt: $SEITEN Seiten des Handbuchs $PROJEKT in $HANDBUCH/"
fi
