#!/bin/bash
# Read-only Phase 1 inventory. Compatible with the Bash shipped by macOS.
set -u
set -o pipefail

printf '%s\n' 'Food Additive Lens — Phase 1 Mac/Xcode inventory'

host_os="$(uname -s)"
if [ "$host_os" != 'Darwin' ]; then
    printf '%s\n' "Unsupported host: $host_os ($(uname -m))."
    printf '%s\n' 'Run this script on the Apple silicon Mac with full Xcode installed.'
    printf '%s\n' 'Xcode and Apple iOS Simulator cannot run on this Linux cloud host.'
    exit 2
fi

phase1_status=0

run_check() {
    local label="$1"
    shift
    printf '\n%s\n' "$label"
    if "$@"; then
        return 0
    else
        local command_status=$?
        printf 'Query failed (exit %s). Complete the relevant Xcode setup and rerun.\n' "$command_status"
        phase1_status=1
    fi
}

run_check 'macOS version:' sw_vers -productVersion
run_check 'Shell process architecture (may reflect Rosetta):' uname -m
run_check 'Apple silicon hardware capability (1 = yes):' sysctl -n hw.optional.arm64
run_check 'Physical memory (bytes):' sysctl -n hw.memsize
run_check 'Free space on the checkout volume:' df -h .
run_check 'Selected developer directory:' xcode-select -p
run_check 'Xcode version:' xcodebuild -version
run_check 'Selected Swift compiler:' xcrun swift --version
run_check 'Available SDKs:' xcodebuild -showsdks
run_check 'Selected iOS Simulator SDK version:' xcrun --sdk iphonesimulator --show-sdk-version
run_check 'Installed simulator runtimes:' xcrun simctl list runtimes
run_check 'Available simulator devices / UDIDs:' xcrun simctl list devices available

printf '\n%s\n' 'Share this report in the project chat when checking Xcode setup or build problems.'
printf '%s\n' 'Query success does not prove a usable runtime, app build, simulator launch, or MLX inference.'
printf '%s\n' 'MLX simulator inference is excluded; inference validation requires supported hardware.'
exit "$phase1_status"
