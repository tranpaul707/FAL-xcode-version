# Runtime resources (restored in later phases)

No model weights or generated knowledge data are supplied in this directory yet.
The Phase 2 app shell must launch with unavailable features reported accurately.

Add restored resources to **both app targets** in Xcode in Phases 3/5:

- `food_additive_embeddings.json`
- `branded_food_short_sample.csv`
- `FoodSubstancesCFR.csv`
- `FoodClassifier.mlpackage` (compiled by Xcode to `FoodClassifier.mlmodelc`)
- classifier `tokenizer_config.json`
- `Llama-3.2-3B-Instruct-4bit/`, preserving its complete directory structure

The existing loaders look in the app bundle root. Use individual file references
for the JSON/CSV/model resources and a folder reference for the Llama directory;
do not copy an enclosing `Resources/` folder into the bundle and change the lookup
paths accidentally. Keep the Llama tokenizer inside its model directory.

Do not add this README, research notebooks, evaluator workbooks, the full branded
food training dataset, or an unresolved Git LFS pointer to app target resources.
Record provenance and the chosen retrieval/storage approach before adding large
artifacts; do not commit model weights as ordinary Git blobs.
