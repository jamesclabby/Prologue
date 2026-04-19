import SwiftUI

struct SearchView: View {
    @Environment(SearchViewModel.self) private var searchVM
    @Environment(LibraryViewModel.self) private var libraryVM
    @Environment(AuthViewModel.self) private var authVM
    @State private var showScanner = false
    @State private var selectedBook: Book?

    var body: some View {
        NavigationStack {
            @Bindable var vm = searchVM

            List {
                if searchVM.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(searchVM.results) { book in
                        BookSearchRow(book: book)
                            .onTapGesture { selectedBook = book }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $vm.query, prompt: "Title, author, or ISBN…")
            .onChange(of: searchVM.query) { _, new in
                searchVM.onQueryChanged(new)
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                ISBNScannerView { isbn in
                    showScanner = false
                    Task { await searchVM.fetchByISBN(isbn) }
                }
            }
            .sheet(item: $selectedBook) { book in
                AddBookSheet(book: book)
                    .environment(libraryVM)
                    .environment(authVM)
            }
        }
    }
}

struct BookSearchRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: book.coverURL) { image in
                image.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6).fill(.quaternary)
            }
            .frame(width: 44, height: 66)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title).font(.headline).lineLimit(2)
                Text(book.authorsDisplay).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                if let pages = book.pageCount {
                    Text("\(pages) pages · ~\(book.estimatedWordCount.formatted()) words")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddBookSheet: View {
    @Environment(LibraryViewModel.self) private var libraryVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    let book: Book
    @State private var selectedStatus: ReadingStatus = .wantToRead
    @State private var isAdding = false
    @State private var addError: String?

    private var userID: UUID? { authVM.userID }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    BookSearchRow(book: book)
                }
                Section("Add to list") {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(ReadingStatus.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.inline)
                }
                if let addError {
                    Section {
                        Text(addError)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isAdding ? "Adding…" : "Add") {
                        guard let userID else {
                            addError = "Not signed in. Please restart the app."
                            return
                        }
                        isAdding = true
                        addError = nil
                        Task {
                            do {
                                try await libraryVM.addBook(book, status: selectedStatus, userID: userID)
                                dismiss()
                            } catch {
                                addError = error.localizedDescription
                                isAdding = false
                            }
                        }
                    }
                    .disabled(isAdding || userID == nil)
                }
            }
        }
    }
}
