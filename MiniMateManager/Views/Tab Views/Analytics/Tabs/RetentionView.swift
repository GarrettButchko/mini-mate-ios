//
//  RetentionView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 3/3/26.
//

import SwiftUI
import UIKit

struct RetentionView: View {
    @EnvironmentObject var VM: RetentionViewModel
    @EnvironmentObject var analyticsVM: AnalyticsViewModel
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                if analyticsVM.loadingEmails {
                    loadingState
                        .transition(.opacity)
                } else {
                    HStack(spacing: 16) {
                        DataCard(
                            data: DataPointObject(value: "\(VM.cachedAvgTimeToReturn)", delta: nil, deltaColor: nil),
                            title: "Avg Days, Return",
                            infoText: "Average number of days between first visit and returning players' second visit.",
                            color: .sub,
                            cornerRadius: 16
                        )
                        .cardShadow()
                        
                        DataCard(
                            data: DataPointObject(value: String(format: "%.0f%%", VM.cached30DayRetention * 100), delta: nil, deltaColor: nil),
                            title: "30-Day Retention",
                            infoText: "Percentage of new players in the date range who returned within 30 days.",
                            color: .sub,
                            cornerRadius: 16
                        )
                        .cardShadow()
                    }
                    
                    VStack{
                        HStack{
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Player Tiers")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("\(String(VM.allEmails.count)) Unique Players")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .offset(x: 0, y: -4)
                            }
                            Spacer()
                            InfoButton(infoText: "Players are categorized into tiers based on their activity level and return behavior. This helps identify patterns and opportunities for engagement. Click on the arrow to get their emails and take action!")
                        }
                        // Four Player Tier Cards
                        PlayerTierCard(
                            tier: .new,
                            players: VM.cachedNewPlayers,
                            VM: VM,
                            shareURL: $shareURL,
                            showShareSheet: $showShareSheet
                        )
                        
                        PlayerTierCard(
                            tier: .midTier,
                            players: VM.cachedMidTierPlayers,
                            VM: VM,
                            shareURL: $shareURL,
                            showShareSheet: $showShareSheet
                        )
                        
                        PlayerTierCard(
                            tier: .frequent,
                            players: VM.cachedFrequentPlayers,
                            VM: VM,
                            shareURL: $shareURL,
                            showShareSheet: $showShareSheet
                        )
                        
                        PlayerTierCard(
                            tier: .atRisk,
                            players: VM.cachedAtRiskPlayers,
                            VM: VM,
                            shareURL: $shareURL,
                            showShareSheet: $showShareSheet
                        )
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.sub)
                            .cardShadow()
                    }
                }
            }
        }
        .contentMargins([.horizontal, .bottom, .top], 16)
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(url: url)
            }
        }
    }
    
    var loadingState: some View {
        VStack(spacing: 16) {
            VStack {
                RoundedRectangle(cornerRadius: 17).fill(.subTwo).frame(height: 100)
                HStack {
                    RoundedRectangle(cornerRadius: 17).fill(.subTwo).frame(height: 100)
                    RoundedRectangle(cornerRadius: 17).fill(.subTwo).frame(height: 100)
                }
            }
            .skeleton(active: true)
            .clipShape(RoundedRectangle(cornerRadius: 17))

            RoundedRectangle(cornerRadius: 17)
                .fill(.subTwo)
                .frame(height: 220)
                .skeleton(active: true)
                .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.sub)
                .cardShadow()
        }
    }
}

// MARK: - Player Tier Card Component
enum PlayerTier: Equatable {
    case new
    case midTier
    case frequent
    case atRisk
    
    var icon: String {
        switch self {
        case .new: return "star.fill"
        case .midTier: return "medal.fill"
        case .frequent: return "crown.fill"
        case .atRisk: return "exclamationmark.triangle.fill"
        }
    }
    
    var label: String {
        switch self {
        case .new: return "New"
        case .midTier: return "Mid-Tier"
        case .frequent: return "Frequent"
        case .atRisk: return "At Risk"
        }
    }
    
    var minidescription: String {
        switch self {
        case .new: return "Played once"
        case .midTier: return "2–5 plays, active"
        case .frequent: return "5+ plays, active"
        case .atRisk: return "Inactive"
        }
    }
    
    var description: String {
        switch self {
        case .new:
            return "Players who have played only once within the average return window."
        case .midTier:
            return "Players who have played 2 to 5 times and have returned within the average window."
        case .frequent:
            return "Players who have played more than 5 times and have returned within the average window."
        case .atRisk:
            return "Players who have played previously but have not returned within the average window."
        }
    }
    
    var color: Color {
        switch self {
        case .new: return .purple
        case .midTier: return .gray
        case .frequent: return .yellow
        case .atRisk: return .red
        }
    }
}

struct PlayerTierCard: View {
    let tier: PlayerTier
    let players: [String: CourseEmail]
    let VM: RetentionViewModel
    @Binding var shareURL: URL?
    @Binding var showShareSheet: Bool
    
    @State private var isExpanded = false
    
    var emails: [String] {
        Array(players.keys).sorted()
    }
    
    var previewEmails: [String] {
        Array(emails.prefix(5))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: tier.icon)
                    .font(.title2)
                    .frame(width: 30)
                    .foregroundStyle(tier.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.label)
                        .font(.headline)
                    Text(tier.minidescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(players.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("players")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.snappy(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded && !players.isEmpty {
                Divider()
                    .padding(.horizontal, 14)
                
                // Expanded content - only rendered when expanded
                ExpandedPlayerTierContent(
                    tier: tier,
                    emails: emails,
                    previewEmails: previewEmails,
                    onCopyToClipboard: copyToClipboard,
                    onDownloadCSV: downloadCSV
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.subTwo)
        )
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        let emailString = emails.joined(separator: ", ")
        UIPasteboard.general.string = emailString
        
        // Visual feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func downloadCSV() {
        guard let fileURL = VM.generateCSVFile(from: emails) else {
            print("❌ Failed to generate CSV")
            return
        }
        
        shareURL = fileURL
        showShareSheet = true
    }
}

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [url]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
