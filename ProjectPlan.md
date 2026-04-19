The Mission
Prologue is a high-performance, privacy-conscious iOS reading tracker designed to replace existing apps that are either cluttered, paywalled, or lacking in social depth. The goal is to provide a "vibe-coded," streamlined experience where users can manage their library, track granular reading progress (down to estimated word counts), and connect with friends without friction.

Technical Stack
Frontend: SwiftUI (iOS 17+) using a clean MVVM architecture.

Backend: Supabase for PostgreSQL database, Authentication (Google Sign-In), and Row Level Security (RLS).

Data Source: Google Books API for book metadata and cover art.

Integrations: AVFoundation for ISBN barcode scanning and Swift Charts for data visualization.

MVP Core Pillars
Personal Library: A central hub to track books across four primary states: Want to Read, In Progress, Read, and Did Not Finish (DNF).

Granular Progress: Users track reading by page number or percentage. The app estimates "Words Read" based on page counts (approx. 275 words/page).

The Discovery Engine: A robust search system combining text queries (Title/Author) with a high-speed ISBN camera scanner.

Social Graph: A relationship-based system where users can add friends to see their reading activity, while maintaining strict "Private Mode" toggles for sensitive titles.

Insights: A dedicated statistics tab that gamifies reading through annual goals and visualizes volume over time (Weekly/Monthly/Yearly).

Development Principles
Clean Data: Use a relational Postgres schema in Supabase to handle complex friendships and library joins.

Native Feel: Prioritize standard SwiftUI components to ensure the app feels like it belongs on an iPhone.

Performance: Implement efficient caching for book metadata to minimize API calls and ensure a snappy UI.

----------

Project Plan: Prologue (iOS Reading Tracker)
Phase 1: Foundation & Data Architecture
Goal: Initialize the SwiftUI project and establish the Supabase schema.

Tasks:

Initialize a new SwiftUI project named Prologue with a directory structure following MVVM (Models, Views, ViewModels, Services).

Create a SupabaseManager service to handle client initialization.

Generate a SQL migration script for Supabase:

profiles: id (uuid), username (text), favorite_genre (text), created_at.

user_books: id, user_id, google_books_id, status (enum: want_to_read, in_progress, read, dnf), current_page, total_pages, is_private (bool), rating, review_text.

friendships: requester_id, receiver_id, status (enum: pending, accepted).

Implement Row Level Security (RLS) policies to ensure data privacy.

Phase 2: Authentication (Google Sign-In)
Goal: Secure user access and link it to Supabase identities.

Tasks:

Add the GoogleSignIn dependency via Swift Package Manager.

Configure Info.plist with the necessary URL Types and Client IDs.

Build a LoginView and AuthViewModel to handle the OAuth flow.

Implement a root ContentView that switches between LoginView and the main AppTabView based on auth state.

Phase 3: Data Layer & Google Books Integration
Goal: Connect the app to external book metadata.

Tasks:

Create a Book model that maps Google Books API responses to Swift objects.

Implement logic to calculate Estimated Word Count (Page Count * 275).

Build a BookSearchService using URLSession to query the Google Books API by Title, Author, and ISBN.

Integrate AVFoundation to create an ISBNScannerView for camera-based lookups.

Phase 4: The Library & Progress Engine
Goal: Build the core user experience for managing personal books.

Tasks:

Build the LibraryView with segmented pickers for different reading statuses (Want to Read, In Progress, etc.).

Create a BookDetailView showing metadata, word counts, and an "Update Progress" section.

Implement the "Progress Slider" logic that calculates percentage completion and updates the user_books table in Supabase.

Add the "Custom Lists" functionality to allow users to group books outside of standard statuses.

Phase 5: Social Graph & Privacy
Goal: Enable user-to-user interaction while respecting privacy toggles.

Tasks:

Build the SocialView to search for users and display "Pending Requests."

Implement "Friend Profile" views that fetch a friend's user_books while strictly filtering out items where is_private is true.

Add push notification logic (or local notifications for MVP) for friend request alerts.

Phase 6: Insights & Analytics
Goal: Transform raw reading data into visual motivation.

Tasks:

Create a StatsViewModel that aggregates data from Supabase (e.g., total words read, books per month).

Integrate Swift Charts to display reading volume over time (Week/Month/Year).

Build the "Annual Goal" progress ring on the InsightsView.

Tips for Claude Code Success
State Management: Explicitly tell Claude to use @Observable (if targeting iOS 17+) or @StateObject to keep the UI in sync with Supabase.

The "Context" Command: If you get stuck on an error, run /context so Claude can see the full state of your files.

Incremental Testing: After Phase 1 and 2, ask Claude to: "Run the app in the simulator and verify the Supabase connection is successful before we move to the Search API."