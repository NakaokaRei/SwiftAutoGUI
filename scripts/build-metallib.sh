#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

swift package \
    --package-path "$repo_root" \
    --allow-writing-to-package-directory \
    build-metal-library
