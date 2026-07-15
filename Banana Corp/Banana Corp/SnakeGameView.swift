//
//  SnakeGameView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct SnakeGameView: View {
    @State private var snakeGame = SnakeGame()
    @State private var direction: Direction = .down
    
    var body: some View {
        VStack {
            StatusBar()
            // Top Half - Game Area
            GameAreaView(snakeGame: $snakeGame, dir: $direction)
            
            // Bottom Half - Control Pad
            ControlPadView(direction: $direction) { dir in
                snakeGame.move(dir)
            }
            .frame(maxHeight: .infinity)
            
        }
        .background(Color.black)
        .navigationBarHidden(true)
    }
}

struct GameAreaView: View {
    @Binding var snakeGame: SnakeGame
    
    @State private var startPos: CGPoint = .zero
    @State private var isStarted = true
    @State private var gameOver = false
    //@State private var dir = Direction.down
    @State private var posArray = [CGPoint(x: 0, y: 0)]
    @State private var foodPos = CGPoint(x: 0, y: 0)
    
    @Binding var dir: Direction
    
    private let snakeSize: CGFloat = 10
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    private let minX = UIScreen.main.bounds.minX
    private let maxX = UIScreen.main.bounds.maxX
    private let minY = UIScreen.main.bounds.minY
    private let maxY = UIScreen.main.bounds.maxY / 2.5
    
    // New variables for UI changes
    private let borderWidth: CGFloat = 15
    private let borderColor = Color.yellow
    
    var body: some View {
        ZStack {
            Color.black
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        Color.white
                            .border(borderColor, width: borderWidth)
                            .clipShape(Rectangle())
                        ForEach(0..<posArray.count, id: \.self) { index in
                            Rectangle()
                                .frame(width: self.snakeSize, height: self.snakeSize)
                                .position(self.posArray[index])
                        }
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: snakeSize, height: snakeSize)
                            .position(foodPos)
                        if self.gameOver {
                            VStack(spacing: 8.0) {
                                Text("Game Over").font(.headline)
                                Text("Your score: \(self.posArray.count - 1)").font(.subheadline)
                                
                                Button(action: {
                                    self.restartGame()
                                }) {
                                    Text("Restart")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear() {
            self.foodPos = self.changeRectPos()
            self.posArray[0] = self.changeRectPos()
        }
        .onReceive(timer) { (_) in
            if !self.gameOver {
                self.changeDirection()
                if self.posArray[0] == self.foodPos {
                    self.posArray.append(self.posArray[0])
                    self.foodPos = self.changeRectPos()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func restartGame() {
        // Reset the game state
        self.posArray = [self.changeRectPos()]
        self.foodPos = self.changeRectPos()
        self.dir = .down
        self.gameOver = false
    }
    
    private func changeRectPos() -> CGPoint {
        let rows = Int((maxX - 2 * borderWidth) / snakeSize)
        let cols = Int((maxY - 2 * borderWidth) / snakeSize)
        
        let randomX = Int.random(in: 1..<rows) * Int(snakeSize)
        let randomY = Int.random(in: 1..<cols) * Int(snakeSize)
        
        return CGPoint(x: CGFloat(randomX) + borderWidth, y: CGFloat(randomY) + borderWidth)
    }
    
    private func changeDirection() {
        if self.posArray[0].x < minX + borderWidth || self.posArray[0].x > maxX - borderWidth && !gameOver {
            gameOver.toggle()
        }
        else if self.posArray[0].y < minY + borderWidth || self.posArray[0].y > maxY - borderWidth && !gameOver {
            gameOver.toggle()
        }
        var prev = posArray[0]
        // Use the direction set by the control pad
        // Note: No need to check the direction here; it's already set by the control pad
        if dir == .down {
            self.posArray[0].y += snakeSize
        } else if dir == .up {
            self.posArray[0].y -= snakeSize
        } else if dir == .left {
            self.posArray[0].x -= snakeSize
        } else if dir == .right {
            self.posArray[0].x += snakeSize
        }
        
        for index in 1..<posArray.count {
            let current = posArray[index]
            posArray[index] = prev
            prev = current
        }
    }
}

struct ControlPadView: View {
    @Binding var direction: Direction // Add binding for direction
    var onDirectionChanged: (Direction) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    self.direction = .up
                    onDirectionChanged(.up)
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
            }
            HStack {
                Button(action: {
                    self.direction = .left
                    onDirectionChanged(.left)
                }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: {
                    self.direction = .right
                    onDirectionChanged(.right)
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
            }
            HStack {
                Button(action: {
                    self.direction = .down
                    onDirectionChanged(.down)
                }) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
            }
            .padding()
            HomeButton()
        }
        .padding()
    }
}


enum Direction {
    case up, down, left, right
}

class SnakeGame: ObservableObject {
    @Published var snakeLength = 0
    
    func move(_ direction: Direction) {
        // Implement your snake movement logic here
        // For simplicity, just increment the snake length for demonstration
        snakeLength += 1
    }
}

struct SnakeGameView_Previews: PreviewProvider {
    static var previews: some View {
        SnakeGameView()
    }
}

