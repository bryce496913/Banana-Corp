//
//  SnakeGameView.swift
//  Banana Corp
//
//  Created by Aditi Abrol on 1/2/24.
//

import SwiftUI

final class SnakeGameModel: ObservableObject {
    enum Direction {
        case up, down, left, right

        var vector: CGPoint {
            switch self {
            case .up: return CGPoint(x: 0, y: -1)
            case .down: return CGPoint(x: 0, y: 1)
            case .left: return CGPoint(x: -1, y: 0)
            case .right: return CGPoint(x: 1, y: 0)
            }
        }

        func isOpposite(of other: Direction) -> Bool {
            switch (self, other) {
            case (.up, .down), (.down, .up), (.left, .right), (.right, .left): return true
            default: return false
            }
        }
    }

    @Published var snake: [CGPoint] = []
    @Published var food: CGPoint = .zero
    @Published var direction: Direction = .right
    @Published var score = 0
    @Published var isGameOver = false

    let gridSize = 20

    init() {
        reset()
    }

    func reset() {
        let start = CGPoint(
            x: CGFloat(Int.random(in: 5..<(gridSize - 5))),
            y: CGFloat(Int.random(in: 5..<(gridSize - 5)))
        )
        snake = [start]
        direction = .right
        score = 0
        isGameOver = false
        spawnFood()
    }

    func changeDirection(_ newDirection: Direction) {
        guard !newDirection.isOpposite(of: direction) else { return }
        direction = newDirection
    }

    func tick() {
        guard !isGameOver, let head = snake.first else { return }

        let vector = direction.vector
        let nextHead = CGPoint(x: head.x + vector.x, y: head.y + vector.y)

        guard isInsideGrid(nextHead) else {
            isGameOver = true
            return
        }

        let willEat = nextHead == food
        let bodyToCheck = willEat ? snake : Array(snake.dropLast())
        guard !bodyToCheck.contains(nextHead) else {
            isGameOver = true
            return
        }

        snake.insert(nextHead, at: 0)

        if willEat {
            score += 1
            spawnFood()
        } else {
            snake.removeLast()
        }
    }

    private func isInsideGrid(_ point: CGPoint) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < CGFloat(gridSize) && point.y < CGFloat(gridSize)
    }

    private func spawnFood() {
        let openCells = (0..<gridSize).flatMap { x in
            (0..<gridSize).map { y in CGPoint(x: CGFloat(x), y: CGFloat(y)) }
        }.filter { !snake.contains($0) }

        food = openCells.randomElement() ?? .zero
    }
}

struct SnakeGameView: View {
    @StateObject private var model = SnakeGameModel()
    private let timer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            StatusBar()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Snake")
                        .appText(.h1, color: AppTheme.Colors.highlight)
                    Text("Banana Corp reflex audit")
                        .appText(.paragraph)
                }
                Spacer()
                Text("Score \(model.score)")
                    .font(.system(size: AppTextStyle.h2.size, weight: AppTextStyle.h2.weight).monospacedDigit())
            }
            .foregroundColor(AppTheme.Colors.highlight)
            .padding(.horizontal, AppTheme.Spacing.lg)

            GeometryReader { geometry in
                let boardSize = min(geometry.size.width - 24, geometry.size.height)
                let cellSize = boardSize / CGFloat(model.gridSize)

                ZStack {
                    Rectangle()
                        .fill(AppTheme.Colors.background)
                    gridLines(cellSize: cellSize, boardSize: boardSize)
                    ForEach(Array(model.snake.enumerated()), id: \.offset) { index, segment in
                        Rectangle()
                            .fill(index == 0 ? Color.yellow : Color.green)
                            .frame(width: cellSize - 1, height: cellSize - 1)
                            .position(x: segment.x * cellSize + cellSize / 2, y: segment.y * cellSize + cellSize / 2)
                    }
                    Circle()
                        .fill(Color.red)
                        .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                        .position(x: model.food.x * cellSize + cellSize / 2, y: model.food.y * cellSize + cellSize / 2)

                    if model.isGameOver {
                        VStack(spacing: 10) {
                            Text("Game Over")
                                .appText(.h1, color: AppTheme.Colors.highlight)
                            Text("Score: \(model.score)")
                                .font(.system(size: AppTextStyle.h2.size, weight: AppTextStyle.h2.weight).monospacedDigit())
                            Button("Restart") { model.reset() }
                                .buttonStyle(.appPrimary)
                        }
                        .padding(24)
                        .background(AppTheme.Colors.surface.opacity(0.9))
                        .foregroundColor(AppTheme.Colors.text)
                        .cornerRadius(16)
                    }
                }
                .frame(width: boardSize, height: boardSize)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.Colors.accent, lineWidth: 3))
                .cornerRadius(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: 390)

            SnakeControlPadView { model.changeDirection($0) }

            HomeButton()
        }
        .padding(.bottom, 10)
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            guard !model.isGameOver else { return }
            model.tick()
        }
    }

    private func gridLines(cellSize: CGFloat, boardSize: CGFloat) -> some View {
        Path { path in
            for index in 1..<model.gridSize {
                let offset = CGFloat(index) * cellSize
                path.move(to: CGPoint(x: offset, y: 0))
                path.addLine(to: CGPoint(x: offset, y: boardSize))
                path.move(to: CGPoint(x: 0, y: offset))
                path.addLine(to: CGPoint(x: boardSize, y: offset))
            }
        }
        .stroke(Color.white.opacity(0.08), lineWidth: 1)
    }
}

struct SnakeControlPadView: View {
    let onDirectionChanged: (SnakeGameModel.Direction) -> Void

    var body: some View {
        VStack(spacing: 6) {
            directionButton(systemName: "arrow.up.circle.fill", direction: .up)
            HStack(spacing: 54) {
                directionButton(systemName: "arrow.left.circle.fill", direction: .left)
                directionButton(systemName: "arrow.right.circle.fill", direction: .right)
            }
            directionButton(systemName: "arrow.down.circle.fill", direction: .down)
        }
        .padding(.vertical, 4)
    }

    private func directionButton(systemName: String, direction: SnakeGameModel.Direction) -> some View {
        Button { onDirectionChanged(direction) } label: {
            Image(systemName: systemName)
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.text)
                .frame(width: 62, height: 54)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SnakeGameView_Previews: PreviewProvider {
    static var previews: some View {
        SnakeGameView()
    }
}
