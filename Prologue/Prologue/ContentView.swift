//
//  ContentView.swift
//  Prologue
//
//  Created by James Clabby on 4/19/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        if authViewModel.isSignedIn {
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
