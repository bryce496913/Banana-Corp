#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
sources=()
for name in PhoneAppRoute StoryTime StoryState StoryPrerequisites StoryPersistence StoryProgressionStore EndgameStore StoryContentModels StoryContentRules StoryContentCatalogue RestrictedAccessModels RestrictedAccessStore StoryContentStore EvidenceComparison; do
    sources+=("$repo_root/Banana Corp/Banana Corp/$name.swift")
done
swiftc -swift-version 5 -warnings-as-errors "${sources[@]}" \
    "$repo_root/Tests/ActsJourneyChecks.swift" -o "$test_dir/acts-journey-checks"
swiftc -swift-version 5 -warnings-as-errors "${sources[@]}" \
    "$repo_root/Tests/CompleteStoryChecks.swift" -o "$test_dir/complete-story-checks"
"$test_dir/acts-journey-checks" "$repo_root/Banana Corp/Banana Corp" write-handoff "$test_dir/journey"
"$test_dir/complete-story-checks" "$repo_root/Banana Corp/Banana Corp" "$test_dir/journey"
