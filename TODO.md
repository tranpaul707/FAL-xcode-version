# Xcode MVP plan — Food Additive Lens

## Goal and boundaries

Turn the supplied Food Additive Lens code by Yihang Feng into a runnable native iOS Xcode project. Preserve the original workflow: ingredient entry/sample selection, camera/photo OCR, food-category prediction and selection, additive identification, knowledge retrieval, contextual explanations, CFR links, and local history. Reuse the supplied implementation and data before considering replacements.

Deliver in two steps:

1. **Runnable simulator MVP:** launch the app, enter ingredients or import a photo, retrieve real additive names and technical effects from the supplied FDA-derived data, and save/reopen/delete local history. Keep unavailable model-dependent features visibly unavailable until restored.
2. **Original-feature parity:** restore the original classifier, on-device LLM identification/explanations, authentic food samples, and CFR resources, then validate their behavior on supported destinations. The first MVP alone does not establish parity with the original application.

Do not add accounts, a backend, cloud inference, barcode scanning, health/safety scores, dietary recommendations, new model architectures, or unrelated UI redesign. Research retraining and paper-wide evaluations are not prerequisites for the first app launch. Preserve the Apache license, Yihang Feng's source credit, and existing acknowledgments; check model/data terms separately.

Phases 1 and 2 are complete based on the supplied Mac inventory, app/test results,
MLX compile, and working Canvas. Phase 3 now restores 3,971 knowledge records and
20 authentic food samples from the initial uploads, with reproducible generation,
provenance, and Python checks. The user-supplied October 22 Mac run passed all
5 unit tests and 1 UI test, including Swift parity and bundled CFR mappings.
A subsequent FDA CSV upload supplies authentic CFR data, now normalized and
bundled. Original classifier/Llama artifacts remain unavailable; no inference
has run. The cloud task is Linux, so Apple-platform validation is performed by
the user. The user clarified that the initial uploads are all the source files
available and can ask the professors about missing artifacts.

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

**Status: complete based on the user-supplied Mac results.** The simulator app builds and runs; Example/Reset/History work; the UI test passed (1 executed, 0 failures); both persistence tests passed after the entity-lookup fix (2 executed, 0 failures, with no entity-ambiguity diagnostics in the supplied rerun). Canvas now renders after the diagnostic tuple-array type annotation. The separate unsigned generic iOS MLX build succeeded and `My Mac` is offered as a destination. MLX execution/signing and inference remain work for later phases. See [Phase 2 implementation and checkpoint](docs/PHASE2-XCODE-SCAFFOLD.md). The user reviewed the checkpoint and authorized Phase 3.

- [x] Add a native SwiftUI iOS application project, `FoodAdditiveLens.xcodeproj`, with a shared `FoodAdditiveLens` scheme, app target, unit-test target, and UI-test target. The additional `FoodAdditiveLens-MLX` scheme uses the same app source for supported hardware. The existing checkout is retained.
- [x] Add the `@main` app entry and inject the Core Data managed-object context into `ContentView` and history. Implement the missing persistence controller with a persistent store and an in-memory preview/test store.
- [x] Add the Core Data `Item` entity with the attributes listed above, matching the existing save/fetch/delete code and choosing manual managed-object code generation.
- [x] Include the supplied Swift source exactly once in each app target. Make only build/integration fixes initially; the existing model prompts and retrieval/classification logic are retained.
- [x] Resolve the corrected locked package configuration for the simulator build: the user reports `BUILD SUCCEEDED` after the requested locked build command. The source correction uses `mlx-swift-examples` 2.25.4 with MLX 0.25.4 and Transformers 0.1.21. This validates acceptance of the graph on that build path, not compilation or execution of the excluded MLX products, nor a fresh-Mac restoration.
- [x] Separate MLX imports, linked products, and initialization from the simulator target with a conditional unavailable backend and a distinct device/iOS-on-Mac inference target. The simulator and separate unsigned generic iOS MLX builds now pass by user report; no simulator inference is claimed.
- [x] Configure bundle identifiers, iOS 17/iPhone settings, generated Info.plist, camera/photo-library usage descriptions, named colors, and iOS-on-Mac capability. The user reports a `My Mac` destination; MLX signing and execution remain untested, and no personal signing team is committed.
- [x] Build the non-MLX simulator app on the user's Mac; `BUILD SUCCEEDED` was reported after correcting the dependency source. The simulator app's SwiftUI/Core Data source now has a real build result.
- [x] Run the simulator test command: the user reports `TEST SUCCEEDED`. This records the runner outcome without inventing counts or per-test results.
- [x] Launch the app shell: the user confirms being able to run `FoodAdditiveLens`.
- [x] Verify Example/Reset/History behavior: the user confirms all instructed checks worked (example ingredient text, cleared editor after Reset, and Analysis History opening/Back).
- [x] Confirm UI smoke-test execution: the supplied `FoodAdditiveLensUITests.xctest` log reports `testLaunchExampleResetAndHistoryWithoutModels` passed, 1 test executed, 0 failures.
- [x] Confirm persistence-test execution: the supplied `FoodAdditiveLensTests.xctest` log reports both named tests passed, 2 executed, 0 failures. This and the UI result establish three passing tests across separate supplied runs, not a single combined run.
- [x] Address the observed Core Data ambiguity in source: add `Item.insert(into:)`, which resolves the entity from the supplied context, and use it in both app save paths and persistence tests. Extend the existing round-trip test to verify entity/context ownership and isolation across two simultaneous stores.
- [x] Verify the insertion fix on the Mac: the supplied rerun reports both `PersistenceTests` passed, 2 executed, 0 failures (0.063 seconds), with no duplicate-entity / `+[Item entity]` diagnostics in the provided log.
- [x] Address the reported Canvas compiler error at `trainingLikeExamples` by declaring its type as `[(String, String)]`. The preview-generated `__designTimeString` calls now have an explicit expected element type.
- [x] Verify Canvas on the Mac after the tuple-array annotation: the user confirms the preview now works. Its resource-loader messages still report the expected missing data/models.
- [x] Verify the Metal compiler is available for the MLX build. The diagnostic helper reached its success footer, which requires the `xcrun --sdk iphoneos metal --version` preflight to pass; the earlier missing-tool blocker is resolved on this build path. No standalone installer output was supplied.
- [x] Run `scripts/diagnose-mlx-build.sh` and collect the result: the user reports its unsigned generic iOS build success footer.
- [x] Compile `FoodAdditiveLens-MLX` with the iPhoneOS SDK, locked packages, and signing disabled. A generic iOS build requires neither a connected iPhone nor model weights. This does not establish signing/install or inference.
- [x] Check Mac destination availability: in response to the requested MLX-scheme check, the user reports `My Mac` appears. This records availability only; MLX execution/signing/inference remain untested.

**Exit:** Xcode opens the shared scheme, resolves packages, and builds/launches an app shell on a selected simulator without model-resource crashes.

## Phase 3 — Restore usable data from the supplied materials

**Status:** resource restoration and Mac automated checkpoint complete; Phase 4
awaits user authorization. See [Phase 3 results and professor artifact list](docs/PHASE3-RESOURCE-RESTORATION.md).
The Mac run confirms all restored resources load and the representative CFR
mapping/URL tests pass. Browser navigation remains unverified. Pause before Phase 4.

- [x] Extract the original 384-dimensional hand-crafted algorithm into `scripts/generate_knowledge_resources.py`, using only the Python standard library and checkout-relative defaults.
- [x] Generate `App/Resources/food_additive_embeddings.json`: 3,971 unique supplied records with the original loader schema. Every vector exactly matches the inspected notebook reference function.
- [x] Validate schema, uniqueness, all finite values, normalization, and deterministic regeneration. Preserve source text, feature layout, weights, patterns, and match threshold `0.244`.
- [x] Check the demonstrated non-ASCII mismatch: Python uses `ord()`, while Swift used `asciiValue ?? 0`. Align Swift scalar values/counts and character-sine precision; add seven notebook-reference parity fixtures. Actual Swift parity execution is part of the Mac checkpoint below.
- [x] Investigate the raw food LFS object: the original repository contains the same pointer, and retrieval is blocked. Recover authentic samples instead from captured original input fields in the supplied validation notebook; the full training dataset is not required for the first MVP.
- [x] Generate a valid seven-column `branded_food_short_sample.csv` with 20 notebook-derived foods, quoted commas, and empty unrecorded FDC/sub-brand fields. Record source entry IDs separately, preserve actual fields, and keep runtime row IDs at 0–19. Fix random selection to retain the chosen row index when FDC IDs are blank/duplicated.
- [x] Restore CFR data from the subsequently uploaded `FoodSubstances.csv`: preserve the source bytes/dated provenance, normalize its 19 Reg add columns into `FoodSubstancesCFR.csv`, and validate every original reference cell. Runtime header remains on line 9; mappings cover 2,171 substances and 3,907 reference cells. No spreadsheet formulas are evaluated.
- [x] Correct generated eCFR section URLs to resolve the actual hierarchy rather than assuming every reference is subpart C. Add an actual-loader/representative-mapping/URL XCTest; browser execution remains unverified.
- [x] Add knowledge JSON, sample CSV, and normalized CFR CSV individually to both app bundle roots. Add the parity fixture only to unit tests; keep provenance, notebooks, workbooks, and full datasets outside app resources.
- [x] Record source revision, provenance, checksums, commands, and future model retrieval/storage in `docs/resources/manifest.json`. The source CSV and embedding notebook match the original author's inspected repository. Keep large downloads/model weights in ignored locations.
- [x] User-supplied Mac run on October 22, 2026: 5 unit tests (2 persistence, 2 knowledge/resource, 1 CFR) and 1 UI smoke test passed with zero failures. Actual Swift query parity and app-bundle resource decoding passed after the main-actor test fix in `5601255`.
- [x] Confirmed in the supplied Mac logs: 3,971 knowledge records, 20 food records, and CFR mappings for 2,171 substances loaded. UI automation passed Random Sample/product card, Reset, and History. The missing classifier message remains expected; analysis remains gated until Phase 4.
- [ ] Include manual entry-ID selection (0–19) and browser navigation in Phase 4 functional validation; these interactions were not exercised by the Phase 3 automated run.

**Exit for first MVP:** real knowledge resources load from the app bundle. Authentic
samples and sourced CFR data are restored in the implementation. The Mac
automated checkpoint passed; obtain user authorization before Phase 4. Remaining professor requests are
exact classifier/tokenizer and Llama artifacts for Phase 5, with source/version
and reuse terms; a complete original sample CSV is optional.

## Phase 4 — Make the first simulator MVP functional

**Status:** user authorized Phase 4; implementation ready for the Mac checkpoint.
See [implementation and validation steps](docs/PHASE4-SIMULATOR-MVP.md). The user reports the
unit suite passed. The later UI rerun passed lookup/history and unmatched-input
checks; only sample/reset/history still failed. Its focused visibility correction
and manual photo/browser checks remain pending. Pause before Phase 5.

- [x] Decouple direct ingredient matching/knowledge retrieval from LLM readiness. Reuse the existing parser, aliases, color/flavor mappings, and technical-effect lookup. Make capability/readiness states reflect which operations actually work.
- [x] Replace the hardware-name gate with destination/backend capability checks. Avoid eager unsupported MLX initialization and keep input, OCR, knowledge lookup, and history usable when inference is unavailable.
- [ ] Verify manual paste/edit, the built-in ingredient example, reset, authentic sample/entry selection when available, additive results, and empty/no-match input. Preserve the original feature sequence and UI intent.
- [ ] Exercise the existing photo-library path with a real ingredient-label image and Vision OCR on simulator. Preserve the camera-unavailable fallback; handle picker cancellation and permission denial. Validate actual camera capture later on an iPhone.
- [ ] Verify lookup with supplied records such as `CALCIUM PROPIONATE` and `ASCORBIC ACID`, showing their actual stored technical effects. Handle missing/malformed JSON and zero embedding dimensions without forced-cast/modulo crashes or indefinite loading.
- [ ] Verify save, history expansion, delete, and persistence after app termination/relaunch. Report store/save errors correctly; retain original history fields/stage semantics.
- [x] Show genuine feature availability: no classifier predictions without a classifier, no generated explanations without the LLM, and no CFR citations without source data. Distinguish an unavailable analysis from a successful analysis finding no additives. Do not substitute canned AI output as proof of functionality.

**MVP acceptance:** clean install → enter or OCR real ingredients → retrieve real additive knowledge → save → terminate/relaunch → reopen/delete history, on at least one documented iPhone simulator. This is useful working functionality, with any remaining original-feature gaps recorded explicitly. Implementation now supports this flow; Mac execution is still required for acceptance.

## Phase 5 — Restore the original model-dependent features

- [ ] Recover the original `FoodClassifier.mlpackage` and its matching vocabulary/class labels. Prefer existing exports; only reproduce the notebook training/export if those artifacts cannot be recovered and the required source data/resources are available. Record any reproduction's limits rather than claiming identical predictions.
- [ ] Let Xcode compile the classifier into `.mlmodelc` and load that compiled resource; explicitly compile raw model resources only if the chosen loading path requires it. Verify model input names, int32 shapes `[1, 256]` for `input_ids`/`attention_mask`, and `logits` order against `class_labels`.
- [ ] Check Swift tokenization, special tokens, padding/truncation, vocabulary IDs, and preprocessing against the original Python tokenizer/export using the same inputs. Verify top-three predictions, confidence display, user selection, and the existing none-of-the-above path.
- [ ] Identify and obtain the intended MLX-compatible Llama 3.2 3B Instruct 4-bit export, complete config/tokenizer/weights, exact revision, checksums, and applicable license. Check source access before requesting any missing credential; never store credentials in the repo.
- [ ] Preserve the `Llama-3.2-3B-Instruct-4bit/` directory structure during bundling or document a minimal explicit resource-path adjustment. Verify all required files and Metal resources before starting inference; provide actionable missing-resource/load errors.
- [ ] Restore the original direct-match plus LLM additive identification, retrieval, and streamed contextual explanation flow. Preserve prompts, matching behavior, category context, and generation settings initially. Check UI responsiveness, error recovery, and repeated use within device memory limits.
- [ ] Run genuine inference on a supported physical iPhone or compatible Apple silicon iOS-on-Mac destination and record actual outcomes. The direct-Mac route was agreed with the user and the Phase 2 MLX scheme prepares that path, but it is not runtime-verified. The Phase 1 MLX documentation excludes simulator inference, so keep the simulator MVP's MLX features unavailable. Revisit only if upstream documentation and a real compatibility check establish support for the chosen backend; do not introduce a remote inference service to bridge the gap.
- [ ] Verify restored authentic sample browsing and CFR links in the original full analysis flow. Confirm generated links correspond to real source citations; browser access to eCFR is distinct from offline analysis.

**Parity acceptance:** authentic samples/input/photo → real category prediction and selection → direct plus LLM additive identification → knowledge/CFR → genuine generated explanations → persisted history. Record which steps pass on simulator versus physical device. Missing original model artifacts remain parity blockers; restored CFR mapping/link behavior still requires runtime validation.

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
