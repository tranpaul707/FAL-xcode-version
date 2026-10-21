# Phase 2 — Xcode app scaffold

Status: **simulator build/test command, app launch, and unsigned generic iOS MLX build reported successful; My Mac destination reported available. Specific UI/preview checks and test counts remain pending.**
The Mac report identifies Xcode 27.1, Swift 6.4, 16 GiB RAM, and an installed iOS
27.0 runtime. The first destination is the booted iPhone 18 Pro. The report does
not initially contain a project build or launch result. The first build failed
at package loading; after the source correction, the user reported
`BUILD SUCCEEDED` for the requested simulator build and subsequently
`TEST SUCCEEDED` for the requested test command. Only those terminal result
lines were initially supplied; detailed test counts have not yet been confirmed.
The user subsequently confirmed running `FoodAdditiveLens` and seeing `My Mac`
as a destination in response to the MLX-scheme check. MLX execution is not
established by this.
Details are below.
This phase does not restore datasets/models or claim the full analysis MVP works.
Pause for the Mac validation checkpoint before Phase 3.

## What changed

- Added `FoodAdditiveLens.xcodeproj`, an iOS 17 app entry point, shared schemes,
  named color assets, camera/photo permission descriptions, and generated app
  metadata. Signing is automatic with no personal development team committed.
- Added the missing Core Data model and manual `Item` subclass, with all existing
  history attributes. Added a persistence controller for normal, preview/in-memory,
  and isolated test stores; storage initialization failure is reported at launch.
- Included the original Swift file once per app target. Preserved its prompts,
  parser, knowledge algorithm, threshold, classifier, and explanation workflow.
  Added conditional MLX compilation, explicit main-actor isolation for the main
  views, main-actor streaming callbacks, and model-actor-local response collection.
- Added an unavailable inference implementation for the normal app target. It
  returns no analysis or explanations and does not import/initialize MLX. Missing
  resources no longer leave the status banner saying it is loading forever.
- Used `ProcessInfo.isiOSAppOnMac` for direct-Mac detection. The original iPhone
  support heuristic otherwise remains pending the later real-hardware validation.
  The MLX path checks that its model directory exists before initializing the GPU.
- Added two Core Data tests (field round trip/delete and SQLite store reopening)
  and a UI smoke test for launch, built-in example, reset, and the history sheet.
  The user reports overall `TEST SUCCEEDED`; per-test execution counts and
  results have not yet been supplied.
- Added a simulator build/test helper and Git ignores for local Xcode/build state.

## Targets and schemes

| Shared scheme | App target / bundle ID | Intended destination | Inference |
| --- | --- | --- | --- |
| `FoodAdditiveLens` | `FoodAdditiveLens` / `com.tranpaul707.foodadditivelens` | Installed compatible iPhone simulators; also usable as the non-MLX shell on devices | MLX imports/backend excluded; original AI actions unavailable |
| `FoodAdditiveLens-MLX` | `FoodAdditiveLensMLX` / `com.tranpaul707.foodadditivelens.mlx` | Supported iPhone, or compatible Apple silicon iOS-on-Mac destination if Xcode offers it | Original MLX backend enabled with `FAL_ENABLE_MLX`; model files still missing |

The app targets share source, model, and assets. They are separate installed apps,
with separate history stores. There is no server, cloud model, fake inference,
or new native macOS app. The MLX target declares `iphoneos` only; its scheme is not
an iOS Simulator configuration. Both targets allow iOS-on-Mac execution in their
build settings; actual destination availability must be confirmed in Xcode.

## Dependency choices

The project uses exact root requirements reviewed against the supplied API usage:

| Package | Tag | Evidence |
| --- | --- | --- |
| `ml-explore/mlx-swift` | `0.25.4` | Declares Swift tools 5.10; exposes `GPU.set(cacheLimit:)` and required products |
| `ml-explore/mlx-swift-examples` | `2.25.4` | Supplies `MLXLLM`/`MLXLMCommon` with the existing directory-based `loadContainer(configuration:)`, model-context `perform`, and streamed `generate` API; permits MLX `>=0.25.4, <0.26.0` |
| `huggingface/swift-transformers` | `0.1.21` | Pins the tokenizer dependency within LM's permitted range, retaining the same-era API/toolchain |

Tag existence and upstream API/manifests were checked over verified HTTPS/Git.
Those initial checks did not establish successful SwiftPM resolution or app
compilation. The subsequent user-reported locked simulator build now establishes
a successful build for the non-MLX app target.
The reported Swift 6.4 compiler exceeds the inspected manifests' declared tools
5.10 floor. Compatibility of the older package sources with Xcode 27.1's compiler
and SDK is now demonstrated for the simulator shell, but the excluded MLX library
products and inference target now have a separate user-reported unsigned generic
iOS build success. Their runtime behavior remains unverified.
The app remains in Swift 5 language mode with targeted concurrency checking;
this is not a Swift 6 migration.

Only the MLX app target links MLX package products. Because package references
belong to the project, Xcode may still resolve/download package source when
opening or building the normal scheme; it should not compile/link MLX for that
scheme. No model weights are downloaded by the project or scripts.

`FoodAdditiveLens.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
contains a lock initially prepared from verified upstream tag commits rather
than generated by Xcode. The corrected locked build is now reported successful
on the user's Mac. It pins the three roots above and GzipSwift
6.0.1, Jinja 1.1.0, swift-argument-parser 1.4.0, swift-collections 1.1.4, and
swift-numerics 1.1.1. Their inspected manifests' normal dependency ranges admit
these versions; this avoids silently selecting newer transitive packages with
newer compiler requirements. Documentation-only dependencies are not included.
All eight package tags/commit IDs were read from their actual remotes.

### First Mac failure and correction

The user ran the simulator build on Xcode 27.1. Package checkout succeeded, but
SwiftPM stopped with `invalid custom path 'Libraries/StableDiffusion' for target
'StableDiffusion'`. No app compilation, test, or launch result was produced.

The original selection used the split `mlx-swift-lm` repository's 2.25.4 tag.
That tag's manifest still declares `StableDiffusion` and `MLXMNIST` targets whose
directories are absent from the split checkout. The initial manifest/API review
missed this invalid package layout.

The corrected source is the original full `mlx-swift-examples` repository's
2.25.4 tag, commit `8e41311a3c17e902441cfcaa46629244c9758afd`. Its manifest is
byte-identical to the split tag's, and all seven declared custom target paths
exist, including `Libraries/StableDiffusion` and `Libraries/MLXMNIST`. The used
`MLXLLM` and `MLXLMCommon` trees (26 and 20 files) are byte-identical between the
two checkouts. This changes the package source and locked commit while keeping
the library API/version and the other seven package selections unchanged.
The unused example targets are package metadata, not new app features.

The user's command display also joined `DerivedData` and the locked-version
switch. The prior helper preserved separate arguments in a controlled launcher
test, so that displayed formatting was not reproduced here. The helper now uses
an explicit Bash argument array and prints the intended output directory.
Argument boundaries and underlying exit-status propagation are checked with
stubbed tools, not presented as an actual Xcode build.

The simulator helper requests only the recorded versions. The reported build
success establishes that Xcode accepted the corrected graph on this Mac/build
path. It does not prove MLX products compiled, that the local lockfile was
unchanged, or that restoration on a fresh Mac was tested. Inspect any future
lockfile change or resolution diagnostic before changing package versions.

## Mac validation checkpoint: separate MLX target

### Resolved blocker: missing Apple Metal Toolchain

The MLX build reached `CompileMetalFile` for `steel_attention.metal`, then the
user supplied the underlying diagnostic:

```text
cannot execute tool 'metal' due to missing Metal Toolchain;
use: xcodebuild -downloadComponent MetalToolchain
```

This identifies an absent Xcode component, not a shader-source diagnostic.
On the user's Mac, install the component using the command suggested by Xcode,
then verify the compiler:

```bash
xcodebuild -downloadComponent MetalToolchain
xcrun --sdk iphoneos metal --version
```

The diagnostic helper initially confirmed the same missing-tool error and stopped
before building. After the installation guidance, the user reported:

```text
BUILD SUCCEEDED (unsigned generic iOS compile only; inference was not run).
```

This footer is emitted only after the iOS Metal compiler preflight, the locked
unsigned generic iOS MLX build, and log capture all succeed. The missing-compiler
blocker is therefore resolved for this build path. No standalone installation
transcript was supplied. No package pins or shader sources were changed to
resolve the missing tool. The result does not establish signing, installation,
direct-Mac execution, or real model inference.

### Reproduce the compile or diagnose a future failure

The inventory, successful simulator build, and successful test-command result
are received. Please include the existing test summary showing whether the two
persistence tests and one UI smoke test all executed, with their pass/fail/skip
counts. No repeated simulator test run is requested merely to obtain those lines.

The simulator app deliberately excludes MLX products and the real backend, so
its successful build/test does not compile that code. The separate MLX check uses
the installed iPhoneOS SDK. This is a compile-only check; a generic iOS
destination does not require a connected phone, signing team, or model weights.
The helper checks `xcrun --sdk iphoneos metal --version` first and stops if it
fails. Otherwise, it runs the locked, unsigned MLX build with one compiler job
to make diagnostics easier to follow and limit concurrent work:

```bash
git pull --ff-only
bash scripts/diagnose-mlx-build.sh
```

Share the final `=== MLX DIAGNOSTIC RESULT ===` section. It repeats the Metal
check and, on build failure, the first compiler/tool error with surrounding output.
Fresh logs are saved under ignored `DerivedData/diagnostics/`; the helper preserves
the build exit status through `tee`. It does not install components, delete caches,
or change dependencies. This target compiles the MLX dependencies and can take longer
than the simulator shell. It builds an unsigned iOS app, not a native macOS app,
and does not load a model or establish direct-Mac execution support.

For targeted project/package/destination diagnostics if needed:

```bash
xcodebuild -list -project FoodAdditiveLens.xcodeproj
xcodebuild -resolvePackageDependencies -project FoodAdditiveLens.xcodeproj -scheme FoodAdditiveLens-MLX -onlyUsePackageVersionsFromResolvedFile
xcodebuild -project FoodAdditiveLens.xcodeproj -scheme FoodAdditiveLens -showdestinations
```

For the app review, open the project, choose `FoodAdditiveLens` and
that simulator, and use
Product → Run. Confirm the app opens, the ingredient editor and Example/Reset
controls work, history opens, and unavailable resources are reported without an
endless loading banner. This is an app-shell check; additive analysis, category
predictions, CFR lookup, and generated explanations remain blocked by missing
resources and are not claimed to work.

If Xcode asks to change package versions, stop and share the diagnostic rather
than updating to current MLX major versions. For a build failure, share the first
actual error and its surrounding output; do not reset the checkout or delete work.
The user reports that `My Mac` appears as a destination in response to the
MLX-scheme check. Execution and signing remain untested; that target may require a locally selected signing team. No
signing identity or personal team is stored in this repository.

## Verification in the Linux task

- The OpenStep/PBX project was parsed with `pbxproj`/`openstep-parser`; schemes,
  Core Data XML/version selection, and asset JSON are checked as file formats.
- Swift syntax is inspected with the tree-sitter Swift grammar. This cannot type
  check Apple APIs, actor rules, package linking, SwiftUI previews, or a model.
- Shell helpers are syntax-checked and exercised for invalid arguments and the
  Linux rejection path. Mac-only actions are not represented as executed.
- Project references and target membership are checked independently of Xcode.

Results in this task: all project object/file references resolved; both app
targets include the original source once and share the intended resources;
the normal target links no MLX products; both scheme XML files, the Core Data
schema/version, and asset JSON parsed; all seven Swift files passed grammar
parsing; both original model-prompt function bodies are unchanged. The helper's
help, invalid-input, build-on-Linux, and test-on-Linux paths returned their
documented statuses. These are structural/negative-path checks, not app test
results or evidence of a successful Apple-platform compilation.

The MLX diagnostic helper passed shell syntax and controlled stub-tool checks
for missing Metal (no build started), successful and failed builds, first-error
context extraction, paths with spaces, unique logs, and preservation of build
and log-capture failure statuses. These Linux checks validate the helper's
control flow. The user subsequently reported the helper's success footer on the Mac.

The initial user-side Xcode build failed during dependency loading. The user
subsequently reported `BUILD SUCCEEDED` and `TEST SUCCEEDED` after the correction.
The user also reported the diagnostic helper's unsigned generic iOS MLX build
success footer after its initial missing-Metal preflight failure. The Linux task
cannot execute Xcode itself. The user also confirms running `FoodAdditiveLens`
and seeing a `My Mac` destination. Detailed test counts, specific UI checks,
preview review, MLX direct-Mac execution/signing, and real inference remain
unverified. Phase 2 remains open for its count/review checks.

## Remaining resource work

Phase 3 generates real knowledge embeddings from the supplied data and handles
authentic sample/CFR recovery. Phase 4 connects the full non-MLX lookup MVP.
Phase 5 restores the original classifier/Llama artifacts and validates genuine
inference, including the direct-Mac path discussed with the user. See `TODO.md`.
