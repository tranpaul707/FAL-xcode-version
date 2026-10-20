# Phase 1 — Xcode host and simulator baseline

Status: **awaiting user-side Mac checks.** Inspection performed October 20, 2026. The user confirmed access to an Apple silicon Mac; macOS, Xcode, RAM, free disk space, and installed runtimes are not yet known. The user subsequently authorized Phase 2 scaffold preparation while this report remains pending; see [Phase 2](PHASE2-XCODE-SCAFFOLD.md).

## Verified in this task

| Check | Result |
| --- | --- |
| Attached cloud host | Debian GNU/Linux 13, x86_64 |
| Apple development tools | `xcodebuild`, `xcrun`, and `swift` not found |
| App build / Simulator launch | Not run; requires macOS/Xcode and the Phase 2 project |
| App project's current state | No Xcode project, app entry point, package resolution, or test targets |
| Mac access | Apple silicon Mac confirmed by the user; not connected to this task |
| MLX simulator support | MLX Swift 0.32.3 documentation explicitly says iOS Simulator is unsupported because it does not provide the required modern Metal GPU family |

Installing Linux Swift does not provide Xcode, Apple's iOS SDKs, CoreSimulator, or the UIKit/Vision/Core Data runtime needed by this app. No attempt was made to install those tools or large models on this cloud host.

## Proposed baseline, pending the Mac report

- **Development host:** the user's Apple silicon Mac with full Xcode supported by its installed macOS. Command Line Tools alone are insufficient. The Mac's actual versions determine the Xcode/package compatibility decision.
- **App target:** native iPhone application; provisional minimum iOS 17 because of the source's Observation/preview usage and inspected MLX package platform declarations. Finalize after resolving compatible tagged dependencies and building in Phase 2.
- **Simulator scope:** original UI, manual/sample input when data is available, Vision photo OCR, genuine knowledge lookup, and Core Data history. Core ML category prediction is a separate capability to validate after its artifacts are recovered. The original MLX LLM features remain unavailable on simulator; do not load their backend or substitute fabricated results.
- **Full AI validation:** supported physical iPhone or compatible Apple silicon iOS-on-Mac execution with the genuine model bundle and adequate memory. The original source's device-name whitelist is not a hardware certification. Exact device/inference checks belong to the model phase; owning a physical phone is not a prerequisite for the first simulator MVP. Direct-Mac execution was added to the proposed validation route after discussion with the user; it remains untested.
- **Resource budget:** collect actual RAM/free space before selecting package versions and downloading models. Allow space for Xcode, SDK/runtime downloads, build caches, and model files. No numeric memory/disk minimum or successful inference claim has been established from this repository.

The inspected tags are requirement evidence, **not selected app dependencies**:

| Tagged source | Declared requirements / finding |
| --- | --- |
| `mlx-swift` 0.32.3 | Swift tools 6.3 with its declared experimental feature; macOS 14 / iOS 17 platform minimums; documented lack of simulator inference support |
| `mlx-swift-lm` 3.32.3 | Swift tools 6.2; macOS 14 / iOS 17 platform minimums; requires MLX `>=0.32.3, <0.33.0`, making the combined toolchain requirement at least MLX's Swift 6.3 requirement |

Do not select these tags just because they exist. The supplied 2025 source may need an older compatible tagged pair to match the user's Xcode and original APIs. A package's macOS deployment minimum does not mean the Xcode/compiler that builds it runs on that macOS version. Verify the actual compiler, APIs, and Metal build before committing dependency resolution. No Xcode release number is inferred solely from a Swift tools version.

## Initial simulator matrix

Choose device types actually offered by the user's Xcode. Record runtime versions and simulator UDIDs after the Mac report; all execution is pending.

| Destination | Purpose | Runtime |
| --- | --- | --- |
| Standard-size available iPhone | Main launch and MVP acceptance flow | Current installed stable compatible iOS runtime |
| Smallest available supported iPhone | Ingredient entry, scrolling, sheets, and results on a narrow screen | Same runtime |
| Large-screen available iPhone / Pro Max | Results, history, and photo-picker layout | Same runtime |
| One available iPhone on the oldest testable supported runtime | Deployment-boundary coverage | iOS 17 if installable in the chosen Xcode; otherwise record the oldest offered runtime and retain an explicit minimum-OS test gap |

Reuse a destination when it satisfies multiple rows. Add other compatible iPhone simulator devices by destination selection, without application-code changes. Do not raise the app's deployment minimum merely to hide an unavailable old simulator runtime, or imply that every historical simulator is installable in a current Xcode.

## Action required on the user's Mac

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

- The first target is an iOS Simulator build/run. This normally does not require a paid Apple Developer membership or device provisioning. The actual unsigned app build remains a Phase 2 check because no project exists yet.
- Physical-device runs later require a signing team/account, an enabled device-development setup as applicable to that iOS version, and provisioning appropriate to the installation method. A personal team may suffice for local development; do not assume paid distribution membership is required for the simulator MVP.
- No account credentials or certificates are needed at this checkpoint.

## Checkpoint before Phase 2

The original checkpoint requested the user's Mac report before Phase 2. The user subsequently authorized independent scaffold preparation, so use that report to record the actual Xcode/Swift/SDK/runtime versions, device UDIDs, resources, and setup errors before validating the Phase 2 build. No simulator boot, Mac package resolution, or model download has executed in this task. Phase 2's implementation and remaining build checkpoint are recorded separately.

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
