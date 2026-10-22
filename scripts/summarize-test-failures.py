#!/usr/bin/env python3
"""Read XCTest assertion messages from an existing Xcode result bundle."""
import argparse
import json
from pathlib import Path
import subprocess
import sys


def value(field, default=""):
    return field.get("_value", default) if isinstance(field, dict) else default


def failure_lines(result):
    issues = result.get("issues", {})
    failures = issues.get("testFailureSummaries", {}).get("_values", [])
    lines = []
    for index, failure in enumerate(failures, 1):
        lines.append("{}. {}".format(index, value(failure.get("testCaseName"), "Unnamed test")))
        lines.append("   " + value(failure.get("message"), "No assertion message recorded."))
        location = value(failure.get("documentLocationInCreatingWorkspace", {}).get("url"))
        if location:
            lines.append("   " + location)
    return lines


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("result_bundle", type=Path, help="Path to the failed .xcresult directory")
    args = parser.parse_args()
    if not args.result_bundle.is_dir():
        parser.error("Result bundle directory does not exist: {}".format(args.result_bundle))
    try:
        result = subprocess.run(
            ["xcrun", "xcresulttool", "get", "object", "--legacy", "--path",
             str(args.result_bundle), "--format", "json"],
            capture_output=True, text=True, timeout=60, check=True,
        )
        lines = failure_lines(json.loads(result.stdout))
    except (OSError, subprocess.SubprocessError, ValueError) as error:
        print("Could not read the saved test result: {}".format(error), file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            print(error.stderr, file=sys.stderr)
        return 1
    print("Saved test result: {}".format(args.result_bundle))
    if lines:
        print("\n".join(lines))
    else:
        print("No XCTest assertion summaries were found. This does not establish a passing run.")
        print("Open the result bundle in Xcode to inspect launch, crash, or build errors.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
