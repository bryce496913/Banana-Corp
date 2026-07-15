//
//  SocialXView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct SocialXView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("Social X")
                .foregroundColor(.white)

            Spacer()

            HomeButton()
        }
        .background(Color.black)
    }
}
