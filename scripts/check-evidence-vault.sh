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
    "$repo_root/Banana Corp/Banana Corp/HomeScreenLayout.swift" \
    "$repo_root/Tests/EvidenceVaultChecks.swift" \
    -o "$test_dir/evidence-vault-checks"
fixture="$repo_root/Tests/Fixtures/evidence-fixtures.json"
"$test_dir/evidence-vault-checks" "$fixture"
"$test_dir/evidence-vault-checks" "$fixture" write "$test_dir/relaunch/story-save.json"
"$test_dir/evidence-vault-checks" "$fixture" read "$test_dir/relaunch/story-save.json"
