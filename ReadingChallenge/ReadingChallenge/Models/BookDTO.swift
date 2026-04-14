import Foundation

struct BookDTO {
    let title: String
    let author: String
    let pageCount: Int32
    let coverURL: String?
}

// Decodable types for Open Library API response
struct OpenLibraryBookData: Decodable {
    let title: String
    let authors: [AuthorEntry]?
    let number_of_pages: Int?
    let cover: CoverURLs?

    struct AuthorEntry: Decodable {
        let name: String
    }

    struct CoverURLs: Decodable {
        let small: String?
        let medium: String?
        let large: String?
    }
}
