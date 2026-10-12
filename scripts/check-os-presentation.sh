#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
swiftc \
    "$repo_root/Banana Corp/Banana Corp/PhoneAppRoute.swift" \
    "$repo_root/Banana Corp/Banana Corp/OSPresentationState.swift" \
    "$repo_root/Tests/OSPresentationChecks.swift" \
    -o "$test_dir/os-presentation-checks"
"$test_dir/os-presentation-checks"
