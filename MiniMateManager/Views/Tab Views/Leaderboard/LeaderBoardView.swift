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
            Text("Leaderboard")
            Spacer()
        }
    }
}
