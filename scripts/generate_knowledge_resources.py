#!/usr/bin/env python3
"""Reproduce the supplied hand-crafted embedding notebook using Python's stdlib."""

import argparse
import csv
import hashlib
import io
import json
import math
from pathlib import Path
import re
import tempfile

ROOT = Path(__file__).resolve().parent.parent
DIMENSION = 384
COLUMNS = ("Substance", "Other Names", "Used for (Technical Effect)")
CHEMICAL_PATTERNS = ("acid", "ate", "ine", "ium", "ide", "oxy", "meth", "eth", "prop")
FOOD_COLUMNS = ("fdc_id", "brand_owner", "brand_name", "subbrand_name", "ingredients",
                "branded_food_category", "description")
LOGGED_FOOD = re.compile(
    r"📋 ENTRY INFORMATION:\n[ \t]+Entry ID: (?P<entry>[^\n]+)\n"
    r"[ \t]+Product: (?P<product>[^\n]+)\n[ \t]+Brand: (?P<owner>[^\n]+)\n"
    r"[ \t]+Category: (?P<category>[^\n]+)\n[ \t]+Brand Name: (?P<brand>[^\n]+)\n"
    r"\n🧾 ORIGINAL INGREDIENT LIST:\n[ \t]+(?P<ingredients>[^\n]+)\n"
)


def generate_query_embedding(text):
    """Keep the notebook's feature positions, weights, Unicode ord(), and norm."""
    embedding = [0.0] * DIMENSION
    words = [word.strip() for word in text.lower().split() if word.strip()]
    if not words:
        return embedding
    for word_index, word in enumerate(words):
        word_weight = 1.0 / len(words)
        position_weight = 1.0 - (word_index / len(words))
        for char_index, char in enumerate(word):
            index = (char_index + word_index * 10) % DIMENSION
            embedding[index] += math.sin(ord(char) * 0.1) * word_weight * position_weight
        length_index = (len(word) * 7) % DIMENSION
        embedding[length_index] += math.tanh(len(word) / 10.0) * word_weight
        for pattern_index, pattern in enumerate(CHEMICAL_PATTERNS):
            if pattern in word:
                index = (pattern_index * 23 + word_index * 5) % DIMENSION
                embedding[index] += 0.5 * word_weight
    magnitude = math.sqrt(sum(value * value for value in embedding))
    if magnitude > 0:
        embedding = [value / magnitude for value in embedding]
    return embedding


def read_records(source):
    records = []
    seen = set()
    with source.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames != list(COLUMNS):
            raise ValueError(f"Expected CSV columns {COLUMNS}; got {reader.fieldnames}")
        for line_number, row in enumerate(reader, 2):
            if None in row or any(value is None for value in row.values()):
                raise ValueError(f"Malformed CSV record ending near line {line_number}")
            substance, other_names, technical_effect = (row[key].strip() for key in COLUMNS)
            if not substance or substance == "nan" or substance.lower() in seen:
                continue
            seen.add(substance.lower())
            searchable_text = f"{substance} {other_names} {technical_effect}".strip()
            records.append({
                "substance": substance,
                "other_names": other_names,
                "technical_effect": technical_effect,
                "searchable_text": searchable_text,
                "embedding": generate_query_embedding(searchable_text),
            })
    return records


def validate_dataset(dataset):
    if dataset.get("model_name") != "hand-crafted" or dataset.get("embedding_dimension") != DIMENSION:
        raise ValueError("Expected the original hand-crafted, 384-dimensional format")
    records = dataset.get("data")
    if not isinstance(records, list) or not records or dataset.get("total_records") != len(records):
        raise ValueError("Declared and actual nonempty record counts must agree")
    seen = set()
    for index, record in enumerate(records):
        if not all(isinstance(record.get(key), str) for key in
                   ("substance", "other_names", "technical_effect", "searchable_text")):
            raise ValueError(f"Record {index} has missing/non-string fields")
        substance = record["substance"]
        if not substance.strip() or substance.lower() in seen:
            raise ValueError(f"Record {index} has an empty/duplicate substance")
        seen.add(substance.lower())
        expected_text = f"{substance} {record['other_names']} {record['technical_effect']}".strip()
        if record["searchable_text"] != expected_text:
            raise ValueError(f"Record {index} has inconsistent searchable text")
        vector = record.get("embedding")
        if not isinstance(vector, list) or len(vector) != DIMENSION:
            raise ValueError(f"Record {index} must have {DIMENSION} values")
        if not all(type(value) in (int, float) and math.isfinite(value) for value in vector):
            raise ValueError(f"Record {index} contains a non-finite/non-numeric value")
        if not math.isclose(sum(value * value for value in vector), 1.0, abs_tol=1e-10):
            raise ValueError(f"Record {index} is not normalized")


def parity_fixtures():
    # Includes the C1 character present in the supplied disodium-guanylate alias,
    # a combining mark, and a non-BMP scalar to catch Character/asciiValue drift.
    texts = ("", "CALCIUM PROPIONATE", "ASCORBIC ACID", "  sodium\n citrate\t",
             "sodium 5\u0092-guanylate (2:1)", "e\u0301 acid", "\U0001f9ea acid")
    return {"embedding_dimension": DIMENSION, "cases": [
        {"text": text, "embedding": generate_query_embedding(text)} for text in texts
    ]}


def recover_food_samples(notebook_path, limit=20):
    """Recover only logged input fields, never the notebook's generated answers."""
    notebook = json.loads(notebook_path.read_text(encoding="utf-8"))
    rows, references, seen = [], [], set()
    for cell_index, cell in enumerate(notebook["cells"]):
        for output_index, output in enumerate(cell.get("outputs", [])):
            if output.get("output_type") != "stream":
                continue
            for match in LOGGED_FOOD.finditer("".join(output.get("text", []))):
                record = {key: value.strip() for key, value in match.groupdict().items()}
                if any(not value or value == "N/A" for value in record.values()):
                    continue
                if not record["entry"].isdigit() or record["entry"] in seen:
                    continue
                if len(record["ingredients"]) <= 50 or "," not in record["ingredients"]:
                    continue
                # Current Swift CSV reader works on physical lines and removes
                # quote delimiters, so select compatible original records.
                if any('"' in value or any(c in value for c in "\r\v\f\x85\u2028\u2029")
                       for value in record.values()):
                    continue
                seen.add(record["entry"])
                rows.append(["", record["owner"], record["brand"], "", record["ingredients"],
                             record["category"], record["product"]])
                references.append({"sample_row_index": len(rows) - 1, "source_entry_id": record["entry"],
                                   "cell_index": cell_index, "output_index": output_index,
                                   "product": record["product"]})
                if len(rows) == limit:
                    return rows, references
    raise ValueError(f"Expected {limit} eligible original logged samples; found {len(rows)}")


def sample_csv(rows):
    stream = io.StringIO(newline="")
    writer = csv.writer(stream, lineterminator="\n")
    writer.writerow(FOOD_COLUMNS)
    writer.writerows(rows)
    return stream.getvalue().encode("utf-8")


def cfr_resource(source):
    """Normalize actual FDA Reg add cells without evaluating spreadsheet syntax."""
    raw = source.read_bytes()
    text = raw.decode("cp1252")
    lines = text.splitlines()
    header_index = next((i for i, line in enumerate(lines)
                         if "Substance" in next(csv.reader([line]))), None)
    if header_index is None:
        raise ValueError("FDA source has no Substance header")
    reader = csv.DictReader(io.StringIO("\n".join(lines[header_index:])), strict=True)
    columns = [name for name in reader.fieldnames if name.startswith(("Reg add", "Regadd"))]
    if not columns:
        raise ValueError("FDA source has no Reg add columns")
    rows, seen = [], set()
    with_codes = references = 0
    for row in reader:
        if None in row or any(value is None for value in row.values()):
            raise ValueError("FDA source has inconsistent columns")
        substance = row["Substance"].strip()
        if not substance or substance.upper() in seen or any(c in substance for c in '\r\n"'):
            raise ValueError("FDA source has an empty/duplicate/incompatible substance")
        seen.add(substance.upper())
        codes = []
        for name in columns:
            value = row[name].strip()
            if not value:
                codes.append("")
                continue
            wrapper = re.fullmatch(r'=T\("([0-9]+\.[0-9]+)"\)', value)
            if wrapper:
                value = wrapper.group(1)
            if not re.fullmatch(r"[0-9]+\.[0-9]+", value):
                raise ValueError(f"Unexpected CFR reference for {substance}: {name}")
            codes.append(value)
        references += sum(bool(code) for code in codes)
        with_codes += any(codes)
        rows.append([substance] + codes)
    if not with_codes:
        raise ValueError("FDA source contains no Reg add references")
    # Retain source provenance/warning, then document the conversion. The original
    # app's CFR loader expects the header on physical line 9; no fake data rows.
    preamble = lines[:header_index] + [
        "Food Additive Lens normalized CFR resource.",
        f"Source SHA-256: {hashlib.sha256(raw).hexdigest()}",
        "Original Reg add values only; spreadsheet text wrappers removed.",
        "",
    ]
    if len(preamble) != 8:
        raise ValueError("Expected the original four-line FDA preamble")
    stream = io.StringIO(newline="")
    stream.write("\n".join(preamble) + "\n")
    writer = csv.writer(stream, lineterminator="\n")
    writer.writerow(["Substance"] + columns)
    writer.writerows(rows)
    summary = {"source_records": len(rows), "substances_with_references": with_codes,
               "reference_cells": references, "regulation_columns": columns,
               "source_header_line": header_index + 1, "runtime_header_line": 9}
    return stream.getvalue().encode("utf-8"), summary


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, allow_nan=False, separators=(",", ":")) + "\n").encode("utf-8")


def write_or_check(path, content, check):
    if check:
        if not path.is_file() or path.read_bytes() != content:
            raise ValueError(f"Generated resource is missing or stale: {path}")
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        # Atomic replacement avoids leaving a half-written bundled resource.
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            try:
                stream.write(content)
                stream.flush()
            except BaseException:
                temporary.unlink(missing_ok=True)
                raise
        try:
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)
    print(f"{'Verified' if check else 'Wrote'} {path.name}: {len(content):,} bytes, SHA-256 {hashlib.sha256(content).hexdigest()}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "FoodSubstances_cleaned_v2.csv")
    parser.add_argument("--output", type=Path, default=ROOT / "App/Resources/food_additive_embeddings.json")
    parser.add_argument("--fixtures-output", type=Path,
                        default=ROOT / "Tests/FoodAdditiveLensTests/Fixtures/embedding-parity.json")
    parser.add_argument("--sample-notebook", type=Path,
                        default=ROOT / "additive identification validation part 1.ipynb")
    parser.add_argument("--sample-output", type=Path, default=ROOT / "App/Resources/branded_food_short_sample.csv")
    parser.add_argument("--sample-provenance-output", type=Path,
                        default=ROOT / "docs/resources/sample-provenance.json")
    parser.add_argument("--cfr-source", type=Path, default=ROOT / "data/source/FoodSubstances.csv")
    parser.add_argument("--cfr-output", type=Path, default=ROOT / "App/Resources/FoodSubstancesCFR.csv")
    parser.add_argument("--check", action="store_true", help="Verify exact reproducibility without writing files")
    args = parser.parse_args()
    try:
        records = read_records(args.source)
        dataset = {"model_name": "hand-crafted", "embedding_dimension": DIMENSION,
                   "total_records": len(records), "data": records}
        validate_dataset(dataset)
        samples, references = recover_food_samples(args.sample_notebook)
        provenance = {
            "source_notebook": args.sample_notebook.name,
            "source_sha256": hashlib.sha256(args.sample_notebook.read_bytes()).hexdigest(),
            "selection": "first 20 distinct complete logged inputs in notebook output order",
            "missing_fields": ["fdc_id", "subbrand_name"],
            "id_note": "Source entry IDs are app row indices, not USDA FDC IDs. Runtime row indices use the 20-row sample.",
            "records": references,
        }
        cfr, cfr_summary = cfr_resource(args.cfr_source)
        write_or_check(args.output, encoded(dataset), args.check)
        write_or_check(args.fixtures_output, encoded(parity_fixtures()), args.check)
        write_or_check(args.sample_output, sample_csv(samples), args.check)
        write_or_check(args.sample_provenance_output, encoded(provenance), args.check)
        write_or_check(args.cfr_output, cfr, args.check)
    except (OSError, UnicodeError, ValueError, csv.Error) as error:
        parser.exit(1, f"Resource generation failed: {error}\n")
    print(f"Validated {len(records):,} unique records with {DIMENSION} finite, normalized values each.")
    print(f"Validated CFR references for {cfr_summary['substances_with_references']:,} substances "
          f"from {cfr_summary['reference_cells']:,} source reference cells.")


if __name__ == "__main__":
    main()
