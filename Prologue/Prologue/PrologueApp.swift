//
//  PrologueApp.swift
//  Prologue
//
//  Created by James Clabby on 4/19/26.
//

import SwiftUI
import GoogleSignIn

@main
struct PrologueApp: App {
    @State private var authViewModel = AuthViewModel()
    @AppStorage("themeMode") private var themeMode: String = "system"

    private var resolvedColorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .preferredColorScheme(resolvedColorScheme)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    await authViewModel.refreshSession()
                }
        }
    }
}
