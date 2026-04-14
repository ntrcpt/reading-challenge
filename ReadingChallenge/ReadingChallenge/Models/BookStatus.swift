import Foundation

enum BookStatus: Int16, CaseIterable {
    case notStarted = 0
    case reading    = 1
    case paused     = 2
    case finished   = 3

    var displayName: String {
        switch self {
        case .notStarted: "Not Started"
        case .reading:    "Reading"
        case .paused:     "Paused"
        case .finished:   "Finished"
        }
    }

    // Lower = higher priority in the list
    var sortOrder: Int {
        switch self {
        case .reading:    0
        case .paused:     1
        case .notStarted: 2
        case .finished:   3
        }
    }
}
