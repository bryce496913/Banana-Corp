#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
swiftc -swift-version 5 -warnings-as-errors \
    "$repo_root/Banana Corp/Banana Corp/PhoneAppRoute.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryTime.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryState.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryPrerequisites.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryPersistence.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryProgressionStore.swift" \
    "$repo_root/Banana Corp/Banana Corp/EndgameStore.swift" \
    "$repo_root/Tests/EndgameChecks.swift" \
    -o "$test_dir/endgame-checks"
"$test_dir/endgame-checks"
"$test_dir/endgame-checks" write "$test_dir/relaunch/story-save.json"
"$test_dir/endgame-checks" read "$test_dir/relaunch/story-save.json"
"$test_dir/endgame-checks" reread "$test_dir/relaunch/story-save.json"
