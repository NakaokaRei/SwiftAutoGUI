#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_file="$repo_root/Sources/SwiftAutoGUIImageRecognition/Shaders/TemplateMatching.metal"
output_file="$repo_root/Sources/SwiftAutoGUIImageRecognition/Resources/TemplateMatching.metallib"
temporary_directory="$(mktemp -d)"

trap 'rm -rf "$temporary_directory"' EXIT

mkdir -p "$(dirname "$output_file")"

xcrun -sdk macosx metal \
    -c \
    -target air64-apple-macos26.0 \
    "$source_file" \
    -o "$temporary_directory/TemplateMatching.air"

xcrun -sdk macosx metallib \
    "$temporary_directory/TemplateMatching.air" \
    -o "$output_file"

echo "Generated $output_file"
