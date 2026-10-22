# Original FDA export

`FoodSubstances.csv` is preserved byte-for-byte from the additional user upload.
Its own preamble identifies the FDA Substances Added to Food inventory:

- Source: `http://www.hfpappexternal.fda.gov/scripts/fdcc/?set=FoodSubstances`
- Inventory last updated: February 13, 2025.
- Downloaded: June 19, 2025.
- Source encoding: Windows-1252; 3,971 rows with a header on physical line 5.
- SHA-256: `9abd2721ba83eb274e6566d4760e2c96b8c5acdabf50a59fc8dc8b688b9a3130`.

The original FDA preamble/notice remains in the file. This is the uploaded dated
snapshot, not a new network retrieval. The generator derives the runtime
`App/Resources/FoodSubstancesCFR.csv` from its actual Reg add columns, preserving
all reference values while removing literal spreadsheet text wrappers. It never
evaluates spreadsheet formulas. The raw source is excluded from app resources.

See [Phase 3 details](../../docs/PHASE3-RESOURCE-RESTORATION.md) and the
[provenance manifest](../../docs/resources/manifest.json).
