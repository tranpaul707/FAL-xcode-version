"""Resource-contract and notebook-reference checks; run with Python's unittest."""

import ast
import copy
import csv
import hashlib
import io
import json
import math
from pathlib import Path
import tempfile
import unittest

import generate_knowledge_resources as resources


class KnowledgeResourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = resources.ROOT / "FoodSubstances_cleaned_v2.csv"
        cls.dataset = json.loads((resources.ROOT / "App/Resources/food_additive_embeddings.json").read_text())
        notebook = json.loads((resources.ROOT / "hand-crafted food additive embedding.ipynb").read_text())
        # Load just the inspected, pure reference function, never Colab/file-upload
        # cells, imports, downloaded code, or other notebook side effects.
        cell_source = "\n".join("".join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code")
        functions = [node for node in ast.parse(cell_source).body
                     if isinstance(node, ast.FunctionDef) and node.name == "generate_query_embedding"]
        if len(functions) != 1:
            raise AssertionError("Expected one original reference function")
        namespace = {"math": math, "EMBEDDING_DIMENSION": resources.DIMENSION}
        exec(compile(ast.Module(body=functions, type_ignores=[]), "original-notebook-function", "exec"), namespace)
        cls.reference = staticmethod(namespace["generate_query_embedding"])

    def test_entire_resource_matches_source_and_original_notebook(self):
        resources.validate_dataset(self.dataset)
        with self.source.open(encoding="utf-8-sig", newline="") as stream:
            rows = list(csv.DictReader(stream))
        self.assertEqual(len(rows), 3971)
        self.assertEqual(len(self.dataset["data"]), len(rows))
        for source, generated in zip(rows, self.dataset["data"]):
            self.assertEqual(generated["substance"], source["Substance"].strip())
            self.assertEqual(generated["other_names"], source["Other Names"].strip())
            self.assertEqual(generated["technical_effect"], source["Used for (Technical Effect)"].strip())
            self.assertEqual(generated["embedding"], self.reference(generated["searchable_text"]), generated["substance"])

    def test_fixtures_match_original_including_unicode_and_blank_queries(self):
        fixtures = json.loads((resources.ROOT / "Tests/FoodAdditiveLensTests/Fixtures/embedding-parity.json").read_text())
        self.assertEqual(len(fixtures["cases"]), 7)
        for example in fixtures["cases"]:
            self.assertEqual(example["embedding"], self.reference(example["text"]))
        self.assertEqual(self.reference(" \n\t"), [0.0] * 384)
        # The old asciiValue ?? 0 fallback differed from the notebook for the
        # actual C1 character in the supplied alias, not just hypothetical inputs.
        alias = next(row["other_names"] for row in self.dataset["data"] if "\u0092" in row["other_names"])
        expected = self.reference(alias)
        old_fallback = self.reference(alias.replace("\u0092", "\0"))
        self.assertGreater(max(abs(a - b) for a, b in zip(expected, old_fallback)), 0.0001)

    def test_csv_quotes_empty_fields_and_first_duplicate_are_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "quoted.csv"
            with source.open("w", encoding="utf-8", newline="") as stream:
                writer = csv.writer(stream)
                writer.writerow(resources.COLUMNS)
                writer.writerow([" CALCIUM PROPIONATE ", 'Alias, with "quotes"', ""])
                writer.writerow(["calcium propionate", "duplicate", "discarded"])
                writer.writerow(["ASCORBIC ACID", "", "ANTIOXIDANT"])
                writer.writerow(["", "", ""])
            records = resources.read_records(source)
            self.assertEqual(len(records), 2)
            self.assertEqual(records[0]["other_names"], 'Alias, with "quotes"')
            self.assertEqual(records[0]["technical_effect"], "")
            self.assertEqual(records[1]["other_names"], "")

    def test_bad_csv_and_lfs_pointers_are_rejected(self):
        cases = (
            "version https://git-lfs.github.com/spec/v1\noid sha256:abc\nsize 100\n",
            "Substance,Other Names\nACID,Alias\n",
            "Substance,Other Names,Used for (Technical Effect)\nACID,Alias,Effect,Unexpected\n",
        )
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "invalid.csv"
            for text in cases:
                with self.subTest(text=text):
                    source.write_text(text)
                    with self.assertRaises(ValueError):
                        resources.read_records(source)

    def test_invalid_record_counts_vectors_and_fields_are_rejected(self):
        base = {"model_name": "hand-crafted", "embedding_dimension": 384,
                "total_records": 1, "data": [self.dataset["data"][0]]}
        cases = []
        for field, value in (("total_records", 9), ("embedding_dimension", 0), ("data", [])):
            dataset = copy.deepcopy(base)
            dataset[field] = value
            cases.append(dataset)
        for invalid in ([0.0] * 384, [1.0] * 383, [math.nan] * 384, [math.inf] * 384, [True] * 384):
            dataset = copy.deepcopy(base)
            dataset["data"][0]["embedding"] = invalid
            cases.append(dataset)
        dataset = copy.deepcopy(base)
        dataset["data"][0]["other_names"] = None
        cases.append(dataset)
        dataset = copy.deepcopy(base)
        dataset["data"] *= 2
        dataset["total_records"] = 2
        cases.append(dataset)
        for index, dataset in enumerate(cases):
            with self.subTest(case=index), self.assertRaises(ValueError):
                resources.validate_dataset(dataset)

    def test_check_mode_does_not_write_and_detects_stale_files(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "resource.json"
            path.write_bytes(b"original\n")
            resources.write_or_check(path, b"original\n", check=True)
            self.assertEqual(path.read_bytes(), b"original\n")
            with self.assertRaises(ValueError):
                resources.write_or_check(path, b"different\n", check=True)
            self.assertEqual(path.read_bytes(), b"original\n")

    def test_samples_trace_to_logged_inputs_without_invented_ids(self):
        notebook_path = resources.ROOT / "additive identification validation part 1.ipynb"
        notebook = json.loads(notebook_path.read_text())
        rows, references = resources.recover_food_samples(notebook_path)
        with (resources.ROOT / "App/Resources/branded_food_short_sample.csv").open(newline="", encoding="utf-8") as stream:
            actual = list(csv.reader(stream))
        self.assertEqual(actual, [list(resources.FOOD_COLUMNS)] + rows)
        self.assertEqual(len(rows), 20)
        self.assertEqual(len({reference["source_entry_id"] for reference in references}), 20)
        self.assertEqual(references[0]["source_entry_id"], "4792")
        for row, reference in zip(rows, references):
            self.assertEqual(len(row), 7)
            self.assertEqual(row[0], "")  # App row index is not a USDA FDC identifier.
            self.assertEqual(row[3], "")  # Original sub-brand was not recorded.
            self.assertGreater(len(row[4]), 50)
            self.assertIn(",", row[4])
            self.assertFalse(any('"' in value or "\n" in value or "\r" in value for value in row))
            output = notebook["cells"][reference["cell_index"]]["outputs"][reference["output_index"]]
            text = "".join(output["text"])
            start = text.index("  Entry ID: " + reference["source_entry_id"] + "\n")
            next_entry = text.find("📋 ENTRY INFORMATION:", start)
            block = text[start:next_entry if next_entry >= 0 else len(text)]
            for label, value in (("Product", row[6]), ("Brand", row[1]), ("Category", row[5]), ("Brand Name", row[2])):
                self.assertIn(f"  {label}: {value}\n", block)
            self.assertIn(f"🧾 ORIGINAL INGREDIENT LIST:\n  {row[4]}\n", block)

    def test_incomplete_notebook_cannot_create_samples(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "incomplete.ipynb"
            path.write_text(json.dumps({"cells": [{"outputs": [{"output_type": "stream", "text": [
                "📋 ENTRY INFORMATION:\n  Entry ID: 1\n  Product: Incomplete\n"
            ]}]}]}))
            with self.assertRaises(ValueError):
                resources.recover_food_samples(path)

    def test_provenance_checksums_match_files(self):
        manifest = json.loads((resources.ROOT / "docs/resources/manifest.json").read_text())
        for identity in manifest["files"].values():
            content = (resources.ROOT / identity["path"]).read_bytes()
            self.assertEqual(len(content), identity["bytes"], identity["path"])
            self.assertEqual(hashlib.sha256(content).hexdigest(), identity["sha256"], identity["path"])

    def test_cfr_resource_preserves_all_original_regulation_cells(self):
        source = resources.ROOT / "data/source/FoodSubstances.csv"
        source_lines = source.read_bytes().decode("cp1252").splitlines()
        source_rows = list(csv.DictReader(io.StringIO("\n".join(source_lines[4:]))))
        result, summary = resources.cfr_resource(source)
        self.assertEqual(result, (resources.ROOT / "App/Resources/FoodSubstancesCFR.csv").read_bytes())
        lines = result.decode("utf-8").splitlines()
        self.assertEqual(lines[:4], source_lines[:4])
        self.assertTrue(lines[8].startswith("Substance,Reg add01,"))
        self.assertIn("Last updated 2/13/2025; downloaded 6/19/2025.", lines[0])
        actual = list(csv.DictReader(io.StringIO("\n".join(lines[8:]))))
        self.assertEqual(len(actual), 3971)
        self.assertEqual(summary["substances_with_references"], 2171)
        self.assertEqual(summary["reference_cells"], 3907)
        self.assertEqual(len(summary["regulation_columns"]), 19)
        self.assertEqual({r["Substance"] for r in actual}, {r["substance"] for r in self.dataset["data"]})
        for original, normalized in zip(source_rows, actual):
            self.assertEqual(normalized["Substance"], original["Substance"].strip())
            for key in summary["regulation_columns"]:
                value = original[key].strip()
                if value:
                    self.assertRegex(value, r'^=T\("[0-9]+\.[0-9]+"\)$')
                self.assertEqual(normalized[key], value[4:-2] if value else "")

    def test_cfr_conversion_rejects_unknown_formula_and_bad_contract(self):
        preamble = "source\n\nwarning\n\n"
        cases = (
            "no columns here\n",
            preamble + "Substance,Other Names\nACID,ALIAS\n",
            preamble + "Substance,Reg add01\nACID,=1+1\n",
            preamble + "Substance,Reg add01\nACID,172.515,extra\n",
            preamble + "Substance,Reg add01\nACID,\n",
            preamble + 'Substance,Reg add01\nACID,=T("172.515")\nACID,=T("172.510")\n',
        )
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source.csv"
            for text in cases:
                with self.subTest(text=text):
                    source.write_bytes(text.encode("cp1252"))
                    with self.assertRaises(ValueError):
                        resources.cfr_resource(source)


if __name__ == "__main__":
    unittest.main()
