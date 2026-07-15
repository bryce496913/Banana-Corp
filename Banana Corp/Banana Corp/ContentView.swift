//
//  ContentView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct LaunchView: View {
    @State private var isLaunchComplete = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if isLaunchComplete {
                HomeScreenView()
            } else {
                Image("Logo-Black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    isLaunchComplete = true
                }
            }
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
            .environmentObject(AppState())
    }
}
