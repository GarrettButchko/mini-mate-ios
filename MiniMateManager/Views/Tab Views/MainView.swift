//
//  MainView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI
import FirebaseAuth
import MarqueeText

struct MainView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CourseViewModel
    @EnvironmentObject var viewManager: ViewManager
    @EnvironmentObject var analyticsVM: AnalyticsViewModel
    
    @State var showLeaderBoardSheet: Bool = false
    @State var showTournamentSheet: Bool = false
    @State var isSheetPresented: Bool = false
    
    @State private var buttonsViewHeight: CGFloat = 0 // State to track the height of the buttons view
    
    @State private var titleHeight: CGFloat = 0 // State to track the height of the title view
    
    @State var showHealthRatingSheet: Bool = false
    
    let healthReportHeight: CGFloat = 350
    
    var body: some View {
        VStack{
            HStack(alignment: .center, spacing: 16) {
                Button {
                    viewManager.navigateToCourseList()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.setCourse(course: nil)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.blue)
                        .frame(width: 20, height: 20)
                }
                
                HStack{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Course Dashboard For,")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        MarqueeText(
                            text: viewModel.selectedCourse?.name ?? "No Course Selected",
                            font: UIFont.preferredFont(forTextStyle: .title2),
                            leftFade: 16,
                            rightFade: 16,
                            startDelay: 2,
                            alignment: .leading
                        )
                        .fontWeight(.semibold)
                    }
                    .background {
                        GeometryReader { proxy in
                            Color.clear
                                .task(id: proxy.size) {
                                    titleHeight = proxy.size.height // Capture the size and monitor changes
                                }
                        }
                    }
                    
                    if let courseLogo = viewModel.selectedCourse?.logo {
                        Divider()
                        
                        AsyncImage(url: URL(string: courseLogo)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .id(URL(string: courseLogo))
                    }
                }
                .frame(maxHeight: titleHeight)
                
                Spacer()
                
                Button(action: {
                    isSheetPresented = true
                }) {
                    if let photoURL = authModel.firebaseUser?.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image("logoOpp")
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image("logoOpp")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    ProfileView(
                        viewManager: viewManager,
                        authModel: authModel,
                        isSheetPresent: $isSheetPresented, context: context
                    )
                }
            }
            .padding([.horizontal, .top])
            
            TitleView(colors: viewModel.selectedCourse?.courseColors, isManager: true)
                .frame(height: 150)
                .padding(.bottom)
            
            ZStack(alignment: .top){
                ScrollView{
                    VStack (spacing: 16){
                        if analyticsVM.isLoadingHealth {
                            ProgressView("Analyzing course health...")
                                .frame(height: 375)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 25)
                                        .subVsColor(makeColor: viewModel.selectedCourse?.scoreCardColor)
                                        .cardShadow()
                                }
                        } else if let report = analyticsVM.healthReport {
                            Button{
                                showHealthRatingSheet = true
                            } label: {
                                HealthRatingChart(healthReport: report)
                                    .frame(height: 375)
                            }
                            .sheet(isPresented: $showHealthRatingSheet){
                                SectionHealthDetailView(healthReport: report)
                                    .presentationDragIndicator(.visible)
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                
                                Text("No Health Data Available")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Text("Analytics data is being collected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(height: 375)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 25)
                                    .subVsColor(makeColor: viewModel.selectedCourse?.scoreCardColor)
                                    .cardShadow()
                            }
                        }
                    }
                }
                .contentMargins(.top, buttonsViewHeight + 16)
                
                
                HStack(spacing: 14){
                    mainViewButton(title: "Leaderboard", icon: "flag.pattern.checkered", color: Color.green) {
                        showLeaderBoardSheet = true
                    }
                    .sheet(isPresented: $showLeaderBoardSheet) {
                        LeaderBoardView()
                            .presentationDragIndicator(.visible)
                    }
                    
                    mainViewButton(title: "Tournament", icon: "medal", color: Color.orange) {
                            showTournamentSheet = true
                    }
                    .sheet(isPresented: $showTournamentSheet) {
                        TournamentView()
                            .presentationDragIndicator(.visible)
                    }
                }
                .padding()
                .background(content: {
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 25)
                            .ifAvailableGlassEffect(strokeWidth: 0, makeColor: viewModel.selectedCourse?.scoreCardColor)
                            .cardShadow()
                            .task(id: proxy.size) {
                                buttonsViewHeight = proxy.size.height // Capture the size and monitor changes
                            }
                    }
                })
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
            .contentMargins([.horizontal, .bottom], 16)
        }
        .background(.bg)
    }
    
    func mainViewButton(title: String, icon: String? = nil, color: Color, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Group{
            Button(action: action) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .fontWeight(.semibold)
                }
                .padding(10)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background {
                    RoundedRectangle(cornerRadius: 17)
                        .foregroundStyle(color)
                }
                .foregroundColor(.white)
                .opacity(disabled ? 0.6 : 1.0)
            }
            .disabled(disabled)
        }
    }
    
}
