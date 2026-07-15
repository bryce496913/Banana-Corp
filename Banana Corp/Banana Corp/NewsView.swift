//
//  NewsView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct NewsView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("News")
                .foregroundColor(.white)

            Spacer()

            HomeButton()
        }
        .background(Color.black)
    }
}
