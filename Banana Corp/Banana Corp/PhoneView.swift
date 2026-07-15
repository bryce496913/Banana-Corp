//
//  PhoneView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct PhoneView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("Phone")
                .foregroundColor(.white)

            Spacer()

            HomeButton()
        }
        .background(Color.black)
    }
}
