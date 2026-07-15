//
//  ContentView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isActive: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                ZStack {
                    Color.black
                    Image("Logo-Black")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200) // Adjust the size as needed
                }
                .opacity(isActive ? 1 : 0)
                //.animation(.easeInOut(duration: 1))
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { // Increased delay to 4 seconds
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: HomeScreenView(),
                    isActive: $isActive,
                    label: { EmptyView() }
                )
                .hidden()
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

