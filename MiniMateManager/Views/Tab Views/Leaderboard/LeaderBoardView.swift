//
//  LeaderBoardView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI

struct LeaderBoardView: View {
    
    @EnvironmentObject var VM: LeaderBoardViewModel
    @EnvironmentObject var courseVM: CourseViewModel
    
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
                    Text("All Time Leaderboard")
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
        .onAppear{
            guard let selectedCourse = courseVM.selectedCourse, selectedCourse.leaderBoardActive else { return }
            VM.onAppear(courseID: selectedCourse.id)
        }
        .onDisappear {
            VM.onDisappear()
        }
        .background(.bg)
    }
    // MARK: - Sections
    private var mainContent: some View {
        VStack {
            if let course = courseVM.selectedCourse, VM.allTimeLeaderboard.count > 3 && course.leaderBoardActive && course.tier >= 2{
                leaderBoard(data: $VM.allTimeLeaderboard)
                    .id("allTime")
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else if let course = courseVM.selectedCourse, VM.allTimeLeaderboard.count <= 3 && course.leaderBoardActive && course.tier >= 2{
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        // Icon
                        Image(systemName: "gauge.badge.plus")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange.opacity(0.8), .green.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // Title & Description
                        VStack(alignment: .center, spacing: 12) {
                            Text("Not enough Player Data Yet")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.mainOpp)
                                .multilineTextAlignment(.center)
                            
                            Text("Your course is live, but no rounds have been completed by players yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Owner Insights
                        VStack(alignment: .leading, spacing: 16) {
                            featureItem(icon: "qrcode",
                                        title: "Share Course",
                                        description: "Give players your course QR code to start tracking scores.")
                            
                            featureItem(icon: "eye.fill",
                                        title: "Live Monitoring",
                                        description: "Once play begins, rankings will appear here in real-time.")
                            
                            featureItem(icon: "list.number",
                                        title: "Score Validation",
                                        description: "Scores are automatically verified by the MiniMate system.")
                        }
                        .padding(.vertical, 8)
                        
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            } else if let course = courseVM.selectedCourse, course.tier >= 2{
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 24) {
                        // Icon - Muted and "Off"
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary.opacity(0.5))
                        
                        // Title & Description
                        VStack(spacing: 12) {
                            Text("Leaderboard Inactive")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.mainOpp)
                            
                            Text("This leaderboard is currently set to inactive. Players cannot see the leaderboard or submit new scores.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Re-activation Steps
                        VStack(alignment: .leading, spacing: 16) {
                            featureItem(icon: "power",
                                        title: "Enable Course",
                                        description: "Go to course settings to set your status back to 'Live'.")
                            
                            featureItem(icon: "lock.fill",
                                        title: "Protected Data",
                                        description: "Your existing leaderboard data is saved and hidden.")
                            
                            featureItem(icon: "bell.badge.fill",
                                        title: "Stay Hidden",
                                        description: "Inactive courses do not appear in player search results.")
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            } else {
                
                
                // Tier 2 Upgrade / Paywall View
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 28) {
                        // Icon - Gold Medal with a Lock
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "medal.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .padding(6)
                                .background(Circle().fill(.bg))
                                .offset(x: 30, y: 30)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Title & Description
                        VStack(spacing: 12) {
                            Text("Unlock Leaderboards")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.mainOpp)
                            
                            Text("Take your course to the next level. Let players compete for the top spot and track their all-time best scores.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Features unlocked at Tier 2
                        VStack(alignment: .leading, spacing: 16) {
                            featureItem(icon: "trophy.fill",
                                        title: "All-Time Rankings",
                                        description: "Automated leaderboards for every player.")
                            
                            featureItem(icon: "person.badge.shield.checkmark.fill",
                                        title: "Profanity Free",
                                        description: "Name filtering and score validation to keep your course family-friendly.")
                        }
                        .padding(.vertical, 8)
                        
                        // CTA Button
                        Button {
                            // Navigate to upgrade screen
                        } label: {
                            Text("Upgrade to Tier 2")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(12)
                                .shadow(color: .orange.opacity(0.2), radius: 10, y: 5)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
        }
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
                                            guard let selectedCourse = courseVM.selectedCourse else { return }
                                            VM.deletePlayerEntry(courseID: selectedCourse.id, playerID: player.id)
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
    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.orange.opacity(0.15)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.mainOpp)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
                .fill(.clear) // or any transparent color
                .frame(maxWidth: .infinity, minHeight: 32)
                .contentShape(Rectangle()) // <--- This makes the whole area tappable/draggable
            
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
