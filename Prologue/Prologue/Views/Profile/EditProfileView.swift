import SwiftUI

struct EditProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var favoriteGenre: String = ""

    var body: some View {
        Form {
            Section("Identity") {
                LabeledContent("Display Name") {
                    TextField("Your name", text: $displayName)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Username") {
                    TextField("handle", text: $username)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            Section("Preferences") {
                LabeledContent("Favorite Genre") {
                    TextField("e.g. Fantasy", text: $favoriteGenre)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(authVM.isSaving ? "Saving…" : "Save") {
                    Task {
                        await authVM.updateProfile(
                            displayName: displayName.isEmpty ? nil : displayName,
                            username: username,
                            favoriteGenre: favoriteGenre.isEmpty ? nil : favoriteGenre
                        )
                        if authVM.error == nil { dismiss() }
                    }
                }
                .disabled(authVM.isSaving || username.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            displayName   = authVM.profile?.displayName ?? ""
            username      = authVM.profile?.username ?? ""
            favoriteGenre = authVM.profile?.favoriteGenre ?? ""
        }
    }
}
