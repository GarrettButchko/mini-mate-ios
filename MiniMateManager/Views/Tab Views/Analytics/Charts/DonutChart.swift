//
//  DonutChart.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/26/26.
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
