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

    // Google Books API key — required to avoid shared-quota rate limits.
    // Get a free key at https://console.cloud.google.com (enable "Books API", create an API key).
    // Paste the key below or store it in a gitignored APIKeys.swift file.
    static var googleBooksAPIKey: String? = nil

    private static func fetchBookFromGoogleBooks(isbn: String) async throws -> BookDTO {
        var urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
        if let key = googleBooksAPIKey { urlString += "&key=\(key)" }
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
        var coverURL = rawCover.map { $0.replacingOccurrences(of: "http://", with: "https://") }

        // If this edition has no cover, search by title+author to find one from another edition
        let author = info.authors?.first ?? "Unknown Author"
        if coverURL == nil {
            coverURL = await fetchAlternateEditionCover(title: title, author: author)
        }

        return BookDTO(
            title: title,
            author: author,
            pageCount: Int32(info.pageCount ?? 0),
            coverURL: coverURL
        )
    }

    private static func fetchAlternateEditionCover(title: String, author: String) async -> String? {
        let query = "intitle:\(title) inauthor:\(author)"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        var urlString = "https://www.googleapis.com/books/v1/volumes?q=\(encoded)&maxResults=10"
        if let key = googleBooksAPIKey { urlString += "&key=\(key)" }
        guard let url = URL(string: urlString),
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let result = try? JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        else { return nil }

        for volume in result.items ?? [] {
            let info = volume.volumeInfo
            guard let raw = info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail else { continue }
            return raw.replacingOccurrences(of: "http://", with: "https://")
        }
        return nil
    }

    static func fetchCoverData(urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }
}
