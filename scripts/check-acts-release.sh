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
    "$repo_root/Banana Corp/Banana Corp/StoryContentModels.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryContentRules.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryContentCatalogue.swift" \
    "$repo_root/Banana Corp/Banana Corp/RestrictedAccessModels.swift" \
    "$repo_root/Banana Corp/Banana Corp/RestrictedAccessStore.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryContentStore.swift" \
    "$repo_root/Banana Corp/Banana Corp/EvidenceComparison.swift" \
    "$repo_root/Tests/ActsJourneyChecks.swift" \
    -o "$test_dir/acts-journey-checks"
"$test_dir/acts-journey-checks" "$repo_root/Banana Corp/Banana Corp" write-handoff "$test_dir/relaunch"
"$test_dir/acts-journey-checks" "$repo_root/Banana Corp/Banana Corp" read-handoff "$test_dir/relaunch"
