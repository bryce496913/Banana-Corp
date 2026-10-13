#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(uname -s)" != Darwin ]] || ! command -v xcodebuild >/dev/null || ! command -v xcrun >/dev/null; then
    echo 'BLOCKED: macOS, full Xcode 26+, and Apple SDK tools are required. No native build or XCTest was run.' >&2
    exit 69
fi
if [[ $# -lt 1 || $# -gt 2 || ! "$1" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
    echo 'Usage: bash scripts/validate-ios-integration.sh SIMULATOR_UDID [NEW_RESULTS_DIRECTORY]' >&2
    exit 64
fi
command -v python3 >/dev/null || { echo 'Python 3 is required for structural/bundle checks.' >&2; exit 69; }
xcode_major="$(xcodebuild -version | awk '/^Xcode / {split($2, v, "."); print v[1]}')"
[[ "$xcode_major" -ge 26 ]] || { echo 'Xcode 26+ is required to compile guarded Liquid Glass symbols.' >&2; exit 69; }
results="${2:-$repo_root/validation/ios-$(date +%Y%m%d-%H%M%S)}"
[[ ! -e "$results" ]] || { echo 'Choose a new results directory; existing evidence will not be overwritten.' >&2; exit 64; }
mkdir -p "$results"
results="$(cd "$results" && pwd)"
derived="$results/DerivedData"
project="$repo_root/Banana Corp/Banana Corp.xcodeproj"
destination="platform=iOS Simulator,id=$1"
# No device selection fallback and no story reset/launch shortcut. Use a dedicated test simulator.
xcodebuild -version | tee "$results/xcode-version.txt"
xcrun swift --version | tee "$results/swift-version.txt"
xcodebuild -showsdks | tee "$results/sdks.txt"
xcrun simctl list runtimes | tee "$results/runtimes.txt"
xcrun simctl list devices available | tee "$results/devices.txt"
xcodebuild -project "$project" -list | tee "$results/schemes.txt"
xcodebuild -project "$project" -scheme 'Banana Corp' -showdestinations | tee "$results/destinations.txt"
python3 "$repo_root/scripts/check-ios-project.py" | tee "$results/structure.txt"
for configuration in Debug Release; do
    xcodebuild -project "$project" -scheme 'Banana Corp' -configuration "$configuration" \
        -destination "$destination" -derivedDataPath "$derived" CODE_SIGNING_ALLOWED=NO \
        build | tee "$results/build-$configuration.log"
    python3 "$repo_root/scripts/check-ios-project.py" \
        --app-bundle "$derived/Build/Products/$configuration-iphonesimulator/Banana Corp.app" \
        | tee "$results/bundle-$configuration.txt"
done
for configuration in Debug Release; do
    # @testable is enabled only for this test invocation, not the normal Release product.
    xcodebuild -project "$project" -scheme 'Banana Corp' -configuration "$configuration" \
        -destination "$destination" -derivedDataPath "$derived" CODE_SIGNING_ALLOWED=NO \
        ENABLE_TESTABILITY=YES -parallel-testing-enabled NO \
        -resultBundlePath "$results/tests-$configuration.xcresult" \
        test | tee "$results/test-$configuration.log"
done
echo "Native validation finished. Review logs and xcresult bundles in $results"
