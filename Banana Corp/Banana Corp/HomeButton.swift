//
//  HomeButton.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct HomeButton: View {
    @State private var isHomeScreenActive = false

    var body: some View {
        NavigationLink(
            destination: HomeScreenView(),
            isActive: $isHomeScreenActive,
            label: {
                EmptyView()
            }
        )
        .buttonStyle(PlainButtonStyle())
        .background(
            Button(action: {
                self.isHomeScreenActive = true
            }) {
                Image(systemName: "house.circle.fill") // Apple icon set
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.yellow)
            }
        )
    }
}

