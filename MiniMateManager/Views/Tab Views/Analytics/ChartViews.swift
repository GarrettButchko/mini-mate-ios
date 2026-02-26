//
//  ChartViews.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/22/26.
//

import Charts
import SwiftUI

struct VisitorData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let color: Color
}

struct VisitorDonutChart: View {
    // Sample Data based on our 65% retention talk
    
    var data: [VisitorData] = [
        .init(name: "Returning", count: 65, color: .orange),
        .init(name: "First-Time", count: 35, color: .blue)
    ]
    
    let higherPercObj: (value: Int, name: String)
    
    init(returningPerc: Double, firstTimePerc: Double){
        
        let returningInt = Int(returningPerc * 100)
        let firstTimeInt = Int(firstTimePerc * 100)
        
        data = [.init(name: "Returning", count: returningInt, color: .orange),
                .init(name: "First-Time", count: firstTimeInt, color: .blue)]
        
        if returningInt > firstTimeInt {
            higherPercObj = (returningInt, "Returning")
        } else if firstTimeInt > returningInt {
            higherPercObj = (firstTimeInt, "First-Time")
        } else {
            higherPercObj = (returningInt, "Equal")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Visitor Composition")
                .foregroundStyle(.mainOpp)
                .font(.system(size: 14, weight: .semibold))
            
            ZStack {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Visitors", item.count),
                        innerRadius: .ratio(0.7), // This creates the "Donut" hole
                        angularInset: 2.0      // Adds the premium gap between slices
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(8)
                }
                .frame(height: 200)
                
                // Central Label: The "Emotional" Metric
                VStack {
                    Text("~\(higherPercObj.value)%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("\(higherPercObj.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Custom Legend
            HStack(spacing: 20) {
                ForEach(data) { data in
                    legendItem(title: data.name, color: data.color)
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(.subTwo)
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}




struct PlayerTrendChart: View {
    
    // Mimicking the dates and curve from your screenshot
    var data: [PlayerActivity] = [
        .init(date: createDate(day: 15), count: 18),
        .init(date: createDate(day: 16), count: 26),
        .init(date: createDate(day: 17), count: 23),
        .init(date: createDate(day: 18), count: 35),
        .init(date: createDate(day: 19), count: 36)
    ]
    
    var lineColor: Color = .purple
    
    init(VM: AnalyticsViewModel){
        data = VM.getDataForGrowthTrend()
        lineColor = VM.growthChartTopic.color
    }

    var body: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Players", item.count)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                
                AreaMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Players", item.count)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [lineColor.opacity(0.4), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartPlotStyle { plot in
            plot
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.bottom, 8)
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            // 1. ADD THE PRESET HERE
            AxisMarks(preset: .aligned, values: getStrideValues(from: data)) { value in
                // 2. Add the Grid Line
                AxisGridLine()
                    .foregroundStyle(.secondary.opacity(0.3))
                    
                // 3. Add the Label
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month().day())
                    }
                }
            }
        }
        .frame(height: 220)
        .padding()
        .padding(.top)
        .background {
            RoundedRectangle(cornerRadius: 17)
                .fill(.subTwo)
        }
    }
    
    func getStrideValues(from data: [PlayerActivity]) -> [Date] {
        let count = data.count
        
        // 1. If we have 5 or fewer days, just show every day.
        // This prevents "half-day" labels when the range is tiny.
        if count <= 5 {
            return data.map { $0.date }
        }
        
        // 2. Otherwise, use the "4 middle points" logic for larger ranges.
        guard let first = data.first?.date, let last = data.last?.date else { return [] }
        
        let diff = last.timeIntervalSince(first)
        let step = diff / 5
        
        return [
            first.addingTimeInterval(step),     // 20% mark
            first.addingTimeInterval(step * 2), // 40% mark
            first.addingTimeInterval(step * 3), // 60% mark
            first.addingTimeInterval(step * 4)  // 80% mark
        ]
    }
}

struct PlayerSummaryChart: View {
    let data: [PlayerActivity]
    let lineColor: Color
    
    init(VM: AnalyticsViewModel) {
        self.data = VM.getDataForGrowthTrend()
        self.lineColor = VM.growthChartTopic.color
    }
    
    var body: some View {
        
        Chart {
            ForEach(data) { item in
                AreaMark(
                    x: .value("Day", item.date),
                    y: .value("Players", item.count)
                )
                .interpolationMethod(.monotone) // More performant for large arrays
                .foregroundStyle(
                    .linearGradient(
                        colors: [lineColor.opacity(0.5), lineColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        // Hide the axes to keep it "Premium" and clean (empty closure removes space)
        .chartXAxis {
        }
        .chartYAxis {
        }
        .overlay(alignment: .center) {
            // Informational Overlay
            VStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .symbolRenderingMode(.multicolor)
                
                Text("Select a range between 9 and 30 days to view daily trends.")
                    .font(.headline)
                    .foregroundStyle(.mainOpp)
                
                Text("\(data.count - 1) Days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .frame(height: 220)
        .padding()
        .padding(.top)
        .background {
            RoundedRectangle(cornerRadius: 17)
                .fill(.subTwo)
        }
    }
}

struct HourData: Identifiable {
    let id = UUID()
    let weekday: Int // 1 (Sun) to 7 (Sat)
    let hour: Int    // 0 to 23
    let count: Int
}

struct BusiestTimesChart: View {
    let data: [HourData]
    
    // Define the weekday labels to match your screenshot
    let dayLabels = ["", "Sun", "", "Tues", "", "Thurs", "", "Sat"]
    
    // Constants for grid
    let maxHours = 24
    let maxDays = 7
    
    var body: some View {
        GeometryReader { geometry in
            let cellWidth = (geometry.size.width / CGFloat(maxHours)) * 0.7
            let cellHeight = (geometry.size.height / CGFloat(maxDays)) * 0.7
            
            Chart {
                ForEach(data) { item in
                    RectangleMark(
                        x: .value("Hour", item.hour),
                        y: .value("Day", item.weekday),
                        width: .fixed(cellWidth),
                        height: .fixed(cellHeight)
                    )
                    .foregroundStyle(by: .value("Count", item.count))
                    .cornerRadius(6) // Makes the "pill" shape
                }
            }
            // 1. Color Scale (Light green to Dark green)
            .chartForegroundStyleScale(
                range: [
                    Color.green.opacity(0.16),
                    Color.green.opacity(0.33),
                    Color.green.opacity(0.5),
                    Color.green.opacity(0.66),
                    Color.green.opacity(0.83),
                    Color.green
                ]
            )
            // 2. Y-Axis (Days)
            .chartYAxis {
                AxisMarks(position: .leading, values: [1, 3, 5, 7]) { value in
                    AxisValueLabel {
                        if let dayInt = value.as(Int.self) {
                            Text(dayLabels[dayInt])
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .offset(x: -8)
                        }
                    }
                }
            }
            .chartXAxis {
                // 1. ADD THE PRESET HERE
                AxisMarks(preset: .aligned, values: [0, 3, 7, 11, 15, 19, 23]) { value in
                    // 2. Add the Grid Line
                    AxisGridLine()
                        .foregroundStyle(.mainOpp.opacity(0.3))
                    
                    // 3. Add the Label
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(formatHour(hour))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .offset(y: -16)
                        }
                    }
                }
            }
        }
        .frame(height: 250)
        .padding(.trailing, 16)
        .padding(.top, 32)
    }
    
    
    func formatHour(_ h: Int) -> String {
        if h == 23 { return "12am" }
        if h == 0 { return "1am" }
        if h == 11 { return "12pm" }
        return h > 12 ? "\(h-12 + 1)pm" : "\(h + 1)am"
    }
}

struct HoleDifficultyData: Identifiable {
    let id = UUID()
    let holeNumber: Int
    let averageStrokes: Double
}

struct HoleDifficultyChart: View {
    let difficultyData: [HoleDifficultyData]
    
    var body: some View {
        VStack(spacing: 0) {
            // Bar chart
            HStack{
                Text("Hole Hardness")
                    .foregroundStyle(.mainOpp)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                InfoButton(infoText: "Greener = Harder, less opacity = easier. Based on average strokes per hole.")
            }
            .padding(.bottom, 8)
            
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

// Helper to build dates quickly
func createDate(day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: day)) ?? Date()
}
