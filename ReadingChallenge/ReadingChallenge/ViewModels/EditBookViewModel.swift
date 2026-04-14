import CoreData
import Combine

final class EditBookViewModel: ObservableObject {
    @Published var title: String
    @Published var author: String
    @Published var isbn: String
    @Published var pageCount: String
    @Published var dateStarted: Date?
    @Published var isLoadingAPI = false
    @Published var errorMessage: String?
    @Published var showAPIUpdateConfirm = false

    private var apiLookupResult: BookDTO?
    private let context = PersistenceController.shared.container.viewContext

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(book: Book) {
        title = book.title
        author = book.author
        isbn = book.isbn
        pageCount = book.pageCount > 0 ? "\(book.pageCount)" : ""
        dateStarted = book.dateStarted
    }

    func lookupISBN() async {
        let trimmed = isbn.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        await MainActor.run {
            isLoadingAPI = true
            errorMessage = nil
        }
        defer {
            Task { @MainActor in isLoadingAPI = false }
        }
        do {
            let dto = try await BookAPIService.fetchBook(isbn: trimmed)
            await MainActor.run {
                apiLookupResult = dto
                showAPIUpdateConfirm = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func applyAPIResult() {
        guard let dto = apiLookupResult else { return }
        title = dto.title
        author = dto.author
        pageCount = dto.pageCount > 0 ? "\(dto.pageCount)" : pageCount
    }

    func save(to book: Book) {
        let newTitle = title.trimmingCharacters(in: .whitespaces)
        let newAuthor = author.trimmingCharacters(in: .whitespaces)
        let newISBN = isbn.trimmingCharacters(in: .whitespaces)
        let newPageCount = Int32(pageCount.trimmingCharacters(in: .whitespaces)) ?? book.pageCount

        book.title = newTitle
        book.author = newAuthor
        book.isbn = newISBN
        book.pageCount = newPageCount
        book.dateStarted = dateStarted

        // Clamp currentPage if the new page count is less than the current position
        if book.currentPage > newPageCount {
            book.currentPage = newPageCount
        }

        PersistenceController.shared.save()
    }
}
