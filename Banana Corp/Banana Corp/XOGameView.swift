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
        VStack(spacing: 18) {
            StatusBar()

            Text("XO Training Grid")
                .font(.title2.weight(.bold))
                .foregroundColor(.yellow)

            Text(statusMessage)
                .font(.headline)
                .foregroundColor(statusColor)
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
            .font(.headline)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(Color.yellow)
            .foregroundColor(.black)
            .cornerRadius(10)

            Spacer(minLength: 0)
            HomeButton()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .background(Color.black.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var statusMessage: String {
        if let winner { return "\(winner) wins" }
        if isDraw { return "Draw" }
        return "Current turn: \(currentPlayer)"
    }

    private var statusColor: Color {
        if let winner { return colorForCell(winner) }
        if isDraw { return .white }
        return colorForCell(currentPlayer)
    }

    private func colorForCell(_ value: String) -> Color {
        switch value {
        case "X": return .yellow
        case "O": return .green
        default: return .white
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
                    .fill(Color.black)
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
