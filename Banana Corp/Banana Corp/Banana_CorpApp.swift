//
//  Banana_CorpApp.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

@main
struct Banana_CorpApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(appState)
        }
    }
}
