#!/bin/zsh
# Baut Spiel und Selbsttest für macOS, Windows und Linux und packt je System ein Zip zur Abnahme.
#
# Feature 007, contracts/export.md „Ein Befehl für alles“, research.md R26. Aufruf vom Repo-Root:
#
#   tools/build/baue_alles.sh              alle drei Systeme
#   tools/build/baue_alles.sh --nur macos  nur ein System: macos, windows oder linux
#
# Je System: den Ordner build/<system>/ leeren, beide Presets headless bauen, im Spiel nach dem
# Läufer des Selbsttests suchen (SC-005: im Spiel 0, im Selbsttest mehr), dann
# build/abnahme/<version>_<system>.zip packen. Unter macOS packt ditto, damit Signatur und Rechte der
# .app bleiben; zip behält das Ausführrecht der Linux-Dateien. Exit 0 nur, wenn alles gebaut und
# geprüft ist; sonst nennt das Skript System und Grund. Godot liegt in $GODOT oder unter /Applications.

set -u
cd "$(dirname "$0")/../.." || exit 2

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ABNAHME="build/abnahme"
LOGS="build/logs"
SPUR="selbsttest_laeufer"
VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' src/project.godot)"

# System → Preset des Spiels, Datei des Spiels, Preset des Selbsttests, Datei des Selbsttests.
# Die Datei, in der das Paket steckt, dient der Prüfung auf Testcode.
typeset -A SPIEL_PRESET SPIEL_DATEI SPIEL_PAKET TEST_PRESET TEST_DATEI TEST_PAKET
SPIEL_PRESET[macos]="macOS"
SPIEL_DATEI[macos]="build/macos/Der Computerladen.app"
SPIEL_PAKET[macos]="build/macos/Der Computerladen.app/Contents/Resources/Der Computerladen.pck"
TEST_PRESET[macos]="Selbsttest macOS"
TEST_DATEI[macos]="build/macos/Der Computerladen Selbsttest.app"
TEST_PAKET[macos]="build/macos/Der Computerladen Selbsttest.app/Contents/Resources/Der Computerladen Selbsttest.pck"
SPIEL_PRESET[windows]="Windows"
SPIEL_DATEI[windows]="build/windows/Der Computerladen.exe"
SPIEL_PAKET[windows]="build/windows/Der Computerladen.exe"
TEST_PRESET[windows]="Selbsttest Windows"
TEST_DATEI[windows]="build/windows/Der Computerladen Selbsttest.exe"
TEST_PAKET[windows]="build/windows/Der Computerladen Selbsttest.exe"
SPIEL_PRESET[linux]="Linux"
SPIEL_DATEI[linux]="build/linux/Der Computerladen.x86_64"
SPIEL_PAKET[linux]="build/linux/Der Computerladen.x86_64"
TEST_PRESET[linux]="Selbsttest Linux"
TEST_DATEI[linux]="build/linux/Der Computerladen Selbsttest.x86_64"
TEST_PAKET[linux]="build/linux/Der Computerladen Selbsttest.x86_64"

SYSTEME=(macos windows linux)
if [[ "${1:-}" == "--nur" ]]; then
    if [[ -z "${2:-}" || -z "${SPIEL_PRESET[${2:-x}]:-}" ]]; then
        echo "Unbekanntes System „${2:-}“. Erlaubt: macos, windows, linux." >&2
        exit 2
    fi
    SYSTEME=("$2")
elif [[ $# -gt 0 ]]; then
    echo "Aufruf: tools/build/baue_alles.sh [--nur macos|windows|linux]" >&2
    exit 2
fi
if [[ ! -x "$GODOT" ]]; then
    echo "Godot fehlt unter $GODOT. Pfad über die Umgebungsvariable GODOT angeben." >&2
    exit 2
fi
mkdir -p "$ABNAHME" "$LOGS"

FEHLER=0

# Baut ein Preset; schreibt die Ausgabe von Godot nach build/logs/ und meldet „gebaut“ oder den
# Fehler mit der letzten Zeile, die Godot als Fehler meldet.
baue() {
    local preset="$1" datei="$2" log="$LOGS/${1// /_}.txt"
    "$GODOT" --headless --path src --export-release "$preset" "../$datei" > "$log" 2>&1
    local rc=$?
    if [[ $rc -ne 0 || ! -e "$datei" ]]; then
        local grund="$(grep -E 'ERROR|Fehler' "$log" | tail -1)"
        echo "Fehler: $preset ließ sich nicht bauen (Exit $rc). ${grund:-Siehe $log}"
        return 1
    fi
    if grep -q "Icon size" "$log"; then
        echo "Fehler: $preset warnt „$(grep -m1 'Icon size' "$log")“"
        return 1
    fi
    echo "gebaut: $preset → $datei"
}

# Zählt, wie oft der Läufer im Paket steht. LC_ALL=C und -a, sonst gibt grep auf Binärdateien
# nichts aus (Phase 2).
spuren() {
    local zahl
    zahl="$(LC_ALL=C grep -a -c "$SPUR" "$1" 2>/dev/null)"
    echo "${zahl:-0}"
}

for system in "${SYSTEME[@]}"; do
    rm -rf "build/$system"
    mkdir -p "build/$system"
    baue "${SPIEL_PRESET[$system]}" "${SPIEL_DATEI[$system]}" || { FEHLER=1; continue; }
    baue "${TEST_PRESET[$system]}" "${TEST_DATEI[$system]}" || { FEHLER=1; continue; }

    im_spiel="$(spuren "${SPIEL_PAKET[$system]}")"
    im_test="$(spuren "${TEST_PAKET[$system]}")"
    if [[ "$im_spiel" -ne 0 ]]; then
        echo "Fehler: $system: Testcode im Spiel, $SPUR steht ${im_spiel}-mal in ${SPIEL_PAKET[$system]}"
        FEHLER=1
        continue
    fi
    if [[ "$im_test" -eq 0 ]]; then
        echo "Fehler: $system: Kein Läufer im Selbsttest, die Prüfung auf Testcode ist ohne Aussage"
        FEHLER=1
        continue
    fi
    echo "geprüft: $system, Läufer im Spiel 0, im Selbsttest $im_test"

    zip_datei="$ABNAHME/${VERSION}_${system}.zip"
    rm -f "$zip_datei"
    if [[ "$system" == "macos" ]]; then
        ditto -c -k "build/$system" "$zip_datei"
    else
        (cd "build/$system" && zip -q -r -X "../../$zip_datei" .)
    fi
    if [[ $? -ne 0 || ! -s "$zip_datei" ]]; then
        echo "Fehler: $system: $zip_datei ließ sich nicht packen"
        FEHLER=1
        continue
    fi
    echo "gepackt: $zip_datei"
done

exit $FEHLER
