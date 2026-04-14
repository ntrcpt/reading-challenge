import CoreData
import Combine

final class AddBookViewModel: ObservableObject {
    @Published var title = ""
    @Published var author = ""
    @Published var isbn = ""
    @Published var pageCount = ""
    @Published var isLoadingAPI = false
    @Published var errorMessage: String?
    @Published var showScanner = false

    private(set) var pendingCoverURL: String?
    private let context = PersistenceController.shared.container.viewContext

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func lookupISBN() async {
        let trimmed = isbn.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoadingAPI = true
        errorMessage = nil
        pendingCoverURL = nil
        defer { isLoadingAPI = false }
        do {
            let dto = try await BookAPIService.fetchBook(isbn: trimmed)
            title = dto.title
            author = dto.author
            pageCount = dto.pageCount > 0 ? "\(dto.pageCount)" : ""
            pendingCoverURL = dto.coverURL
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func onBarcodeScan(_ scannedISBN: String) {
        isbn = scannedISBN
        showScanner = false
        Task { await lookupISBN() }
    }

    func saveBook() {
        let trimmedISBN = isbn.trimmingCharacters(in: .whitespaces)
        let pc = Int32(pageCount.trimmingCharacters(in: .whitespaces)) ?? 0
        let dto = BookDTO(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces),
            pageCount: pc,
            coverURL: pendingCoverURL
        )
        let book = Book.create(from: dto, isbn: trimmedISBN, in: context)

        // Save immediately so the book appears in the list
        PersistenceController.shared.save()

        // Download cover image in the background
        if let coverURL = pendingCoverURL {
            let objectID = book.objectID
            Task {
                if let imageData = await BookAPIService.fetchCoverData(urlString: coverURL),
                   let book = context.object(with: objectID) as? Book {
                    book.coverData = imageData
                    PersistenceController.shared.save()
                }
            }
        }

        resetForm()
    }

    func resetForm() {
        title = ""
        author = ""
        isbn = ""
        pageCount = ""
        errorMessage = nil
        pendingCoverURL = nil
    }
}
