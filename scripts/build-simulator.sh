#!/bin/bash
# Build/test the non-MLX app on a caller-selected installed simulator.
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: bash scripts/build-simulator.sh SIMULATOR_UDID [build|test|unit-test|ui-test|sample-test]

Run on a Mac with full Xcode and an installed compatible iOS Simulator runtime.
Find a UDID with: xcrun simctl list devices available
The default action is build. Use test for all tests, unit-test for unit tests,
ui-test for all UI tests, or sample-test for the sample/reset/history test.
Test execution has a 120-second default and a
180-second maximum allowance per test; simulator startup/build time is separate.
This builds the FoodAdditiveLens scheme with signing disabled for the simulator.
Build output goes to the ignored DerivedData/ directory in the checkout.
USAGE
}

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ]; then
    usage
    exit 0
fi
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage >&2
    exit 64
fi

simulator_udid="$1"
action="${2:-build}"
if [[ ! "$simulator_udid" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$ ]]; then
    printf '%s\n' 'Supply an installed simulator UDID, not a device name.' >&2
    exit 64
fi
case "$action" in
    build|test|unit-test|ui-test|sample-test) ;;
    *)
        printf '%s\n' 'Action must be build, test, unit-test, ui-test, or sample-test.' >&2
        exit 64
        ;;
esac
if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'This command requires macOS and full Xcode; it cannot build iOS on Linux.' >&2
    exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
# Keep paths and switches as separate arguments without line continuations.
xcodebuild_arguments=(
    -project "$repo_root/FoodAdditiveLens.xcodeproj"
    -scheme FoodAdditiveLens
    -configuration Debug
    -destination "platform=iOS Simulator,id=$simulator_udid"
    -derivedDataPath "$repo_root/DerivedData"
    -onlyUsePackageVersionsFromResolvedFile
)
if [ "$action" != 'build' ]; then
    xcodebuild_arguments+=(
        -test-timeouts-enabled YES
        -default-test-execution-time-allowance 120
        -maximum-test-execution-time-allowance 180
        -parallel-testing-enabled NO
    )
    case "$action" in
        unit-test) xcodebuild_arguments+=(-only-testing:FoodAdditiveLensTests) ;;
        ui-test) xcodebuild_arguments+=(-only-testing:FoodAdditiveLensUITests) ;;
        sample-test) xcodebuild_arguments+=(-only-testing:FoodAdditiveLensUITests/AppLaunchTests/testLaunchSampleResetAndHistoryWithoutModels) ;;
    esac
    action=test
fi
xcodebuild_arguments+=(CODE_SIGNING_ALLOWED=NO "$action")
printf 'Build output directory: %s\n' "$repo_root/DerivedData"
exec xcodebuild "${xcodebuild_arguments[@]}"
