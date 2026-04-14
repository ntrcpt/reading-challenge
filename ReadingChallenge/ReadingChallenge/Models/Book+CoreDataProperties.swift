import CoreData

extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var id: UUID?
    @NSManaged var title: String
    @NSManaged var author: String
    @NSManaged var isbn: String
    @NSManaged var pageCount: Int32
    @NSManaged var coverURL: String?
    @NSManaged var coverData: Data?
    @NSManaged var statusRaw: Int16
    @NSManaged var currentPage: Int32
    @NSManaged var dateAdded: Date?
    @NSManaged var dateStarted: Date?
    @NSManaged var dateFinished: Date?
}
