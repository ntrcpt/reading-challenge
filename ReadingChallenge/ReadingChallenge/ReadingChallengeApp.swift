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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
