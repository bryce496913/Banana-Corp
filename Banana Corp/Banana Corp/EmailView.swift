//
//  EmailView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct EmailView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("Email View")
                .appText(.h1)

            Spacer()

            HomeButton()
        }
        .background(AppTheme.Colors.background)
    }
}
