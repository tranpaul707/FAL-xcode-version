# Phase 2 — Xcode app scaffold

Status: **corrected simulator build reported successful; test and launch checkpoint pending.**
The Mac report identifies Xcode 27.1, Swift 6.4, 16 GiB RAM, and an installed iOS
27.0 runtime. The first destination is the booted iPhone 18 Pro. The report does
not initially contain a project build or launch result. The first build failed
at package loading; after the source correction, the user reported
`BUILD SUCCEEDED` for the requested simulator build. Details are below.
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
  These are authored tests, **not passed test results**.
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
products and inference target still require their own build/runtime validation.
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

## Mac validation checkpoint: tests and launch

The inventory and successful build result are received. Next, run the tests on
the same iPhone 18 Pro destination:

```bash
git pull --ff-only
bash scripts/build-simulator.sh 89CA5AC4-8662-4AB0-8D53-0F1B7A355A30 test
```

This should execute two persistence tests and one UI smoke test. Share the test
summary with passed/failed counts and any first error; a build-only or zero-test
result is not a test pass. The helper uses the locked versions and disables
simulator signing. The successful build used the reported iOS 27.0 destination
with the iOS 27.1 SDK; no additional runtime download is needed for this test.

For targeted project/package/destination diagnostics if needed:

```bash
xcodebuild -list -project FoodAdditiveLens.xcodeproj
xcodebuild -resolvePackageDependencies -project FoodAdditiveLens.xcodeproj -scheme FoodAdditiveLens-MLX -onlyUsePackageVersionsFromResolvedFile
xcodebuild -project FoodAdditiveLens.xcodeproj -scheme FoodAdditiveLens -showdestinations
```

After reviewing test results, open the project, choose `FoodAdditiveLens` and
that simulator, and use
Product → Run. Confirm the app opens, the ingredient editor and Example/Reset
controls work, history opens, and unavailable resources are reported without an
endless loading banner. This is an app-shell check; additive analysis, category
predictions, CFR lookup, and generated explanations remain blocked by missing
resources and are not claimed to work.

If Xcode asks to change package versions, stop and share the diagnostic rather
than updating to current MLX major versions. For a build failure, share the first
actual error and its surrounding output; do not reset the checkout or delete work.
After the simulator build, separately check whether Xcode offers the direct-Mac
destination for `FoodAdditiveLens-MLX`. That target may require a locally selected
signing team. No signing identity or personal team is stored in this repository.

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

The initial user-side Xcode build failed during dependency loading. The user
subsequently reported `BUILD SUCCEEDED` after the correction. The Linux task
cannot execute Xcode itself. XCTest execution, UI test outcomes, manual launch,
direct-Mac/MLX target compilation, previews, and real inference remain unverified.
Phase 2 remains open for its test/launch and separate-target checks.

## Remaining resource work

Phase 3 generates real knowledge embeddings from the supplied data and handles
authentic sample/CFR recovery. Phase 4 connects the full non-MLX lookup MVP.
Phase 5 restores the original classifier/Llama artifacts and validates genuine
inference, including the direct-Mac path discussed with the user. See `TODO.md`.
