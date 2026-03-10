//
//  HoleDifficultyChart.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/26/26.
//

import Charts
import SwiftUI

struct HoleDifficultyData: Identifiable {
    let id = UUID()
    let holeNumber: Int
    let averageStrokes: Double
}

struct HoleDifficultyChart: View {
    @Binding var difficultyData: [HoleDifficultyData]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(difficultyData) { hole in
                    VStack() {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(colorForDifficulty(hole.averageStrokes))
                            .frame(height: 60)
                        if shouldShowLabel(holeNumber: hole.holeNumber) {
                            Text("\(hole.holeNumber)")
                                .lineLimit(1)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        } else {
                            Color.clear
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func colorForDifficulty(_ strokes: Double) -> Color {
        // Normalize the difficulty to get a value between 0 and 1
        let allStrokes = difficultyData.map { $0.averageStrokes }
        guard let minStrokes = allStrokes.min(),
              let maxStrokes = allStrokes.max(),
              maxStrokes > minStrokes else {
            return Color.green.opacity(0.5)
        }
        
        let normalized = (strokes - minStrokes) / (maxStrokes - minStrokes)
        
        // Map to opacity from 0.16 to 1.0
        let opacity = 0.16 + (normalized * 0.84)
        
        return Color.green.opacity(opacity)
    }
    
    private func shouldShowLabel(holeNumber: Int) -> Bool {
        let maxHole = difficultyData.map({ $0.holeNumber }).max() ?? 0
        
        // Show first, last, and every third hole
        if holeNumber == 1 || holeNumber == maxHole {
            return true
        }
        
        return holeNumber % 3 == 0
    }
}

struct HoleHardnessRow: View {
    let hole: HoleDifficultyData
    let minStrokes: Double
    let maxStrokes: Double
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(colorForHardness(hole.averageStrokes).opacity(0.2))
                    .frame(width: 32, height: 32)
                Text("\(hole.holeNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(colorForHardness(hole.averageStrokes))
            }
            
            Text("Hole \(hole.holeNumber)")
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(String(format: "%.2f", hole.averageStrokes))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                Text("avg strokes")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func colorForHardness(_ strokes: Double) -> Color {
        guard maxStrokes > minStrokes else { return .green }
        let normalized = (strokes - minStrokes) / (maxStrokes - minStrokes)
        let opacity = 0.3 + (normalized * 0.7)
        return Color.green.opacity(opacity)
    }
}

struct HoleHardnessPreviewList: View {
    @Binding var difficultyData: [HoleDifficultyData]
    @State private var isExpanded = false
    
    // The "Hardest" holes (highest average strokes)
    var hardestHoles: [HoleDifficultyData] {
        difficultyData.sorted { $0.averageStrokes > $1.averageStrokes }
    }
    
    var body: some View {
        let min = difficultyData.map { $0.averageStrokes }.min() ?? 0
        let max = difficultyData.map { $0.averageStrokes }.max() ?? 1
        
        VStack(spacing: 0) {
            let displayList = isExpanded ? difficultyData : Array(hardestHoles.prefix(3))
            
            ForEach(displayList) { hole in
                HoleHardnessRow(hole: hole, minStrokes: min, maxStrokes: max)
                
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
