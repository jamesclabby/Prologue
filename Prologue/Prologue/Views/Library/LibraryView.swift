import SwiftUI

struct LibraryView: View {
    @Environment(LibraryViewModel.self) private var libraryVM
    @State private var selectedStatus: ReadingStatus = .inProgress

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Status", selection: $selectedStatus) {
                    ForEach(ReadingStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                let books = libraryVM.books(for: selectedStatus)

                if libraryVM.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if books.isEmpty {
                    ContentUnavailableView(
                        "No Books Here",
                        systemImage: "book.closed",
                        description: Text("Search for books to add to your \(selectedStatus.displayName) list.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 140))], spacing: 16) {
                            ForEach(books) { userBook in
                                NavigationLink(destination: BookDetailView(userBook: userBook)) {
                                    BookCoverCell(
                                        userBook: userBook,
                                        book: libraryVM.bookCache[userBook.googleBooksID]
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Library")
        }
    }
}


struct BookCoverCell: View {
    let userBook: UserBook
    let book: Book?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: book?.coverURL) { image in
                image.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .aspectRatio(2/3, contentMode: .fit)
                    .overlay {
                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(.tertiary)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 2)

            if userBook.status == .inProgress {
                ProgressView(value: userBook.progressPercent, total: 100)
                    .tint(.accentColor)
            }

            Text(book?.title ?? "Loading…")
                .font(.caption.bold())
                .lineLimit(2)
        }
    }
}

#Preview {
    LibraryView()
        .environment(LibraryViewModel())
        .environment(AuthViewModel())
}
