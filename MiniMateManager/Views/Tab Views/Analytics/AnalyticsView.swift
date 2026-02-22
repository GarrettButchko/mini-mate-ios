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
    
    @State private var topBarHeight: CGFloat = 0
    
    var body: some View {
        VStack {
            HStack{
                Text("Analytics")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
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
                
                HStack{
                    Text("all: \(VM.allDailyDocs.count) range: \(VM.rangeDailyDocs.count) delta: \(VM.deltaDailyDocs.count), \(courseVM.selectedCourse?.name ?? "N/A") in range \(VM.range.title)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.sub)
                        .cardShadow()
                }
                
                if VM.loadingDocs {
                    VStack(alignment: .center){
                        Text("Loading data...")
                        ProgressView()
                    }
                } else {
                    growthStats
                }
            }
        }
        .contentMargins(.horizontal, 16)
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
                
                let activeUserDT = VM.activeUsersPrime()
                DataCard(title: "Active (Unique)", value: activeUserDT.value, deltaText: activeUserDT.delta, cornerRadius: 16, infoText: "Number of unique active players in the selected time range.", color: .subTwo, textColor: activeUserDT.dColor)

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
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(AnalyticsSection.allCases) { section in
                            let obj = VM.analyticsObjects[section.rawValue]!
                            Button {
                                withAnimation(.snappy) {
                                    VM.selectedSection = section
                                    proxy.scrollTo(section, anchor: .leading) // ✅ shove to front
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: obj.icon)
                                    
                                    Text(section.rawValue)
                                        .fontWeight(.bold)
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                            }
                            .id(section)
                            .foregroundStyle(obj.color)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 11)
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
                }
            }
            .contentMargins([.horizontal, .top],16, for: .scrollContent)
            
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

struct DataCard: View {
    @State var showInfo: Bool = false
    var title: String
    var value: String
    var deltaText: String
    var cornerRadius: CGFloat = 12
    var infoText: String = "No Text Yet"
    var color: Color = .sub
    var textColor: Color = .mainOpp
    
    var body: some View {
        
            VStack(spacing: 8) {
                HStack{
                    Text(title)
                        .foregroundStyle(.mainOpp)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Spacer()
                    
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
                
                
                HStack{
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(textColor)
                    Text(deltaText)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(textColor)
                    Spacer()
                }
                
            }
        .padding()
        .background{
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
        }
    }
}




