//
//  SettingsView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("Settings")
                .appText(.h1)

            Spacer()

            HomeButton()
        }
        .background(AppTheme.Colors.background)
    }
}
