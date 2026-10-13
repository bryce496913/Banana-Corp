#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
swiftc -D DEBUG -swift-version 5 -warnings-as-errors \
    "$repo_root/Banana Corp/Banana Corp/PhoneAppRoute.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryTime.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryState.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryPrerequisites.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryPersistence.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryProgressionStore.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryContentModels.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryContentRules.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryContentCatalogue.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryContentStore.swift" \
    "$repo_root/Banana Corp/Banana Corp/EvidenceComparison.swift" \
    "$repo_root/Tests/FirstAnomalyChecks.swift" \
    -o "$test_dir/first-anomaly-checks"
production="$repo_root/Banana Corp/Banana Corp/StoryContent.json"
"$test_dir/first-anomaly-checks" "$production"
for path in preserved unpreserved; do
    save_file="$test_dir/$path/story-save.json"
    for phase in intro email before-change removed before-warning questioned investigated advanced reopened; do
        "$test_dir/first-anomaly-checks" "$production" "$phase-$path" "$save_file"
    done
done
