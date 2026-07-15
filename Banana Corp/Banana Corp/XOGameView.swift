//
//  XOGameView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct XOGameView: View {
    @State private var board = Array(repeating: "", count: 9)
    @State private var currentPlayer = "X"
    @State private var winner: String?
    @State private var isDraw = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        PhoneShellView(title: nil) {
            VStack(spacing: 18) {
                Text("XO Training Grid")
                .appText(.h1, color: AppTheme.Colors.highlight)

            Text(statusMessage)
                .appText(.h2, color: statusColor)
                .frame(minHeight: 28)

            GeometryReader { geometry in
                let boardSize = min(geometry.size.width - 32, geometry.size.height)

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(0..<board.count, id: \.self) { index in
                        CellView(value: board[index], color: colorForCell(board[index])) {
                            makeMove(at: index)
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(6)
                .frame(width: boardSize, height: boardSize)
                .background(Color.white)
                .cornerRadius(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: 360)

            Button("Reset Grid") {
                resetGame()
            }
            .buttonStyle(.modernPhoneProminent)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
        }
    }

    private var statusMessage: String {
        if let winner { return "\(winner) wins" }
        if isDraw { return "Draw" }
        return "Current turn: \(currentPlayer)"
    }

    private var statusColor: Color {
        if let winner { return colorForCell(winner) }
        if isDraw { return AppTheme.Colors.text }
        return colorForCell(currentPlayer)
    }

    private func colorForCell(_ value: String) -> Color {
        switch value {
        case "X": return .yellow
        case "O": return .green
        default: return AppTheme.Colors.text
        }
    }

    private func makeMove(at index: Int) {
        guard winner == nil else { return }
        guard !isDraw else { return }
        guard board[index].isEmpty else { return }

        board[index] = currentPlayer
        checkForWinner()

        if winner == nil && !isDraw {
            currentPlayer = currentPlayer == "X" ? "O" : "X"
        }
    }

    private func checkForWinner() {
        let winningCombinations: [[Int]] = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],
            [0, 3, 6], [1, 4, 7], [2, 5, 8],
            [0, 4, 8], [2, 4, 6]
        ]

        for combination in winningCombinations {
            let values = combination.map { board[$0] }
            if values.allSatisfy({ $0 == "X" }) || values.allSatisfy({ $0 == "O" }) {
                winner = values[0]
                return
            }
        }

        isDraw = !board.contains("")
    }

    private func resetGame() {
        board = Array(repeating: "", count: 9)
        currentPlayer = "X"
        winner = nil
        isDraw = false
    }
}

struct CellView: View {
    let value: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(AppTheme.Colors.surface)
                Text(value)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(value.isEmpty ? "Empty cell" : "Cell \(value)")
    }
}

struct XOGameView_Previews: PreviewProvider {
    static var previews: some View {
        XOGameView()
    }
}
