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
                .foregroundColor(.white)

            Spacer()

            HomeButton()
        }
        .background(Color.black)
    }
}
