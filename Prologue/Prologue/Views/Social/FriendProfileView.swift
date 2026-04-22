import SwiftUI

struct FriendProfileView: View {
    @Environment(SocialViewModel.self) private var socialVM
    let profile: Profile
    @State private var friendBooks: [UserBook] = []
    @State private var isLoading = true

    var inProgressBooks: [UserBook] { friendBooks.filter { $0.status == .inProgress } }
    var readBooks: [UserBook] { friendBooks.filter { $0.status == .read } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.username).font(.title2.bold())
                        if let genre = profile.favoriteGenre {
                            Text("Loves \(genre)").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Text("\(readBooks.count) books read").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding()

                if isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    if !inProgressBooks.isEmpty {
                        bookSection(title: "Currently Reading", books: inProgressBooks)
                    }
                    if !readBooks.isEmpty {
                        bookSection(title: "Read", books: readBooks)
                    }
                    if friendBooks.isEmpty {
                        ContentUnavailableView("Nothing to Show", systemImage: "books.vertical")
                    }
                }
            }
        }
        .navigationTitle(profile.username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            friendBooks = (try? await socialVM.loadFriendBooks(friendID: profile.id)) ?? []
            isLoading = false
        }
    }

    @ViewBuilder
    private func bookSection(title: String, books: [UserBook]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(books) { userBook in
                        let book = socialVM.friendBookCache[userBook.googleBooksID]
                        NavigationLink {
                            SocialBookDetailView(googleBooksID: userBook.googleBooksID)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                AsyncImage(url: book?.coverURL) { image in
                                    image.resizable().aspectRatio(2/3, contentMode: .fill)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8).fill(.quaternary).aspectRatio(2/3, contentMode: .fit)
                                }
                                .frame(width: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 2)

                                Text(book?.title ?? "…")
                                    .font(.caption.bold())
                                    .lineLimit(2)
                                    .frame(width: 80, alignment: .leading)

                                if let rating = userBook.rating {
                                    HStack(spacing: 1) {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= rating ? "star.fill" : "star")
                                                .font(.system(size: 8))
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
