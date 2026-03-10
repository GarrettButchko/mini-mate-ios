//
//  BouncingBallsView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 03/09/26.
//

import SwiftUI

struct BouncingBallsView: View {
    private let containerHeight: CGFloat
    let topThreePlayers: [LeaderboardEntry]
    
    init(containerWidth: CGFloat = UIScreen.main.bounds.width - 40, containerHeight: CGFloat = 220, topThreePlayers: [LeaderboardEntry] = []) {
        self.containerHeight = containerHeight
        self.topThreePlayers = Array(topThreePlayers.prefix(3))
    }
    
    var body: some View {
        Group {
            if topThreePlayers.isEmpty {
                podiumEmptyState
            } else {
                HStack(alignment: .bottom, spacing: 12) {
                    podiumSlot(for: 2)
                    podiumSlot(for: 1)
                    podiumSlot(for: 3)
                }
                .frame(maxWidth: .infinity)
                .frame(height: containerHeight, alignment: .bottom)
            }
        }
    }
    
    private var podiumEmptyState: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.main.opacity(0.06))
            .overlay {
                Text("Leaderboard updates will show here")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            }
            .frame(height: containerHeight * 0.8)
    }
    
    @ViewBuilder
    private func podiumSlot(for rank: Int) -> some View {
        if let player = player(for: rank) {
            podiumColumn(player: player, rank: rank)
                .frame(maxWidth: .infinity, alignment: .bottom)
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
        }
    }
    
    private func podiumColumn(player: LeaderboardEntry, rank: Int) -> some View {
        VStack(spacing: 8) {
            ZStack() {
                Circle()
                    .fill(podiumColor(for: rank).opacity(0.16))
                    .frame(width: bubbleSize(rank: rank), height: bubbleSize(rank: rank))
                
                Image("logoOpp")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: bubbleSize(rank: rank) * 0.82, height: bubbleSize(rank: rank) * 0.82)
            }
            
            VStack(spacing: 2) {
                Text(player.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.mainOpp)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                
                Text("\(player.totalStrokes) strokes")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(podiumColor(for: rank).opacity(rank == 1 ? 0.26 : 0.18))
                .overlay {
                    VStack(spacing: 2) {
                        Text("#\(rank)")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.mainOpp)
                        Text(rankTitle(for: rank))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .frame(height: podiumHeight(rank: rank))
        }
    }
    
    private func player(for rank: Int) -> LeaderboardEntry? {
        let index = rank - 1
        guard topThreePlayers.indices.contains(index) else { return nil }
        return topThreePlayers[index]
    }
    
    private func bubbleSize(rank: Int) -> CGFloat {
        switch rank {
        case 1: return 85
        case 2: return 70
        case 3: return 55
        default: return 60
        }
    }
    
    private func podiumHeight(rank: Int) -> CGFloat {
        switch rank {
        case 1: return 92
        case 2: return 70
        case 3: return 56
        default: return 56
        }
    }
    
    private func podiumColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .gray
        }
    }
    
    private func rankTitle(for rank: Int) -> String {
        switch rank {
        case 1: return "First"
        case 2: return "Second"
        case 3: return "Third"
        default: return "Top"
        }
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
