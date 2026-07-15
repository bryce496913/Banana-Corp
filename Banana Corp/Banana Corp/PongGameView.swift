//
//  PongGameView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 2/2/24.
//

import SwiftUI

final class PongGameModel: ObservableObject {
    @Published var ballPosition: CGPoint = .zero
    @Published var ballVelocity: CGVector = .zero
    @Published var playerPaddleY: CGFloat = 0
    @Published var aiPaddleY: CGFloat = 0
    @Published var playerScore = 0
    @Published var aiScore = 0
    @Published var roundMessage: String?

    let paddleWidth: CGFloat = 8
    let paddleHeight: CGFloat = 72
    let ballSize: CGFloat = 14

    private let horizontalInset: CGFloat = 24
    private var didInitialize = false
    private var messageTicksRemaining = 0

    func reset(boardSize: CGSize) {
        guard boardSize.width > 0, boardSize.height > 0 else { return }
        didInitialize = true
        playerPaddleY = boardSize.height / 2
        aiPaddleY = boardSize.height / 2
        resetBall(boardSize: boardSize, towardPlayer: Bool.random())
        roundMessage = "Banana Corp training round armed"
        messageTicksRemaining = 90
    }

    func tick(boardSize: CGSize) {
        guard boardSize.width > 0, boardSize.height > 0 else { return }
        if !didInitialize { reset(boardSize: boardSize) }

        if messageTicksRemaining > 0 {
            messageTicksRemaining -= 1
            if messageTicksRemaining == 0 { roundMessage = nil }
        }

        ballPosition.x += ballVelocity.dx
        ballPosition.y += ballVelocity.dy

        if ballPosition.y <= ballSize / 2 {
            ballPosition.y = ballSize / 2
            ballVelocity.dy = abs(ballVelocity.dy)
        } else if ballPosition.y >= boardSize.height - ballSize / 2 {
            ballPosition.y = boardSize.height - ballSize / 2
            ballVelocity.dy = -abs(ballVelocity.dy)
        }

        moveAI(boardHeight: boardSize.height)
        handlePaddleCollisions(boardSize: boardSize)

        if ballPosition.x < -ballSize {
            aiScore += 1
            scorePoint(message: "Signal lost on left node", boardSize: boardSize, towardPlayer: true)
        } else if ballPosition.x > boardSize.width + ballSize {
            playerScore += 1
            scorePoint(message: "Right node captured a point", boardSize: boardSize, towardPlayer: false)
        }
    }

    func movePlayerPaddle(to y: CGFloat, boardHeight: CGFloat) {
        playerPaddleY = clampedPaddleY(y, boardHeight: boardHeight)
    }

    private func moveAI(boardHeight: CGFloat) {
        aiPaddleY += (ballPosition.y - aiPaddleY) * 0.08
        aiPaddleY = clampedPaddleY(aiPaddleY, boardHeight: boardHeight)
    }

    private func handlePaddleCollisions(boardSize: CGSize) {
        let playerRect = CGRect(
            x: horizontalInset - paddleWidth / 2,
            y: playerPaddleY - paddleHeight / 2,
            width: paddleWidth,
            height: paddleHeight
        )
        let aiRect = CGRect(
            x: boardSize.width - horizontalInset - paddleWidth / 2,
            y: aiPaddleY - paddleHeight / 2,
            width: paddleWidth,
            height: paddleHeight
        )
        let ballRect = CGRect(
            x: ballPosition.x - ballSize / 2,
            y: ballPosition.y - ballSize / 2,
            width: ballSize,
            height: ballSize
        )

        if ballVelocity.dx < 0, ballRect.intersects(playerRect) {
            ballPosition.x = playerRect.maxX + ballSize / 2
            bounce(from: playerPaddleY, direction: 1)
        } else if ballVelocity.dx > 0, ballRect.intersects(aiRect) {
            ballPosition.x = aiRect.minX - ballSize / 2
            bounce(from: aiPaddleY, direction: -1)
        }
    }

    private func bounce(from paddleY: CGFloat, direction: CGFloat) {
        let normalizedOffset = max(-1, min(1, (ballPosition.y - paddleY) / (paddleHeight / 2)))
        let speed: CGFloat = 4.6
        ballVelocity = CGVector(dx: direction * speed, dy: normalizedOffset * 3.2)
    }

    private func scorePoint(message: String, boardSize: CGSize, towardPlayer: Bool) {
        roundMessage = message
        messageTicksRemaining = 80
        resetBall(boardSize: boardSize, towardPlayer: towardPlayer)
    }

    private func resetBall(boardSize: CGSize, towardPlayer: Bool) {
        ballPosition = CGPoint(x: boardSize.width / 2, y: boardSize.height / 2)
        let xSpeed: CGFloat = towardPlayer ? -4 : 4
        ballVelocity = CGVector(dx: xSpeed, dy: CGFloat.random(in: -2.4...2.4))
    }

    private func clampedPaddleY(_ y: CGFloat, boardHeight: CGFloat) -> CGFloat {
        min(boardHeight - paddleHeight / 2, max(paddleHeight / 2, y))
    }
}

struct PongGameView: View {
    @StateObject private var model = PongGameModel()
    @State private var currentBoardSize: CGSize = .zero
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        PhoneShellView(title: nil) {
            VStack(spacing: 12) {
                Text("Pong")
                .appText(.h1, color: AppTheme.Colors.highlight)

            HStack(spacing: 28) {
                scoreBlock(label: "LEFT", score: model.playerScore)
                scoreBlock(label: "RIGHT", score: model.aiScore)
            }

            GeometryReader { geometry in
                let boardSize = CGSize(width: geometry.size.width - 24, height: geometry.size.height)

                PongBoardView(model: model, boardSize: boardSize)
                    .frame(width: boardSize.width, height: boardSize.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        currentBoardSize = boardSize
                        model.reset(boardSize: boardSize)
                    }
                    .onChange(of: boardSize) { newSize in
                        currentBoardSize = newSize
                        model.reset(boardSize: newSize)
                    }
            }
            .frame(maxHeight: 420)
            .padding(.horizontal, 12)

            Text(model.roundMessage ?? "Drag left paddle to train reflexes")
                .appText(.paragraph, color: model.roundMessage == nil ? AppTheme.Colors.text.opacity(0.75) : AppTheme.Colors.highlight)
                .frame(minHeight: 20)
            }
        }
        .onReceive(timer) { _ in
            model.tick(boardSize: currentBoardSize)
        }
    }

    private func scoreBlock(label: String, score: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .appText(.paragraph)
            Text("\(score)")
                .font(.system(size: AppTextStyle.h2.size, weight: .bold).monospacedDigit())
        }
        .foregroundColor(AppTheme.Colors.text)
    }
}

private struct PongBoardView: View {
    @ObservedObject var model: PongGameModel
    let boardSize: CGSize

    var body: some View {
        ZStack {
            Rectangle()
                .fill(AppTheme.Colors.background)

            VStack(spacing: 10) {
                ForEach(0..<18, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 3, height: 10)
                }
            }

            Rectangle()
                .fill(Color.white)
                .frame(width: model.paddleWidth, height: model.paddleHeight)
                .position(x: 24, y: model.playerPaddleY)

            Rectangle()
                .fill(Color.white)
                .frame(width: model.paddleWidth, height: model.paddleHeight)
                .position(x: boardSize.width - 24, y: model.aiPaddleY)

            Circle()
                .fill(AppTheme.Colors.highlight)
                .frame(width: model.ballSize, height: model.ballSize)
                .position(model.ballPosition)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    model.movePlayerPaddle(to: value.location.y, boardHeight: boardSize.height)
                }
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.Colors.accent, lineWidth: 2))
        .cornerRadius(12)
    }
}
