#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(uname -s)" != Darwin ]] || ! command -v xcodebuild >/dev/null || ! command -v xcrun >/dev/null; then
    echo 'BLOCKED: Apple SDK/Xcode/simulator unavailable. No player UI playthrough executed.' >&2
    exit 69
fi
if [[ $# -ne 2 ]]; then
    echo 'Usage: bash scripts/validate-acts-journey.sh INSTALLED_IOS_RUNTIME_ID IPHONE_DEVICE_TYPE_ID' >&2
    echo 'Example IDs: com.apple.CoreSimulator.SimRuntime.iOS-18-0 com.apple.CoreSimulator.SimDeviceType.iPhone-16' >&2
    exit 64
fi
[[ "$1" == com.apple.CoreSimulator.SimRuntime.iOS-* && "$2" == com.apple.CoreSimulator.SimDeviceType.iPhone-* ]] || exit 64
command -v python3 >/dev/null || { echo 'Python 3 is required for result verification.' >&2; exit 69; }
xcode_major="$(xcodebuild -version | awk '/^Xcode / {split($2, v, "."); print v[1]}')"
[[ "$xcode_major" -ge 26 ]] || { echo 'Xcode 26+ is required.' >&2; exit 69; }
results="$repo_root/validation/acts-$(date +%Y%m%d-%H%M%S)"
[[ ! -e "$results" ]] || { echo 'Results directory already exists.' >&2; exit 64; }
mkdir -p "$results"
xcodebuild -version | tee "$results/xcode.txt"
xcrun simctl list runtimes | tee "$results/runtimes.txt"
xcrun simctl list devicetypes | tee "$results/device-types.txt"
qa_simulator=''
qa_runtime="$1"
qa_device_type="$2"
cleanup() {
    if [[ -n "$qa_simulator" ]]; then
        local shutdown_status=0
        xcrun simctl shutdown "$qa_simulator" >> "$results/simulator-cleanup.log" 2>&1 || shutdown_status=$?
        local record_status=0
        python3 - "$results/retained-simulators.jsonl" "$qa_simulator" "$configuration" "$path" "$qa_runtime" "$qa_device_type" "$shutdown_status" <<'PYRETAIN' || record_status=$?
import json,sys
from pathlib import Path
record_path,identifier,configuration,path,runtime,device_type,shutdown_status=sys.argv[1:]
results=Path(record_path).parent
record=dict(udid=identifier,created_by_runner=True,retained=True,configuration=configuration,
            preservation_path=path,runtime=runtime,device_type=device_type,
            shutdown_exit=int(shutdown_status),shutdown_succeeded=shutdown_status=='0',
            xcresult=str(results/f'{configuration}-{path}.xcresult'),
            save=str(results/f'{configuration}-{path}-save.json'),
            note='Retained for explicit review/reuse; do not restart a fresh-journey test on this progressed save.')
with open(record_path,'a') as output: output.write(json.dumps(record)+'\n')
PYRETAIN
        if [[ "$shutdown_status" -ne 0 || "$record_status" -ne 0 ]]; then
            printf '%s\n' "$qa_simulator" > "$results/outstanding-owned-simulator.txt"
            echo 'CLEANUP FAILED: owned simulator retained; inspect shutdown/retention metadata.' >&2
            qa_simulator=''
            return 1
        fi
        qa_simulator=''
    fi
    return 0
}
finalize() {
    local original_status=$?
    if ! cleanup; then
        if [[ "$original_status" -eq 0 ]]; then original_status=70; fi
    fi
    exit "$original_status"
}
trap finalize EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Shut down only this runner's simulators; retain their identities and saves for review/reuse.
# Never automatically delete simulators or reset a player's device/save.
for configuration in Debug Release; do
    for path in both email video neither; do
        qa_simulator="$(xcrun simctl create "Banana QA $configuration $path" "$2" "$1")"
        xcrun simctl boot "$qa_simulator"
        xcrun simctl bootstatus "$qa_simulator" -b
        # TEST_RUNNER_ variables are delivered to XCTest; the app has no QA launch flags.
        TEST_RUNNER_BANANA_QA_PATH="$path" xcodebuild \
            -project "$repo_root/Banana Corp/Banana Corp.xcodeproj" -scheme 'Banana Corp' \
            -configuration "$configuration" -destination "platform=iOS Simulator,id=$qa_simulator" \
            -derivedDataPath "$results/DerivedData" CODE_SIGNING_ALLOWED=NO \
            ENABLE_TESTABILITY=YES -parallel-testing-enabled NO \
            '-only-testing:Banana CorpUITests/ActsJourneyTests/testActsOneThreePlayerJourney' \
            -resultBundlePath "$results/$configuration-$path.xcresult" \
            test 2>&1 | tee "$results/$configuration-$path.log"
        # Fail closed if a toolchain failed to forward the runner path and skipped the test.
        xcrun xcresulttool get test-results summary --path "$results/$configuration-$path.xcresult" \
            > "$results/$configuration-$path-summary.json"
        python3 - "$results/$configuration-$path-summary.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f: result=json.load(f)
assert result.get('passedTests', 0) == 1, result
assert result.get('skippedTests', 0) == 0 and result.get('failedTests', 0) == 0, result
PY
        data_container="$(xcrun simctl get_app_container "$qa_simulator" Bryce-Cameron-Design.Banana-Corp data)"
        cp "$data_container/Library/Application Support/BananaCorp/story-save.json" "$results/$configuration-$path-save.json"
        python3 - "$results/$configuration-$path-save.json" "$path" <<'PY'
import json,sys
with open(sys.argv[1]) as f: state=json.load(f)
assert state['currentAct']==4, state['currentAct']
assert state['solvedPuzzleIDs']==['puzzle.banana_wall.review_cross_reference']
assert state['accessMilestoneIDs']==['access.banana_wall.breached']
assert 'milestone.banana_wall.breached' in state['completedMilestoneIDs']
assert 'event.puzzle.banana_wall.review_cross_reference' in state['completedEventIDs']
records=state['preservedEvidence']
assert ('evidence.act1.echo_review.v1' in records)==(sys.argv[2] in ['both','email'])
assert ('evidence.act2.alex_review.v1' in records)==(sys.argv[2] in ['both','video'])
assert 'event.act2.sources_connected' in state['completedEventIDs']
assert len(state['completedEventIDs'])==len(set(state['completedEventIDs']))
assert len(state['contentDelivery']['notifications'])==1
required=['version.act1.promo.v1','version.act1.echo_review.v1',
          'version.act1.first_anomaly.warning.v1','version.act1.first_anomaly.denial.v1',
          'version.act2.alex_review.v1','version.act2.alex_review.v2',
          'version.act2.messages.daniel.v1','version.act2.email.maya.v1',
          'version.act2.web.echo07.v1','version.act2.diagnostics.excerpt.v1']
required.extend(['version.act3.banana_wall.scope_record.v1', 'version.act3.conclusion.resistance.v1', 'version.act4.entry.v1'])
assert 'milestone.act3.investigation_concluded' in state['completedMilestoneIDs']
assert state.get('ascensionMilestone') is None
assert not state['observerClueIDs']
assert not state['routePrerequisiteIDs']
assert set(required).issubset(state['readContentIDs'])
PY
        if ! cleanup; then exit 70; fi
        qa_simulator=''
    done
done
echo "Review full journey captures/results in $results before updating device QA status."
