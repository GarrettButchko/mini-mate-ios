//
//  AnalyticsView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI
import Combine
import Foundation

struct AnalyticsView: View {
    
    @EnvironmentObject var courseVM: CourseViewModel
    @EnvironmentObject var VM: AnalyticsViewModel
    
    let anaRepo = AnalyticsRepository()
    
    @State private var topBarHeight: CGFloat = 140
    @State private var canManualRefresh = true
    @State private var refreshRotation: Double = 0
    private let refreshCooldown: TimeInterval = 3
    
    @State var isRotating: Bool = false
    
    var body: some View {
        VStack {
            VStack (spacing: 8){
                HStack{
                    VStack(alignment: .leading){
                        Text("Analytics")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(VM.pickedSection == "Day Range" ? VM.selectedSection.rawValue : "Retention")
                            .font(.subheadline)
                    }
                    
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(){
                            isRotating = true
                            triggerAnalyticsRefresh(isAnalytics: VM.pickedSection == "Day Range")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isRotating = false
                            }
                        }
                    }) {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .rotationEffect(.degrees(isRotating ? 360 : 0))
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 30, height: 30)
                    }
                    .disabled(!canManualRefresh)
                    .opacity(canManualRefresh ? 1 : 0.45)
                    

                    Menu {
                        Button {
                            anaRepo.uploadDebugDailyDocs(courseID: courseVM.selectedCourse!.id) { success in
                                if success{
                                    Task {
                                        await VM.onAppearDailyAnalytics(course: courseVM.selectedCourse)
                                    }
                                }
                            }
                        } label: {
                            Label("Upload Daily Docs", systemImage: "calendar")
                        }
                        
                        Button {
                            anaRepo.uploadDebugEmails(courseID: courseVM.selectedCourse!.id, count: 100) { success in
                                if success {
                                    // Refresh the emails after upload
                                    Task {
                                        await VM.onAppearRetention(course: courseVM.selectedCourse)
                                    }
                                }
                            }
                        } label: {
                            Label("Upload 100 Test Emails", systemImage: "envelope.badge.fill")
                        }
                    } label: {
                        Image(systemName: "hammer.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Picker("Section", selection: $VM.pickedSection) {
                    ForEach(VM.pickerSections, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding([.horizontal, .top])
            
            ZStack (alignment: .top){
                if VM.pickedSection == "Day Range" {
                    dayRangecontent
                    topBar
                } else {
                    RetentionView()
                        
                }
            }
        }
        .environmentObject(VM)
        .background(.bg)
        .onChange(of: VM.range) { old, new in
            withAnimation{
                VM.onChange(old: old, new: new, course: courseVM.selectedCourse)
            }
        }
    }
    var dayRangecontent: some View {
        // Content
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0){
                    Color.clear
                        .frame(height: 0)
                        .id("top")
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
                            GrowthTab()
                                .transition(.opacity)
                        } else if VM.selectedSection == .operations {
                            OperationsTab()
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        } else if VM.selectedSection == .experience {
                            ExpierenceTab()
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        }
                    }
                }
            }
            .contentMargins([.horizontal, .bottom], 16)
            .contentMargins(.top, topBarHeight)
            .onChange(of: VM.selectedSection) { _, _ in
                proxy.scrollTo("top", anchor: .top)
            }
            .onChange(of: VM.range) { _, _ in
                withAnimation {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }
    
    
    
    
    
    
    
    var topBar: some View {
        // Top Bar
        VStack (spacing: 16){
            
            
            HStack {
                ForEach(AnalyticsSection.allCases) { section in
                    if let obj = VM.analyticsObjects[section.rawValue] {
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
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                topBarHeight = proxy.size.height + 24
                            }
                        }
                    }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
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
    
    private func triggerAnalyticsRefresh(isAnalytics: Bool = true) {
        guard canManualRefresh else { return }
        canManualRefresh = false

        if isAnalytics {
            VM.refreshAnalytics(course: courseVM.selectedCourse)
        } else {
            Task {
                await VM.onAppearRetention(course: courseVM.selectedCourse)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + refreshCooldown) {
            canManualRefresh = true
        }
    }
}

struct HoleDifficultyCharts: View {
    @EnvironmentObject var VM: AnalyticsViewModel
    @State var difficultyData: [HoleDifficultyData] = []
    
    var body: some View {
        // SECTION 1: HARDNESS
        VStack(spacing: 16) {
            HoleDifficultyChart(difficultyData: $difficultyData)
            HoleHardnessPreviewList(difficultyData: $difficultyData)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 17).fill(.subTwo))
        .task{
            difficultyData = await VM.getHoleDifficultyData()
        }
    }
}

struct HoleDifficultyParCharts: View {
    @EnvironmentObject var VM: AnalyticsViewModel
    @State var difficultyData: [HoleHeatmapData] = []
    let course: Course
    
    init(course: Course) {
        self.course = course
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HoleDifficultyParChart(difficultyData: $difficultyData)
                .frame(height: 100)
            
            HolePreviewList(allHoles: $difficultyData)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 17).fill(.subTwo))
        .task{
            difficultyData = await VM.getHoleHeatmapForParData(course: course)
        }
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


