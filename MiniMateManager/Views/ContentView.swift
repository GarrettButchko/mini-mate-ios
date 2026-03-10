//
//  ContentView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/6/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewManager: ViewManager
    @StateObject var viewModel = CourseViewModel()
    
    let courseRepo = CourseRepository()
    
    @State private var selectedTab = 1
    
    var body: some View {
        ZStack {
            Group {
                switch viewManager.currentView {
                case .courseTab(let tab):
                    ZStack{
                        CourseTabView(selectedTab: tab)
                        ColorPickerView(showColor: $viewModel.showColor, addTarget: $viewModel.addTarget) { color in
                            withAnimation() {
                                guard var course = viewModel.selectedCourse else { return }
                                
                                switch viewModel.addTarget {
                                case .scoreCardColor:
                                    course.scoreCardColorDT = colorToString(color)
                                case .courseColor:
                                    course.courseColorsDT = (course.courseColorsDT ?? []) + [colorToString(color)]
                                case nil:
                                    viewModel.addTarget = nil
                                }
                                
                                viewModel.selectedCourse = course
                                courseRepo.addOrUpdateCourse(course) { _ in }
                                viewModel.showColor = false
                            }
                        }
                        .opacity(viewModel.showColor ? 1 : 0)
                        .animation(.spring(duration: 0.25, bounce: 0.4), value: viewModel.showColor)
                        .allowsHitTesting(viewModel.showColor)
                    }
                case .courseList:
                    CourseListView()
                case .welcome:
                    WelcomeView(viewManager: viewManager, welcomeText: "Mini Mate Manager", gradientColors: [.managerBlue, .managerGreen])
                case .signIn:
                    SignInView(gradientColors: [.managerBlue, .managerGreen])
                }
            }
        }
        .animation(.easeInOut(duration: 0.1), value: viewManager.currentView)
        .environmentObject(viewModel)
    }
    
    func colorToString(_ color: Color) -> String {
        return String(describing: color)
    }
}

struct CourseTabView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var analyticsVM = AnalyticsViewModel()
    @StateObject private var leaderboardVM = LeaderBoardViewModel()
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var VM: CourseViewModel

    @State var selectedTab: Int
    
    init(selectedTab: Int){
        self.selectedTab = selectedTab
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AnalyticsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(0)
            
            MainView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(1)
            
            CourseSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(2)
        }
        .onAppear {
            VM.start()
            Task {
                await analyticsVM.loadHealthData(course: VM.selectedCourse)
            }
        }
        .onDisappear {
            VM.stop()
        }
        .environmentObject(analyticsVM)
        .environmentObject(analyticsVM.growthVM)
        .environmentObject(analyticsVM.operationsVM)
        .environmentObject(analyticsVM.experienceVM)
        .environmentObject(analyticsVM.retentionVM)
        .environmentObject(leaderboardVM)
    }
}
