import CoreData
import Combine

final class BookListViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var bookToConfirmStart: Book?
    @Published private(set) var pendingNewBook: Book?
    @Published var alertMessage: String?
    private let context = PersistenceController.shared.container.viewContext
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        refreshBooks()
        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didSaveObjectsNotification, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshBooks() }
            .store(in: &cancellables)
    }

    func refreshBooks() {
        let request = Book.fetchRequest()
        let fetched = (try? context.fetch(request)) ?? []
        books = fetched.sorted {
            if $0.status.sortOrder != $1.status.sortOrder {
                return $0.status.sortOrder < $1.status.sortOrder
            }
            return ($0.dateAdded ?? .distantPast) > ($1.dateAdded ?? .distantPast)
        }
    }

    // MARK: - Status Transitions

    func startReading(_ newBook: Book) {
        let active = books.first { $0.status == .reading }
        if let active, active.objectID != newBook.objectID {
            pendingNewBook = newBook
            bookToConfirmStart = active
        } else {
            applyStartReading(newBook)
            persistence.save()
        }
    }

    func confirmPauseAndStart(currentPage: Int) {
        guard let active = bookToConfirmStart, let newBook = pendingNewBook else { return }
        if active.hasPageInfo {
            active.currentPage = Int32(currentPage)
        }
        active.status = .paused
        applyStartReading(newBook)
        bookToConfirmStart = nil
        pendingNewBook = nil
        persistence.save()
    }

    func cancelPause() {
        bookToConfirmStart = nil
        pendingNewBook = nil
    }

    func pauseBook(_ book: Book, currentPage: Int? = nil) {
        if let page = currentPage, book.hasPageInfo {
            book.currentPage = Int32(page)
        }
        book.status = .paused
        persistence.save()
    }

    func finishBook(_ book: Book) {
        book.status = .finished
        if book.hasPageInfo {
            book.currentPage = book.pageCount
        }
        book.dateFinished = Date()
        if book.dateStarted == nil {
            book.dateStarted = Date()
        }
        persistence.save()
    }

    func deleteBook(_ book: Book) {
        context.delete(book)
        persistence.save()
    }

    func updateCurrentPage(_ book: Book, page: Int) {
        book.currentPage = Int32(page)
        persistence.save()
    }

    // MARK: - Private

    private func applyStartReading(_ book: Book) {
        book.status = .reading
        if book.dateStarted == nil {
            book.dateStarted = Date()
        }
    }
}
