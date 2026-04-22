import SwiftUI
import StoreKit

struct SupportLegalView: View {
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        Form {
            Section("Support") {
                Button("Rate Prologue") {
                    requestReview()
                }
                Link("Contact Support", destination: URL(string: "mailto:support@prologue.app")!)
            }

            Section("Legal") {
                Link("Privacy Policy", destination: URL(string: "https://prologue.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://prologue.app/terms")!)
            }
        }
        .navigationTitle("Support & Legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
