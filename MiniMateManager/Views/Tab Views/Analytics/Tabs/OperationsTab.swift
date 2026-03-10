//
//  OperationsTab.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//

import SwiftUI

struct OperationsTab: View {
    
    @EnvironmentObject var VM: OperationsViewModel

    var body: some View {
        VStack(spacing: 16){
            
            VStack(spacing: 8){
                HStack{
                    Text("Games vs Days")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                DataCard(data: VM.avgGamesPerDayPrime(), title: "Avg Games Per Day", infoText: "The average number of games played per day.", color: .subTwo, cornerRadius: 17)
                
                VStack{
                    HStack(alignment: .center) {
                        Text("Games Over Time")
                            .foregroundStyle(.mainOpp)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        InfoButton(infoText: "Shows the duration of the games over time.")
                    }
                    .padding(.bottom, 16)
                    GamesPerDayChart()
                        .id(VM.rangeDailyDocs.count)
                }
                .frame(height: 240)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 17)
                        .fill(.subTwo)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.sub)
                    .cardShadow()
            }
            
            DataCard(data: VM.avgPlayersPerGamePrime(), title: "Avg Players Per Game", infoText: "The number of total plays divided by the number of total visits. (Counts a player once per day. If a player visits on multiple days, each day is counted.)", color: .sub, cornerRadius: 25)
                .cardShadow()
            
            VStack(spacing: 8){
                HStack{
                    Text("Busiest Times")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                HStack{
                    DataCard(data: VM.getBusiestHour(), title: "Busiest Hour", infoText: "Based on the number of games played that hour.", color: .subTwo, cornerRadius: 17)
                    
                    DataCard(data: VM.getBusiestDay(), title: "Busiest Day", infoText: "Based on the number of games played that day.", color: .subTwo, cornerRadius: 17)
                }
                
                BusiestTimesChart()
                    .padding(.horizontal)
                    .background {
                        RoundedRectangle(cornerRadius: 17)
                            .fill(.subTwo)
                    }
                    .id(VM.rangeDailyDocs.count)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.sub)
                    .cardShadow()
            }
            
            // SECTION 3: Game Duration & Engagement
            VStack(spacing: 8){
                HStack{
                    Text("Game Duration")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                HStack{
                    DataCard(data: VM.getAvgGameDuration(), title: "Avg Duration", infoText: "Average time players spend per game.", color: .subTwo, cornerRadius: 17)
                    
                    DataCard(data: VM.getTotalPlayTime(), title: "Total Time", infoText: "Total play time across all games in this period.", color: .subTwo, cornerRadius: 17)
                }
                
                HStack{
                    DataCard(data: VM.getFastestGameTime(), title: "Fastest Game", infoText: "Shortest game duration recorded.", color: .subTwo, cornerRadius: 17)
                    
                    DataCard(data: VM.getSlowestGameTime(), title: "Longest Game", infoText: "Longest game duration recorded.", color: .subTwo, cornerRadius: 17)
                }
                
                VStack{
                    HStack(alignment: .center) {
                        Text("Game Duration Over Time")
                            .foregroundStyle(.mainOpp)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        InfoButton(infoText: "Shows the duration of the games over time.")
                    }
                    .padding(.bottom, 16)
                    GameDurationTrendChart(VM: VM)
                        .id(VM.rangeDailyDocs.count)
                }
                
                
                .frame(height: 200)
                .padding()
                .background(RoundedRectangle(cornerRadius: 17).fill(.subTwo))
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
