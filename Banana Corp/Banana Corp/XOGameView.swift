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
    @State private var winner: String? = nil

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
                .navigationBarHidden(true)

            VStack {
                StatusBar()
                
                Spacer()

                VStack(spacing: 5) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 5) {
                            ForEach(0..<3) { col in
                                CellView(value: self.board[row * 3 + col], onTap: {
                                    self.makeMove(at: row * 3 + col)
                                })
                            }
                        }
                    }
                }
                .cornerRadius(10)
                .padding()

                Spacer()

                if let winner = winner {
                    Text("Player \(winner) wins!")
                        .foregroundColor(winner == "X" ? .yellow : .green)
                        .font(.title)
                        .padding()

                    Button("Restart") {
                        self.resetGame()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Spacer()
            
                HomeButton()
                
            }
        }
    }

    private func makeMove(at index: Int) {
        guard board[index] == "" else { return }
        board[index] = currentPlayer
        checkForWinner()
        currentPlayer = currentPlayer == "X" ? "O" : "X"
    }

    private func checkForWinner() {
        let winningCombinations: [[Int]] = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6] // Diagonals
        ]

        for combination in winningCombinations {
            let values = combination.map { board[$0] }
            if Set(values) == ["X"] || Set(values) == ["O"] {
                winner = values[0]
                return
            }
        }

        if !board.contains("") {
            winner = "Nobody"
        }
    }

    private func resetGame() {
        board = Array(repeating: "", count: 9)
        currentPlayer = "X"
        winner = nil
    }
}

struct CellView: View {
    let value: String
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            self.onTap()
        }) {
            Text(value)
                .font(.system(size: 40))
                .frame(width: 70, height: 70)
                .background(Color.white)
                .cornerRadius(8)
        }
    }
}

struct XOGameView_Previews: PreviewProvider {
    static var previews: some View {
        XOGameView()
    }
}
