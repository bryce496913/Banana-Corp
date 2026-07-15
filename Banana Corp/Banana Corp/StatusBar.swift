//
//  StatusBar.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

// StatusBar.swift

import SwiftUI

struct StatusBar: View {
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var currentTime = Date()
    
    var body: some View {
        HStack {
            // Left side: Real-world time
            Text(currentTime, style: .time)
                .padding(.leading, 10)
                .foregroundColor(.white)
            
            Spacer()
            
            // Right side: Cell reception, Wifi reception, Battery icons
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
            .padding(.trailing, 10)
            .foregroundColor(.white)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .frame(height: 20)
        .background(Color.black)
    }
}
