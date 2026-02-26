//
//  TrendChart.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/26/26.
//

import Charts
import SwiftUI

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
