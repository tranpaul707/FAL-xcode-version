#!/bin/bash
# Collect the actual MLX compiler diagnostic on the user's Mac.
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: bash scripts/diagnose-mlx-build.sh

Check the iOS Metal compiler, then build FoodAdditiveLens-MLX for generic iOS
without signing. No phone or model weights are required. Logs are saved under
DerivedData/diagnostics/. Share the final MLX DIAGNOSTIC RESULT section.
This script does not install Xcode components or change package versions.
USAGE
}

if [ "$#" -eq 1 ] && { [ "$1" = '--help' ] || [ "$1" = '-h' ]; }; then
    usage
    exit 0
fi
if [ "$#" -ne 0 ]; then
    usage >&2
    exit 64
fi
if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'This diagnostic requires macOS and full Xcode; it cannot build iOS on Linux.' >&2
    exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
log_dir="$repo_root/DerivedData/diagnostics"
mkdir -p "$log_dir"
metal_log="$(mktemp "$log_dir/metal-check.XXXXXX")"

printf '%s\n' 'Checking the iOS Metal compiler...'
if xcrun --sdk iphoneos metal --version >"$metal_log" 2>&1; then
    metal_status=0
else
    metal_status=$?
fi
cat "$metal_log"
if [ "$metal_status" -ne 0 ]; then
    printf '\n%s\n' '=== MLX DIAGNOSTIC RESULT ==='
    printf 'Metal compiler check failed (exit %s):\n' "$metal_status"
    cat "$metal_log"
    printf '%s\n' 'The MLX build was not started because the Metal compiler check failed.'
    printf '%s\n' 'If the error reports a missing Metal Toolchain, run on this Mac:'
    printf '%s\n' '  xcodebuild -downloadComponent MetalToolchain'
    printf '%s\n' 'Then rerun this diagnostic.'
    printf 'Metal check log: %s\n' "$metal_log"
    exit "$metal_status"
fi

build_log="$(mktemp "$log_dir/mlx-build.XXXXXX")"
xcodebuild_arguments=(
    -project "$repo_root/FoodAdditiveLens.xcodeproj"
    -scheme FoodAdditiveLens-MLX
    -configuration Debug
    -destination 'generic/platform=iOS'
    -derivedDataPath "$repo_root/DerivedData"
    -onlyUsePackageVersionsFromResolvedFile
    -jobs 1
    CODE_SIGNING_ALLOWED=NO
    build
)
printf '\nFull build log: %s\n' "$build_log"
# Capture both statuses immediately: tee must not hide an xcodebuild failure.
set +e
xcodebuild "${xcodebuild_arguments[@]}" 2>&1 | tee "$build_log"
pipeline_status=("${PIPESTATUS[@]}")
set -e
build_status="${pipeline_status[0]}"
log_status="${pipeline_status[1]}"

printf '\n%s\n' '=== MLX DIAGNOSTIC RESULT ==='
printf '%s\n' 'Metal compiler check succeeded:'
cat "$metal_log"
printf 'xcodebuild exit status: %s\n' "$build_status"
printf 'Full build log: %s\n' "$build_log"
if [ "$log_status" -ne 0 ]; then
    printf 'Log capture failed (tee exit %s); the log may be incomplete.\n' "$log_status"
fi
if [ "$build_status" -ne 0 ]; then
    printf '\n%s\n' 'First compiler/tool error and surrounding output:'
    # Use macOS's built-in awk. Keep six preceding and twenty following lines.
    awk '
        {
            if (found) {
                print
                remaining--
                if (remaining == 0) exit
            } else {
                current = tolower($0)
                if (current ~ /error:|fatal error|cannot execute tool|command .* failed/) {
                    start = NR - 6
                    if (start < 1) start = 1
                    for (i = start; i < NR; i++) print previous[i % 6]
                    print
                    found = 1
                    remaining = 20
                } else {
                    previous[NR % 6] = $0
                }
            }
        }
        END {
            if (!found) print "No compiler/tool error matched. Share the full build log above."
        }
    ' "$build_log"
    exit "$build_status"
fi
if [ "$log_status" -ne 0 ]; then
    exit "$log_status"
fi
printf '%s\n' 'BUILD SUCCEEDED (unsigned generic iOS compile only; inference was not run).'
