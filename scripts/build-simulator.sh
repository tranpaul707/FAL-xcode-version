#!/bin/bash
# Build/test the non-MLX app on a caller-selected installed simulator.
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: bash scripts/build-simulator.sh SIMULATOR_UDID [build|test]

Run on a Mac with full Xcode and an installed compatible iOS Simulator runtime.
Find a UDID with: xcrun simctl list devices available
The default action is build. Tests run only when the action is test.
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
if [ "$action" != 'build' ] && [ "$action" != 'test' ]; then
    printf '%s\n' 'Action must be build or test.' >&2
    exit 64
fi
if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'This command requires macOS and full Xcode; it cannot build iOS on Linux.' >&2
    exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
exec xcodebuild \
    -project "$repo_root/FoodAdditiveLens.xcodeproj" \
    -scheme FoodAdditiveLens \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$simulator_udid" \
    -derivedDataPath "$repo_root/DerivedData" \
    -onlyUsePackageVersionsFromResolvedFile \
    CODE_SIGNING_ALLOWED=NO \
    "$action"
