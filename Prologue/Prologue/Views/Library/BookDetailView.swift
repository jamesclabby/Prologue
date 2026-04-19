import SwiftUI

struct BookDetailView: View {
    @Environment(LibraryViewModel.self) private var libraryVM
    @State private var userBook: UserBook
    @State private var originalUserBook: UserBook
    @State private var book: Book?
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var showSaveToast = false
    @State private var pageInput: String = ""

    init(userBook: UserBook) {
        _userBook = State(initialValue: userBook)
        _originalUserBook = State(initialValue: userBook)
        _pageInput = State(initialValue: "\(userBook.currentPage)")
    }

    private var hasChanges: Bool { userBook != originalUserBook }

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
                        Text(book?.title ?? "Loading…").font(.headline)
                        Text(book?.authorsDisplay ?? "")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if let pages = book?.pageCount {
                            Label("\(pages) pages · ~\(book!.estimatedWordCount.formatted()) words",
                                  systemImage: "doc.text")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Status picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status").font(.headline)
                    Picker("Status", selection: $userBook.status) {
                        ForEach(ReadingStatus.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: userBook.status) { _, newStatus in
                        // Mark fully read when moved to "read" so word count is accurate
                        if newStatus == .read, let total = userBook.totalPages {
                            userBook.currentPage = total
                            pageInput = "\(total)"
                        }
                    }
                }

                // Progress — shown for in-progress books only
                if userBook.status == .inProgress, let totalPages = userBook.totalPages, totalPages > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Progress").font(.headline)

                        // Page input row
                        HStack(spacing: 6) {
                            Text("Page")
                                .font(.subheadline)
                            TextField("0", text: $pageInput)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 64)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: pageInput) { _, raw in
                                    if let parsed = Int(raw) {
                                        userBook.currentPage = min(max(parsed, 0), totalPages)
                                    }
                                }
                            Text("of \(totalPages)")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(userBook.progressPercent))%")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        // Slider (syncs pageInput when dragged)
                        Slider(
                            value: Binding(
                                get: { Double(userBook.currentPage) },
                                set: {
                                    userBook.currentPage = Int($0)
                                    pageInput = "\(Int($0))"
                                }
                            ),
                            in: 0...Double(totalPages),
                            step: 1
                        )
                        .tint(Color.accentColor)

                        Text("~\(userBook.estimatedWordsRead.formatted()) words read")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                // Rating
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating").font(.headline)
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= (userBook.rating ?? 0) ? "star.fill" : "star")
                                .foregroundStyle(star <= (userBook.rating ?? 0) ? .yellow : .secondary)
                                .font(.title2)
                                .onTapGesture {
                                    userBook.rating = userBook.rating == star ? nil : star
                                }
                        }
                    }
                }

                // Review
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review").font(.headline)
                    TextEditor(text: Binding(
                        get: { userBook.reviewText ?? "" },
                        set: { userBook.reviewText = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Privacy toggle
                Toggle("Private (hide from friends)", isOn: $userBook.isPrivate)
                    .font(.subheadline)

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Remove from Library", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if hasChanges {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showSaveToast {
                Text("Saved!")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 4)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: showSaveToast)
        .animation(.default, value: hasChanges)
        .task {
            book = libraryVM.bookCache[userBook.googleBooksID]
        }
        .confirmationDialog("Remove this book?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                Task { try? await libraryVM.removeBook(userBook: userBook) }
            }
        }
    }

    private func save() async {
        isSaving = true
        try? await libraryVM.updateProgress(userBook: userBook)
        originalUserBook = userBook  // reset dirty tracking
        isSaving = false
        withAnimation { showSaveToast = true }
        try? await Task.sleep(for: .seconds(2))
        withAnimation { showSaveToast = false }
    }
}
