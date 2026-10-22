import Foundation
import XCTest
@testable import FoodAdditiveLens

final class KnowledgeResourceTests: XCTestCase {
    @MainActor
    func testBundledCFRMappingsAndSectionURLs() async throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "FoodSubstancesCFR", withExtension: "csv"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let lines = text.components(separatedBy: .newlines)
        let header = try XCTUnwrap(lines.dropFirst(8).first)
        XCTAssertTrue(header.hasPrefix("Substance,Reg add01,"))

        let manager = CFRManager()
        await manager.loadCFRData()
        XCTAssertTrue(manager.isLoaded)
        XCTAssertEqual(manager.getCFRCodes(for: "CALCIUM PROPIONATE"), ["179.45", "181.23", "184.1221"])
        XCTAssertEqual(manager.getCFRCodes(for: "ASCORBIC ACID"), ["172.280", "182.3013", "182.8013"])
        XCTAssertEqual(manager.getCFRCodes(for: "ACESULFAME POTASSIUM"), ["172.800"])
        let links = manager.generateCFRURLs(for: ["184.1221", "172.280"])
        XCTAssertEqual(links.map { $0.url.absoluteString }, [
            "https://www.ecfr.gov/current/title-21/section-184.1221",
            "https://www.ecfr.gov/current/title-21/section-172.280"
        ])
    }

    private struct ParityFixtures: Decodable {
        let embeddingDimension: Int
        let cases: [Example]
        struct Example: Decodable {
            let text: String
            let embedding: [Double]
        }
    }

    private struct Dataset: Decodable {
        let embeddingDimension: Int
        let totalRecords: Int
        let data: [Record]
        struct Record: Decodable {
            let substance: String
            let otherNames: String
            let technicalEffect: String
            let searchableText: String
            let embedding: [Double]
        }
    }

    func testQueryFeaturesMatchNotebookFixtures() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "embedding-parity", withExtension: "json"))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let fixtures = try decoder.decode(ParityFixtures.self, from: Data(contentsOf: url))
        XCTAssertEqual(fixtures.embeddingDimension, 384)
        XCTAssertEqual(fixtures.cases.count, 7)
        for example in fixtures.cases {
            let actual = AdditiveKnowledgeManager.generateQueryEmbedding(for: example.text, dimension: fixtures.embeddingDimension)
            XCTAssertEqual(actual.count, example.embedding.count)
            for (value, expected) in zip(actual, example.embedding) {
                // Swift accumulates in Float; the notebook uses double precision.
                XCTAssertEqual(Double(value), expected, accuracy: 0.000003, "Query: \(example.text)")
            }
        }
        XCTAssertTrue(AdditiveKnowledgeManager.generateQueryEmbedding(for: "acid", dimension: 0).isEmpty)
    }

    func testAppBundleContainsValidKnowledgeRecords() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "food_additive_embeddings", withExtension: "json"))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dataset = try decoder.decode(Dataset.self, from: Data(contentsOf: url))
        XCTAssertEqual(dataset.embeddingDimension, 384)
        XCTAssertEqual(dataset.totalRecords, 3971)
        XCTAssertEqual(dataset.data.count, dataset.totalRecords)
        XCTAssertEqual(Set(dataset.data.map { $0.substance.lowercased() }).count, dataset.totalRecords)
        for record in dataset.data {
            XCTAssertFalse(record.substance.isEmpty)
            XCTAssertEqual(record.embedding.count, dataset.embeddingDimension)
            XCTAssertTrue(record.embedding.allSatisfy { $0.isFinite })
            let squaredNorm = record.embedding.reduce(0.0) { $0 + $1 * $1 }
            XCTAssertEqual(squaredNorm, 1.0, accuracy: 0.000001, record.substance)
        }
        let calcium = try XCTUnwrap(dataset.data.first { $0.substance == "CALCIUM PROPIONATE" })
        XCTAssertEqual(calcium.technicalEffect, "ANTIMICROBIAL AGENT|ANTIOXIDANT")
        let ascorbic = try XCTUnwrap(dataset.data.first { $0.substance == "ASCORBIC ACID" })
        XCTAssertTrue(ascorbic.otherNames.contains("VITAMIN C"))
        XCTAssertTrue(ascorbic.technicalEffect.contains("ANTIOXIDANT"))
        let sampleURL = try XCTUnwrap(Bundle.main.url(forResource: "branded_food_short_sample", withExtension: "csv"))
        let sampleText = try String(contentsOf: sampleURL, encoding: .utf8)
        XCTAssertEqual(sampleText.components(separatedBy: .newlines).filter { !$0.isEmpty }.count, 21)
        XCTAssertTrue(sampleText.hasPrefix("fdc_id,brand_owner,brand_name,subbrand_name,ingredients,branded_food_category,description\n"))
    }
}
