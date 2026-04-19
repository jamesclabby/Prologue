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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    await authViewModel.refreshSession()
                }
        }
    }
}
