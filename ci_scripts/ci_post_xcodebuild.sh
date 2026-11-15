#!/bin/zsh

set -euo pipefail

# Test and analyze actions do not produce a TestFlight upload.
if [[ -d "${CI_APP_STORE_SIGNED_APP_PATH:-}" ]]; then
  python3 "$CI_PRIMARY_REPOSITORY_PATH/ci_scripts/testflight_notes.py" generate
fi
