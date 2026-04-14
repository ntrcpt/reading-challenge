import SwiftUI
import CoreData

struct BookListView: View {
    @StateObject private var viewModel = BookListViewModel()
    @State private var showAddBook = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if viewModel.books.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(viewModel.books, id: \.objectID) { book in
                                NavigationLink {
                                    BookDetailView(book: book, viewModel: viewModel)
                                } label: {
                                    BookRowView(book: book)
                                }
                                .listRowSeparator(.automatic)
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { viewModel.deleteBook(viewModel.books[$0]) }
                            }
                        }
                        .listStyle(.plain)
                    }
                }

                // Floating add button
                Button {
                    showAddBook = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("My Library")
            .sheet(isPresented: $showAddBook, onDismiss: { viewModel.refreshBooks() }) {
                AddBookView()
            }
            .sheet(item: $viewModel.bookToConfirmStart) { activeBook in
                PauseProgressSheet(
                    activeBook: activeBook,
                    newBookTitle: viewModel.pendingNewBook?.title ?? "new book",
                    onConfirm: { page in viewModel.confirmPauseAndStart(currentPage: page) },
                    onCancel: { viewModel.cancelPause() }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No books yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap + to add your first book")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
