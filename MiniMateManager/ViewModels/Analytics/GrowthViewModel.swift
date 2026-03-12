//
//  GrowthViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class GrowthViewModel: ObservableObject {
    
    @Published var rangeDailyDocs: [DailyDoc] = []
    @Published var deltaDailyDocs: [DailyDoc] = []
    @Published var range: AnalyticsRange = .last30
    @Published var growthChartTopic: ChartTopic = .total
    
    // MARK: - Growth Metrics
    
    func getActiveUsers(_ docs: [DailyDoc]) -> Int {
        docs.reduce(0) { $0 + $1.totalCount }
    }
    
    func getFirstTimeUsers(_ docs: [DailyDoc]) -> Int {
        docs.reduce(0) { $0 + $1.newPlayers }
    }
    
    func firstTimePercOfTotal() -> Double {
        let value = getFirstTimeUsers(rangeDailyDocs)
        
        guard value > 0 else { return 0 }
        
        return Double(value) / Double(getActiveUsers(rangeDailyDocs))
    }
    
    func getReturningUsers(_ docs: [DailyDoc]) -> Int {
        docs.reduce(0) { $0 + $1.returningPlayers }
    }
    
    func returningPercOfTotal() -> Double {
        let value = getReturningUsers(rangeDailyDocs)
        
        guard value > 0 else { return 0 }
        
        return Double(value) / Double(getActiveUsers(rangeDailyDocs))
    }
    
    func avgPlayersPerGame(_ docs: [DailyDoc]) -> Double {
        
        let totalGames = docs.reduce(0) { $0 + $1.gamesPlayed }
        let players = getActiveUsers(docs)
        
        return players > 0 ? Double(players) / Double(totalGames) : 0
    }
    
    // MARK: - Prime (Data Points with Deltas)
    
    func activeUsersPrime() -> DataPointObject {
        let rangeUsers = getActiveUsers(rangeDailyDocs)
        let deltaUsers = getActiveUsers(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        let data = deltaErrorCalc(delta: &delta, positiveGood: true)
        
        return DataPointObject(value: String(rangeUsers), delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    func firstTimePrime() -> DataPointObject {
        let rangeUsers = getFirstTimeUsers(rangeDailyDocs)
        let deltaUsers = getFirstTimeUsers(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        let data = deltaErrorCalc(delta: &delta, positiveGood: true)
        
        return DataPointObject(value: String(rangeUsers), delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    func returningPrime() -> DataPointObject {
        let rangeUsers = getReturningUsers(rangeDailyDocs)
        let deltaUsers = getReturningUsers(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        let data = deltaErrorCalc(delta: &delta, positiveGood: true)
        
        return DataPointObject(value: String(rangeUsers), delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    func avgPlayersPerGamePrime() -> DataPointObject {
        let rangeUsers = avgPlayersPerGame(rangeDailyDocs)
        let deltaUsers = avgPlayersPerGame(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        let data = deltaErrorCalc(delta: &delta, positiveGood: true)
        
        return DataPointObject(value: String(format: "%.2f / 1", rangeUsers), delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    // MARK: - Chart Data
    
    func getDataForGrowthTrend() async -> [PlayerActivity] {
        // Get snapshot of data
        let rangeDocs = rangeDailyDocs
        let rangeObj = range
        let chartTopic = growthChartTopic
        
        // Compute on background thread
        return await Task.detached(priority: .userInitiated) {
            // 1. Sort the source data first so the line draws from left to right
            let sortedDocs = rangeDocs.sorted { $0.dayID < $1.dayID }
            
            // 2. Create a dictionary for quick lookup of existing data
            let docsByDateString = Dictionary(uniqueKeysWithValues: sortedDocs.map { ($0.dayID, $0) })
            
            // 3. Generate all dates in the range and fill in missing days with count 0
            var result: [PlayerActivity] = []
            var currentDate = await Calendar.current.startOfDay(for: rangeObj.startDate)
            let endDate = await Calendar.current.startOfDay(for: rangeObj.endDate)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            while currentDate <= endDate {
                let dateString = formatter.string(from: currentDate)
                
                if let doc = docsByDateString[dateString] {
                    // Data exists for this day
                    let count: Int
                    switch chartTopic {
                    case .total:
                        count = await doc.totalCount
                    case .first:
                        count = doc.newPlayers
                    case .returning:
                        count = doc.returningPlayers
                    }
                    result.append(PlayerActivity(date: currentDate, count: count))
                } else {
                    // No data for this day, add zero
                    result.append(PlayerActivity(date: currentDate, count: 0))
                }
                
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            return result
        }.value
    }
    
    // MARK: - Helper Functions
    
    private func deltaErrorCalc(delta: inout Double, positiveGood: Bool) -> (deltaS: String?, deltaC: Color?) {
        // Only zero out delta if we have no delta data at all
        // Otherwise, calculate with whatever data we have
        
        if deltaDailyDocs.isEmpty || (rangeDailyDocs.count != deltaDailyDocs.count && rangeDailyDocs.count != deltaDailyDocs.count + 1 && rangeDailyDocs.count != deltaDailyDocs.count - 1) || (delta > 999 || delta < -999) {
            delta = 0
        }
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        if delta == 0 {
            return(nil, nil)
        } else {
            return(deltaString, postive(good: positiveGood, delta))
        }
    }
    
    private func calcDelta(_ prev: Int, _ current: Int) -> Double {
        guard prev != 0 else { return 0 }
        return (Double(current - prev) / Double(prev)) * 100
    }
    
    private func calcDelta(_ prev: Double, _ current: Double) -> Double {
        guard prev != 0 else { return 0 }
        return ((current - prev) / prev) * 100
    }
    
    private func postive(good: Bool, _ delta: Double) -> Color {
        if delta > 0 && good {
            return .green
        } else if delta < 0 && !good {
            return .green
        } else if delta < 0 && good {
            return .red
        } else if delta > 0 && !good {
            return .red
        } else if delta == 0 {
            return .mainOpp
        } else {
            return .mainOpp
        }
    }
}
