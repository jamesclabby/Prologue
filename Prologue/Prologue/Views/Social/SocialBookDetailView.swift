import SwiftUI

struct SocialBookDetailView: View {
    @Environment(SocialViewModel.self) private var socialVM
    @Environment(LibraryViewModel.self) private var libraryVM
    @Environment(AuthViewModel.self) private var authVM

    let googleBooksID: String
    @State private var book: Book?
    @State private var friendReviews: [FriendReview] = []
    @State private var isLoading = true
    @State private var showAddSheet = false
    @State private var isDescriptionExpanded = false

    private static let descriptionThreshold = 200

    private var alreadyInLibrary: Bool {
        libraryVM.userBooks.contains { $0.googleBooksID == googleBooksID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Cover + basic info
                HStack(alignment: .top, spacing: 16) {
                    AsyncImage(url: book?.coverURL) { image in
                        image.resizable().aspectRatio(2/3, contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10).fill(.quaternary)
                    }
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(book?.title ?? "Loading…")
                            .font(.title3.bold())
                            .lineLimit(3)
                        Text(book?.authorsDisplay ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let year = book?.publishedDate.flatMap({ String($0.prefix(4)) }) {
                            Text(year).font(.caption).foregroundStyle(.secondary)
                        }
                        if let pages = book?.pageCount {
                            Label("\(pages) pages", systemImage: "doc.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let publisher = book?.publisher {
                            Text(publisher)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                        }
                        if let genre = book?.genre {
                            Text(genre)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                // Description
                if let rawDescription = book?.description {
                    let description = rawDescription.strippedHTML
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About").font(.headline)
                        if description.count <= Self.descriptionThreshold || isDescriptionExpanded {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(String(description.prefix(Self.descriptionThreshold)) + "…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if description.count > Self.descriptionThreshold {
                            Button(isDescriptionExpanded ? "Show less" : "Show more") {
                                isDescriptionExpanded.toggle()
                            }
                            .font(.subheadline.bold())
                        }
                    }
                }

                // Friends' ratings and reviews
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Friends' Ratings & Reviews").font(.headline)
                    if isLoading {
                        ProgressView()
                    } else if friendReviews.isEmpty {
                        Text("No friends have reviewed this book yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(friendReviews) { review in
                            FriendReviewRow(review: review)
                            if review.id != friendReviews.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(book?.title ?? "Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if alreadyInLibrary {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .disabled(book == nil)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            if let book {
                AddBookSheet(book: book)
                    .environment(libraryVM)
                    .environment(authVM)
            }
        }
        .task {
            async let bookFetch = socialVM.bookMetadata(for: googleBooksID)
            async let reviewsFetch = socialVM.loadFriendReviews(for: googleBooksID)
            book = await bookFetch
            friendReviews = await reviewsFetch
            isLoading = false
        }
    }
}

struct FriendReviewRow: View {
    let review: FriendReview

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.profile.username).font(.subheadline.bold())
                Spacer()
                if let rating = review.userBook.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
            if let text = review.userBook.reviewText, !text.isEmpty {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - HTML stripping

private extension String {
    var strippedHTML: String {
        var s = self
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
        while s.contains("\n\n\n") {
            s = s.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
