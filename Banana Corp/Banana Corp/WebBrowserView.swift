//
//  WebBrowserView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct WebBrowserView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("Web Browser")
                .foregroundColor(.white)

            Spacer()

            HomeButton()
        }
        .background(Color.black)
    }
}
