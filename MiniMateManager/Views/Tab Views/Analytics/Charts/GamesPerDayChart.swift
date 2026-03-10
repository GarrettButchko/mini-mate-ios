//
//  GamesPerDayChart.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 3/8/26.
//

import Charts
import SwiftUI

struct GamesPerDayChart: View {
    
    @EnvironmentObject var VM: OperationsViewModel
    
    @State var data: [PlayerActivity] = []
    
    let lineColor: Color = .purple
    
    var body: some View {
        if data.allSatisfy({ $0.count == 0 }) {
            VStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Not enough data yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("Games over time will appear here once players start visiting your course.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 17).fill(.subTwo))
            .task{
                data = await VM.getDataForGamesPerDay()
            }
        } else {
            VStack{
                HStack(alignment: .center) {
                    Text("Games Over Time")
                        .foregroundStyle(.mainOpp)
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    InfoButton(infoText: "Shows the duration of the games over time.")
                }
                .padding(.bottom, 16)
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Games", item.count)
                        )
                        .foregroundStyle(lineColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        
                        AreaMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Games", item.count)
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
                .task{
                    data = await VM.getDataForGamesPerDay()
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
                    AxisMarks(preset: .aligned, values: getStrideValues(from: data)) { value in
                        AxisGridLine()
                            .foregroundStyle(.secondary.opacity(0.3))
                        
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
                .id(VM.rangeDailyDocs.count)
            }
            .frame(height: 240)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 17)
                    .fill(.subTwo)
            }
        }
    }
    
    func getStrideValues(from data: [PlayerActivity]) -> [Date] {
        let count = data.count
        
        if count <= 5 {
            return data.map { $0.date }
        }
        
        guard let first = data.first?.date, let last = data.last?.date else { return [] }
        
        let diff = last.timeIntervalSince(first)
        let step = diff / 5
        
        return [
            first.addingTimeInterval(step),
            first.addingTimeInterval(step * 2),
            first.addingTimeInterval(step * 3),
            first.addingTimeInterval(step * 4)
        ]
    }
}
