#!/usr/bin/env python3
"""Portable shell command-contract tests; never builds or runs the iOS app.

Runners are copied into temporary repositories and receive fake Apple tools.
No simulator, real save, project setting, or repository validation output is touched.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
MOCK = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
root = pathlib.Path(os.environ['MOCK_ROOT'])
with (root / 'commands.jsonl').open('a') as f:
    f.write(json.dumps([name, args, os.environ.get('TEST_RUNNER_BANANA_QA_PATH')]) + '\n')
if name == 'uname':
    print('Darwin'); sys.exit()
if name == 'xcodebuild':
    if args == ['-version']:
        print('Xcode 26.0\nBuild version MOCK'); sys.exit()
    if args and args[-1] in ['build', 'test']:
        action = args[-1]
        configuration = args[args.index('-configuration') + 1]
        print('mock stdout ' + action)
        print('mock diagnostic ' + action, file=sys.stderr)
        if os.environ.get('MOCK_FAIL') == action:
            sys.exit(42)
        if action == 'test' and os.environ.get('TEST_RUNNER_BANANA_QA_PATH'):
            path = os.environ['TEST_RUNNER_BANANA_QA_PATH']
            records = {}
            if path in ['both', 'email']: records['evidence.act1.echo_review.v1'] = {}
            if path in ['both', 'video']: records['evidence.act2.alex_review.v1'] = {}
            versions = ['act1.promo', 'act1.echo_review', 'act1.first_anomaly.warning',
                'act1.first_anomaly.denial', 'act2.alex_review', 'act2.messages.daniel',
                'act2.email.maya', 'act2.web.echo07', 'act2.diagnostics.excerpt',
                'act3.banana_wall.scope_record', 'act3.conclusion.resistance', 'act4.entry']
            state = dict(currentAct=4, solvedPuzzleIDs=['puzzle.banana_wall.review_cross_reference'],
                accessMilestoneIDs=['access.banana_wall.breached'],
                completedMilestoneIDs=['milestone.banana_wall.breached', 'milestone.act3.investigation_concluded'],
                completedEventIDs=['event.puzzle.banana_wall.review_cross_reference', 'event.act2.sources_connected'],
                preservedEvidence=records, contentDelivery=dict(notifications={'notification': {}}),
                observerClueIDs=[], routePrerequisiteIDs=[],
                readContentIDs=['version.' + v + '.v1' for v in versions] + ['version.act2.alex_review.v2'])
            save = root / 'container/Library/Application Support/BananaCorp/story-save.json'
            save.parent.mkdir(parents=True, exist_ok=True)
            save.write_text(json.dumps(state))
    sys.exit()
if name == 'xcrun':
    if args[:2] == ['simctl', 'create']:
        counter = root / 'counter'
        number = int(counter.read_text()) + 1 if counter.exists() else 1
        counter.write_text(str(number))
        print('owned-simulator-' + str(number))
    elif args[:2] == ['simctl', 'get_app_container']:
        print(root / 'container')
    elif args[:4] == ['xcresulttool', 'get', 'test-results', 'summary']:
        skipped = os.environ.get('MOCK_SKIP') == '1'
        print(json.dumps(dict(passedTests=0 if skipped else 1, skippedTests=1 if skipped else 0, failedTests=0)))
    sys.exit()
raise RuntimeError(name)
'''


def run_case(runner, failure=None, skip=False):
    with tempfile.TemporaryDirectory(prefix="banana-runner-contract-") as directory:
        root = Path(directory)
        (root / "scripts").mkdir()
        (root / "bin").mkdir()
        shutil.copy2(ROOT / "scripts" / runner, root / "scripts" / runner)
        # Bundle checks are outside this test's contract and require real Xcode products.
        (root / "scripts/check-ios-project.py").write_text("print('mock structure/bundle check')\n")
        for tool in ["uname", "xcodebuild", "xcrun"]:
            executable = root / "bin" / tool
            executable.write_text(MOCK)
            executable.chmod(0o755)
        environment = os.environ.copy()
        environment.update(PATH=str(root / "bin") + os.pathsep + environment["PATH"],
                           MOCK_ROOT=str(root), MOCK_FAIL=failure or "", MOCK_SKIP="1" if skip else "0")
        integration = runner == "validate-ios-integration.sh"
        arguments = (["00000000-0000-0000-0000-000000000001", str(root / "results")]
                     if integration else ["com.apple.CoreSimulator.SimRuntime.iOS-18-0",
                                          "com.apple.CoreSimulator.SimDeviceType.iPhone-16"])
        result = subprocess.run(["bash", str(root / "scripts" / runner), *arguments],
                                env=environment, capture_output=True, text=True, timeout=30)
        commands = [json.loads(line) for line in (root / "commands.jsonl").read_text().splitlines()]
        invocations = [entry for entry in commands if entry[0] == "xcodebuild" and entry[1][-1:] in [["build"], ["test"]]]
        assert invocations, result.stderr
        for _, args, path in invocations:
            assert ("ENABLE_TESTABILITY=YES" in args) == (args[-1] == "test"), args
            assert "CODE_SIGNING_ALLOWED=NO" in args
            if not integration:
                assert path in ["both", "email", "video", "neither"]
                assert "-only-testing:Banana CorpUITests/ActsJourneyTests/testActsOneThreePlayerJourney" in args
        logs = list(root.rglob("*.log"))
        assert logs
        for log in logs:
            action = "build" if log.name.startswith("build-") else "test"
            assert "mock diagnostic " + action in log.read_text(), log
            assert "mock stdout " + action in log.read_text(), log
        if failure:
            assert result.returncode == 42, (result.returncode, result.stdout, result.stderr)
            expected_count = 3 if integration and failure == "test" else 1
            assert len(invocations) == expected_count
        elif skip:
            assert result.returncode != 0 and len(invocations) == 1
        else:
            assert result.returncode == 0, (result.stdout, result.stderr)
            assert len(invocations) == (4 if integration else 8)
            assert {entry[1][entry[1].index("-configuration") + 1] for entry in invocations} == {"Debug", "Release"}
        mutations = [args for name, args, _ in commands
                     if name == "xcrun" and args[:1] == ["simctl"] and args[1] in ["shutdown", "delete"]]
        if integration:
            assert not mutations, "Integration runner must not delete the caller's simulator"
        else:
            created = [entry for entry in commands if entry[0] == "xcrun" and entry[1][:2] == ["simctl", "create"]]
            assert len(mutations) == 2 * len(created)
            for number in range(1, len(created) + 1):
                identifier = "owned-simulator-" + str(number)
                assert ["simctl", "shutdown", identifier] in mutations
                assert ["simctl", "delete", identifier] in mutations


for runner in ["validate-ios-integration.sh", "validate-acts-journey.sh"]:
    run_case(runner)
    run_case(runner, failure="test")
run_case("validate-ios-integration.sh", failure="build")
run_case("validate-acts-journey.sh", skip=True)
print("PASS: six mocked native-runner cases; Debug/Release testability, diagnostics, failure/skip propagation and owned-simulator cleanup")
print("MOCK ONLY: no Apple build, XCTest, simulator, bundle or gameplay validation was performed")
