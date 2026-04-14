import SwiftUI

struct EditBookView: View {
    let book: Book
    @StateObject private var viewModel: EditBookViewModel
    @Environment(\.dismiss) private var dismiss

    private let originalISBN: String

    init(book: Book) {
        self.book = book
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
        }
    }
}
