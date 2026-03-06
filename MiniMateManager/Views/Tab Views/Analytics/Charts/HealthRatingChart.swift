//
//  HealthRatingChart.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 3/4/26.
//

import Charts
import SwiftUI

struct HealthRatingChart: View {
    @EnvironmentObject var viewModel: CourseViewModel
    let healthReport: CourseHealthReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Course Health Rating")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
                InfoButton(infoText: "Overall health score based on Growth (30%), Operations (20%), Experience (20%), and Retention (30%).")
            }
            VStack{
                ZStack {
                    // Central Label
                    VStack(spacing: 4) {
                        Text("\(Int(healthReport.overallScore))%")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(healthReport.overallGrade.color)
                        
                        Text(healthReport.overallGrade.rawValue)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(healthReport.overallGrade.color)
                    }
                    
                    
                    Chart {
                        SectorMark(
                            angle: .value("Score", healthReport.overallScore),
                            innerRadius: .ratio(0.7),
                            angularInset: 1.0
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                        
                        SectorMark(
                            angle: .value("Remaining", 100 - healthReport.overallScore),
                            innerRadius: .ratio(0.7),
                            angularInset: 1.0
                        )
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .frame(height: 130)
                .background{
                    Circle()
                        .subTwoVsColor(makeColor: viewModel.selectedCourse?.scoreCardColor)
                        .scaledToFit()
                        .frame(height: 145)
                }
                .padding(.bottom, 10)
                
                VStack{
                    // Quick stats
                    HStack{
                        miniStatCard(
                            title: "Growth",
                            score: healthReport.growthHealth.score,
                            grade: healthReport.growthHealth.grade
                        )
                        miniStatCard(
                            title: "Retention",
                            score: healthReport.retentionHealth.score,
                            grade: healthReport.retentionHealth.grade
                        )
                    }
                    HStack{
                        miniStatCard(
                            title: "Operations",
                            score: healthReport.operationsHealth.score,
                            grade: healthReport.operationsHealth.grade
                        )
                        miniStatCard(
                            title: "Experience",
                            score: healthReport.experienceHealth.score,
                            grade: healthReport.experienceHealth.grade
                        )
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 25)
                .subVsColor(makeColor: viewModel.selectedCourse?.scoreCardColor)
                .cardShadow()
        }
    }
    
    private var gradientColors: [Color] {
        switch healthReport.overallScore {
        case 85...:
            return [.green, .green.opacity(0.7)]
        case 70..<85:
            return [.blue, .cyan]
        case 50..<70:
            return [.orange, .yellow]
        default:
            return [.red, .orange]
        }
    }
    
    @ViewBuilder
    private func miniStatCard(title: String, score: Double, grade: HealthGrade) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack{
                HStack{
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.mainOpp)
                        .lineLimit(1)
                    Spacer()
                }
                HStack(spacing: 6) { // Slightly reduced spacing to match smaller text
                    Text("\(Int(score))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(grade.color)
                        .lineLimit(1)
                    
                    Text(grade.rawValue)
                        .font(.caption)
                        .lineLimit(1)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(grade.color)
                        }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .subTwoVsColor(makeColor: viewModel.selectedCourse?.scoreCardColor)
        }
    }
}

struct SectionHealthDetailView: View {
    let healthReport: CourseHealthReport
    @State var titleHeight: CGFloat = 0
    
    var body: some View {
        ZStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 12) {
                        sectionCard(healthReport.growthHealth)
                        sectionCard(healthReport.retentionHealth)
                        sectionCard(healthReport.operationsHealth)
                        sectionCard(healthReport.experienceHealth)
                    }
                    
                    // Top Insights
                    if !healthReport.topInsights.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Key Insights")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                ForEach(Array(healthReport.topInsights.prefix(5).enumerated()), id: \.offset) { _, insight in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.caption)
                                            .foregroundStyle(.yellow)
                                            .frame(width: 16)
                                        
                                        Text(insight)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.subTwo)
                        }
                    }
                }
            }
            .contentMargins(.top, titleHeight)
            .contentMargins(16)
            
            VStack{
                HStack {
                    Text("Health Breakdown")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.top, 32)
                .padding(.horizontal)
                .padding(.bottom)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .task(id: proxy.size) {
                                titleHeight = proxy.size.height // Capture the size and monitor changes
                            }
                    }
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.main,
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                )
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func sectionCard(_ rating: SectionHealthRating) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rating.section.rawValue)
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(Int(rating.score))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(rating.grade.color)
                    
                    Text(rating.grade.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(rating.grade.color)
                        }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(rating.grade.color)
                        .frame(width: geometry.size.width * (rating.score / 100), height: 8)
                }
            }
            .frame(height: 8)
            
            // Top insights for this section
            if !rating.insights.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(rating.insights.prefix(2).enumerated()), id: \.offset) { _, insight in
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: insight.imageName)
                                .font(.caption)
                                .foregroundStyle(insight.color)
                                .frame(width: 16, height: 16)
                            
                            Text(insight.descripton)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.subTwo)
        }
    }
}
