// file: ContentView.swift
// what: the main screen of the app.
// story: us01

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("settings") {
                    NavigationLink("security") {
                        SecurityView()
                    }
                }
            }
            .navigationTitle("fitvault")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppModel())
}
