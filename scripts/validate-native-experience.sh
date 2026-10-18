#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
    echo 'Usage: bash scripts/validate-native-experience.sh INSTALLED_IOS_RUNTIME_ID IPHONE_DEVICE_TYPE_ID [Debug-reset|Release-absence|Debug-audit|Release-audit ...]' >&2
}
[[ $# -ge 2 ]] || { usage; exit 64; }
runtime="$1"
device_type="$2"
shift 2
[[ "$runtime" == com.apple.CoreSimulator.SimRuntime.iOS-* && "$device_type" == com.apple.CoreSimulator.SimDeviceType.iPhone-* ]] || { usage; exit 64; }
cases=("$@")
if [[ ${#cases[@]} -eq 0 ]]; then cases=(Debug-reset Release-absence Debug-audit Release-audit); fi
seen=' '
for case_name in "${cases[@]}"; do
    case "$case_name" in Debug-reset|Release-absence|Debug-audit|Release-audit) ;; *) usage; exit 64 ;; esac
    [[ "$seen" != *" $case_name "* ]] || { echo "Duplicate case: $case_name" >&2; exit 64; }
    seen="$seen$case_name "
done
[[ -f "$repo_root/Banana Corp/Banana Corp.xcodeproj/project.pbxproj" && -f "$repo_root/Banana Corp/Banana CorpUITests/StoryResetUITests.swift" && -f "$repo_root/Banana Corp/Banana CorpUITests/AccessibilityAuditUITests.swift" ]] || {
    echo 'BLOCKED: integrate this staged script under repository scripts/ and reviewed test files in the UI test target first.' >&2
    exit 69
}
if [[ "$(uname -s)" != Darwin ]] || ! command -v xcodebuild >/dev/null || ! command -v xcrun >/dev/null; then
    echo 'BLOCKED: macOS, Xcode 26+, Apple SDK and simulator tools are required. No native test executed.' >&2
    exit 69
fi
command -v python3 >/dev/null || { echo 'Python 3 is required for verification.' >&2; exit 69; }
xcode_major="$(xcodebuild -version | awk '/^Xcode / {split($2, v, "."); print v[1]}')"
[[ "$xcode_major" -ge 26 ]] || { echo 'Xcode 26+ is required.' >&2; exit 69; }
results="$repo_root/validation/native-experience-$(date +%Y%m%d-%H%M%S)-$$"
[[ ! -e "$results" ]] || { echo 'Results directory already exists; refusing overwrite.' >&2; exit 64; }
mkdir -p "$results"
xcodebuild -version | tee "$results/xcode.txt"
xcrun simctl list runtimes --json > "$results/runtimes.json"
xcrun simctl list devicetypes --json > "$results/device-types.json"
python3 - "$results/runtimes.json" "$results/device-types.json" "$runtime" "$device_type" <<'PY'
import json,sys
with open(sys.argv[1]) as stream: runtimes=json.load(stream)['runtimes']
with open(sys.argv[2]) as stream: devices=json.load(stream)['devicetypes']
assert any(item['identifier']==sys.argv[3] and item.get('isAvailable') is True for item in runtimes), 'Requested iOS runtime is not installed/available'
assert any(item['identifier']==sys.argv[4] for item in devices), 'Requested iPhone device type is unavailable'
PY
printf 'case\tconfiguration\tsimulator_udid\truntime\tdevice_type\n' > "$results/owned-simulators.tsv"
qa_simulator=''
case_name=''
cleanup_attempted=0
cleanup_failed=0
cleanup() {
    if [[ -n "$qa_simulator" ]]; then
        cleanup_attempted=1
        # This variable is assigned only from a successful create in this run.
        if ! xcrun simctl shutdown "$qa_simulator" >> "$results/cleanup.log" 2>&1; then
            echo "Shutdown did not complete for owned simulator $qa_simulator; attempting deletion (it may already be shut down)." | tee -a "$results/cleanup.log" >&2
        fi
        if xcrun simctl delete "$qa_simulator" >> "$results/cleanup.log" 2>&1; then
            qa_simulator=''
            cleanup_failed=0
        else
            cleanup_failed=1
            printf '%s\n' "$qa_simulator" > "$results/outstanding-owned-simulator.txt"
            echo "CLEANUP FAILED: owned simulator $qa_simulator remains outstanding; see $results/cleanup.log and outstanding-owned-simulator.txt." >&2
            return 1
        fi
    fi
    return 0
}
finalize() {
    original_status=$?
    if [[ -n "$qa_simulator" && "$cleanup_attempted" -eq 0 ]]; then
        if ! cleanup; then
            if [[ "$original_status" -eq 0 ]]; then original_status=70; fi
        fi
    elif [[ "$cleanup_failed" -eq 1 && "$original_status" -eq 0 ]]; then
        original_status=70
    fi
    # Preserve the native/test failure when cleanup also fails. Never retry
    # deletion automatically or discard an outstanding owned UUID.
    exit "$original_status"
}
trap finalize EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for case_name in "${cases[@]}"; do
    configuration="${case_name%%-*}"
    case "$case_name" in
        Debug-reset)
            test_id='Banana CorpUITests/StoryResetUITests/testSettingsResetCancelConfirmAndRelaunch'
            guard_name=TEST_RUNNER_BANANA_QA_RESET
            guard_value=fresh-simulator
            ;;
        Release-absence)
            test_id='Banana CorpUITests/StoryResetUITests/testReleaseSettingsOmitsDevelopmentDiagnostics'
            guard_name=TEST_RUNNER_BANANA_QA_RESET
            guard_value=fresh-simulator
            ;;
        Debug-audit|Release-audit)
            test_id='Banana CorpUITests/AccessibilityAuditUITests/testHomeAndRegisteredApplicationsAccessibilityAudit'
            guard_name=TEST_RUNNER_BANANA_QA_ACCESSIBILITY
            guard_value=owned-simulator
            ;;
    esac
    created_simulator="$(xcrun simctl create "Banana Experience $case_name $(basename "$results")" "$device_type" "$runtime")"
    [[ "$created_simulator" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || {
        echo 'simctl create did not return a valid simulator UDID; no existing simulator will be selected.' >&2
        exit 69
    }
    qa_simulator="$created_simulator"
    cleanup_attempted=0
    cleanup_failed=0
    printf '%s\t%s\t%s\t%s\t%s\n' "$case_name" "$configuration" "$qa_simulator" "$runtime" "$device_type" >> "$results/owned-simulators.tsv"
    xcrun simctl boot "$qa_simulator" > "$results/$case_name-boot.log" 2>&1
    xcrun simctl bootstatus "$qa_simulator" -b >> "$results/$case_name-boot.log" 2>&1
    test_status=0
    # Metadata reaches XCTest only. The app has no launch flags/save shortcuts.
    env "$guard_name=$guard_value" xcodebuild \
        -project "$repo_root/Banana Corp/Banana Corp.xcodeproj" -scheme 'Banana Corp' \
        -configuration "$configuration" -destination "platform=iOS Simulator,id=$qa_simulator" \
        -derivedDataPath "$results/DerivedData" CODE_SIGNING_ALLOWED=NO ENABLE_TESTABILITY=YES \
        -parallel-testing-enabled NO "-only-testing:$test_id" \
        -resultBundlePath "$results/$case_name.xcresult" test 2>&1 | tee "$results/$case_name.log" || test_status=$?
    printf '%s\n' "$test_status" > "$results/$case_name-xcodebuild-exit.txt"
    # Preserve result metadata even when a test fails. Never retry a failing case.
    summary_status=0
    xcrun xcresulttool get test-results summary --path "$results/$case_name.xcresult" \
        > "$results/$case_name-summary.json" 2> "$results/$case_name-summary-error.log" || summary_status=$?
    # Export only the newly created simulator's campaign bytes for later review.
    artifact_status=0
    data_container=''
    if data_container="$(xcrun simctl get_app_container "$qa_simulator" Bryce-Cameron-Design.Banana-Corp data 2> "$results/$case_name-container-error.log")"; then
        story_directory="$data_container/Library/Application Support/BananaCorp"
        if [[ -d "$story_directory" ]]; then
            cp -R "$story_directory" "$results/$case_name-story-artifacts" \
                2> "$results/$case_name-artifact-export-error.log" || artifact_status=$?
        fi
    fi
    printf '%s\n' "$artifact_status" > "$results/$case_name-artifact-export-exit.txt"
    if [[ "$test_status" -ne 0 ]]; then
        echo "FAILED: $case_name; native xcodebuild exit $test_status, logs retained at $results" >&2
        if [[ "$artifact_status" -ne 0 ]]; then echo "Artifact export also failed with exit $artifact_status; original native failure takes precedence." >&2; fi
        exit "$test_status"
    fi
    [[ "$summary_status" -eq 0 ]] || { echo "FAILED: missing/verifiably unreadable summary for $case_name" >&2; exit "$summary_status"; }
    python3 - "$results/$case_name-summary.json" <<'PY'
import json,sys
with open(sys.argv[1]) as stream: result=json.load(stream)
assert result.get('passedTests',0)==1, result
assert result.get('failedTests',0)==0 and result.get('skippedTests',0)==0, result
PY
    [[ "$artifact_status" -eq 0 ]] || { echo "FAILED: artifact export for $case_name (exit $artifact_status); native result retained separately." >&2; exit "$artifact_status"; }
    if ! cleanup; then exit 70; fi
done
echo "Native experience cases completed. Review actual xcresults, screenshots and logs at $results before recording QA outcomes."
