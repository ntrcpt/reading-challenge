import SwiftUI

struct EditBookView: View {
    let book: Book
    let onDelete: (() -> Void)?
    @StateObject private var viewModel: EditBookViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    private let originalISBN: String

    init(book: Book, onDelete: (() -> Void)? = nil) {
        self.book = book
        self.onDelete = onDelete
        self.originalISBN = book.isbn
        _viewModel = StateObject(wrappedValue: EditBookViewModel(book: book))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Book Details") {
                    TextField("Title", text: $viewModel.title)
                    TextField("Author", text: $viewModel.author)
                    TextField("Page count", text: $viewModel.pageCount)
                        .keyboardType(.numberPad)
                }

                Section("ISBN") {
                    TextField("ISBN", text: $viewModel.isbn)
                        .keyboardType(.numberPad)
                    if viewModel.isbn != originalISBN {
                        Button {
                            Task { await viewModel.lookupISBN() }
                        } label: {
                            if viewModel.isLoadingAPI {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 4)
                                    Text("Looking up...")
                                }
                            } else {
                                Text("Look Up ISBN")
                            }
                        }
                        .disabled(viewModel.isLoadingAPI)
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                if viewModel.dateStarted != nil {
                    Section("Dates") {
                        DatePicker(
                            "Started",
                            selection: Binding(
                                get: { viewModel.dateStarted ?? Date() },
                                set: { viewModel.dateStarted = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }

                if onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Book", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(to: book)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave || viewModel.isLoadingAPI)
                }
            }
            .confirmationDialog(
                "Update book details from ISBN lookup?",
                isPresented: $viewModel.showAPIUpdateConfirm,
                titleVisibility: .visible
            ) {
                Button("Apply API Results") { viewModel.applyAPIResult() }
                Button("Keep Mine", role: .cancel) { }
            }
            .confirmationDialog("Delete this book?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    onDelete?()
                }
            }
        }
    }
}
