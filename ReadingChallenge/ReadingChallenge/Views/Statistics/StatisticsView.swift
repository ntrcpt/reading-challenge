import SwiftUI
import CoreData

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    StatCard(
                        value: "\(viewModel.booksFinished)",
                        label: "Books Finished"
                    )
                    StatCard(
                        value: "\(viewModel.pagesRead)",
                        label: "Pages Read"
                    )
                    StatCard(
                        value: viewModel.avgReadingDays > 0
                            ? String(format: "%.1f", viewModel.avgReadingDays)
                            : "—",
                        label: "Avg. Days / Book"
                    )
                    StatCard(
                        value: viewModel.booksPerWeek > 0
                            ? String(format: "%.1f", viewModel.booksPerWeek)
                            : "—",
                        label: "Books / Week"
                    )
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
