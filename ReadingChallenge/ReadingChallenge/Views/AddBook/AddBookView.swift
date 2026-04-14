import SwiftUI
import CoreData

struct AddBookView: View {
    @StateObject private var viewModel = AddBookViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("ISBN") {
                    HStack {
                        TextField("Enter ISBN", text: $viewModel.isbn)
                            .keyboardType(.numberPad)
                        Button {
                            viewModel.showScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundStyle(.blue)
                        }
                    }

                    Button {
                        Task { await viewModel.lookupISBN() }
                    } label: {
                        if viewModel.isLoadingAPI {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Looking up...")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Look Up ISBN")
                        }
                    }
                    .disabled(viewModel.isbn.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoadingAPI)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section("Book Details") {
                    TextField("Title", text: $viewModel.title)
                    TextField("Author", text: $viewModel.author)
                    TextField("Page count (optional)", text: $viewModel.pageCount)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.saveBook()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave || viewModel.isLoadingAPI)
                }
            }
            .sheet(isPresented: $viewModel.showScanner) {
                BarcodeScannerView { isbn in
                    viewModel.onBarcodeScan(isbn)
                }
            }
        }
    }
}
