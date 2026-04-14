import CoreData

@objc(Book)
public class Book: NSManagedObject, Identifiable {

    var status: BookStatus {
        get { BookStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    var hasPageInfo: Bool { pageCount > 0 }

    var progressFraction: Double {
        guard pageCount > 0 else { return 0 }
        return Double(currentPage) / Double(pageCount)
    }

    static func create(from dto: BookDTO, isbn: String, in context: NSManagedObjectContext) -> Book {
        let book = Book(context: context)
        book.id = UUID()
        book.title = dto.title
        book.author = dto.author
        book.isbn = isbn
        book.pageCount = dto.pageCount
        book.coverURL = dto.coverURL
        book.statusRaw = BookStatus.notStarted.rawValue
        book.currentPage = 0
        book.dateAdded = Date()
        return book
    }
}
