import SwiftUI
import CoreData

struct BookRowView: View {
    @ObservedObject var book: Book

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            coverView

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    StatusBadge(status: book.status)

                    if book.status == .paused && book.hasPageInfo {
                        Text("Page \(book.currentPage) / \(book.pageCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)

                if book.status == .reading && book.hasPageInfo {
                    ProgressView(value: book.progressFraction)
                        .tint(.blue)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var coverView: some View {
        if let data = book.coverData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 68)
                .clipped()
                .cornerRadius(4)
        } else {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 68)
                .cornerRadius(4)
        }
    }
}

struct StatusBadge: View {
    let status: BookStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var color: Color {
        switch status {
        case .reading:    .blue
        case .paused:     .orange
        case .notStarted: .gray
        case .finished:   .green
        }
    }
}
