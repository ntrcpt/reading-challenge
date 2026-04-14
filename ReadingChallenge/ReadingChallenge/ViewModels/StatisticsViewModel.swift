import CoreData
import Combine

final class StatisticsViewModel: ObservableObject {
    @Published var booksFinished: Int = 0
    @Published var pagesRead: Int = 0
    @Published var avgReadingDays: Double = 0
    @Published var booksPerWeek: Double = 0

    private let context = PersistenceController.shared.container.viewContext
    private var cancellables = Set<AnyCancellable>()

    init() {
        compute()
        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didSaveObjectsNotification, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.compute() }
            .store(in: &cancellables)
    }

    func compute() {
        let books = (try? context.fetch(Book.fetchRequest())) ?? []
        let finished = books.filter { $0.status == .finished }

        booksFinished = finished.count

        pagesRead = finished
            .filter { $0.pageCount > 0 }
            .reduce(0) { $0 + Int($1.pageCount) }

        let withDates = finished.filter { $0.dateStarted != nil && $0.dateFinished != nil }
        if !withDates.isEmpty {
            let totalDays = withDates.reduce(0.0) { sum, book in
                sum + book.dateFinished!.timeIntervalSince(book.dateStarted!) / 86400.0
            }
            avgReadingDays = totalDays / Double(withDates.count)
        } else {
            avgReadingDays = 0
        }

        if let earliest = books.compactMap({ $0.dateAdded }).min() {
            let weeks = Date().timeIntervalSince(earliest) / (86400.0 * 7.0)
            booksPerWeek = weeks > 0 ? Double(finished.count) / weeks : 0
        } else {
            booksPerWeek = 0
        }
    }
}
