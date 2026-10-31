#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
sources=()
for name in PhoneAppRoute StoryTime StoryState StoryPrerequisites StoryPersistence StoryProgressionStore EndgameStore StoryContentModels StoryContentRules StoryContentCatalogue RestrictedAccessModels RestrictedAccessStore StoryContentStore EvidenceComparison AssistantQuestionMatcher; do
    sources+=("$repo_root/Banana Corp/Banana Corp/$name.swift")
done
swiftc -swift-version 5 -warnings-as-errors "${sources[@]}" "$repo_root/Tests/PhoneLifeChecks.swift" -o "$test_dir/phone-life-checks"
"$test_dir/phone-life-checks" "$repo_root/Banana Corp/Banana Corp"
swiftc -swift-version 5 -warnings-as-errors "$repo_root/Banana Corp/Banana Corp/BrowserNavigation.swift" "$repo_root/Tests/BrowserNavigationChecks.swift" -o "$test_dir/browser-checks"
"$test_dir/browser-checks"
