# Phase 1 — Xcode host and simulator baseline

Status: **Mac host baseline recorded from the user's inventory report.** The user ran the inventory script on the Apple silicon Mac and supplied the results below. Ongoing app build, test, launch, and inference evidence is tracked in [Phase 2](PHASE2-XCODE-SCAFFOLD.md). The Mac is not remotely connected to this cloud task.

## User-reported Mac inventory

| Check | Reported result |
| --- | --- |
| Mac | Apple silicon MacBook Air; process architecture `arm64`; hardware arm64 capability `1` |
| macOS | `26.6.2` |
| Memory | 17,179,869,184 bytes = 16 GiB |
| Free space on checkout volume | Approximately 240 GiB |
| Developer directory | `/Applications/Xcode.app/Contents/Developer` |
| Xcode | `27.1`, build `27A9275` |
| Swift | Apple Swift `6.4`, driver `1.168.6` |
| iOS device / Simulator SDK | `27.1` / `27.1` |
| Installed iOS Simulator runtime | iOS `27.0`, build `24A434` |
| Initial simulator | iPhone 18 Pro, already reported booted |
| Metal compiler (later MLX checks) | Initially missing; the user subsequently reported the diagnostic helper's success footer, establishing a passed Metal preflight and unsigned generic iOS MLX build |

The original script output contains successful responses for the queries it
performed and no query-failure messages. It did not yet query the Metal compiler;
that check was added after the separate MLX attempt exposed the missing component.
This establishes the originally reported host/tool availability,
not project or model compatibility. The Simulator SDK and installed runtime have
different version numbers; that alone does not establish a fault or a need for
another download. Confirm this destination through the Phase 2 build. No additional
runtime or model download is required for the first app-shell attempt.

## Cloud inspection and remaining verification limits

| Check | Result |
| --- | --- |
| Attached cloud host | Debian GNU/Linux 13, x86_64 |
| Apple development tools | `xcodebuild`, `xcrun`, and `swift` not found |
| App build / launch | Follow the separate Phase 2 record for user-reported Mac build/test results and outstanding checks |
| App project's current state | Xcode scaffold is present; current validation scope is recorded in Phase 2 |
| Mac access | User-side command output supplied; the cloud task cannot execute commands on that Mac |
| MLX simulator support | MLX Swift 0.32.3 documentation explicitly says iOS Simulator is unsupported because it does not provide the required modern Metal GPU family |

Installing Linux Swift does not provide Xcode, Apple's iOS SDKs, CoreSimulator, or the UIKit/Vision/Core Data runtime needed by this app. No attempt was made to install those tools or large models on this cloud host.

## Baseline selected from the Mac report

- **Development host:** the user's Apple silicon MacBook Air with the reported macOS 26.6.2, full Xcode 27.1, and Swift 6.4. Tool queries succeeded; compatibility of the app's older pinned packages with this compiler/SDK is a Phase 2 build check.
- **App target:** native iPhone application; provisional minimum iOS 17 because of the source's Observation/preview usage and inspected MLX package platform declarations. Finalize after resolving compatible tagged dependencies and building in Phase 2.
- **Simulator scope:** original UI, manual/sample input when data is available, Vision photo OCR, genuine knowledge lookup, and Core Data history. Core ML category prediction is a separate capability to validate after its artifacts are recovered. The original MLX LLM features remain unavailable on simulator; do not load their backend or substitute fabricated results.
- **Full AI validation:** supported physical iPhone or compatible Apple silicon iOS-on-Mac execution with the genuine model bundle and adequate memory. The original source's device-name whitelist is not a hardware certification. Exact device/inference checks belong to the model phase; owning a physical phone is not a prerequisite for the first simulator MVP. Direct-Mac execution was added to the proposed validation route after discussion with the user; it remains untested.
- **Resource budget:** the Mac reports 16 GiB RAM and about 240 GiB free on the checkout volume. Record these for later model planning; neither number proves the original model can load/generate successfully. No model weights are needed for the initial simulator shell.

The inspected tags are requirement evidence, **not selected app dependencies**:

| Tagged source | Declared requirements / finding |
| --- | --- |
| `mlx-swift` 0.32.3 | Swift tools 6.3 with its declared experimental feature; macOS 14 / iOS 17 platform minimums; documented lack of simulator inference support |
| `mlx-swift-lm` 3.32.3 | Swift tools 6.2; macOS 14 / iOS 17 platform minimums; requires MLX `>=0.32.3, <0.33.0`, making the combined toolchain requirement at least MLX's Swift 6.3 requirement |

Do not select these tags just because they exist. The supplied 2025 source may need an older compatible tagged pair to match the user's Xcode and original APIs. A package's macOS deployment minimum does not mean the Xcode/compiler that builds it runs on that macOS version. Verify the actual compiler, APIs, and Metal build before committing dependency resolution. No Xcode release number is inferred solely from a Swift tools version.

## Initial simulator matrix

These destinations are selected from the user's actual available-device list.
Use the Phase 2 record for app results on the main iPhone 18 Pro destination.
The other matrix destinations and minimum-OS layout coverage remain unverified.

| Destination / UDID | Purpose | Runtime / inventory state |
| --- | --- | --- |
| iPhone 18 Pro — `89CA5AC4-8662-4AB0-8D53-0F1B7A355A30` | First build and launch; main MVP flow later | iOS 27.0 / booted |
| iPhone 17e — `3B5A92D6-0357-443E-988B-6E986AF5213A` | Alternate iPhone layout; confirm viewport for narrow-screen coverage | iOS 27.0 / shutdown |
| iPhone 18 Pro Max — `599D5E89-FE53-454F-A7B4-A6DF1B8400FE` | Larger layout, history, results, and picker checks | iOS 27.0 / shutdown |
| iOS 17 deployment boundary | Minimum-OS compatibility | Not covered: no iOS 17 runtime was reported installed |

The user also reported an available iPhone Air and iPad device profiles. Those
are not needed for the first iPhone app-shell build. No iPad feature expansion
or broad simulator matrix execution is part of this checkpoint.

Reuse a destination when it satisfies multiple rows. Add other compatible iPhone simulator devices by destination selection, without application-code changes. Do not raise the app's deployment minimum merely to hide an unavailable old simulator runtime, or imply that every historical simulator is installable in a current Xcode.

## Inventory instructions (completed by the user)

1. Install full Xcode if needed, launch it, finish its first-launch/license/component setup, and install at least one compatible iOS Simulator runtime through Xcode Settings. Apple's Settings labels may vary by Xcode release.
2. In Xcode Settings → Locations, select the intended Xcode Command Line Tools version if needed. If using `xcode-select` instead, point it at the actual full Xcode application's developer directory; do not copy an assumed application path blindly.
3. Obtain/update this repository's `main` branch while preserving any local changes. From the checkout run:

   ```bash
   bash scripts/check-xcode-environment.sh
   ```

4. Share the report here. It reads tool/OS versions, architecture, RAM, disk space, and installed SDKs/runtimes/devices. It does not inspect tokens, signing identities, Apple ID details, or the process environment. It does not install components, boot devices, download models, or change system settings.

An exit status of 2 means the host is not macOS. An exit status of 1 means at least one tool query failed; the script continues collecting the other results. An exit status of 0 means the queries succeeded, **not** that the app built, a simulator booted, or a usable runtime was proven present. Inspect the runtime/device lists for actual availability before closing Phase 1.

If the Mac has no local checkout yet:

```bash
git clone https://github.com/tranpaul707/FAL-xcode-version.git
cd FAL-xcode-version
bash scripts/check-xcode-environment.sh
```

For an existing clean `main` checkout, use `git pull --ff-only` before running the script. Local work or a pull conflict should be resolved without resetting or overwriting it.

## Signing and accounts

- The first target is an iOS Simulator build/run. This normally does not require a paid Apple Developer membership or device provisioning. The scaffold's helper disables signing, and its corrected simulator build is now reported successful. Test execution and app launch remain Phase 2 checks.
- Physical-device runs later require a signing team/account, an enabled device-development setup as applicable to that iOS version, and provisioning appropriate to the installation method. A personal team may suffice for local development; do not assume paid distribution membership is required for the simulator MVP.
- No account credentials or certificates are needed at this checkpoint.

## Follow-on checkpoint: Phase 2

The host inventory checkpoint is complete. Follow the current commands and
remaining app-validation steps in [Phase 2](PHASE2-XCODE-SCAFFOLD.md), which records
the user's simulator build/test-command successes and any still-missing evidence.
The cloud task cannot execute Xcode on the user's Mac. Phase 3 remains paused
until the Phase 2 checkpoint is reviewed.

## Sources and verification limits

Fetched and inspected tagged upstream files:

- [MLX 0.32.3: running on iOS Simulator](https://github.com/ml-explore/mlx-swift/blob/0.32.3/Source/MLX/Documentation.docc/troubleshooting.md#running-on-ios-simulator)
- [MLX 0.32.3 package manifest](https://github.com/ml-explore/mlx-swift/blob/0.32.3/Package.swift)
- [MLX LM 3.32.3 package manifest](https://github.com/ml-explore/mlx-swift-lm/blob/3.32.3/Package.swift)

Official Apple references for the user to check on the Mac:

- [Xcode support and macOS/SDK compatibility](https://developer.apple.com/support/xcode/)
- [Downloading and installing additional Xcode components](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components)
- [Developer membership comparison](https://developer.apple.com/support/compare-memberships/)

Apple's pages returned a proxy `403 Forbidden` from this environment. Their live compatibility tables and instructions were not retrieved here, and no exact current Xcode/macOS pairing is claimed as verified.
