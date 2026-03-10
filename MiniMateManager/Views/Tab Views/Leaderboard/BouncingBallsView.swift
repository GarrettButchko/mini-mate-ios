//
//  BouncingBallsView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 03/09/26.
//

import SwiftUI
import Combine

// MARK: - UserDefaults Extension for Motion Preference
extension UserDefaults {
    private static let noMotionModeKey = "com.minimate.noMotionMode"
    
    var noMotionMode: Bool {
        get { bool(forKey: Self.noMotionModeKey) }
        set { set(newValue, forKey: Self.noMotionModeKey) }
    }
}

class BallPhysics: NSObject, ObservableObject {
    struct Ball {
        let id: Int
        let rank: Int
        let color: Color
        var x: CGFloat
        var y: CGFloat
        var velocityX: CGFloat
        var velocityY: CGFloat
        let radius: CGFloat
    }
    
    @Published var balls: [Ball]
    
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    
    private var displayLink: CADisplayLink?
    
    init(containerWidth: CGFloat, containerHeight: CGFloat) {
        self.containerWidth = containerWidth
        self.containerHeight = containerHeight
        
        self.balls = [
            Ball(id: 0, rank: 2, color: .gray, x: containerWidth * 0.25, y: containerHeight * 0.6, velocityX: 1, velocityY: 2, radius: 40),
            Ball(id: 1, rank: 1, color: .yellow, x: containerWidth * 0.5, y: containerHeight * 0.3, velocityX: -1.5, velocityY: -1, radius: 60),
            Ball(id: 2, rank: 3, color: .brown, x: containerWidth * 0.75, y: containerHeight * 0.7, velocityX: 0.75, velocityY: 1.5, radius: 20)
        ]
        
        super.init()
    }
    
    func startAnimation() {
        guard !UserDefaults.standard.noMotionMode else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update() {
        updateBalls()
    }
    
    private func updateBalls() {
        for i in 0..<balls.count {
            // Update position
            balls[i].x += balls[i].velocityX
            balls[i].y += balls[i].velocityY
            
            // Bounce off walls
            if balls[i].x - balls[i].radius <= 0 {
                balls[i].x = balls[i].radius
                balls[i].velocityX = abs(balls[i].velocityX) * 1
            }
            if balls[i].x + balls[i].radius >= containerWidth {
                balls[i].x = containerWidth - balls[i].radius
                balls[i].velocityX = -abs(balls[i].velocityX) * 1
            }
            
            if balls[i].y - balls[i].radius <= 0 {
                balls[i].y = balls[i].radius
                balls[i].velocityY = abs(balls[i].velocityY) * 1
            }
            if balls[i].y + balls[i].radius >= containerHeight {
                balls[i].y = containerHeight - balls[i].radius
                balls[i].velocityY = -abs(balls[i].velocityY) * 1
            }
            
            // Ball to ball collision
            for j in (i + 1)..<balls.count {
                let dx = balls[j].x - balls[i].x
                let dy = balls[j].y - balls[i].y
                let distance = sqrt(dx * dx + dy * dy)
                let minDistance = balls[i].radius + balls[j].radius
                
                if distance < minDistance && distance > 0 {
                    let angle = atan2(dy, dx)
                    let sin = sin(angle)
                    let cos = cos(angle)
                    
                    // Swap velocities along collision axis
                    let vx1 = balls[i].velocityX * cos + balls[i].velocityY * sin
                    let vy1 = balls[i].velocityY * cos - balls[i].velocityX * sin
                    let vx2 = balls[j].velocityX * cos + balls[j].velocityY * sin
                    let vy2 = balls[j].velocityY * cos - balls[j].velocityX * sin
                    
                    balls[i].velocityX = vx2 * cos - vy1 * sin
                    balls[i].velocityY = vy1 * cos + vx2 * sin
                    balls[j].velocityX = vx1 * cos - vy2 * sin
                    balls[j].velocityY = vy2 * cos + vx1 * sin
                    
                    // Separate balls
                    let overlap = (minDistance - distance) / 2
                    balls[i].x -= overlap * cos
                    balls[i].y -= overlap * sin
                    balls[j].x += overlap * cos
                    balls[j].y += overlap * sin
                }
            }
        }
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

struct BouncingBallsView: View {
    @StateObject private var physics: BallPhysics
    @State private var noMotionMode: Bool = UserDefaults.standard.noMotionMode
    
    let topThreePlayers: [LeaderboardEntry]
    
    init(containerWidth: CGFloat = UIScreen.main.bounds.width - 40, containerHeight: CGFloat = 200, topThreePlayers: [LeaderboardEntry] = []) {
        _physics = StateObject(wrappedValue: BallPhysics(containerWidth: containerWidth, containerHeight: containerHeight))
        self.topThreePlayers = topThreePlayers
    }
    
    var body: some View {
        Group{
            ZStack {
                // Balls
                ForEach(physics.balls, id: \.id) { ball in
                    VStack(spacing: 0) {
                        topRankBubble(player: topThreePlayers[ball.rank - 1], rank: ball.rank, color: ball.color)
                    }
                    .position(x: ball.x, y: ball.y)
                }
            }
            .frame(height: physics.containerHeight)
            .clipped()
            .onAppear {
                physics.startAnimation()
            }
            .onDisappear {
                physics.stopAnimation()
            }
            
        }
    }
    
    private func topRankBubble(player: LeaderboardEntry, rank: Int, color: Color) -> some View {
        VStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: bubbleSize(rank: rank), height: bubbleSize(rank: rank))
                Image("logoOpp")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: bubbleSize(rank: rank) * 0.9, height: bubbleSize(rank: rank) * 0.9)
                Text("\(medalEmoji(for: rank)) \(player.name)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.mainOpp)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background {
                        Capsule()
                            .fill(.main.opacity(0.6))
                    }
                    .offset(y: bubbleSize(rank: rank) * 0.30)
            }
        }
    }
    
    private func bubbleSize(rank: Int) -> CGFloat {
        CGFloat(abs(rank - 4) * 50)
    }
    private func medalEmoji(for rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "🏅"
        }
    }
}

#Preview {
    BouncingBallsView()
        .background(.bg)
}
