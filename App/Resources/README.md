# Runtime resources

Phase 3 restores two files to the root of **both app bundles**:

- `food_additive_embeddings.json`: 3,971 supplied substance records with their
  original 384-dimensional hand-crafted vectors, about 17 MB.
- `branded_food_short_sample.csv`: 20 original food inputs recovered from captured
  output in the supplied validation notebook. Unrecorded FDC IDs and sub-brands
  are blank. Runtime sample indices are 0–19; notebook entry IDs are not FDC IDs.

Regenerate or verify with Python 3.9+ (no third-party packages):

```bash
python3 scripts/generate_knowledge_resources.py
python3 scripts/generate_knowledge_resources.py --check
python3 -m unittest discover -s scripts -p 'test_knowledge_resources.py' -v
```

The generator also writes a test-only parity fixture and per-sample provenance.
See [Phase 3 details](../../docs/PHASE3-RESOURCE-RESTORATION.md) and
[checksums/source records](../../docs/resources/manifest.json).

Still unavailable:

- `FoodSubstancesCFR.csv`: absent from the supplied materials and inspected
  original repository snapshot; the cleaned CSV has no regulation columns.
- `FoodClassifier.mlpackage` and its matching classifier `tokenizer_config.json`.
- The complete intended `Llama-3.2-3B-Instruct-4bit/` model bundle.

Original classifier/Llama restoration belongs to Phase 5. Record model source,
revision, terms, required files, and checksums before retrieving/bundling. Keep
raw downloads in ignored `artifacts/`; the future Llama folder is also ignored
to prevent ordinary Git commits of weights. Keep the two tokenizers separate.

Use individual root-level file references for CSV/JSON/model resources, and a
folder reference preserving the Llama bundle's directory structure. Exclude this
README, provenance documents, notebooks, spreadsheets, full training data, and
unresolved LFS pointers from Copy Bundle Resources.
