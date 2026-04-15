# Reading Challenge

My wife set a goal to read one book per week. Instead of using an existing app, I built one tailored exactly to her needs.

Deliberately minimal: scan a book's barcode, track progress, see stats. No accounts, no cloud, no noise.

Built with SwiftUI for iOS.

---

## Stack

- **iOS 17+** · SwiftUI · MVVM · Core Data
- **AVFoundation** for barcode scanning
- **URLSession** → [Open Library API](https://openlibrary.org/developers/api) + [Google Books API](https://developers.google.com/books) for ISBN lookup
- **Swift 6** concurrency with `@MainActor` isolation

## Build & Run

### Prerequisites

ISBN lookup uses Open Library as a primary source and falls back to the Google Books API for books with missing data (common with non-English titles). Google Books requires an API key to avoid shared rate limits.

1. Create a project at [console.cloud.google.com](https://console.cloud.google.com) and enable the **Books API**
2. Generate an API key (optionally restrict it to the Books API)
3. Create `ReadingChallenge/ReadingChallenge/Services/APIKeys.swift` — this file is gitignored:

```swift
enum APIKeys {
    static let googleBooks = "YOUR_API_KEY_HERE"
}
```

### Running

1. Complete the prerequisites above
2. Open `ReadingChallenge.xcodeproj` in Xcode 26+
3. Select a device or simulator (iOS 17+)
4. `Cmd+R`

Camera access is required for barcode scanning — grant permission on first scan.
