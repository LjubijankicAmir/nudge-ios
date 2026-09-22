#!/bin/bash
# Formats every Swift source in place using the swift-format that ships with Xcode.
# No third-party dependency. Pass --lint to check without writing.
set -euo pipefail
cd "$(dirname "$0")/.."

MODE=(--in-place)
if [[ "${1:-}" == "--lint" ]]; then
    MODE=(lint --strict)
fi

find Nudge Packages -name '*.swift' -not -path '*/.build/*' -print0 2>/dev/null \
    | xargs -0 xcrun swift-format "${MODE[@]}" --configuration .swift-format --parallel
