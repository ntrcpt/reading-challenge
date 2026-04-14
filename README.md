# Reading Challenge

My wife set a goal to read one book per week. Instead of using an existing app, I built one tailored exactly to her needs.

Deliberately minimal: scan a book's barcode, track progress, see stats. No accounts, no cloud, no noise.

Built with SwiftUI for iOS.

---

## Stack

- **iOS 17+** · SwiftUI · MVVM · Core Data
- **AVFoundation** for barcode scanning
- **URLSession** → [Open Library API](https://openlibrary.org/developers/api) for ISBN lookup
- **Swift 6** concurrency with `@MainActor` isolation

## Build & Run

1. Open `ReadingChallenge.xcodeproj` in Xcode 26+
2. Select a device or simulator (iOS 17+)
3. `Cmd+R`

Camera access is required for barcode scanning — grant permission on first scan.
