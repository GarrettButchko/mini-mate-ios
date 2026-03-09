//
//  BusiestTimeChart.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/26/26.
//

import Charts
import SwiftUI

struct HourData: Identifiable {
    let id = UUID()
    let weekday: Int // 1 (Sun) to 7 (Sat)
    let hour: Int    // 0 to 23
    let count: Int
}

struct BusiestTimesChart: View {
    @EnvironmentObject var VM: AnalyticsViewModel
    
    @State var data: [HourData] = []
    
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
            .task{
                data = await VM.prepareChartData()
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
