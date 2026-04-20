//
//  ContentView.swift
//  Prologue
//
//  Created by James Clabby on 4/19/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    private var isUITestingAuthenticated: Bool {
        ProcessInfo.processInfo.environment["UI_TESTING_AUTHENTICATED"] == "1"
    }

    var body: some View {
        if isUITestingAuthenticated || authViewModel.isSignedIn {
            AppTabView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
