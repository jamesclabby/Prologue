import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // Unit tests launch the host app but don't need a live Supabase connection.
        // Initialising with a placeholder avoids reading from the test bundle's Info.plist,
        // which doesn't have the xcconfig values substituted in.
        let env = ProcessInfo.processInfo.environment
        let isRunningTests = env["XCTestConfigurationFilePath"] != nil  // unit tests
                          || env["UI_TESTING"] == "1"                   // UI tests

        let url = isRunningTests
            ? URL(string: "https://placeholder.supabase.co")!
            : Config.supabaseURL

        let key = isRunningTests
            ? "placeholder"
            : Config.supabaseAnonKey

        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
