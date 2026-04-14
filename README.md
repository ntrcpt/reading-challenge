# Reading Challenge iOS App

## Project Description

This project started with a personal challenge.

My wife set a goal to read one book per week.
Instead of relying on existing apps, I decided to build a dedicated iOS app tailored exactly to her needs.

The goal was not to create another feature-heavy reading platform, but a deliberately minimal tool:

* add books via ISBN scan
* track reading progress
* manage a single active book
* keep simple, meaningful statistics

The app is fully offline-first, requires no account, and focuses entirely on reducing friction and maintaining consistency.

This project is as much about software development as it is about product design — exploring how far you can get by intentionally limiting scope and building only what truly matters.

Built with SwiftUI, following a clean and minimal architecture.

---

## Technical Stack

**Platform:** iOS 17+ (built for iOS 26.4 with Xcode 26 beta)

**Language:** Swift 5.0 with Swift 6 concurrency (Actor isolation)

**UI Framework:** SwiftUI

**Architecture:** MVVM (Model-View-ViewModel)

**Data Persistence:** Core Data

**Networking:** URLSession

**Camera:** AVFoundation (barcode scanning)

**Concurrency:** Swift Concurrency with `@MainActor` isolation

## Architecture Overview

### Project Structure

```
ReadingChallenge/
├── Models/
│   ├── Book+CoreDataClass.swift       # NSManagedObject subclass
│   ├── Book+CoreDataProperties.swift  # @NSManaged properties
│   ├── BookStatus.swift               # Status enum (notStarted, reading, paused, finished)
│   └── BookDTO.swift                  # Data transfer object for API responses
├── Services/
│   └── BookAPIService.swift           # Open Library API client
├── ViewModels/
│   ├── BookListViewModel.swift        # List logic + status transitions
│   ├── AddBookViewModel.swift         # Book entry + ISBN lookup
│   └── StatisticsViewModel.swift      # Stats calculations
├── Views/
│   ├── ContentView.swift              # Root TabView
│   ├── BookList/
│   │   ├── BookListView.swift         # Main library view
│   │   ├── BookRowView.swift          # List item cell
│   │   └── PauseProgressSheet.swift   # Pause progress dialog
│   ├── AddBook/
│   │   ├── AddBookView.swift          # ISBN entry form
│   │   └── BarcodeScannerView.swift   # Barcode capture (AVFoundation)
│   ├── Detail/
│   │   └── BookDetailView.swift       # Book detail + status management
│   └── Statistics/
│       └── StatisticsView.swift       # Reading stats dashboard
├── Persistence.swift                  # Core Data stack singleton
├── ReadingChallengeApp.swift          # App entry point
└── ReadingChallenge.xcdatamodeld      # Core Data model
```

### Core Data Model

**Entity: Book**
- `id: UUID` — unique identifier
- `title: String` — book title
- `author: String` — author name
- `isbn: String` — ISBN-13 barcode
- `pageCount: Int32` — total pages (0 = unknown)
- `coverURL: String?` — URL to cover image
- `coverData: Data?` — cached cover image (stored externally)
- `statusRaw: Int16` — backing field for BookStatus enum
- `currentPage: Int32` — reading progress
- `dateAdded: Date` — when added to library
- `dateStarted: Date?` — when reading started
- `dateFinished: Date?` — when reading completed

### Design Decisions

**Status Sort Order:** Books are sorted by `reading > paused > notStarted > finished`. Since the `statusRaw` enum values don't match this display order, sorting happens in-memory after Core Data fetch.

**Single Active Book:** Only one book can have `status == .reading` at a time. When starting a new book while another is reading, the app shows a progress sheet to pause the current book first.

**Offline-First:** All book data is stored locally in Core Data. The API is only called when adding a new book via ISBN lookup.

**No Accounts:** The app works entirely on a single device with no cloud sync or authentication.

## Features

### 1. Add Books
- **Barcode Scan** — Primary method using device camera (AVFoundation)
- **Manual Entry** — Fallback ISBN input
- **ISBN Lookup** — Fetches book data from Open Library API (title, author, page count, cover image)
- **Offline Saving** — Books saved immediately to Core Data

### 2. Track Reading
- **Status Management** — notStarted → reading → paused → finished
- **Progress Slider** — Manual page tracking (only for books with page count)
- **Active Book Constraint** — Enforces max 1 book in "reading" state
- **Pause Flow** — Shows progress dialog when switching active books

### 3. Statistics
- **Books Finished** — count of completed books
- **Pages Read** — total pages of finished books
- **Avg. Reading Days** — average duration per book
- **Books Per Week** — velocity metric

### 4. Book Management
- **Detail View** — Full book info, status controls, date editing
- **Delete** — Remove books with confirmation
- **Cover Images** — Downloaded and cached with books
- **Dates** — Track when each book was added, started, and finished

## Building & Running

### Prerequisites
- Xcode 26+ (or Xcode 16.1+)
- iOS 17+ device or simulator
- Swift 5.0+

### Setup
1. Open `ReadingChallenge.xcodeproj` in Xcode
2. Select target "ReadingChallenge"
3. Set deployment target to iOS 17.0 minimum
4. Build (`Cmd+B`)

### Running
- On **real device**: Connect iPhone, select device, press Play (`Cmd+R`)
- On **simulator**: Select iPhone simulator, press Play (`Cmd+R`)

### Camera Permission
The app requests camera access on first barcode scan. Grant permission in Settings for full functionality.

## API Integration

**Open Library Books API**

Endpoint: `https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&format=json&jscmd=data`

Returns:
- `title: String`
- `authors: [{ name: String }]`
- `number_of_pages: Int?`
- `cover: { small: String?, medium: String?, large: String? }`

No authentication required. Free and open.

## Swift 6 Concurrency Notes

This project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which isolates all code to the main actor by default. This simplifies concurrency for a UI-focused app:

- All ViewModels run on `@MainActor`
- All Views are main-actor-safe by default
- `BookAPIService` uses `async throws` for network calls
- `BarcodeScannerView` uses `nonisolated(unsafe)` for camera session state (safe due to explicit queue management)

## Testing

Manual testing checklist:

- [ ] Add a book via barcode scan
- [ ] Add a book via manual ISBN entry
- [ ] Start reading a book
- [ ] Try to start another book → pause flow appears
- [ ] Update progress with slider
- [ ] Pause and resume reading
- [ ] Finish a book
- [ ] Check statistics update correctly
- [ ] Delete a book
- [ ] Restart app — data persists
- [ ] Use offline (disable network) — all features work

## Future Enhancements (Out of Scope for MVP)

- Reading schedule recommendations
- Book ratings and notes
- Reading streak tracking
- Cloud sync via iCloud
- Widget showing current book
- Sharing reading progress
- Book recommendations
- Reading history archive

## License

Personal project. Built for iOS with care.
