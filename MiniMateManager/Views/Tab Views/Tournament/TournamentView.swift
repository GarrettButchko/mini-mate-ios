//
//  TournamentView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI

struct TournamentView: View {
    @EnvironmentObject var courseVM: CourseViewModel
    
    var body: some View {
        ZStack {
            Color.bg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "medal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange.opacity(0.8), .green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Title & Description
                    VStack(spacing: 12) {
                        Text("Tournaments Coming Soon")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.mainOpp)
                        
                        Text("Organize and manage mini golf tournaments with leaderboards, player tracking, and real-time scoring.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                    }
                    
                    // Feature Preview
                    VStack(alignment: .leading, spacing: 12) {
                        featureItem(icon: "flag.pattern.checkered", title: "Tournament Brackets", description: "Create and manage tournament brackets")
                        featureItem(icon: "person.2.fill", title: "Player Management", description: "Invite and track player performance")
                        featureItem(icon: "chart.bar.fill", title: "Live Leaderboards", description: "Real-time scoring and rankings")
                    }
                    
                    // Coming Soon Badge
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("Available in a future update")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .foregroundStyle(LinearGradient(
                        gradient: Gradient(colors: [.orange.opacity(0.8), .green.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
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
