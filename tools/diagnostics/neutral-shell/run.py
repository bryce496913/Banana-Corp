#!/usr/bin/env python3
"""Developer-only neutral input reproduction. Creates, shuts down and retains only its own simulator."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re
import signal
import subprocess
import sys
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
RUNTIME = 'com.apple.CoreSimulator.SimRuntime.iOS-26-5'
DEVICE = 'com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro'
EXCLUDED = {'build', 'Build', '.build', 'DerivedData', 'xcuserdata', '__pycache__', '.git', 'project.xcworkspace'}
FIXTURE_INPUTS = (
    'NeutralShellReproApp.swift', 'NeutralShellReproUITests.swift',
    'NeutralShellRepro.xcodeproj/project.pbxproj',
    'NeutralShellRepro.xcodeproj/xcshareddata/xcschemes/NeutralShellRepro.xcscheme',
    'source-comparison.json',
    'baseline-fixture-sha256.json', 'run.py', 'README.md',
)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inventory():
    fixture = {name: digest(HERE / name) for name in FIXTURE_INPUTS}
    canonical = {}
    for p in sorted((ROOT / 'Banana Corp').rglob('*')):
        if EXCLUDED.intersection(p.relative_to(ROOT).parts):
            continue
        if p.is_symlink():
            raise RuntimeError('Refusing canonical symlink: ' + str(p.relative_to(ROOT)))
        if p.is_file() and p.suffix in {'.swift', '.json', '.pbxproj', '.xcscheme'}:
            canonical[str(p.relative_to(ROOT))] = digest(p)
    for name in ['AGENTS.md', 'BANANA_CORP_GAME_BIBLE.md']:
        canonical[name] = digest(ROOT / name)
    return {'fixture': fixture, 'canonical_read_only': canonical}


def exact_pass_summary(export_status, summary):
    expected = {'totalTestCount': 2, 'passedTests': 2, 'failedTests': 0, 'skippedTests': 0}
    return (export_status == 0 and isinstance(summary, dict) and
            all(type(summary.get(key)) is int and summary[key] == count
                for key, count in expected.items()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('label', help='Unique result label; ASCII letters, numbers, hyphen or underscore')
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,79}', args.label):
        parser.error('Invalid result label')
    if sys.platform != 'darwin':
        parser.error('macOS with Xcode 26+ and installed iOS 26.5 runtime required')
    results = ROOT / 'validation' / ('neutral-shell-repro-' + args.label)
    results.mkdir(parents=True, exist_ok=False)  # Never overwrite.
    def write(name, value):
        (results / name).write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')
    def command(*words):
        return subprocess.check_output(words, stderr=subprocess.STDOUT, text=True)
    before = inventory()
    write('hashes-before.json', before)
    write('invocation.json', {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                              'runtime_requested': RUNTIME, 'device_type_requested': DEVICE,
                              'diagnostic_only': True, 'automatic_retries': False})
    owned = None
    native = None
    status = 1
    cleanup_failed = False
    integrity_failed = False
    def interrupted(signum, _frame):
        raise KeyboardInterrupt(signum)
    signal.signal(signal.SIGTERM, interrupted)
    try:
        version = command('xcodebuild', '-version')
        (results / 'xcode-version.txt').write_text(version)
        match = re.search(r'^Xcode (\d+)', version, re.M)
        if not match or int(match.group(1)) < 26:
            raise RuntimeError('Xcode 26+ required')
        runtimes = json.loads(command('xcrun', 'simctl', 'list', 'runtimes', '--json'))
        types = json.loads(command('xcrun', 'simctl', 'list', 'devicetypes', '--json'))
        write('runtimes.json', runtimes)
        write('device-types.json', types)
        selected = [r for r in runtimes['runtimes'] if r['identifier'] == RUNTIME and r.get('isAvailable') is True]
        selected_types = [d for d in types['devicetypes'] if d['identifier'] == DEVICE]
        if len(selected) != 1 or selected[0].get('version') != '26.5' or len(selected_types) != 1:
            raise RuntimeError('Exact installed iOS 26.5 runtime / iPhone 17 Pro type unavailable; no fallback')
        write('selected-runtime-device.json', {'runtime': selected[0], 'device_type': selected_types[0]})
        created = command('xcrun', 'simctl', 'create', 'Neutral Shell ' + args.label, DEVICE, RUNTIME).strip()
        parsed = str(uuid.UUID(created))
        if parsed.lower() != created.lower():
            raise RuntimeError('Unexpected simulator UUID; refusing existing-device substitution')
        # Preserve simctl spelling: Xcode destination matching rejected lowercase UUIDs.
        owned = created
        write('owned-simulator.json', {'udid': owned, 'created_by_this_run': True})
        with (results / 'boot.log').open('w') as log:
            subprocess.run(['xcrun', 'simctl', 'boot', owned], stdout=log, stderr=subprocess.STDOUT, check=True)
            subprocess.run(['xcrun', 'simctl', 'bootstatus', owned, '-b'], stdout=log, stderr=subprocess.STDOUT, check=True)
        words = ['xcodebuild', '-project', str(HERE / 'NeutralShellRepro.xcodeproj'),
                 '-scheme', 'NeutralShellRepro', '-configuration', 'Debug',
                 '-destination', 'platform=iOS Simulator,id=' + owned,
                 '-derivedDataPath', str(results / 'DerivedData'),
                 'CODE_SIGNING_ALLOWED=NO', 'ENABLE_TESTABILITY=YES', '-parallel-testing-enabled', 'NO',
                 '-only-testing:NeutralShellReproUITests/NeutralShellReproUITests/testTwoRoundsFifteenApplicationsAndHome',
                 '-only-testing:NeutralShellReproUITests/NeutralShellReproUITests/testReservedStripUpwardSwipe',
                 '-resultBundlePath', str(results / 'tests.xcresult'), 'test']
        write('native-command.json', words)
        with (results / 'native.log').open('w') as log:
            native = subprocess.Popen(words, cwd=HERE, stdout=log, stderr=subprocess.STDOUT)
            status = native.wait()
        (results / 'native-exit.txt').write_text(str(status) + '\n')
        summary_status = 1
        try:
            with (results / 'summary.json').open('w') as out, (results / 'summary-export.log').open('w') as err:
                summary_status = subprocess.run(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary',
                    '--path', str(results / 'tests.xcresult')], stdout=out, stderr=err, timeout=60).returncode
            summary = json.loads((results / 'summary.json').read_text()) if summary_status == 0 else {}
            exact_pass = exact_pass_summary(summary_status, summary)
        except (OSError, ValueError, subprocess.TimeoutExpired) as error:
            write('summary-error.json', {'error': str(error)})
            exact_pass = False
        (results / 'summary-export-exit.txt').write_text(str(summary_status) + '\n')
        write('native-verdict.json', {'native_exit': status, 'exact_two_pass_zero_fail_zero_skip': exact_pass,
                                     'diagnostic_pass': status == 0 and exact_pass})
        if status == 0 and not exact_pass:
            status = 1
    except KeyboardInterrupt as error:
        status = 143 if error.args and error.args[0] == signal.SIGTERM else 130
        write('interrupted.json', {'runner_status': status})
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        write('runner-error.json', {'error': str(error)})
        if status == 0:
            status = 1
    finally:
        if native is not None and native.poll() is None:
            stops = []
            for name, send, limit in [('SIGINT', lambda: native.send_signal(signal.SIGINT), 20),
                                      ('SIGTERM', native.terminate, 10), ('SIGKILL', native.kill, 10)]:
                if native.poll() is not None:
                    break
                stops.append(name)
                send()
                try:
                    native.wait(timeout=limit)
                except subprocess.TimeoutExpired:
                    pass
            write('native-stop-signals.json', stops)
            (results / 'native-exit.txt').write_text(str(native.poll()) + '\n')
        if owned is not None:
            outcomes = []
            with (results / 'cleanup.log').open('w') as log:
                for operation in ['shutdown']:
                    try:
                        code = subprocess.run(['xcrun', 'simctl', operation, owned], stdout=log,
                                              stderr=subprocess.STDOUT, timeout=60).returncode
                    except (OSError, subprocess.TimeoutExpired) as error:
                        code = None
                        log.write(str(error) + '\n')
                    outcomes.append({'operation': operation, 'owned_udid': owned, 'returncode': code})
            cleanup_failed = any(item['returncode'] != 0 for item in outcomes)
            write('cleanup.json', {'outcomes': outcomes, 'cleanup_failed': cleanup_failed,
                                   'ownership_retained_for_followup': owned, 'retained': True,
                                   'shutdown_succeeded': not cleanup_failed})
        try:
            after = inventory()
            write('hashes-after.json', after)
            integrity_failed = before != after
            write('integrity.json', {'fixture_unchanged': before['fixture'] == after['fixture'],
                                     'canonical_unchanged': before['canonical_read_only'] == after['canonical_read_only']})
        except (OSError, RuntimeError) as error:
            integrity_failed = True
            write('integrity-error.json', {'error': str(error)})
        write('runner-status.json', {'primary_status': status, 'cleanup_failed': cleanup_failed,
                                     'integrity_failed': integrity_failed})
    print('Diagnostic evidence retained:', results)
    return status if status != 0 else (2 if cleanup_failed or integrity_failed else 0)


if __name__ == '__main__':
    sys.exit(main())
