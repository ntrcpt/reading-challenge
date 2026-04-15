import XCTest
@testable import ReadingChallenge

final class ISBNLookupTests: XCTestCase {

    /// Verifies that the ISBN for the German edition of "Escaping the Build Trap"
    /// resolves to the correct title, author, and page count.
    /// Open Library has no record for this ISBN, so this exercises the Google Books fallback.
    func testGermanBook_9783960091202() async throws {
        let dto = try await BookAPIService.fetchBook(isbn: "9783960091202")

        XCTAssert(
            dto.title.localizedCaseInsensitiveContains("Raus aus der Feature-Falle"),
            "Title should contain 'Raus aus der Feature-Falle', got: \"\(dto.title)\""
        )

        // Accept any name order: "Melissa Perri" or "Perri, Melissa"
        let author = dto.author
        XCTAssert(
            author.localizedCaseInsensitiveContains("Melissa") &&
            author.localizedCaseInsensitiveContains("Perri"),
            "Author should contain 'Melissa' and 'Perri', got: \"\(author)\""
        )

        XCTAssertEqual(dto.pageCount, 190, "Expected 190 pages, got \(dto.pageCount)")

        // Note: neither Open Library nor Google Books has a cover image for this ISBN.
        // The test documents the known state rather than asserting presence.
    }
}
