//
//  File.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//
import SwiftUI

struct ExpierenceTab: View {
    @EnvironmentObject var courseVM: CourseViewModel
    @EnvironmentObject var VM: ExperienceViewModel
    
    var body: some View {
        VStack(spacing: 16){
            
            if let course = courseVM.selectedCourse {
                // SECTION 1: Par Performance Overview
                
                VStack(spacing: 8){
                    HStack{
                        Text("Hole Dificulty")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        InfoButton(infoText: "Greener = Harder, Less opacity = Easier. Based on average strokes per hole. P.S. if holes are missing they are likely unplayed or have no data yet.")
                    }
                    
                    HoleDifficultyCharts()
                    
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
                        Text("Par Performance")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    HStack{
                        DataCard(data: VM.getAvgRelativeToPar(), title: "Avg vs Par", infoText: "Average strokes above or below par across all holes played.", color: .subTwo, cornerRadius: 17)
                        
                        DataCard(data: VM.getMostBeatenPar(), title: "Best Hole", infoText: "Hole where players most frequently beat par.", color: .subTwo, cornerRadius: 17)
                    }
                    
                    HoleDifficultyParCharts(course: course)
                    
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.sub)
                        .cardShadow()
                }
                
                // SECTION 2: Score Distribution
                VStack(spacing: 8){
                    HStack{
                        Text("Score Distribution")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    HStack{
                        DataCard(data: VM.getUnderParPercentage(), title: "Under Par", infoText: "Percentage of holes completed under par.", color: .subTwo, cornerRadius: 17)
                        
                        DataCard(data: VM.getOverParPercentage(), title: "Over Par", infoText: "Percentage of holes completed over par.", color: .subTwo, cornerRadius: 17)
                    }
                    
                    DataCard(data: VM.getHoleInOneCount(), title: "Total Holes-in-One", infoText: "Total number of holes completed in one stroke during this period.", color: .subTwo, cornerRadius: 17)
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
}
