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
    "$repo_root/Banana Corp/Banana Corp/RestrictedAccessModels.swift" \
    "$repo_root/Banana Corp/Banana Corp/RestrictedAccessStore.swift" \
    "$repo_root/Banana Corp/Banana Corp/StoryContentStore.swift" \
    "$repo_root/Banana Corp/Banana Corp/EvidenceComparison.swift" \
    "$repo_root/Tests/RestrictedAccessChecks.swift" \
    -o "$test_dir/restricted-access-checks"
fixture="$repo_root/Tests/Fixtures/restricted-access-fixtures.json"
content="$repo_root/Tests/Fixtures/restricted-content-fixtures.json"
production="$repo_root/Banana Corp/Banana Corp/RestrictedAccess.json"
"$test_dir/restricted-access-checks" "$fixture" "$content" "$production"
"$test_dir/restricted-access-checks" "$fixture" "$content" "$production" write "$test_dir/relaunch/story-save.json"
"$test_dir/restricted-access-checks" "$fixture" "$content" "$production" read "$test_dir/relaunch/story-save.json"
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
    "$repo_root/Tests/RestrictedAccessReleaseChecks.swift" \
    -o "$test_dir/restricted-access-release-checks"
"$test_dir/restricted-access-release-checks" "$fixture" "$production"
strings "$test_dir/restricted-access-release-checks" > "$test_dir/release-strings.txt"
fixture_pattern='This test accepts the word DEMO|Development test challenge'
if command -v rg >/dev/null 2>&1; then
    if rg -q "$fixture_pattern" "$test_dir/release-strings.txt"; then
        echo 'Development fixture leaked into Release binary' >&2
        exit 1
    fi
else
    if grep -Eq "$fixture_pattern" "$test_dir/release-strings.txt"; then
        echo 'Development fixture leaked into Release binary' >&2
        exit 1
    fi
fi
echo 'PASS: isolated development demo strings absent from Release binary'
