# Phase 3 — Restore available runtime data

Status: **implementation and Linux checks complete; Mac build/resource/parity
validation pending.** The user clarified that the initial uploads are all the
original files available. The supplied data is sufficient for this checkpoint;
a later FDA CSV upload now supplies the original CFR mappings. Pause before Phase 4.

## Knowledge resource

`App/Resources/food_additive_embeddings.json` contains 3,971 unique substance
records from `FoodSubstances_cleaned_v2.csv`. Each keeps the supplied substance,
aliases, and technical effects and has a finite, normalized 384-dimensional
vector. The JSON is 17,396,664 bytes and uses the original loader schema:
`model_name`, `embedding_dimension`, `total_records`, and `data` containing
`substance`, `other_names`, `technical_effect`, `searchable_text`, and `embedding`.

`scripts/generate_knowledge_resources.py` extracts the supplied notebook's
hand-crafted algorithm into a standard-library Python 3.9+ command. It retains
feature positions, weights, normalization, case-insensitive first-record
deduplication, and source order. Compact JSON reduces bundle/Git size. No learned
embedding model or Colab/Drive setup is needed.

All 3,971 vectors matched the original notebook's pure `generate_query_embedding`
function exactly. Reference tests load only that inspected function, without
running notebook upload/Drive cells. Regeneration is byte-for-byte repeatable:

```bash
python3 scripts/generate_knowledge_resources.py
python3 scripts/generate_knowledge_resources.py --check
python3 -m unittest discover -s scripts -p 'test_knowledge_resources.py' -v
```

For example, `CALCIUM PROPIONATE` has the supplied technical effects
`ANTIMICROBIAL AGENT|ANTIOXIDANT`. `ASCORBIC ACID` includes the alias `VITAMIN C`
and its actual stored effects. No regulation references are inferred from them.

## Food samples recovered from existing uploads

The branded-food upload is a 134-byte LFS pointer to a 111,633,644-byte object.
The original repository contains the same pointer. Its LFS batch request returned
`Resource not accessible by integration`; media downloads returned proxy 403.

`additive identification validation part 1.ipynb` contains 108 complete logged
food inputs in its stored stream output. The generator recovers the first 20
distinct compatible inputs into `App/Resources/branded_food_short_sample.csv`
(14,232 bytes). It reads entry metadata and original ingredient text, excluding
classifier predictions, additive results, and generated explanations. These are
original logged examples; recovery does not verify a current USDA listing.

The seven fields follow the existing loader's order:

```text
fdc_id,brand_owner,brand_name,subbrand_name,ingredients,branded_food_category,description
```

Unrecorded FDC IDs and sub-brands are empty. Owner, brand, ingredients, category,
and description are preserved from the output. Source entry IDs such as `4792`
are original app row indices; they are retained in
`docs/resources/sample-provenance.json`, not placed in the FDC field. Runtime
entry selection uses the small sample's own indices 0–19.

The CSV retains quoted commas and empty optional fields. Recovery selects records
compatible with the current line-based Swift parser: required owner/category,
ingredient length over 50, comma-separated ingredients, and no multiline fields
or literal quote characters. The first 20 complete entries meet those conditions.

Random selection now retains the selected array index directly. Previously, it
searched by FDC ID afterward, selecting index 0 for every record with an empty
ID. The preference for ingredient lists longer than 100 characters is retained.
After loading, the button reads **Random Sample**; **Example** remains its fallback
when data is absent. The UI test now checks loaded sample text and its product
card, Reset, and History.

## Python/Swift feature agreement

One supplied alias contains U+0092. Python's notebook uses `ord()` for Unicode
code points; Swift previously substituted zero through `asciiValue ?? 0` and
used grapheme counts. Those produce different features for that actual alias.

Swift now iterates Unicode scalars, counts scalars for length features, and
evaluates character sine in double precision before Float storage/accumulation.
The feature layout, weights, chemical patterns, and threshold `0.244` are retained.
Source text, including the original C1 character, is preserved. An internal pure
static query function allows parity testing without service/model initialization.

The test-only `embedding-parity.json` covers seven queries: blank input, calcium
propionate, ascorbic acid, mixed whitespace, the actual alias character, a
combining mark, and a non-BMP scalar. XCTest permits a 0.000003 per-component
difference for Float precision. A Linux Float32 arithmetic model stays within
that tolerance (maximum observed error about 6.44e-8); actual Swift execution is
still pending on the Mac.

The parity XCTest uses an async `@MainActor` entry point because the query method
belongs to the main-actor-isolated knowledge manager. This matches the existing
persistence test pattern and avoids calling an actor-isolated static method from
a synchronous, nonisolated test. The reported Mac test build failed before test
execution; the corrected build still needs a Mac rerun.

## Restored CFR source and mappings

The later upload `FoodSubstances.csv` resolves the missing regulation source.
Its metadata identifies the FDA Substances Added to Food inventory, last updated
February 13, 2025 and downloaded June 19, 2025. The original Windows-1252 bytes
are preserved in `data/source/FoodSubstances.csv` (SHA-256 recorded in the manifest).
Its 3,971 substance keys exactly match the supplied cleaned knowledge dataset.

The source header is on physical line 5, with 19 `Reg add` columns. Its 3,907
nonempty reference cells use literal spreadsheet text wrappers such as
`=T("184.1221")`. The generator strips those wrappers by exact pattern matching,
never formula evaluation, and retains every substance/reference cell in order.
Other source columns (color, prohibited, administrative, labeling) are not added
to the lookup, preserving the original app's Reg add scope.

The normalized `App/Resources/FoodSubstancesCFR.csv` has 3,971 rows, with mappings
for 2,171 substances. It is 213,185 bytes. The original four-line preamble and
FDA notice are retained, followed by four conversion-metadata lines so the
runtime header remains on physical line 9 as the existing loader expects.
Runtime content is ASCII-compatible UTF-8; raw source encoding remains unchanged.
Examples preserved from the actual source:

| Substance | Reg add references |
| --- | --- |
| CALCIUM PROPIONATE | 179.45, 181.23, 184.1221 |
| ASCORBIC ACID | 172.280, 182.3013, 182.8013 |
| ACESULFAME POTASSIUM | 172.800 |

The URL builder now uses `https://www.ecfr.gov/current/title-21/section-CODE`.
The earlier hard-coded `subpart-C` path was incorrect for source references in
other subparts. The original general-category fallback is retained. The new
Mac XCTest invokes the actual bundled CFR loader, checks representative exact
mappings, and checks section URL construction. Representative HTTP requests returned proxy 403; browser navigation remains
unverified on this Linux host.

## Remaining resources and additional upload audit

The remaining professor requests are the exported `FoodClassifier.mlpackage`
with matching tokenizer/vocabulary/ordered labels, and the exact Llama 3.2 3B
Instruct 4-bit bundle or download source/revision. Original sample CSVs with FDC
IDs/sub-brands are optional improvements; 20 logged samples already support the
first MVP. Artifact versions and reuse terms should accompany model files.

The re-uploaded cleaned-v2 CSV, hand-crafted notebook, and classifier-0705
notebook match existing files. The earlier cleaned CSV retains presentation
markers. The alternative embedding notebook uses learned MiniLM vectors, which
are incompatible with the app's hand-crafted query features despite having the
same dimension; it does not replace the restored matched resource. The older
DeepSeek Python RAG prototype and technical-effect explanation table are research
references, not the missing trained classifier or on-device Llama export.
The demo video exceeds the 32 MiB transfer limit and was not inspected.

No model weights or raw branded-food training dataset are committed. Future raw
model downloads go in ignored `artifacts/`, and the Llama folder is ignored.
Select exact revisions and record file inventories/checksums before retrieval.
The large branded CSV upload also exceeds the transfer limit and remains
unverified here; the notebook-derived samples continue to supply the MVP data.

## Provenance and bundle membership

Yihang Feng's [original repository](https://github.com/yih-f/Food-Additive-Lens)
was inspected at `64b70c4798c230c6acaabec39261cbbe9510e5a4`. Its substances CSV and
embedding notebook match the uploads byte-for-byte. The repository's Apache-2.0
license and source credit are retained. The later FDA source provides its own
update/download dates as recorded above; this restoration preserves that snapshot.

`docs/resources/manifest.json` records input/output SHA-256 hashes, counts, source
revision, sample limitations, and missing artifacts. `sample-provenance.json`
records the cell/output/source-entry reference for every sample.

Both app targets copy the JSON, sample CSV, and normalized CFR CSV individually
into their bundle root. The full original FDA source stays outside app resources.
The parity fixture belongs only to unit tests. Provenance, notebooks,
spreadsheets, READMEs, and full datasets are excluded from Copy Bundle Resources.
Package pins and MLX versions are unchanged.

## Verification and Mac checkpoint

Linux checks passed: eleven Python tests (including all notebook-vector matches
and sample provenance, all 3,907 CFR reference cells, and bad formula/CSV rejection),
exact regeneration of five outputs, project reference
and resource membership validation, and grammar parsing of all eight Swift files.
These do not type-check Apple APIs or execute the app.

On the Mac:

```bash
git pull --ff-only
bash scripts/build-simulator.sh 89CA5AC4-8662-4AB0-8D53-0F1B7A355A30 test
```

Expected inventory: **5 unit tests** (2 persistence, 2 knowledge/resource, 1 CFR) and
**1 UI test** (`testLaunchSampleResetAndHistoryWithoutModels`). These six tests
have not yet been run on the Mac for this change. Share pass/fail/skip results
and any first actual compiler error.

Run `FoodAdditiveLens` and confirm these loader messages:

```text
✅ Native: Loaded 3971 additive records successfully
✅ Loaded 20 food records from CSV
✅ CFR: Loaded CFR data for 2171 substances
```

Check **Random Sample**, its product card, and loading an entry ID from 0–19.
Knowledge/sample/CFR missing-file errors should disappear. The classifier
missing message remains expected. Analysis/explanations are still gated by model
readiness; enabling direct simulator lookup belongs to Phase 4. Pause here before Phase 4.
