import SwiftUI

struct AppTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var libraryVM = LibraryViewModel()
    @State private var searchVM = SearchViewModel()
    @State private var socialVM = SocialViewModel()
    @State private var statsVM = StatsViewModel()

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .environment(libraryVM)

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .environment(searchVM)
                .environment(libraryVM)

            SocialView()
                .tabItem { Label("Friends", systemImage: "person.2") }
                .badge(socialVM.pendingRequests.count)
                .environment(socialVM)
                .environment(libraryVM)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .environment(statsVM)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .environment(socialVM)
                .environment(libraryVM)
        }
        .task {
            // userID uses currentUser?.id as primary — it's set before AppTabView ever
            // appears, whereas profile?.id can still be nil if loadOrCreateProfile hasn't
            // finished yet when this task fires.
            guard let userID = authViewModel.userID else { return }
            await libraryVM.loadLibrary(userID: userID)
            await socialVM.loadFriends(userID: userID)
            await statsVM.loadStats(userID: userID)
        }
    }
}

#Preview {
    AppTabView()
        .environment(AuthViewModel())
}
