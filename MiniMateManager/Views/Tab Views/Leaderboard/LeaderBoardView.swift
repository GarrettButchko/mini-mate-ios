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
    
    @State var editingPlayerID: String? = nil
    
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
            }
            .padding(.horizontal, 20)
        }
        .background(.bg)
    }
    // MARK: - Sections
    private var mainContent: some View {
        VStack {
            Group {
                if VM.pickedSection == .weekly {
                    leaderBoard(data: $VM.weeklyLeaderboard)
                        .id("weekly")
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    leaderBoard(data: $VM.allTimeLeaderboard)
                        .id("allTime")
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }

            LeaderBoardSectionToggleView(pickedSection: $VM.pickedSection)
        }
        .animation(.easeInOut, value: VM.pickedSection)
        .padding(.bottom)
    }
    
    private func leaderBoard(data: Binding<[LeaderboardEntry]>) -> some View {
        VStack{
            BouncingBallsView(topThreePlayers: Array(data.wrappedValue.prefix(3)))
            ScrollView{
                VStack{
                    ForEach(data) { player in
                        let rank = data.firstIndex(where: { $0.id == player.id })! + 1
                        if rank <= 25 && rank >= 4{
                            GeometryReader { proxy in
                                HStack(alignment: .center){
                                    PlayerRow(player: player.wrappedValue, rank: rank)
                                        .frame(width: proxy.size.width)
                                        .transition(.opacity.combined(with: .blurReplace))
                                        .swipeMod(editingID: $editingPlayerID, id: String(rank), buttonPressFunction: {}) {
                                            print("Delete Func Here for \(rank)")
                                        }
                                }
                            }
                            .frame(height: 40)
                            
                            
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
        }
    }
}

struct PlayerRow: View {
    let player: LeaderboardEntry
    let rank: Int
    
    var body: some View {
        HStack(alignment: .center){
            ZStack {
                Circle()
                    .fill(.subTwo)
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.mainOpp)
            }
            
            Text("\(player.name)")
                .font(.system(size: 16, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            
            Rectangle()
                .fill(.clear)
                .frame(maxWidth: .infinity, minHeight: 32)
            
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
