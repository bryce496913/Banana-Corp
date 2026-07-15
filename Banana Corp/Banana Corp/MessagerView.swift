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
                .foregroundColor(.white)

            Spacer()

            HomeButton()
        }
        .background(Color.black)
    }
}
