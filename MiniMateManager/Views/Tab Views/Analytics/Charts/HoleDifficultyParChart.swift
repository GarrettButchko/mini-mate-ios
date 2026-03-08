//
//  ChartViews.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/22/26.
//

import Charts
import SwiftUI

struct HoleHeatmapData: Identifiable {
    let id = UUID()
    let holeNumber: Int
    let relativeToPar: Double // e.g., +1.2 or -0.3
    let holePar: Int
}

struct HoleDifficultyParChart: View {
    let difficultyData: [HoleHeatmapData] // Using the new relative data
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Hole Difficulty (vs Par) Map")
                    .foregroundStyle(.mainOpp)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                InfoButton(infoText: "Heatmap: Purple (Under Par) | Blue (Little Under Par) | Green (Par) | Orange (Just Over Par) | Red (Over Par). Note: Missing holes represent unplayed or incomplete data.")
            }
            .padding(.bottom, 8)
            
            HStack(spacing: 4) {
                ForEach(difficultyData) { hole in
                    VStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(colorForDifficulty(hole.relativeToPar))
                            .frame(height: 60)
                        
                        if shouldShowLabel(holeNumber: hole.holeNumber) {
                            Text("\(hole.holeNumber)")
                                .lineLimit(1)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        } else {
                            Color.clear
                                .frame(height: 14) // Keep layout consistent
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top)
    }
    
    private func colorForDifficulty(_ relativeToPar: Double) -> Color {
        // Heatmap Logic based on Score vs. Par
        if relativeToPar <= -1.5 {
            return Color.purple.opacity(0.8)  // Very Easy (Way under par)
        } else if relativeToPar <= -0.5 {
            return Color.blue.opacity(0.8)    // Easy
        } else if relativeToPar < 0.5 {
            return Color.green.opacity(0.8)   // Fair (Near Par)
        } else if relativeToPar < 1.5 {
            return Color.orange.opacity(0.8)  // Hard
        } else {
            return Color.red.opacity(0.8)     // Very Hard (Way over par)
        }
    }
    
    private func shouldShowLabel(holeNumber: Int) -> Bool {
        let maxHole = difficultyData.map({ $0.holeNumber }).max() ?? 0
        return holeNumber == 1 || holeNumber == maxHole || holeNumber % 3 == 0
    }
}

// Helper to build dates quickly
func createDate(day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: day)) ?? Date()
}

struct HolePreviewList: View {
    let allHoles: [HoleHeatmapData]
    @State private var isExpanded = false
    
    // Identifies the holes that deviate most from Par (Hardest & Easiest)
    var outliers: [HoleHeatmapData] {
        allHoles.sorted { abs($0.relativeToPar) > abs($1.relativeToPar) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Display either the top 3 outliers or the full sorted course list
            let displayList = isExpanded ? allHoles.sorted { $0.holeNumber < $1.holeNumber } : Array(outliers.prefix(3))
            
            ForEach(displayList) { hole in
                HoleStatusRow(data: hole)
                
                // Don't show divider on the last item
                if hole.id != displayList.last?.id {
                    Divider().background(.mainOpp.opacity(0.1))
                }
            }
            
            // Toggle Button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(isExpanded ? "Show Less" : "View All Hole Data")
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 12)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct HoleStatusRow: View {
    let data: HoleHeatmapData
    
    var body: some View {
        HStack {
            // Hole Number Badge
            ZStack {
                Circle()
                    .fill(colorForDifficulty(data.relativeToPar).opacity(0.15))
                    .frame(width: 32, height: 32)
                Text("\(data.holeNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(colorForDifficulty(data.relativeToPar))
            }
            
            Text("Hole \(data.holeNumber)")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.mainOpp)
            
            Text("Par \(data.holePar)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Score Detail
            VStack(alignment: .trailing, spacing: 2) {
                Text(data.relativeToPar >= 0 ? "+\(String(format: "%.1f", data.relativeToPar))" : String(format: "%.1f", data.relativeToPar))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(colorForDifficulty(data.relativeToPar))
                
                Text("vs Par")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 10)
    }
    
    private func colorForDifficulty(_ relativeToPar: Double) -> Color {
        // Heatmap Logic based on Score vs. Par
        if relativeToPar <= -1.5 {
            return Color.purple.opacity(0.8)  // Very Easy (Way under par)
        } else if relativeToPar <= -0.5 {
            return Color.blue.opacity(0.8)    // Easy
        } else if relativeToPar < 0.5 {
            return Color.green.opacity(0.8)   // Fair (Near Par)
        } else if relativeToPar < 1.5 {
            return Color.orange.opacity(0.8)  // Hard
        } else {
            return Color.red.opacity(0.8)     // Very Hard (Way over par)
        }
    }
}
