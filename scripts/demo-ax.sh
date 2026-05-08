#!/bin/bash
# Demo script for the SwiftAutoGUI AX (accessibility) actions.
#
# Drives the macOS Calculator and TextEdit through the `sagui ax` CLI
# subcommand to show off semantic, coordinate-free GUI automation.
#
# Prerequisites:
#   - Your terminal app needs Accessibility permission in
#     System Settings > Privacy & Security > Accessibility.
#   - Build the package once before running:  swift build
#
# Usage:
#   scripts/demo-ax.sh           # run all sections
#   scripts/demo-ax.sh calc      # Calculator only
#   scripts/demo-ax.sh textedit  # TextEdit only
#   scripts/demo-ax.sh discover  # introspection (tree + find) only

set -e
cd "$(dirname "$0")/.."

SAGUI=".build/debug/sagui"
if [[ ! -x "$SAGUI" ]]; then
    echo "Building sagui..."
    swift build
fi

CALC_BUNDLE="com.apple.calculator"
TEXTEDIT_BUNDLE="com.apple.TextEdit"

section() {
    printf '\n\033[1;34m=== %s ===\033[0m\n' "$1"
}

calc_demo() {
    section "Calculator: 5 + 3 ="
    open -a Calculator
    sleep 1
    # Calculator labels operator buttons by their *verb*, not the symbol shown
    # on the button face: "+" => "Add", "=" => "Equals", "-" => "Subtract", etc.
    "$SAGUI" ax press --label "5"      --bundle-id "$CALC_BUNDLE"
    "$SAGUI" ax press --label "Add"    --bundle-id "$CALC_BUNDLE"
    "$SAGUI" ax press --label "3"      --bundle-id "$CALC_BUNDLE"
    "$SAGUI" ax press --label "Equals" --bundle-id "$CALC_BUNDLE"
    echo "Calculator should now display 8."
}

textedit_demo() {
    section "TextEdit: new doc + type"
    open -a TextEdit
    sleep 1
    "$SAGUI" ax menu File "New" --bundle-id "$TEXTEDIT_BUNDLE"
    sleep 1
    "$SAGUI" ax set --role AXTextArea \
                    --value "Hello from sagui ax!" \
                    --bundle-id "$TEXTEDIT_BUNDLE"
}

discover_demo() {
    section "Discovery: AX tree of frontmost window"
    "$SAGUI" ax tree --max-depth 4 --max-nodes 80

    section "Discovery: list buttons in Calculator"
    open -a Calculator
    sleep 1
    "$SAGUI" ax find --role AXButton --bundle-id "$CALC_BUNDLE" --limit 30
}

case "${1:-all}" in
    all)
        discover_demo
        calc_demo
        textedit_demo
        ;;
    calc|calculator)    calc_demo ;;
    textedit|text)      textedit_demo ;;
    discover|introspect) discover_demo ;;
    *)
        echo "Unknown section: $1"
        echo "Usage: $0 [all|calc|textedit|discover]"
        exit 1
        ;;
esac

section "Done"
