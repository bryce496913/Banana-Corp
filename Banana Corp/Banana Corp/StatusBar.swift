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
            // Left side: in-world carrier and real-world time
            HStack(spacing: 6) {
                Text("BANANA 5G")
                Text(currentTime, style: .time)
            }
            .padding(.leading, 10)
            .appText(.paragraph)
            
            Spacer()
            
            // Right side: Cell reception, Wifi reception, Battery icons
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
                    .foregroundColor(AppTheme.Colors.highlight)
            }
            .padding(.trailing, 10)
            .appText(.paragraph)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .frame(height: 20)
        .background(AppTheme.Colors.background)
    }
}
