//
//  WatchVideoView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct WatchVideoView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("Watch Video")
                .appText(.h1)

            Spacer()

            HomeButton()
        }
        .background(AppTheme.Colors.background)
    }
}
