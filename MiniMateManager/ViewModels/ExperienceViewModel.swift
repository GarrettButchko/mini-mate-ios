//
//  ExperienceViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ExperienceViewModel: ObservableObject {
    
    @Published var rangeDailyDocs: [DailyDoc] = []
    @Published var currentCourse: Course?
    
    // MARK: - Experience Metrics
    
    func getHardestHole() -> DataPointObject {
        let avgStrokesPerHole = getHoleCombined()
        
        let hardestHoleID = avgStrokesPerHole.max(by: { $0.value < $1.value })?.key ?? "N/A"
        return DataPointObject(value: "\(hardestHoleID != "N/A" ? "Hole \(hardestHoleID)" : "N/A")", delta: nil, deltaColor: .mainOpp)
    }
    
    func getEasiestHole() -> DataPointObject {
        let avgStrokesPerHole = getHoleCombined()
        
        let easiestHoleID = avgStrokesPerHole.min(by: { $0.value < $1.value })?.key ?? "N/A"
        return DataPointObject(value: "\(easiestHoleID != "N/A" ? "Hole \(easiestHoleID)" : "N/A")", delta: nil, deltaColor: .mainOpp)
    }
    
    func getHoleCombined() -> [String: Double] {
        
        var combinedTotalStrokes: [String: Int] = [:]
        var combinedPlays: [String: Int] = [:]
        
        for doc in rangeDailyDocs {
            for (holeID, strokes) in doc.holeAnalytics.totalStrokesPerHole {
                combinedTotalStrokes[holeID, default: 0] += strokes
            }
            
            for (holeID, plays) in doc.holeAnalytics.playsPerHole {
                combinedPlays[holeID, default: 0] += plays
            }
        }
        
        let avgStrokesPerHole: [String: Double] = combinedTotalStrokes.reduce(into: [:]) { dict, hole in
            return dict[hole.key] = Double(hole.value) / Double(combinedPlays[hole.key] ?? 1)
        }
        
        return avgStrokesPerHole
    }
    
    func getHoleDifficultyData() async -> [HoleDifficultyData] {
        // In your Parent View / ViewModel
        let results = getHoleCombined()
        
        // Compute on background thread
        return await Task.detached(priority: .userInitiated) {
            // Convert [String: Double] to [HoleDifficultyData] sorted by hole number
            let chartData = results.compactMap { (key, value) -> HoleDifficultyData? in
                guard let holeNum = Int(key) else { return nil }
                return HoleDifficultyData(holeNumber: holeNum, averageStrokes: value)
            }.sorted(by: { $0.holeNumber < $1.holeNumber })
            
            return chartData
        }.value
    }
    
    func getHoleHeatmapForParData(course: Course) async -> [HoleHeatmapData] {
        let combinedResults = getHoleCombined() // [String: Double] (HoleID: AvgStrokes)
        
        // Compute on background thread
        return await Task.detached(priority: .userInitiated) {
            return combinedResults.compactMap { (key, avgStrokes) -> HoleHeatmapData? in
                guard let holeNum = Int(key) else { return nil }
                
                // Ensure we don't go out of bounds of the pars array (Index is holeNum - 1)
                let index = holeNum - 1
                guard index >= 0 && index < course.pars.count else { return nil }
                
                let par = Double(course.pars[index])
                let offset = avgStrokes - par
                
                return HoleHeatmapData(holeNumber: holeNum, relativeToPar: offset, holePar: course.pars[index])
            }
            .sorted(by: { $0.holeNumber < $1.holeNumber })
        }.value
    }
    
    /// Calculate average strokes relative to par across all holes
    func getAvgRelativeToPar() -> DataPointObject {
        guard let course = currentCourse else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        let holeCombined = getHoleCombined()
        var totalOffset: Double = 0
        var validHoleCount = 0
        
        for (holeID, avgStrokes) in holeCombined {
            guard let holeNum = Int(holeID),
                  holeNum > 0,
                  holeNum <= course.pars.count else { continue }
            
            let par = Double(course.pars[holeNum - 1])
            totalOffset += (avgStrokes - par)
            validHoleCount += 1
        }
        
        guard validHoleCount > 0 else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        let avgOffset = totalOffset / Double(validHoleCount)
        let sign = avgOffset > 0 ? "+" : ""
        let valueString = String(format: "%@%.2f", sign, avgOffset)
        
        return DataPointObject(value: valueString, delta: nil, deltaColor: avgOffset <= 0 ? .green : .red)
    }
    
    /// Find the hole where players beat par most frequently
    func getMostBeatenPar() -> DataPointObject {
        guard let course = currentCourse else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        let holeCombined = getHoleCombined()
        var bestHole = 0
        var bestOffset: Double = .greatestFiniteMagnitude
        
        for (holeID, avgStrokes) in holeCombined {
            guard let holeNum = Int(holeID),
                  holeNum > 0,
                  holeNum <= course.pars.count else { continue }
            
            let par = Double(course.pars[holeNum - 1])
            let offset = avgStrokes - par
            
            if offset < bestOffset {
                bestOffset = offset
                bestHole = holeNum
            }
        }
        
        guard bestHole > 0 else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        return DataPointObject(value: "Hole \(bestHole)", delta: nil, deltaColor: .mainOpp)
    }
    
    /// Calculate percentage of holes completed under par
    func getUnderParPercentage() -> DataPointObject {
        guard let course = currentCourse else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        var totalHolesPlayed = 0
        var underParCount = 0
        
        for doc in rangeDailyDocs {
            for (holeID, totalStrokes) in doc.holeAnalytics.totalStrokesPerHole {
                guard let holeNum = Int(holeID),
                      holeNum > 0,
                      holeNum <= course.pars.count,
                      let plays = doc.holeAnalytics.playsPerHole[holeID],
                      plays > 0 else { continue }
                
                let par = Double(course.pars[holeNum - 1])
                let avgStrokes = Double(totalStrokes) / Double(plays)
                
                if avgStrokes < par {
                    underParCount += plays
                }
                totalHolesPlayed += plays
            }
        }
        
        guard totalHolesPlayed > 0 else {
            return DataPointObject(value: "0%", delta: nil, deltaColor: .mainOpp)
        }
        
        let percentage = (Double(underParCount) / Double(totalHolesPlayed)) * 100
        return DataPointObject(value: percentage != 0 ? String(format: "%.1f%%", percentage) : "N/A", delta: nil, deltaColor: .mainOpp)
    }
    
    /// Calculate percentage of holes completed over par
    func getOverParPercentage() -> DataPointObject {
        guard let course = currentCourse else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        var totalHolesPlayed = 0
        var overParCount = 0
        
        for doc in rangeDailyDocs {
            for (holeID, totalStrokes) in doc.holeAnalytics.totalStrokesPerHole {
                guard let holeNum = Int(holeID),
                      holeNum > 0,
                      holeNum <= course.pars.count,
                      let plays = doc.holeAnalytics.playsPerHole[holeID],
                      plays > 0 else { continue }
                
                let par = Double(course.pars[holeNum - 1])
                let avgStrokes = Double(totalStrokes) / Double(plays)
                
                if avgStrokes > par {
                    overParCount += plays
                }
                totalHolesPlayed += plays
            }
        }
        
        guard totalHolesPlayed > 0 else {
            return DataPointObject(value: "0%", delta: nil, deltaColor: .mainOpp)
        }
        
        let percentage = (Double(overParCount) / Double(totalHolesPlayed)) * 100
        return DataPointObject(value: percentage != 0 ? String(format: "%.1f%%", percentage) : "N/A", delta: nil, deltaColor: .mainOpp)
    }
    
    /// Count total number of holes-in-one
    func getHoleInOneCount() -> DataPointObject {
        var holeInOneCount = 0
        
        for doc in rangeDailyDocs {
            // Check if there's a holeInOne count or if we need to look at strokes == 1
            for (holeID, totalStrokes) in doc.holeAnalytics.totalStrokesPerHole {
                guard let plays = doc.holeAnalytics.playsPerHole[holeID] else { continue }
                
                if totalStrokes == plays { // All plays were holes-in-one
                    holeInOneCount += plays
                }
            }
        }
        
        return DataPointObject(value: String(holeInOneCount), delta: nil, deltaColor: .yellow)
    }
}
