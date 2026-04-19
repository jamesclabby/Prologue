import Foundation

enum Config {
    static let supabaseURL: URL = {
        guard let host = Bundle.main.infoDictionary?["SUPABASE_HOST"] as? String,
              !host.isEmpty else {
            fatalError("SUPABASE_HOST missing from Info.plist")
        }
        return URL(string: "https://\(host)")!
    }()

    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY missing from Info.plist")
        }
        return key
    }()

    static let googleBooksAPIKey: String = {
        guard let key = Bundle.main.infoDictionary?["GOOGLE_BOOKS_API_KEY"] as? String,
              !key.isEmpty else {
            fatalError("GOOGLE_BOOKS_API_KEY missing from Info.plist")
        }
        return key
    }()

    static let googleClientID: String = {
        guard let id = Bundle.main.infoDictionary?["GIDClientID"] as? String,
              !id.isEmpty else {
            fatalError("GIDClientID missing from Info.plist")
        }
        return id
    }()
}
