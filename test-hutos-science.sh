#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$ROOT/rootfs/bin/hutos"
"$ROOT/scripts/build-hutos-tools.sh" >/dev/null
check() {
    label=$1
    expected=$2
    shift 2
    output=$("$BIN" "$@")
    case "$output" in
        *"$expected"*) printf 'PASS  %s\n' "$label" ;;
        *) printf 'FAIL  %s\nExpected: %s\nGot:\n%s\n' "$label" "$expected" "$output" >&2; exit 1 ;;
    esac
}

check "simply supported beam reaction" "500 N" mech beam 2 1000 200000000000 8e-6 center
check "simply supported beam moment" "500 N·m" mech beam 2 1000 200000000000 8e-6 center
check "cantilever tip-load moment" "2000 N·m" mech beam 2 1000 200000000000 8e-6 cantilever
check "normal stress" "10 MPa" mech stress 10000 0.001 0.00025 2 250000000
check "yield factor of safety" "25" mech stress 10000 0.001 0.00025 2 250000000
check "ideal gas pressure" "101.3249 kPa" mech thermo 1 273.15 0.022414
check "pipe Reynolds number" "50000" mech fluids 1000 1 0.05 0.001
check "Fahrenheit to kelvin" "273.15" mech units 32 F
check "nested formula molar mass" "342.131077 g/mol" chem molar-mass 'Al2(SO4)3'
check "nested hydroxide formula" "74.092000 g/mol" chem molar-mass 'Ca(OH)2'
check "molarity" "0.25 mol/L" chem molarity 0.5 2
check "dilution" "0.4" chem dilution 2 0.1 0.5
check "dashboard" "SYSTEM STATUS" --plain about
check "monochrome output" "Operating system" --plain about

if "$BIN" mech beam 0 1000 200000000000 8e-6 center >/dev/null 2>&1; then
    echo "FAIL  rejects zero beam span" >&2
    exit 1
fi
if "$BIN" mech units -500 C >/dev/null 2>&1; then
    echo "FAIL  rejects temperature below absolute zero" >&2
    exit 1
fi
echo "PASS  invalid physical inputs rejected"

printf '2\n1\n2\n1000\n200000000000\n8e-6\n6\n' | "$BIN" tools > /tmp/hutos-tools-menu.log
grep -q 'SIMPLY SUPPORTED BEAM' /tmp/hutos-tools-menu.log
echo "PASS  interactive toolkit selection"
rm -f /tmp/hutos-tools-menu.log
