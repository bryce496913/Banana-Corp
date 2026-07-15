//
//  PhotoAlbumView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct PhotoAlbumView: View {
    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            Text("Photo Album")
                .foregroundColor(.white)

            Spacer()

            HomeButton()
        }
        .background(Color.black)
    }
}
