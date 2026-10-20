# Xcode MVP plan — Food Additive Lens

## Goal and boundaries

Turn the supplied Food Additive Lens code by Yihang Feng into a runnable native iOS Xcode project. Preserve the original workflow: ingredient entry/sample selection, camera/photo OCR, food-category prediction and selection, additive identification, knowledge retrieval, contextual explanations, CFR links, and local history. Reuse the supplied implementation and data before considering replacements.

Deliver in two steps:

1. **Runnable simulator MVP:** launch the app, enter ingredients or import a photo, retrieve real additive names and technical effects from the supplied FDA-derived data, and save/reopen/delete local history. Keep unavailable model-dependent features visibly unavailable until restored.
2. **Original-feature parity:** restore the original classifier, on-device LLM identification/explanations, authentic food samples, and CFR resources, then validate their behavior on supported destinations. The first MVP alone does not establish parity with the original application.

Do not add accounts, a backend, cloud inference, barcode scanning, health/safety scores, dietary recommendations, new model architectures, or unrelated UI redesign. Research retraining and paper-wide evaluations are not prerequisites for the first app launch. Preserve the Apache license, Yihang Feng's source credit, and existing acknowledgments; check model/data terms separately.

The Phase 2 Xcode scaffold is prepared. The first user-side Mac build failed during package loading, before compilation; its dependency source has been corrected and a retry is pending. No successful app build, test suite, or app launch is verified. The cloud task remains on Linux.

**Execution checkpoints:** work one phase at a time. Report results and any action needed from the user at each phase boundary, and pause before starting the next phase. For intermediate work that requires the user's machine, configuration, access, or a decision, ask for that prerequisite and pause the dependent work while finishing independent checks.

## Initial repository findings (before Phase 2)

- The app is a single 4,450-line file, `code of Food Additive Lens.swift`. The README describes the app and research paper but supplies no build instructions.
- No `.xcodeproj`/workspace, shared scheme, `@main` app entry, asset catalog, Core Data model, persistence controller, package manifest/resolution, or test target is present.
- `Item` and `PersistenceController` are referenced but not supplied. `Item` needs `timestamp` (Date) and `ingredientText`, `stage`, `identifiedAdditives`, `analysisResult`, `knowledgeData`, and `explanations` (String).
- Imports include SwiftUI, UIKit, Vision, Core ML, NaturalLanguage, Accelerate, Core Data, and the third-party MLX/MLXRandom/MLXLLM/MLXLMCommon products. Package versions are not recorded.
- `canAnalyze` currently requires the LLM to be loaded, and `identifyAdditives()` checks the device before performing direct knowledge lookup. Missing MLX assets therefore block otherwise usable functionality (source around lines 1373–1450).
- MLX initializes eagerly. `UIDevice.supportsMLX()` uses an iPhone/Mac identifier whitelist; simulator `arm64`/`x86_64` identifiers fail that check (around lines 2213 and 4138). Removing the check alone would not establish inference support.
- The current cloud host is **Linux x86_64**, with no `xcodebuild`, `xcrun`, or Swift executable found. Xcode and Apple's iOS Simulator require a macOS host. Linux can support source/documentation and data preparation, but cannot validate an iOS app build or simulator launch.

### Resource inventory

| Resource expected by the Swift app | What is available / required action |
| --- | --- |
| `food_additive_embeddings.json` | Missing. Generate from the supplied `FoodSubstances_cleaned_v2.csv` using the supplied hand-crafted embedding notebook's existing 384-dimensional algorithm. The CSV contains 3,971 actual substance rows. |
| `branded_food_short_sample.csv` | Missing. Requires at least seven ordered columns: FDC ID, brand owner, brand name, sub-brand, ingredients, food category, description. Recover authentic food records and create a small valid sample. |
| `branded_food_short.csv` | The committed file is a 134-byte **Git LFS pointer**, not a dataset. It references an object of 111,633,644 bytes with SHA-256 `37a768281698a656f52771e7d8775271d62d6cc6bb5c2017fda973ab28da1ecd`. The object was not included in the upload; access at the current remote is unverified. Renaming the pointer will not supply sample data. |
| `Llama-3.2-3B-Instruct-4bit/` | Missing, including weights, configuration, and tokenizer. The directory name does not establish the exact upstream export/revision. Recover the intended MLX-compatible bundle and its provenance/license. |
| `FoodClassifier.mlpackage` and classifier `tokenizer_config.json` | Missing. The classifier notebook describes their export, not a supplied runtime artifact. Recover the original paired model/vocabulary/ordered class labels before considering reproduction. |
| `FoodSubstancesCFR.csv` | Missing. Loader expects an FDA-style CSV with its header on physical row 9, `Substance`, and `Reg add…` columns. The cleaned substances CSV has no CFR columns and cannot replace it. |

Reference source locations: sample loader near line 189; Llama loader near 2197–2258; embedding loader near 2772; classifier loader near 3243; CFR loader near 4206. Research notebooks and evaluator spreadsheets belong outside the app's runtime target.

## Phase 1 — Establish the Mac/Xcode and simulator baseline

**Status:** Mac host baseline recorded from the user's inventory: Apple silicon MacBook Air, macOS 26.6.2, Xcode 27.1, Swift 6.4, 16 GiB RAM, about 240 GiB free, iOS 27.1 SDK, and an installed iOS 27.0 runtime. See [Phase 1 results](docs/PHASE1-XCODE-BASELINE.md). This closes the inventory checkpoint, not the app build/runtime checks; minimum-iOS-17 coverage remains a documented gap.

- [x] Record the user's Apple silicon Mac, working full-Xcode tool queries, installed iOS runtime, RAM, and free storage. Confirm app/package compatibility and real model memory behavior in their later build/inference checks; no large model download is needed now.
- [x] Record Xcode 27.1 / Swift 6.4, the scaffold's iOS 17 deployment target, iOS 27.1 device/Simulator SDKs, and the installed iOS 27.0 runtime. Final minimum-OS compatibility still needs build/runtime validation.
- [x] Enumerate available simulator devices/runtimes from the supplied command output. Record the booted iPhone 18 Pro UDID as the first destination; no additional runtime installation is required for the first attempt.
- [x] Record an initial matrix using iPhone 18 Pro, iPhone 17e, and iPhone 18 Pro Max on iOS 27.0 with their real UDIDs. Layout tests remain unrun, and no iOS 17 runtime was reported; retain that coverage gap. Additional compatible iPhone simulators should be selectable without editing application code.
- [x] Separate simulator availability from MLX inference support. MLX Swift 0.32.3 explicitly documents iOS Simulator inference as unsupported because the required Metal GPU family is unavailable. The baseline therefore excludes MLX initialization/inference on simulators, with full inference reserved for a supported physical device. Package pins, actual hardware, and real-device inference remain unverified; see the Phase 1 sources.
- [x] Document simulator versus physical-device signing requirements and configure the simulator helper without signing. The actual unsigned simulator build remains a required Phase 2 check; no personal signing/account setup is requested for this attempt.

**Exit:** a documented Mac toolchain and available simulator destinations; explicit limitations for the current Linux environment and inference hardware.

## Phase 2 — Create the minimal Xcode application

**Status:** scaffold and platform separation implemented; first Mac build failed during package loading because the split LM release omitted declared target directories. The source is corrected to the original full upstream 2.25.4 tag; retry pending on the booted iPhone 18 Pro. See [Phase 2 implementation and checkpoint](docs/PHASE2-XCODE-SCAFFOLD.md). Checked items below mean source/project artifacts are implemented, not that an Xcode build or runtime test has passed. Pause for Mac results before Phase 3.

- [x] Add a native SwiftUI iOS application project, `FoodAdditiveLens.xcodeproj`, with a shared `FoodAdditiveLens` scheme, app target, unit-test target, and UI-test target. The additional `FoodAdditiveLens-MLX` scheme uses the same app source for supported hardware. The existing checkout is retained.
- [x] Add the `@main` app entry and inject the Core Data managed-object context into `ContentView` and history. Implement the missing persistence controller with a persistent store and an in-memory preview/test store.
- [x] Add the Core Data `Item` entity with the attributes listed above, matching the existing save/fetch/delete code and choosing manual managed-object code generation.
- [x] Include the supplied Swift source exactly once in each app target. Make only build/integration fixes initially; the existing model prompts and retrieval/classification logic are retained.
- [ ] Validate the selected exact MLX 0.25.4 / MLX libraries from `mlx-swift-examples` 2.25.4 / Transformers 0.1.21 requirements and complete candidate package lock with Xcode's resolver on the Mac. The original split `mlx-swift-lm` 2.25.4 checkout had invalid target paths; the corrected full upstream tag has all seven target directories and identical used library source. The revised eight-package lock still needs a successful Mac resolution. Do not track upstream `main` or upgrade versions to hide a build error.
- [x] Separate MLX imports, linked products, and initialization from the simulator target with a conditional unavailable backend and a distinct device/iOS-on-Mac inference target. The actual simulator compile remains part of the pending Mac check; no simulator inference is claimed.
- [x] Configure bundle identifiers, iOS 17/iPhone settings, generated Info.plist, camera/photo-library usage descriptions, named colors, and iOS-on-Mac capability. Device/Mac signing and destination availability remain untested; no personal signing team is committed.
- [ ] Build on the Mac and resolve actual package/API, actor-isolation, SwiftUI, and Core Data compile failures. Verify SwiftUI previews use their preview store. No additional compiler defects are established until this build runs.

**Exit:** Xcode opens the shared scheme, resolves packages, and builds/launches an app shell on a selected simulator without model-resource crashes.

## Phase 3 — Restore usable data from the supplied materials

- [ ] Extract a small repeatable local resource generator from `hand-crafted food additive embedding.ipynb`; remove Colab/Drive path assumptions from the generator, while keeping the original notebook as research material.
- [ ] Generate `food_additive_embeddings.json` from `FoodSubstances_cleaned_v2.csv` with the existing algorithm and schema: `embedding_dimension`, `total_records`, and records containing `substance`, `other_names`, `technical_effect`, `searchable_text`, and `embedding`.
- [ ] Validate nonempty records, 384 finite values per vector, declared/actual counts, and normalization. Check Python/Swift query-feature agreement, including the existing Python `ord` versus Swift `asciiValue` behavior for non-ASCII input. Preserve the original matching threshold and mappings unless a demonstrated integration defect requires a documented fix.
- [ ] Recover the real branded-food object from its original accessible LFS/source location, or recover the intended authentic sample directly. Verify size/hash for the referenced LFS object. If unavailable, retain built-in/manual ingredient input for the first MVP and mark database sample/entry lookup unavailable.
- [ ] Create a small authentic `branded_food_short_sample.csv` with the exact seven-column contract and valid ingredient records. Test quoted commas, empty optional fields, row/index selection, and the loader's filters. Do not bundle the entire 111 MB research dataset just to launch the app.
- [ ] Recover the distinct original CFR dataset and verify its encoding/header/column contract. Preserve actual substance-to-regulation mappings; do not invent codes or derive citations from the cleaned CSV. Mark links unavailable until authentic data is present.
- [ ] Add validated resources with correct target membership and bundle paths. Keep classifier tokenizer files separate from Llama tokenizer files; keep notebooks, XLSX workbooks, and training datasets outside Copy Bundle Resources.
- [ ] Record provenance, dataset versions, generation commands, licenses, and checksums. Define a reproducible retrieval/storage approach for large model artifacts rather than committing weights as ordinary Git blobs or assuming LFS pointers are hydrated.

**Exit for first MVP:** real knowledge resources load from the app bundle. Authentic database samples and CFR data have either been restored and checked or are explicit outstanding feature blockers; they do not block manual input and knowledge lookup.

## Phase 4 — Make the first simulator MVP functional

- [ ] Decouple direct ingredient matching/knowledge retrieval from LLM readiness. Reuse the existing parser, aliases, color/flavor mappings, and technical-effect lookup. Make capability/readiness states reflect which operations actually work.
- [ ] Replace the hardware-name gate with destination/backend capability checks. Avoid eager unsupported MLX initialization and keep input, OCR, knowledge lookup, and history usable when inference is unavailable.
- [ ] Verify manual paste/edit, the built-in ingredient example, reset, authentic sample/entry selection when available, additive results, and empty/no-match input. Preserve the original feature sequence and UI intent.
- [ ] Exercise the existing photo-library path with a real ingredient-label image and Vision OCR on simulator. Preserve the camera-unavailable fallback; handle picker cancellation and permission denial. Validate actual camera capture later on an iPhone.
- [ ] Verify lookup with supplied records such as `CALCIUM PROPIONATE` and `ASCORBIC ACID`, showing their actual stored technical effects. Handle missing/malformed JSON and zero embedding dimensions without forced-cast/modulo crashes or indefinite loading.
- [ ] Verify save, history expansion, delete, and persistence after app termination/relaunch. Report store/save errors correctly; retain original history fields/stage semantics.
- [ ] Show genuine feature availability: no classifier predictions without a classifier, no generated explanations without the LLM, and no CFR citations without source data. Distinguish an unavailable analysis from a successful analysis finding no additives. Do not substitute canned AI output as proof of functionality.

**MVP acceptance:** clean install → enter or OCR real ingredients → retrieve real additive knowledge → save → terminate/relaunch → reopen/delete history, on at least one documented iPhone simulator. This is useful working functionality, with any remaining original-feature gaps recorded explicitly.

## Phase 5 — Restore the original model-dependent features

- [ ] Recover the original `FoodClassifier.mlpackage` and its matching vocabulary/class labels. Prefer existing exports; only reproduce the notebook training/export if those artifacts cannot be recovered and the required source data/resources are available. Record any reproduction's limits rather than claiming identical predictions.
- [ ] Let Xcode compile the classifier into `.mlmodelc` and load that compiled resource; explicitly compile raw model resources only if the chosen loading path requires it. Verify model input names, int32 shapes `[1, 256]` for `input_ids`/`attention_mask`, and `logits` order against `class_labels`.
- [ ] Check Swift tokenization, special tokens, padding/truncation, vocabulary IDs, and preprocessing against the original Python tokenizer/export using the same inputs. Verify top-three predictions, confidence display, user selection, and the existing none-of-the-above path.
- [ ] Identify and obtain the intended MLX-compatible Llama 3.2 3B Instruct 4-bit export, complete config/tokenizer/weights, exact revision, checksums, and applicable license. Check source access before requesting any missing credential; never store credentials in the repo.
- [ ] Preserve the `Llama-3.2-3B-Instruct-4bit/` directory structure during bundling or document a minimal explicit resource-path adjustment. Verify all required files and Metal resources before starting inference; provide actionable missing-resource/load errors.
- [ ] Restore the original direct-match plus LLM additive identification, retrieval, and streamed contextual explanation flow. Preserve prompts, matching behavior, category context, and generation settings initially. Check UI responsiveness, error recovery, and repeated use within device memory limits.
- [ ] Run genuine inference on a supported physical iPhone or compatible Apple silicon iOS-on-Mac destination and record actual outcomes. The direct-Mac route was agreed with the user and the Phase 2 MLX scheme prepares that path, but it is not runtime-verified. The Phase 1 MLX documentation excludes simulator inference, so keep the simulator MVP's MLX features unavailable. Revisit only if upstream documentation and a real compatibility check establish support for the chosen backend; do not introduce a remote inference service to bridge the gap.
- [ ] Restore and verify authentic sample browsing and CFR links still blocked after Phase 3. Confirm generated links correspond to real source citations; browser access to eCFR is distinct from offline analysis.

**Parity acceptance:** authentic samples/input/photo → real category prediction and selection → direct plus LLM additive identification → knowledge/CFR → genuine generated explanations → persisted history. Record which steps pass on simulator versus physical device. Missing original model/CFR artifacts remain parity blockers.

## Phase 6 — Verify, document, and hand off

- [ ] Add focused tests for CSV/resource contracts, representative alias/direct lookups, embedding consistency, malformed inputs, classifier preprocessing once available, and in-memory/persistent history behavior. Use genuine expected outcomes; do not count skipped inference tests as passes.
- [ ] Add a simulator UI smoke test for the MVP acceptance flow, including empty input and an unavailable-model state. Run it on the agreed device/runtime matrix, selecting a destination by UDID rather than hardcoding one simulator name.
- [ ] Validate real-device camera capture, model loading/inference, memory behavior, and the original complete analysis flow. Confirm the bundled analysis path works offline; external CFR browser links require connectivity.
- [ ] Add concise README instructions for Mac prerequisites, resource preparation/retrieval, opening the project, package resolution, simulator selection/photo import, running tests, and physical-device signing. Include an honest per-feature/per-destination verification table and unresolved asset requirements.
- [ ] Document and execute the actual CLI commands after the project exists: `xcodebuild -list`, `xcodebuild -showdestinations`, build/test with the shared scheme and `-destination 'platform=iOS Simulator,id=<UDID>'`, and simulator boot/install/launch steps if needed. These are future checks, not commands verified on this Linux host.
- [ ] Verify a clean checkout with documented artifact preparation on the Mac. Keep generated build outputs, local signing settings, secrets, large downloaded caches, and user-specific Xcode state out of Git; retain project metadata, shared schemes, package resolution, and necessary resource manifests.
- [ ] Review changes against the original feature list, distinguish the first MVP from full parity, and record exact builds/tests/destinations that passed, failed, or remain unrun before handoff.

**Done:** another developer can follow the README to run the tested MVP on an installed compatible simulator, with full original AI behavior verified on a supported destination or explicitly blocked by named missing artifacts/platform capabilities.

## External dependencies to resolve without blocking independent work

- A macOS/Xcode machine is required for all iOS builds, simulator runs, and Apple-framework runtime validation.
- Original classifier/tokenizer exports and the complete intended Llama bundle are required for original AI parity; training notebooks alone are insufficient.
- Authentic branded-food records are required for database sampling/entry lookup, and the separate CFR dataset is required for regulation links.
- The current repository is sufficient to plan the project scaffold and derive real additive knowledge resources. These tasks can proceed while the external artifacts and Mac validation are arranged.

Dependency references for choosing compatible pinned releases: [MLX Swift](https://github.com/ml-explore/mlx-swift) and [MLX Swift LM](https://github.com/ml-explore/mlx-swift-lm). Their current default branches are not a compatibility guarantee for this supplied source.
