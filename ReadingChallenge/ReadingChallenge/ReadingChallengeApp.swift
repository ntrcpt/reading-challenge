//
//  ReadingChallengeApp.swift
//  ReadingChallenge
//
//  Created by David Reiner on 14.04.26.
//

import SwiftUI
import CoreData

@main
struct ReadingChallengeApp: App {
    init() {
        BookAPIService.googleBooksAPIKey = APIKeys.googleBooks
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
