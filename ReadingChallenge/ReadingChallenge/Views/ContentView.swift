import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            BookListView()
                .tabItem { Label("Library", systemImage: "books.vertical") }
            StatisticsView()
                .tabItem { Label("Statistics", systemImage: "chart.bar") }
        }
    }
}
