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

        // Try Open Library first
        var olDTO: BookDTO?
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if (response as? HTTPURLResponse)?.statusCode == 200,
               let dict = try? JSONDecoder().decode([String: OpenLibraryBookData].self, from: data),
               let entry = dict["ISBN:\(cleaned)"] {
                olDTO = BookDTO(
                    title: entry.title,
                    author: entry.authors?.first?.name ?? "Unknown Author",
                    pageCount: Int32(entry.number_of_pages ?? 0),
                    coverURL: entry.cover?.medium
                )
            }
        } catch {
            // Network failure — fall through to Google Books
        }

        // Return immediately if Open Library gave us a complete result
        if let dto = olDTO, dto.pageCount > 0, dto.coverURL != nil {
            return dto
        }

        // Try Google Books as full fallback or to fill in missing fields
        let gbDTO = try? await fetchBookFromGoogleBooks(isbn: cleaned)

        guard let ol = olDTO else {
            guard let gb = gbDTO else { throw APIError.notFound }
            return gb
        }

        // Gap-fill: prefer Open Library values, use Google Books for anything missing
        return BookDTO(
            title: ol.title,
            author: ol.author,
            pageCount: ol.pageCount > 0 ? ol.pageCount : (gbDTO?.pageCount ?? 0),
            coverURL: ol.coverURL ?? gbDTO?.coverURL
        )
    }

    private static func fetchBookFromGoogleBooks(isbn: String) async throws -> BookDTO {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.badResponse
        }

        let result = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        guard let info = result.items?.first?.volumeInfo, let title = info.title else {
            throw APIError.notFound
        }

        // Google Books returns HTTP URLs; upgrade to HTTPS for App Transport Security
        let rawCover = info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail
        let coverURL = rawCover.map { $0.replacingOccurrences(of: "http://", with: "https://") }

        return BookDTO(
            title: title,
            author: info.authors?.first ?? "Unknown Author",
            pageCount: Int32(info.pageCount ?? 0),
            coverURL: coverURL
        )
    }

    static func fetchCoverData(urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }
}
