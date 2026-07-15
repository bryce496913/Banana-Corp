//
//  VRExperienceView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct VRExperienceView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("VR Experience")
                .appText(.h1)

            Spacer()

            HomeButton()
        }
        .background(AppTheme.Colors.background)
    }
}
