# Food-Additive-Lens
The repository for iOS application Food Additive Lens on App Store

The repository for research paper titled 'Food Additive Lens: An on-device AI application for real-time science-based consumer education on food additives using retrieval-augmented generation'

## Xcode development

The **Phase 2 Xcode scaffold is complete**, based on the user-supplied Mac results,
including simulator build and test-command success on the iPhone 18 Pro
destination with Xcode 27.1. The supplied UI-runner log
confirms **1 UI test passed, 0 failures**. A separate persistence-test log confirms
**2 tests passed, 0 failures**. After fixing context-specific insertion, the
Mac rerun again passed both tests with no entity-lookup diagnostics in the
supplied log.
The separate **FoodAdditiveLens-MLX unsigned generic iOS build also succeeded**,
as reported by the user after running the diagnostic helper. This confirms the
Metal preflight and compilation passed; signing, execution, and inference remain
unverified for the MLX target. The user also confirms running **FoodAdditiveLens**
and seeing **My Mac** as a destination. The user verified **Example**, **Reset**,
and opening/closing **History**. **Canvas now renders**, as confirmed by the user
after adding an explicit type to the diagnostic tuple array. Genuine inference
still requires the missing model resources. Phase 3 now supplies knowledge data,
20 authentic logged food samples, and sourced CFR mappings. All six Phase 3 Mac tests
passed. Phase 4 now connects direct ingredient lookup; its expanded Mac checks
passed in the user-reported full test command after the input-handling fix.
The user confirmed Example and entry selection. Manual photo/browser validation
remains pending; [synthetic photo fixtures and import steps](Tests/Fixtures/README.md)
are available for the simulator.
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
ingredient editor, 20 recovered food samples (with a built-in example fallback),
photo OCR, direct ingredient lookup, sourced CFR links, and saved history.
Choose **Identify & Analyze Additives** to match the loaded knowledge base even
without AI models. Results identify direct-only matching; classification and
generated explanations require the missing models. See the
[Phase 4 workflow and Mac checkpoint](docs/PHASE4-SIMULATOR-MVP.md).

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
diagnostics are absent from the supplied log. Those are Phase 2 results. Phase 3
resource/parity/CFR and updated sample tests subsequently passed: **5 unit
tests and 1 UI test**, zero failures. Phase 4 adds lookup, resource-failure, Vision,
and history UI coverage: expect **8 unit tests and 3 UI tests** in the next run.
The user reports the full Phase 4 test command passed after the input-handling fix.
The user confirmed Example and entry selection. Manual photo/browser validation
remains pending; [synthetic photo fixtures and import steps](Tests/Fixtures/README.md)
are available for the simulator.

The shared **FoodAdditiveLens-MLX** scheme builds the same UI with the original MLX
implementation for supported physical hardware. On an Apple silicon Mac, try the
compatible **My Mac (Designed for iPhone/iPad)** destination if Xcode offers it;
otherwise use a supported iPhone. This is an iOS app on Mac, not a Catalyst/native
macOS rewrite. The user reports that **My Mac** appears as a destination. MLX
device/Mac execution, signing, and inference remain unverified.
This scheme cannot use iOS Simulator. It requires the missing original model
resources before AI analysis can work. The two app targets have different
bundle IDs, so their installed apps and history stores are separate.

## Phase 3 resources

`App/Resources/` now contains 3,971 supplied additive records with their original
hand-crafted embeddings and 20 food inputs recovered from the uploaded validation
notebook. Both app targets bundle them. Unknown FDC IDs/sub-brands stay blank;
source notebook references are recorded separately. The newly uploaded FDA
`FoodSubstances.csv` supplies 2,171 substance-to-CFR mappings (3,907 reference
cells); its normalized runtime CSV is also bundled. The source identifies an
inventory update of February 13, 2025 and download of June 19, 2025. Classifier
and Llama artifacts remain missing.

Generate or verify from a checkout with Python 3.9+ and no extra packages:

```bash
python3 scripts/generate_knowledge_resources.py
python3 scripts/generate_knowledge_resources.py --check
python3 -m unittest discover -s scripts -p 'test_knowledge_resources.py' -v
```

[Phase 3 details](docs/PHASE3-RESOURCE-RESTORATION.md) include provenance, optional
professor artifact requests, limitations, and the Mac checkpoint. After pulling,
run the simulator helper's `test` action above, then check **Random Sample** and
entry IDs 0–19. The expected console counts are 3,971 additive records and 20 food
records, plus CFR data for 2,171 substances. The classifier missing message
remains expected; knowledge/sample/CFR missing messages should disappear.
Phase 4 is authorized and implemented; its [Mac checkpoint](docs/PHASE4-SIMULATOR-MVP.md)
remains pending. Pause before Phase 5.

See [Phase 2 details and validation checkpoint](docs/PHASE2-XCODE-SCAFFOLD.md),
[resource requirements](App/Resources/README.md), and the phased [TODO](TODO.md).
The research notebooks and evaluator workbooks are not app runtime dependencies.
