//
//  LeaderBoardView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI

struct LeaderBoardView: View {
    
    @EnvironmentObject var VM: LeaderBoardViewModel
    
    @State private var titleHeight: CGFloat = 40
    
    var body: some View {
        ZStack{
            mainContent
                .padding(.horizontal)
                .padding(.top, titleHeight)
            
            VStack {
                HStack {
                    Spacer()
                    Text("\(VM.pickedSection == .weekly ? "Weekly" : "All Time") Leaderboard")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.vertical, 8)
                        .padding(.top, 20)
                    Spacer()
                }
                .padding(.bottom)
                .background(){
                    GeometryReader { proxy in
                        Color.clear.ignoresSafeArea()
                            .task(id: proxy.size) {
                                titleHeight = proxy.size.height
                            }
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    LeaderBoardSectionToggleView(pickedSection: $VM.pickedSection)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .background(.bg)
    }
    // MARK: - Sections
    private var mainContent: some View {
        Group {
            if VM.pickedSection == .weekly {
                leaderBoard(data: VM.weeklyLeaderboard)
            } else {
                leaderBoard(data: VM.allTimeLeaderboard)
            }
        }
    }
    
    private func leaderBoard(data: [LeaderboardEntry]) -> some View {
        VStack{
            BouncingBallsView(topThreePlayers: Array(data.prefix(3)))
            ScrollView{
                VStack{
                    ForEach(data) { player in
                        let rank = data.firstIndex(where: { $0.id == player.id })! + 1
                        if rank <= 25 && rank >= 4{
                            PlayerRow(player: player, rank: rank)
                            
                            if rank != 25 {
                                Divider().background(.mainOpp.opacity(0.1))
                            }
                        }
                    }
                }
            }
            .contentMargins(16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(.sub)
            )
            .padding(.bottom)
        }
    }
}

struct PlayerRow: View {
    let player: LeaderboardEntry
    let rank: Int
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(.subTwo)
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.subThree)
            }
            
            Text("\(player.name)")
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(player.totalStrokes)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                Text("strokes")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}
