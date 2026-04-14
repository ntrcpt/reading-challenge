import SwiftUI
import CoreData

struct BookDetailView: View {
    @ObservedObject var book: Book
    @ObservedObject var viewModel: BookListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var currentPage: Double
    @State private var showEditSheet = false
    @State private var showCoverOptions = false
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var selectedCoverImage: UIImage?

    init(book: Book, viewModel: BookListViewModel) {
        self.book = book
        self.viewModel = viewModel
        _currentPage = State(initialValue: Double(book.currentPage))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Cover
                coverSection

                // Title & Author
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(book.author)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    if !book.isbn.isEmpty {
                        Text("ISBN: \(book.isbn)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Status actions
                statusSection

                // Progress slider
                if (book.status == .reading || book.status == .paused) && book.hasPageInfo {
                    progressSection
                }

                // Dates
                datesSection

                Divider()

                // Delete
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Book", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 16)
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditBookView(book: book)
        }
        .confirmationDialog("Delete this book?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.deleteBook(book)
                dismiss()
            }
        }
        .confirmationDialog("Change Cover Photo", isPresented: $showCoverOptions, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showCameraPicker = true }
            }
            Button("Choose from Library") { showImagePicker = true }
            if book.coverData != nil {
                Button("Remove Cover", role: .destructive) {
                    book.coverData = nil
                    PersistenceController.shared.save()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $selectedCoverImage)
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView(selectedImage: $selectedCoverImage)
        }
        .onChange(of: selectedCoverImage) { _, newImage in
            guard let image = newImage,
                  let data = image.jpegData(compressionQuality: 0.85) else { return }
            book.coverData = data
            PersistenceController.shared.save()
            selectedCoverImage = nil
        }
    }

    // MARK: - Sections

    private var coverSection: some View {
        Button {
            showCoverOptions = true
        } label: {
            Group {
                if let data = book.coverData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 160)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white, .blue)
                                .padding(6)
                        }
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 170)
                            .cornerRadius(8)
                        VStack(spacing: 6) {
                            Image(systemName: "camera")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Add Cover")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)

            HStack(spacing: 12) {
                switch book.status {
                case .notStarted:
                    actionButton("Start Reading", systemImage: "book.fill", color: .blue) {
                        viewModel.startReading(book)
                    }

                case .reading:
                    actionButton("Pause", systemImage: "pause.fill", color: .orange) {
                        viewModel.pauseBook(book, currentPage: Int(currentPage))
                    }
                    actionButton("Finish", systemImage: "checkmark.circle.fill", color: .green) {
                        viewModel.finishBook(book)
                        dismiss()
                    }

                case .paused:
                    actionButton("Resume", systemImage: "play.fill", color: .blue) {
                        viewModel.startReading(book)
                    }
                    actionButton("Finish", systemImage: "checkmark.circle.fill", color: .green) {
                        viewModel.finishBook(book)
                        dismiss()
                    }

                case .finished:
                    StatusBadge(status: .finished)
                    Spacer()
                    actionButton("Read Again", systemImage: "arrow.counterclockwise", color: .blue) {
                        book.status = .notStarted
                        book.dateStarted = nil
                        book.dateFinished = nil
                        book.currentPage = 0
                        currentPage = 0
                        PersistenceController.shared.save()
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.headline)

            Slider(
                value: $currentPage,
                in: 0...Double(book.pageCount),
                step: 1
            ) { editing in
                if !editing {
                    viewModel.updateCurrentPage(book, page: Int(currentPage))
                }
            }

            HStack {
                Text("Page \(Int(currentPage)) of \(book.pageCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Text("\(Int(book.progressFraction * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dates")
                .font(.headline)

            if let dateAdded = book.dateAdded {
                labeledDate("Added", date: dateAdded, isEditable: false) { _ in }
            }

            if book.status == .reading || book.status == .paused || book.status == .finished {
                labeledDate("Started", date: book.dateStarted ?? Date(), isEditable: true) { newDate in
                    book.dateStarted = newDate
                    PersistenceController.shared.save()
                }
            }

            if book.status == .finished {
                labeledDate("Finished", date: book.dateFinished ?? Date(), isEditable: true) { newDate in
                    book.dateFinished = newDate
                    PersistenceController.shared.save()
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func actionButton(_ title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }

    @ViewBuilder
    private func labeledDate(_ label: String, date: Date, isEditable: Bool, onChange: @escaping (Date) -> Void) -> some View {
        if isEditable {
            DatePicker(
                label,
                selection: Binding(
                    get: { date },
                    set: { onChange($0) }
                ),
                displayedComponents: .date
            )
            .font(.subheadline)
        } else {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
            }
        }
    }
}
