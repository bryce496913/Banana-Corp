//
//  FlapFlapGameView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

struct FlapFlapGameView: View {
    @State private var isGameRunning = false
    @State private var playerPosition: CGFloat = 150
    @State private var playerVelocity: CGFloat = 0
    @State private var score = 0
    @State private var pipes: [Pipe] = []

    var body: some View {
        VStack {
            StatusBar()

            Spacer()

            if isGameRunning {
                ZStack {
                    FlappyBirdGame(playerPosition: $playerPosition, playerVelocity: $playerVelocity, score: $score, pipes: $pipes, stopGame: stopGame)
                        .onTapGesture {
                            // Handle tap gesture to lift the player character
                            playerVelocity = -10  // Adjust the lifting force as needed
                        }
                        .onAppear {
                            // Start the game logic
                            startGame()
                        }

                    // Draw pipes
                    ForEach(pipes) { pipe in
                        Group {
                            // Top pipe
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: pipe.width, height: pipe.topHeight)
                                .offset(x: pipe.x, y: pipe.y - pipe.topHeight)

                            // Bottom pipe
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: pipe.width, height: pipe.bottomHeight)
                                .offset(x: pipe.x, y: pipe.y + pipe.gap)
                        }
                    }
                }
            }
            else {
                VStack {
                    Text("Start Screen")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                        .padding()

                    Button("Start Game") {
                        startGame()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }

            Spacer()

            HomeButton()
        }
    }

    private func startGame() {
        isGameRunning = true
        score = 0
        pipes = []
        startPipeGeneration()

        let gravity: CGFloat = 0.5

        let gameTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            // Update player position
            playerVelocity += gravity
            playerPosition += playerVelocity

            // Check for collisions with pipes
            for pipe in pipes {
                if playerPosition < pipe.topHeight || playerPosition > (pipe.y + pipe.gap) {
                    if pipe.x < 150 && pipe.x + pipe.width > 100 {
                        stopGame()
                        timer.invalidate()
                    }
                }
            }

            // Remove off-screen pipes
            pipes.removeAll { pipe in
                let isVisible = pipe.x + pipe.width > 0
                if !isVisible && pipe.x == 0 {
                    score += 1
                }
                return !isVisible
            }

            // Generate new pipes every 3 seconds
            if Int(timer.fireDate.timeIntervalSinceNow) % 3 == 0 {
                generatePipe()
            }

            // Update pipe positions
            for i in 0..<pipes.count {
                pipes[i].x -= 5
            }
        }
        gameTimer.fire()
    }

    private func stopGame() {
        isGameRunning = false
        pipes = [] // Reset pipes if needed

        let gameOverView = GameOverView(score: score) {
            // Restart game action
            startGame()
        }

        UIApplication.shared.windows.first?.rootViewController?.present(UIHostingController(rootView: gameOverView), animated: true, completion: nil)
    }

    private func startPipeGeneration() {
        let pipeGenerationTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            generatePipe()
        }
        pipeGenerationTimer.fire()
    }

    private func generatePipe() {
        let gapHeight: CGFloat = 100
        let pipeWidth: CGFloat = 50
        let screenHeight = UIScreen.main.bounds.height
        let randomY = CGFloat.random(in: 50...(screenHeight - gapHeight - 50))

        pipes.append(Pipe(x: 400, y: randomY, width: pipeWidth, gap: gapHeight))
    }
}

struct GameOverView: View {
    var score: Int
    var restartAction: () -> Void

    var body: some View {
        VStack {
            Text("Game Over")
                .font(.title)
                .foregroundColor(.red)
                .padding()

            Text("Score: \(score)")
                .font(.headline)
                .padding()

            Button("Restart Game") {
                restartAction()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct FlappyBirdGame: View {
    @Binding var playerPosition: CGFloat
    @Binding var playerVelocity: CGFloat
    @Binding var score: Int
    @Binding var pipes: [Pipe]
    var stopGame: () -> Void
    
    var body: some View {
        Image(systemName: "applelogo")
            .resizable()
            .frame(width: 50, height: 50)
            .offset(x: 100, y: playerPosition)
            .animation(.linear)
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                updateGame()
            }
            .gesture(
                TapGesture()
                    .onEnded {
                        // Handle tap gesture to lift the player character
                        playerVelocity = -10  // Adjust the lifting force as needed
                    }
            )
    }
    
    private func updateGame() {
        // Apply gravity to descend player
        playerVelocity += 0.5
        
        // Update player vertical position
        playerPosition += playerVelocity
        
        // Check for pipe collisions
        for pipe in pipes {
            if playerPosition < pipe.topHeight || playerPosition > (pipe.y + pipe.gap) {
                if pipe.x < 150 && pipe.x + pipe.width > 100 {
                    stopGame()
                }
            }
        }
    }
}

struct Pipe: Identifiable, Hashable {
    var id: UUID = UUID()
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var gap: CGFloat

    var topHeight: CGFloat {
        return y
    }

    var bottomHeight: CGFloat {
        return UIScreen.main.bounds.height - (y + gap)
    }
}

struct FlapFlapGameView_Previews: PreviewProvider {
    static var previews: some View {
        FlapFlapGameView()
    }
}
