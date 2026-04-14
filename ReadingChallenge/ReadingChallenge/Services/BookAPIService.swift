import Foundation

enum BookAPIService {

    enum APIError: LocalizedError {
        case invalidURL
        case notFound
        case badResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL:    "Invalid URL."
            case .notFound:      "Book not found for this ISBN."
            case .badResponse:   "Network error — please try again."
            }
        }
    }

    static func fetchBook(isbn: String) async throws -> BookDTO {
        let cleaned = isbn.trimmingCharacters(in: .whitespaces)
        let urlString = "https://openlibrary.org/api/books?bibkeys=ISBN:\(cleaned)&format=json&jscmd=data"
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.badResponse
        }

        let dict = try JSONDecoder().decode([String: OpenLibraryBookData].self, from: data)
        guard let entry = dict["ISBN:\(cleaned)"] else { throw APIError.notFound }

        return BookDTO(
            title: entry.title,
            author: entry.authors?.first?.name ?? "Unknown Author",
            pageCount: Int32(entry.number_of_pages ?? 0),
            coverURL: entry.cover?.medium
        )
    }

    static func fetchCoverData(urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }
}
