import SwiftUI
import CoreData

struct PauseProgressSheet: View {
    let activeBook: Book
    let newBookTitle: String
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void

    @State private var currentPage: Double

    init(activeBook: Book, newBookTitle: String, onConfirm: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.activeBook = activeBook
        self.newBookTitle = newBookTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _currentPage = State(initialValue: Double(activeBook.currentPage))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Before you start")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Where did you stop in \"\(activeBook.title)\"?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                if activeBook.hasPageInfo {
                    VStack(spacing: 12) {
                        Slider(
                            value: $currentPage,
                            in: 0...Double(activeBook.pageCount),
                            step: 1
                        )
                        Text("Page \(Int(currentPage)) of \(activeBook.pageCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Button {
                        onConfirm(Int(currentPage))
                    } label: {
                        Text("Pause & Start \"\(newBookTitle)\"")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)

                    Button("Cancel", role: .cancel, action: onCancel)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
    }
}
