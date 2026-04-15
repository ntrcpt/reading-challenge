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

// Decodable types for Google Books API response
struct GoogleBooksResponse: Decodable {
    let items: [Volume]?

    struct Volume: Decodable {
        let volumeInfo: VolumeInfo

        struct VolumeInfo: Decodable {
            let title: String?
            let authors: [String]?
            let pageCount: Int?
            let imageLinks: ImageLinks?

            struct ImageLinks: Decodable {
                let thumbnail: String?
                let smallThumbnail: String?
            }
        }
    }
}
