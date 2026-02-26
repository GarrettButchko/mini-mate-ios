//
//  AnalyticsView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI
import Combine
import Foundation

/*
 Retention
 
 Repeat Rate
 
 % of active players with playCount >= 2 (for a period, you’ll filter by lastPlayed in range)
 
 Avg Time to Return
 
 average of daysBetween(firstSeen, secondSeen) for players where secondSeen != nil
 
 30-Day Retention
 
 % of players whose firstSeen is in range AND secondSeen <= firstSeen + 30
 */




struct AnalyticsView: View {
    
    @EnvironmentObject var courseVM: CourseViewModel
    @StateObject var VM = AnalyticsViewModel()
    
    let anaRepo = AnalyticsRepository()
    
    @State private var topBarHeight: CGFloat = 0
    
    var inRange: Bool {
        VM.rangeDailyDocs.count > 28 || VM.rangeDailyDocs.count + 1 < 8
    }
    
    var body: some View {
        VStack {
            HStack{
                VStack(alignment: .leading){
                    Text("Analytics")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(VM.selectedSection.rawValue)
                        .font(.subheadline)
                }
                
                Spacer()
                Button {
                    anaRepo.uploadDebugDailyDocs(courseID: courseVM.selectedCourse!.id) { _ in }
                } label: {
                    Text("Debug")
                }
            }
            .padding([.horizontal, .top])
            ZStack (alignment: .top){
                content
                topBar
            }
        }
        .onChange(of: VM.range) { old, new in
            withAnimation{
                VM.onChange(old: old, new: new, course: courseVM.selectedCourse)
            }
        }
        .onAppear{
            withAnimation{
                VM.onAppear(course: courseVM.selectedCourse)
            }
        }
        .environmentObject(VM)
        .background(.bg)
    }
    
    var content: some View {
        // Content
        ScrollView(.vertical) {
            VStack(spacing: 16){
                if VM.loadingDocs {
                    VStack(spacing: 16) {
                        // Mock Player Data Card
                        VStack {
                            RoundedRectangle(cornerRadius: 17).fill(.subTwo).frame(height: 100)
                            HStack {
                                RoundedRectangle(cornerRadius: 17).fill(.subTwo).frame(height: 100)
                                RoundedRectangle(cornerRadius: 17).fill(.subTwo).frame(height: 100)
                            }
                        }
                        .skeleton(active: true)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                        
                        // Mock Chart
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
                    .transition(.opacity)
                } else {
                    if VM.selectedSection == .growth {
                        growthStats
                            .transition(.opacity)
                    } else if VM.selectedSection == .operations {
                        operationsStats
                            .frame(maxWidth: .infinity)
                            .transition(.opacity)
                    } else if VM.selectedSection == .experience {
                        expierenceStats
                            .frame(maxWidth: .infinity)
                            .transition(.opacity)
                    }
                }
            }
        }
        .contentMargins([.horizontal, .bottom], 16)
        .contentMargins(.top, topBarHeight + 16)
    }
    
    var growthStats: some View {
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
                
                VisitorDonutChart(returningPerc: VM.returningPercOfTotal(), firstTimePerc: VM.firstTimePercOfTotal())
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
                            if inRange {
                                VM.growthChartTopic = .total
                            } else {
                                withAnimation {
                                    VM.growthChartTopic = .total
                                }
                            }
                        }
                        Button("First-Time") {
                            if inRange {
                                VM.growthChartTopic = .first
                            } else {
                                withAnimation {
                                    VM.growthChartTopic = .first
                                }
                            }
                        }
                        Button("Returning") {
                            if inRange {
                                VM.growthChartTopic = .returning
                            } else {
                                withAnimation {
                                    VM.growthChartTopic = .returning
                                }
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
                
                if inRange {
                    PlayerSummaryChart(VM: VM)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    PlayerTrendChart(VM: VM)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
    
    var operationsStats: some View {
        VStack(spacing: 16){
            
            VStack(spacing: 8){
                HStack{
                    Text("Hole Stats")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                // SECTION 1: HARDNESS
                let hardnessData = VM.getHoleDifficultyData()
                
                VStack(spacing: 16) {
                    HoleDifficultyChart(difficultyData: VM.getHoleDifficultyData())
                    HoleHardnessPreviewList(difficultyData: hardnessData)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 17).fill(.subTwo))
                
                HStack{
                    DataCard(data: VM.getEasiestHole(), title: "Easiest", infoText: "The hole which has the the lowest average strokes per plays", color: .subTwo, cornerRadius: 17)
                    
                    DataCard(data: VM.getHardestHole(), title: "Hardest", infoText: "The hole which has the the highest average strokes per plays", color: .subTwo, cornerRadius: 17)
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
                    Text("Busiest Times")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                HStack{
                    DataCard(data: VM.getBusiestHour(), title: "Busiest Hour", infoText: "Based on the number of games played that hour.", color: .subTwo, cornerRadius: 17)
                    
                    DataCard(data: VM.getBusiestDay(), title: "Busiest Day", infoText: "Based on the number of games played that day.", color: .subTwo, cornerRadius: 17)
                }
                
                BusiestTimesChart(data: VM.prepareChartData())
                    .padding(.horizontal)
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
        }
    }
    
    var expierenceStats: some View {
        VStack(spacing: 16){

            let heatmapData = VM.getHoleHeatmapForParData(course: courseVM.selectedCourse!)
            
            VStack(spacing: 16) {
                HoleDifficultyParChart(difficultyData: heatmapData)
                    .frame(height: 100) // Constrain height so the list has room
                    .padding(.bottom)
                
                HolePreviewList(allHoles: heatmapData)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.sub)
                    .cardShadow()
            }
        }
    }
    
    var topBar: some View {
        // Top Bar
        VStack (spacing: 16){
            HStack {
                ForEach(AnalyticsSection.allCases) { section in
                    let obj = VM.analyticsObjects[section.rawValue]!
                    Button {
                        
                        withAnimation(.snappy) {
                            VM.selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: obj.icon)
                            
                            if VM.selectedSection == section {
                                Text(section.rawValue)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .id(section)
                    .foregroundStyle(obj.color)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        VM.selectedSection == section ? obj.color.opacity(0.2) : .clear
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(obj.color.opacity(0.3), lineWidth: 4)
                            .opacity(VM.selectedSection != section ? 0.5 : 0)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    
                }
            }
            .padding([.horizontal, .top], 16)
            
            AnalyticsRangeBar()
                .padding([.horizontal, .bottom], 16)
            
        }
        .background{
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 25)
                    .ifAvailableGlassEffect()
                    .cardShadow()
                    .task(id: proxy.size) {
                        topBarHeight = proxy.size.height // Capture the size and monitor changes
                    }
            }
        }
        .padding(.horizontal)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.bg,
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }
}


struct InfoButton: View {
    
    @State var showInfo: Bool = false
    let infoText: String
    
    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.blue)
            
        }
        .alert("Info", isPresented: $showInfo) {
            Button("OK") {}
        } message: {
            Text(infoText)
        }
    }
}





