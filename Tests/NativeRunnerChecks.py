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
    elif args[:2] == ['simctl', 'shutdown'] and os.environ.get('MOCK_SHUTDOWN_FAIL') == '1':
        sys.exit(42)
    elif args[:2] == ['simctl', 'get_app_container']:
        print(root / 'container')
    elif args[:4] == ['xcresulttool', 'get', 'test-results', 'summary']:
        skipped = os.environ.get('MOCK_SKIP') == '1'
        print(json.dumps(dict(passedTests=0 if skipped else 1, skippedTests=1 if skipped else 0, failedTests=0)))
    sys.exit()
raise RuntimeError(name)
'''


def run_case(runner, failure=None, skip=False, shutdown_failure=False):
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
                           MOCK_ROOT=str(root), MOCK_FAIL=failure or "", MOCK_SKIP="1" if skip else "0",
                           MOCK_SHUTDOWN_FAIL="1" if shutdown_failure else "0")
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
            if log.name == "simulator-cleanup.log": continue
            action = "build" if log.name.startswith("build-") else "test"
            assert "mock diagnostic " + action in log.read_text(), log
            assert "mock stdout " + action in log.read_text(), log
        if failure:
            assert result.returncode == 42, (result.returncode, result.stdout, result.stderr)
            expected_count = 3 if integration and failure == "test" else 1
            assert len(invocations) == expected_count
        elif skip:
            assert result.returncode != 0 and len(invocations) == 1
        elif shutdown_failure:
            assert result.returncode == 70 and len(invocations) == 1, (result.returncode, result.stdout, result.stderr)
        else:
            assert result.returncode == 0, (result.stdout, result.stderr)
            assert len(invocations) == (4 if integration else 8)
            assert {entry[1][entry[1].index("-configuration") + 1] for entry in invocations} == {"Debug", "Release"}
        mutations = [args for name, args, _ in commands
                     if name == "xcrun" and args[:1] == ["simctl"] and args[1] in ["shutdown", "delete", "erase"]]
        if integration:
            assert not mutations, "Integration runner must not delete the caller's simulator"
        else:
            created = [entry for entry in commands if entry[0] == "xcrun" and entry[1][:2] == ["simctl", "create"]]
            assert len(mutations) == len(created)
            assert not any(args[1] in ["delete", "erase"] for args in mutations), "Journey QA must retain simulators"
            retained_files = list(root.rglob("retained-simulators.jsonl"))
            assert len(retained_files) == 1
            records = [json.loads(line) for line in retained_files[0].read_text().splitlines()]
            assert len(records) == len(created), "Each owned simulator must be recorded exactly once"
            for number in range(1, len(created) + 1):
                identifier = "owned-simulator-" + str(number)
                assert ["simctl", "shutdown", identifier] in mutations
                record = records[number - 1]
                assert record["udid"] == identifier and record["created_by_runner"] and record["retained"]
                assert record["shutdown_exit"] == (42 if shutdown_failure else 0)
                assert record["shutdown_succeeded"] == (not shutdown_failure)
                assert record["configuration"] in ["Debug", "Release"]
                assert record["preservation_path"] in ["both", "email", "video", "neither"]
                assert record["runtime"] == arguments[0] and record["device_type"] == arguments[1]
                assert Path(record["xcresult"]).parent == retained_files[0].parent
                assert Path(record["save"]).parent == retained_files[0].parent


for runner in ["validate-ios-integration.sh", "validate-acts-journey.sh"]:
    run_case(runner)
    run_case(runner, failure="test")
run_case("validate-ios-integration.sh", failure="build")
run_case("validate-acts-journey.sh", skip=True)
run_case("validate-acts-journey.sh", shutdown_failure=True)
print("PASS: seven mocked existing native-runner cases, including retained journey simulators")

EXPERIENCE_MOCK = r'''#!/usr/bin/env python3
import json, os, pathlib, shutil, sys
name=pathlib.Path(sys.argv[0]).name
args=sys.argv[1:]
root=pathlib.Path(os.environ['MOCK_ROOT'])
guards={key:os.environ.get(key) for key in ['TEST_RUNNER_BANANA_QA_RESET','TEST_RUNNER_BANANA_QA_ACCESSIBILITY','TEST_RUNNER_BANANA_QA_ACCESSIBILITY_TYPE','TEST_RUNNER_BANANA_QA_ACCESSIBILITY_CATEGORY','TEST_RUNNER_BANANA_QA_AUDIT_CATEGORY']}
with (root/'commands.jsonl').open('a') as stream:
    stream.write(json.dumps([name,args,guards])+'\n')
if name=='uname':
    print('Darwin'); sys.exit()
if name=='cp':
    if os.environ.get('EXPERIENCE_EXPORT_FAIL')=='1':
        print('mock export failure',file=sys.stderr); sys.exit(43)
    assert args[0]=='-R',args
    shutil.copytree(args[1],args[2]); sys.exit()
if name=='xcodebuild':
    if args==['-version']:
        print('Xcode 26.0\nBuild version MOCK'); sys.exit()
    assert args[-1]=='test',args
    bundle=pathlib.Path(args[args.index('-resultBundlePath')+1]); bundle.mkdir()
    save=root/'container/Library/Application Support/BananaCorp/story-save.json'
    save.parent.mkdir(parents=True,exist_ok=True); save.write_text('{"mock":true}')
    print('mock experience test stdout')
    print('mock experience test diagnostic',file=sys.stderr)
    if os.environ.get('EXPERIENCE_NATIVE_FAIL')=='1': sys.exit(42)
    sys.exit()
if name=='xcrun':
    if args==['simctl','list','runtimes','--json']:
        print(json.dumps({'runtimes':[{'identifier':'com.apple.CoreSimulator.SimRuntime.iOS-18-0','isAvailable':True}]}))
    elif args==['simctl','list','devicetypes','--json']:
        print(json.dumps({'devicetypes':[{'identifier':'com.apple.CoreSimulator.SimDeviceType.iPhone-16'}]}))
    elif args[:2]==['simctl','create']:
        counter=root/'counter'; number=int(counter.read_text())+1 if counter.exists() else 1
        counter.write_text(str(number)); print(f'00000000-0000-0000-0000-{number:012d}')
    elif args[:2]==['simctl','boot'] or args[:2]==['simctl','bootstatus']:
        pass
    elif args[:2]==['simctl','shutdown']:
        if os.environ.get('EXPERIENCE_SHUTDOWN_FAIL')=='1': sys.exit(71)
    elif args[:2] in [['simctl','delete'],['simctl','erase']]:
        raise RuntimeError('Automatic simulator deletion/erasure is forbidden')
    elif args[:2]==['simctl','get_app_container']:
        print(root/'container')
    elif args[:4]==['xcresulttool','get','test-results','summary']:
        print(os.environ.get('EXPERIENCE_SUMMARY','{"passedTests":1,"failedTests":0,"skippedTests":0}'))
    else: raise RuntimeError(('Unrecognized fake xcrun command',args))
    sys.exit()
raise RuntimeError(('Unrecognized fake tool',name,args))
'''


def experience_case(label, *, summary=None, native_fail=False, export_fail=False,
                    shutdown_fail=False, selected=None, expected=0):
    with tempfile.TemporaryDirectory(prefix='banana-experience-contract-') as directory:
        root=Path(directory)
        (root/'scripts').mkdir()
        (root/'bin').mkdir()
        project=root/'Banana Corp/Banana Corp.xcodeproj/project.pbxproj'
        project.parent.mkdir(parents=True); project.write_text('mock project placeholder')
        tests=root/'Banana Corp/Banana CorpUITests'; tests.mkdir()
        for filename in ['StoryResetUITests.swift','AccessibilityAuditUITests.swift']:
            (tests/filename).write_text('// mock existence fixture, never compiled')
        runner=root/'scripts/validate-native-experience.sh'
        shutil.copy2(ROOT/'scripts/validate-native-experience.sh',runner)
        # All Apple command entry points are replaced; unknown commands fail.
        # cp is replaced to exercise export failure without touching host data.
        for tool in ['uname','xcrun','xcodebuild','cp']:
            executable=root/'bin'/tool; executable.write_text(EXPERIENCE_MOCK); executable.chmod(0o755)
        environment=os.environ.copy()
        for key in list(environment):
            if key.startswith(('TEST_RUNNER_BANANA_QA_','BANANA_QA_','EXPERIENCE_')):
                environment.pop(key)
        environment.update(PATH=str(root/'bin')+os.pathsep+environment['PATH'],MOCK_ROOT=str(root),
            EXPERIENCE_NATIVE_FAIL='1' if native_fail else '0',
            EXPERIENCE_EXPORT_FAIL='1' if export_fail else '0',
            EXPERIENCE_SHUTDOWN_FAIL='1' if shutdown_fail else '0')
        if summary is not None: environment['EXPERIENCE_SUMMARY']=json.dumps(summary)
        arguments=['com.apple.CoreSimulator.SimRuntime.iOS-18-0','com.apple.CoreSimulator.SimDeviceType.iPhone-16']
        if selected: arguments.extend(selected)
        result=subprocess.run(['bash',str(runner),*arguments],env=environment,
            text=True,capture_output=True,timeout=30)
        assert (result.returncode==0 if expected==0 else result.returncode==expected if expected>0 else result.returncode!=0), (label,result.returncode,result.stdout,result.stderr)
        entries=[json.loads(line) for line in (root/'commands.jsonl').read_text().splitlines()]
        invocations=[entry for entry in entries if entry[0]=='xcodebuild' and entry[1][-1:] == ['test']]
        successful_all=expected==0 and not selected
        assert len(invocations)==(4 if successful_all else len(selected) if expected==0 and selected else 1),label
        expected_filters={
            'Debug-reset':('Debug','Banana CorpUITests/StoryResetUITests/testSettingsResetCancelConfirmAndRelaunch'),
            'Release-absence':('Release','Banana CorpUITests/StoryResetUITests/testReleaseSettingsOmitsDevelopmentDiagnostics'),
            'Debug-audit':('Debug','Banana CorpUITests/AccessibilityAuditUITests/testHomeAndRegisteredApplicationsAccessibilityAudit'),
            'Release-audit':('Release','Banana CorpUITests/AccessibilityAuditUITests/testHomeAndRegisteredApplicationsAccessibilityAudit'),
            'Debug-type':('Debug','Banana CorpUITests/AccessibilityAuditUITests/testHomeDynamicTypeAccessibilityAudit'),
            'Release-type':('Release','Banana CorpUITests/AccessibilityAuditUITests/testHomeDynamicTypeAccessibilityAudit')}
        for token in ['contrast', 'element-detection', 'hit-region', 'element-description', 'dynamic-type', 'text-clipped', 'trait']:
            expected_filters['Debug-category-'+token]=('Debug','Banana CorpUITests/AccessibilityAuditUITests/testHomeSingleCategoryAccessibilityDiagnostic')
        cases=selected or ['Debug-reset','Release-absence','Debug-audit','Release-audit']
        for (name,args,guards),case_name in zip(invocations,cases):
            configuration,test_id=expected_filters[case_name]
            assert args[args.index('-configuration')+1]==configuration
            assert '-only-testing:'+test_id in args
            assert 'CODE_SIGNING_ALLOWED=NO' in args and 'ENABLE_TESTABILITY=YES' in args
            assert args[args.index('-parallel-testing-enabled')+1]=='NO'
            assert not any(argument.startswith(('-retry','-test-iterations','-allowProvisioning','-launch')) for argument in args)
            expected_guards={key:None for key in guards}
            if case_name.startswith('Debug-category-'):
                expected_guards['TEST_RUNNER_BANANA_QA_ACCESSIBILITY_CATEGORY']='owned-simulator'
                expected_guards['TEST_RUNNER_BANANA_QA_AUDIT_CATEGORY']=case_name.removeprefix('Debug-category-')
            elif case_name.endswith('type'):
                expected_guards['TEST_RUNNER_BANANA_QA_ACCESSIBILITY_TYPE']='owned-simulator'
            elif case_name.endswith('audit'):
                expected_guards['TEST_RUNNER_BANANA_QA_ACCESSIBILITY']='owned-simulator'
            else:
                expected_guards['TEST_RUNNER_BANANA_QA_RESET']='fresh-simulator'
            assert guards==expected_guards,(case_name,guards,expected_guards)
        results=next((root/'validation').iterdir())
        ledger=(results/'owned-simulators.tsv').read_text().splitlines()
        assert len(ledger)==len(invocations)+1
        created=[entry for entry in entries if entry[0]=='xcrun' and entry[1][:2]==['simctl','create']]
        assert len(created)==len(invocations)
        for number,invocation in enumerate(invocations,1):
            identifier=f'00000000-0000-0000-0000-{number:012d}'
            assert identifier in ledger[number]
            assert invocation[1][invocation[1].index('-destination')+1]=='platform=iOS Simulator,id='+identifier
        mutations=[entry[1] for entry in entries if entry[0]=='xcrun' and entry[1][:2] in [['simctl','delete'],['simctl','erase'],['simctl','shutdown']]]
        assert len(mutations)==len(created), (label,mutations)
        assert all(args[1]=='shutdown' for args in mutations), 'No automatic deletion or erasure'
        retained=[json.loads(line) for line in (results/'retained-simulators.jsonl').read_text().splitlines()]
        assert len(retained)==len(created)
        for number,record in enumerate(retained,1):
            assert record['udid']==f'00000000-0000-0000-0000-{number:012d}'
            assert record['retained'] and record['created_by_runner']
            assert record['shutdown_exit']==(71 if shutdown_fail else 0)
            assert record['shutdown_succeeded']==(not shutdown_fail)
            assert record['case']==cases[number-1]
            assert record['runtime']==arguments[0] and record['device_type']==arguments[1]
            assert Path(record['xcresult']).parent==results
        for args in mutations:
            assert args[2] in [f'00000000-0000-0000-0000-{number:012d}' for number in range(1,len(created)+1)]
        # Serial ownership: successful shutdown/retention precedes any next create.
        active=False
        for tool,args,_ in entries:
            if tool=='xcrun' and args[:2]==['simctl','create']:
                assert not active; active=True
            if tool=='xcrun' and args[:2]==['simctl','shutdown'] and not shutdown_fail: active=False
        for log in results.glob('*.log'):
            if log.name in [case+'.log' for case in cases]:
                assert 'mock experience test stdout' in log.read_text()
                assert 'mock experience test diagnostic' in log.read_text()
        if shutdown_fail:
            assert (results/'outstanding-owned-simulator.txt').read_text().strip()=='00000000-0000-0000-0000-000000000001'
            assert 'CLEANUP FAILED' in result.stderr
        else: assert not (results/'outstanding-owned-simulator.txt').exists()
        if native_fail and export_fail:
            assert 'original native failure takes precedence' in result.stderr
        if export_fail:
            assert (results/(cases[0]+'-artifact-export-exit.txt')).read_text().strip()=='43'
        if not export_fail:
            assert list(results.glob('*-story-artifacts/story-save.json'))
        print('PASS MOCK experience:',label)


experience_case('four cases, both configurations, exact guards/filters and serial ownership')
experience_case('explicit Release audit selection',selected=['Release-audit'])
experience_case('native failure',native_fail=True,expected=42)
experience_case('skip rejected',summary=dict(passedTests=0,failedTests=0,skippedTests=1),expected=-1)
experience_case('failure count rejected',summary=dict(passedTests=1,failedTests=1,skippedTests=0),expected=-1)
experience_case('extra pass rejected',summary=dict(passedTests=2,failedTests=0,skippedTests=0),expected=-1)
experience_case('export failure',export_fail=True,expected=43)
experience_case('native failure takes precedence over export failure',native_fail=True,export_fail=True,expected=42)
experience_case('shutdown failure retains owned UUID and fails runner',shutdown_fail=True,expected=70)
experience_case('native failure takes precedence over cleanup failure',native_fail=True,shutdown_fail=True,expected=42)
experience_case('shutdown failure does not start another case',selected=['Debug-reset','Release-absence'],shutdown_fail=True,expected=70)
print('PASS: staged mock command contracts; no Apple build, XCTest, simulator, bundle, accessibility or gameplay validation was performed')

experience_case('optional focused Dynamic Type both configurations',selected=['Debug-type','Release-type'])
experience_case('focused Dynamic Type skip rejected',selected=['Debug-type'],summary=dict(passedTests=0,failedTests=0,skippedTests=1),expected=-1)
experience_case('focused Dynamic Type native failure',selected=['Release-type'],native_fail=True,expected=42)
print('PASS MOCK ONLY: three focused Dynamic Type command contracts; no native audit or simulator execution')

experience_case('all seven optional Debug categories',selected=['Debug-category-contrast', 'Debug-category-element-detection', 'Debug-category-hit-region', 'Debug-category-element-description', 'Debug-category-dynamic-type', 'Debug-category-text-clipped', 'Debug-category-trait'])
experience_case('category skip rejected',selected=['Debug-category-contrast'],summary=dict(passedTests=0,failedTests=0,skippedTests=1),expected=-1)
experience_case('category native failure',selected=['Debug-category-trait'],native_fail=True,expected=42)
print('PASS MOCK ONLY: category guard/filter isolation; no native accessibility diagnostic execution')

NEUTRAL_MOCK = r'''#!/usr/bin/env python3
import json,os,pathlib,sys
name=pathlib.Path(sys.argv[0]).name;args=sys.argv[1:]
root=pathlib.Path(os.environ['MOCK_ROOT'])
with (root/'commands.jsonl').open('a') as stream:stream.write(json.dumps([name,args])+'\n')
if name=='xcodebuild':
    if args==['-version']:print('Xcode 26.5\nBuild version MOCK');sys.exit()
    assert args[-1]=='test' and 'ENABLE_TESTABILITY=YES' in args and 'CODE_SIGNING_ALLOWED=NO' in args
    assert sum(word.startswith('-only-testing:') for word in args)==2
    assert not any(word.startswith(('-retry','-test-iterations','-allowProvisioning','-launch')) for word in args)
    pathlib.Path(args[args.index('-resultBundlePath')+1]).mkdir()
    sys.exit(42 if os.environ.get('NEUTRAL_NATIVE_FAIL')=='1' else 0)
if name=='xcrun':
    if args==['simctl','list','runtimes','--json']:
        print(json.dumps({'runtimes':[{'identifier':'com.apple.CoreSimulator.SimRuntime.iOS-26-5','version':'26.5','isAvailable':True}]}))
    elif args==['simctl','list','devicetypes','--json']:
        print(json.dumps({'devicetypes':[{'identifier':'com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro'}]}))
    elif args[:2]==['simctl','create']:print('00000000-0000-0000-0000-000000000001')
    elif args[:2] in [['simctl','boot'],['simctl','bootstatus']]:pass
    elif args[:2]==['simctl','shutdown']:sys.exit(71 if os.environ.get('NEUTRAL_SHUTDOWN_FAIL')=='1' else 0)
    elif args[:2] in [['simctl','delete'],['simctl','erase']]:raise RuntimeError('Automatic simulator deletion/erasure forbidden')
    elif args[:4]==['xcresulttool','get','test-results','summary']:
        print(json.dumps(dict(totalTestCount=2,passedTests=2,failedTests=0,skippedTests=0)))
    else:raise RuntimeError(args)
    sys.exit()
raise RuntimeError(name)
'''


def neutral_retention_case(*, shutdown_fail=False, native_fail=False):
    with tempfile.TemporaryDirectory(prefix='banana-neutral-retention-contract-') as directory:
        root=Path(directory);fixture=root/'tools/diagnostics/neutral-shell'
        fixture.mkdir(parents=True);(root/'bin').mkdir();(root/'Banana Corp').mkdir()
        for name in ['NeutralShellReproApp.swift','NeutralShellReproUITests.swift',
                     'NeutralShellRepro.xcodeproj/project.pbxproj',
                     'NeutralShellRepro.xcodeproj/xcshareddata/xcschemes/NeutralShellRepro.xcscheme',
                     'source-comparison.json','baseline-fixture-sha256.json','run.py','README.md']:
            target=fixture/name;target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/'tools/diagnostics/neutral-shell'/name,target)
        for name in ['AGENTS.md','BANANA_CORP_GAME_BIBLE.md']:(root/name).write_text('neutral test fixture only\n')
        for name in ['xcodebuild','xcrun']:
            p=root/'bin'/name;p.write_text(NEUTRAL_MOCK);p.chmod(0o755)
        env=os.environ.copy();env.update(PATH=str(root/'bin')+os.pathsep+env['PATH'],MOCK_ROOT=str(root),
            NEUTRAL_SHUTDOWN_FAIL='1' if shutdown_fail else '0',NEUTRAL_NATIVE_FAIL='1' if native_fail else '0')
        # Platform guard is faked only inside this isolated Python process; all Apple tools are mocks.
        import sys
        wrapper="import runpy,subprocess,sys;sys.platform='darwin';sys.argv=[sys.argv[1],'retention-contract'];runpy.run_path(sys.argv[0],run_name='__main__')"
        result=subprocess.run([sys.executable,'-c',wrapper,str(fixture/'run.py')],env=env,text=True,capture_output=True,timeout=30)
        expected=42 if native_fail else 2 if shutdown_fail else 0
        assert result.returncode==expected,(result.returncode,result.stdout,result.stderr)
        out=root/'validation/neutral-shell-repro-retention-contract'
        commands=[json.loads(line) for line in (root/'commands.jsonl').read_text().splitlines()]
        mutations=[args for name,args in commands if name=='xcrun' and args[:2] in [['simctl','shutdown'],['simctl','delete'],['simctl','erase']]]
        assert mutations==[['simctl','shutdown','00000000-0000-0000-0000-000000000001']]
        ownership=json.loads((out/'owned-simulator.json').read_text())
        cleanup=json.loads((out/'cleanup.json').read_text())
        assert cleanup['retained'] and cleanup['ownership_retained_for_followup']==ownership['udid']
        assert cleanup['cleanup_failed']==shutdown_fail and cleanup['shutdown_succeeded']==(not shutdown_fail)
        assert cleanup['outcomes']==[{'operation':'shutdown','owned_udid':ownership['udid'],'returncode':71 if shutdown_fail else 0}]
        integrity=json.loads((out/'integrity.json').read_text())
        assert integrity['fixture_unchanged'] and integrity['canonical_unchanged']
        print('PASS MOCK neutral simulator retention:', 'native failure' if native_fail else 'native success', 'shutdown failure' if shutdown_fail else 'shutdown success')


neutral_retention_case()
neutral_retention_case(shutdown_fail=True)
neutral_retention_case(shutdown_fail=True,native_fail=True)
print('PASS MOCK ONLY: neutral ownership retained after success/failure, cleanup failure propagation and primary failure precedence; no simulator execution')
