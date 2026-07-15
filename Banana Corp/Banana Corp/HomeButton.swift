//
//  HomeButton.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct HomeButton: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button {
            appState.goHome()
        } label: {
            Image(systemName: "house.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(Color.yellow)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Home")
    }
}
