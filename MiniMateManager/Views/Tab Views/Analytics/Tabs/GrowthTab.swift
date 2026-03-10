//
//  GrowthTab.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//

import SwiftUI
struct GrowthTab: View {
    @EnvironmentObject var VM: GrowthViewModel
    
    var body: some View {
        VStack(spacing: 16){
            VStack(spacing: 8){
                HStack{
                    Text("Player Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                DataCard(data: VM.activeUsersPrime(), title: "Total Visits", infoText: "Total player visits during the selected date range. (Counts a player once per day. If a player visits on multiple days, each day is counted.)", color: .subTwo, cornerRadius: 16)
                
                HStack{
                    DataCard(data: VM.firstTimePrime(), title: "First Time", infoText: "Players who visited this course for the first time during the selected date range.", color: .subTwo, cornerRadius: 16)
                    DataCard(data: VM.returningPrime(), title: "Returning", infoText: "Players who had previously visited and played again during the selected date range.", color: .subTwo, cornerRadius: 16)
                }
                
                if VM.returningPercOfTotal() == 0 && VM.firstTimePercOfTotal() == 0 {
                    VStack(spacing: 10) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("Not enough data yet")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Visit data will appear here once players start coming to your course.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(.subTwo))
                } else {
                    VisitorDonutChart(returningPerc: VM.returningPercOfTotal(), firstTimePerc: VM.firstTimePercOfTotal())
                        .id(VM.rangeDailyDocs.count)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.sub)
                    .cardShadow()
            }
            
            VStack(spacing: 8){

                HStack{
                    Text("Trend")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                HStack{
                    Text("Days vs:")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 17)
                                .fill(.subTwo)
                        }
                    
                    Menu {
                        Button("Total") {
                            withAnimation {
                                VM.growthChartTopic = .total
                            }
                        }
                        Button("First-Time") {
                            withAnimation {
                                VM.growthChartTopic = .first
                            }
                        }
                        Button("Returning") {
                            withAnimation {
                                VM.growthChartTopic = .returning
                            }
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(VM.growthChartTopic.color)
                                .frame(width: 10, height: 10)
                            Text(VM.growthChartTopic.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.mainOpp)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .foregroundStyle(.mainOpp.opacity(0.5))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 17)
                                .fill(.subTwo)
                        )
                    }
                }
                
                if VM.rangeDailyDocs.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("Not enough data yet")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Player trend data will appear here once players start visiting your course.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(.subTwo))
                } else {
                    PlayerTrendChart(VM: VM)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .id(VM.growthChartTopic)
                        .id(VM.rangeDailyDocs.count)
                }
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


