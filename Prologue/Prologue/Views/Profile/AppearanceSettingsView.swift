import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("themeMode") private var themeMode: String = "system"

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $themeMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
