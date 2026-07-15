//
//  MessagerView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct MessagerView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("Messager")
                .appText(.h1)

            Spacer()

            HomeButton()
        }
        .background(AppTheme.Colors.background)
    }
}
