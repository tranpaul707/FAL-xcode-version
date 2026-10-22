# Food-Additive-Lens
The repository for iOS application Food Additive Lens on App Store

The repository for research paper titled 'Food Additive Lens: An on-device AI application for real-time science-based consumer education on food additives using retrieval-augmented generation'

## Xcode development

The Phase 2 simulator scaffold has **user-reported build and test-command success**
on the iPhone 18 Pro destination with Xcode 27.1. The supplied UI-runner log
confirms **1 UI test passed, 0 failures**. A separate persistence-test log confirms
**2 tests passed, 0 failures**. After fixing context-specific insertion, the
Mac rerun again passed both tests with no entity-lookup diagnostics in the
supplied log.
The separate **FoodAdditiveLens-MLX unsigned generic iOS build also succeeded**,
as reported by the user after running the diagnostic helper. This confirms the
Metal preflight and compilation passed; signing, execution, and inference remain
unverified for the MLX target. The user also confirms running **FoodAdditiveLens**
and seeing **My Mac** as a destination. The user verified **Example**, **Reset**,
and opening/closing **History**. Canvas reported a type-inference timeout in a
diagnostic example array; an explicit tuple-array type is added and awaits a
Mac preview retry. Genuine inference still requires the missing model resources.
The original source credit and Apache license are retained.

The MLX target also needs Xcode's **Metal Toolchain** component. If its compiler
reports that this component is missing, install it on the Mac and verify it:

```bash
xcodebuild -downloadComponent MetalToolchain
xcrun --sdk iphoneos metal --version
```

To check Metal and build the MLX target, or diagnose a future failure, run:

```bash
git pull --ff-only
bash scripts/diagnose-mlx-build.sh
```

Share the final `=== MLX DIAGNOSTIC RESULT ===` section. The helper saves logs in
ignored `DerivedData/diagnostics/` and stops before building if Metal is unavailable.
It does not install components. The previously missing Metal compiler no longer
blocks the reported generic iOS build.

On an Apple silicon Mac with full Xcode and an installed iOS Simulator runtime:

```bash
bash scripts/check-xcode-environment.sh
open FoodAdditiveLens.xcodeproj
```

Select the shared **FoodAdditiveLens** scheme, choose an installed iPhone simulator,
and use Product → Run. This target excludes MLX and provides the original app shell,
ingredient editor, built-in example, photo selection, and history interface. Its
unavailable resources are reported explicitly. Analysis stays unavailable until
the knowledge/model resources are restored in the later phases.

To build or run the included tests from Terminal, choose an actual simulator UDID:

```bash
xcrun simctl list devices available
bash scripts/build-simulator.sh YOUR_SIMULATOR_UDID build
bash scripts/build-simulator.sh YOUR_SIMULATOR_UDID test
```

Replace `YOUR_SIMULATOR_UDID` with a UUID from the device list. The helper disables
signing only for the simulator and keeps output in ignored `DerivedData/`.
The user reported `TEST SUCCEEDED` and supplied the UI smoke-test result:
**1 test executed, 0 failures**. The separately supplied persistence-test log
confirms **2 executed, 0 failures**. The context-specific insertion fix was
verified by a Mac rerun: both persistence tests passed and the earlier entity-lookup
diagnostics are absent from the supplied log. No further test rerun is requested.

The shared **FoodAdditiveLens-MLX** scheme builds the same UI with the original MLX
implementation for supported physical hardware. On an Apple silicon Mac, try the
compatible **My Mac (Designed for iPhone/iPad)** destination if Xcode offers it;
otherwise use a supported iPhone. This is an iOS app on Mac, not a Catalyst/native
macOS rewrite. The user reports that **My Mac** appears as a destination. MLX
device/Mac execution, signing, and inference remain unverified.
This scheme cannot use iOS Simulator. It requires the missing original model and
knowledge resources before analysis can work. The two app targets have different
bundle IDs, so their installed apps and history stores are separate.

See [Phase 2 details and validation checkpoint](docs/PHASE2-XCODE-SCAFFOLD.md),
[resource requirements](App/Resources/README.md), and the phased [TODO](TODO.md).
The research notebooks and evaluator workbooks are not app runtime dependencies.
