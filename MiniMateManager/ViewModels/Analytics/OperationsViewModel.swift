//
//  OperationsViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class OperationsViewModel: ObservableObject {
    
    @Published var rangeDailyDocs: [DailyDoc] = []
    @Published var deltaDailyDocs: [DailyDoc] = []
    @Published var range: AnalyticsRange = .last30
    
    // MARK: - Operations Metrics
    
    func avgGamesPerDay(_ docs: [DailyDoc]) -> Double {
        let totalGames = docs.reduce(0) { $0 + $1.gamesPlayed }
        let avgGamesPerDay = Double(totalGames) / max(1, Double(rangeDailyDocs.count))
        
        return avgGamesPerDay
    }
    
    func avgGamesPerDayPrime() -> DataPointObject {
        let rangeData = avgGamesPerDay(rangeDailyDocs)
        let deltaData = avgGamesPerDay(deltaDailyDocs)
        var delta = calcDelta(deltaData, rangeData)
        
        let data = deltaErrorCalc(delta: &delta, positiveGood: true)
        
        return DataPointObject(value: String(format: "%.2f", rangeData), delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    func avgPlayersPerGame(_ docs: [DailyDoc]) -> Double {
        let totalGames = docs.reduce(0) { $0 + $1.gamesPlayed }
        let totalPlayers = docs.reduce(0) { $0 + $1.totalCount }
        
        return totalGames > 0 ? Double(totalPlayers) / Double(totalGames) : 0
    }
    
    func avgPlayersPerGamePrime() -> DataPointObject {
        let rangeUsers = avgPlayersPerGame(rangeDailyDocs)
        let deltaUsers = avgPlayersPerGame(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        let data = deltaErrorCalc(delta: &delta, positiveGood: true)
        
        return DataPointObject(value: String(format: "%.2f / 1", rangeUsers), delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    func getBusiestHour() -> DataPointObject {
        let fragments: [[String: Int]] = rangeDailyDocs.map(\.hourlyCounts)

        guard !fragments.isEmpty else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }

        // Initialize all hours to zero so keys are always present.
        var combinedCounts: [String: Int] = (0...23).reduce(into: [:]) { dict, hour in
            dict["\(hour)"] = 0
        }

        for fragment in fragments {
            for (hour, count) in fragment {
                combinedCounts[hour, default: 0] += count
            }
        }

        guard let busiest = combinedCounts.max(by: { $0.value < $1.value }), busiest.value > 0 else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }

        let busiestHour = Int(busiest.key) ?? 0
        var suffix = ""
        var displayHour = busiestHour

        switch busiestHour {
        case 0:
            displayHour = 12
            suffix = "am"
        case 1...11:
            suffix = "am"
        case 12:
            suffix = "pm"
        case 13...23:
            displayHour = busiestHour - 12
            suffix = "pm"
        default:
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }

        let valueString = "\(displayHour)\(suffix)"

        return DataPointObject(value: valueString, delta: nil, deltaColor: .mainOpp)
    }

    func getBusiestDay() -> DataPointObject {
        guard !rangeDailyDocs.isEmpty else {
            return DataPointObject(value: "N/A", deltaColor: .mainOpp)
        }

        // Sum up games played by weekday.
        let weeklyVolume = rangeDailyDocs.reduce(into: [Int: Int]()) { dict, doc in
            dict[doc.weekDay, default: 0] += doc.gamesPlayed
        }

        guard let busiestDay = weeklyVolume.max(by: { $0.value < $1.value }), busiestDay.value > 0 else {
            return DataPointObject(value: "N/A", deltaColor: .mainOpp)
        }

        let dayLabels = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard (1...7).contains(busiestDay.key) else {
            return DataPointObject(value: "N/A", deltaColor: .mainOpp)
        }

        return DataPointObject(value: dayLabels[busiestDay.key], deltaColor: .mainOpp)
    }
    
    func prepareChartData() async -> [HourData] {
        // Get snapshot of data
        let rangeDocs = rangeDailyDocs
        
        // Compute on background thread
        return await Task.detached(priority: .userInitiated) {
            var chartData: [HourData] = []
            
            // Loop through each day (1-7)
            for day in 1...7 {
                // Find docs that match this weekday
                let dayDocs = rangeDocs.filter { $0.weekDay == day }
                
                // Loop through each hour (0-23)
                for hour in 0...23 {
                    // Sum up all games played at this hour across all filtered docs
                    let totalForHour = dayDocs.reduce(0) { $0 + ($1.hourlyCounts["\(hour)"] ?? 0) }
                    
                    chartData.append(HourData(weekday: day, hour: hour, count: totalForHour))
                }
            }
            return chartData
        }.value
    }
    
    func getDataForGamesPerDay() async -> [PlayerActivity] {
        // Get snapshot of data
        let rangeDocs = rangeDailyDocs
        let rangeObj = range
        
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
                    // Data exists for this day - use gamesPlayed
                    result.append(PlayerActivity(date: currentDate, count: doc.gamesPlayed))
                } else {
                    // No data for this day, add zero
                    result.append(PlayerActivity(date: currentDate, count: 0))
                }
                
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            return result
        }.value
    }
    
    // MARK: - Game Duration Metrics
    
    /// Calculate average game duration in minutes
    func getAvgGameDuration() -> DataPointObject {
        let totalGames = rangeDailyDocs.reduce(0) { $0 + $1.gamesPlayed }
        let totalSeconds = rangeDailyDocs.reduce(0) { $0 + $1.totalRoundSeconds }
        let totalGamesDelta = deltaDailyDocs.reduce(0) { $0 + $1.gamesPlayed }
        let totalSecondsDelta = deltaDailyDocs.reduce(0) { $0 + $1.totalRoundSeconds }
        
        guard totalGames > 0 else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        let avgSeconds = Double(totalSeconds) / Double(totalGames)
        let minutes = Int(avgSeconds / 60)
        
        guard totalGamesDelta > 0 else {
            return DataPointObject(value: "\(minutes) min", delta: nil, deltaColor: .mainOpp)
        }
        
        let avgSecondsDelta = Double(totalSecondsDelta) / Double(totalGamesDelta)
        let minutesDelta = Int(avgSecondsDelta / 60)
        
        var delta = calcDelta(minutes, minutesDelta)
        let data = deltaErrorCalc(delta: &delta, positiveGood: false)
        
        return DataPointObject(value: "\(minutes) min", delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    /// Calculate total play time across all games
    func getTotalPlayTime() -> DataPointObject {
        let totalSeconds = rangeDailyDocs.reduce(0) { $0 + $1.totalRoundSeconds }
        let totalSecondsDelta = deltaDailyDocs.reduce(0) { $0 + $1.totalRoundSeconds }
        
        let hours = Int(totalSeconds / 3600)
        let hoursDelta = Int(totalSecondsDelta / 3600)
        
        var delta = calcDelta(hours, hoursDelta)
        let data = deltaErrorCalc(delta: &delta, positiveGood: false)
        
        if hours < 1 {
            let minutes = Int(totalSeconds / 60)
            return DataPointObject(value: "\(minutes) min", delta: data.deltaS, deltaColor: data.deltaC)
        } else if hours < 24 {
            return DataPointObject(value: "\(hours) hrs", delta: data.deltaS, deltaColor: data.deltaC)
        } else {
            let days = hours / 24
            let remainingHours = hours % 24
            return DataPointObject(value: "\(days)d \(remainingHours)h", delta: data.deltaS, deltaColor: data.deltaC)
        }
    }
    
    /// Find the fastest game duration
    func getFastestGameTime() -> DataPointObject {
        var fastestSeconds: Int64 = .max
        
        for doc in rangeDailyDocs {
            guard doc.gamesPlayed > 0 else { continue }
            let avgForDay = doc.totalRoundSeconds / Int64(doc.gamesPlayed)
            if avgForDay < fastestSeconds && avgForDay > 0 {
                fastestSeconds = avgForDay
            }
        }
        
        var fastestSecondsDelta: Int64 = .max
        
        for doc in deltaDailyDocs {
            guard doc.gamesPlayed > 0 else { continue }
            let avgForDay = doc.totalRoundSeconds / Int64(doc.gamesPlayed)
            if avgForDay < fastestSeconds && avgForDay > 0 {
                fastestSecondsDelta = avgForDay
            }
        }
        
        var delta = calcDelta(fastestSeconds, fastestSecondsDelta)
        let data = deltaErrorCalc(delta: &delta, positiveGood: false)
        
        guard fastestSeconds != .max && fastestSeconds > 0 else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        let minutes = Int(fastestSeconds / 60)
        return DataPointObject(value: "\(minutes) min", delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    /// Find the longest game duration
    func getSlowestGameTime() -> DataPointObject {
        var slowestSeconds: Int64 = 0
        
        for doc in rangeDailyDocs {
            guard doc.gamesPlayed > 0 else { continue }
            let avgForDay = doc.totalRoundSeconds / Int64(doc.gamesPlayed)
            if avgForDay > slowestSeconds {
                slowestSeconds = avgForDay
            }
        }
        
        var slowestSecondsDelta: Int64 = 0
        
        for doc in rangeDailyDocs {
            guard doc.gamesPlayed > 0 else { continue }
            let avgForDay = doc.totalRoundSeconds / Int64(doc.gamesPlayed)
            if avgForDay > slowestSeconds {
                slowestSecondsDelta = avgForDay
            }
        }
        
        var delta = calcDelta(slowestSeconds, slowestSecondsDelta)
        let data = deltaErrorCalc(delta: &delta, positiveGood: false)
        
        guard slowestSeconds > 0 else {
            return DataPointObject(value: "N/A", delta: nil, deltaColor: .mainOpp)
        }
        
        let minutes = Int(slowestSeconds / 60)
        return DataPointObject(value: "\(minutes) min", delta: data.deltaS, deltaColor: data.deltaC)
    }
    
    /// Generate time-series data for duration trend chart
    func getDataForDurationTrend() async -> [GameDurationActivity] {
        // Get snapshot of data
        let rangeDocs = rangeDailyDocs
        let rangeObj = range
        
        // Compute on background thread
        return await Task.detached(priority: .userInitiated) {
            // Sort the source data first
            let sortedDocs = rangeDocs.sorted { $0.dayID < $1.dayID }
            
            // Create a dictionary for quick lookup
            let docsByDateString = Dictionary(uniqueKeysWithValues: sortedDocs.map { ($0.dayID, $0) })
            
            // Generate all dates in the range
            var result: [GameDurationActivity] = []
            var currentDate = await Calendar.current.startOfDay(for: rangeObj.startDate)
            let endDate = await Calendar.current.startOfDay(for: rangeObj.endDate)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            while currentDate <= endDate {
                let dateString = formatter.string(from: currentDate)
                
                if let doc = docsByDateString[dateString], doc.gamesPlayed > 0 {
                    let avgSeconds = Double(doc.totalRoundSeconds) / Double(doc.gamesPlayed)
                    let avgMinutes = avgSeconds / 60.0
                    result.append(GameDurationActivity(date: currentDate, avgMinutes: avgMinutes))
                } else {
                    // No data for this day, add zero
                    result.append(GameDurationActivity(date: currentDate, avgMinutes: 0))
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
    
    private func calcDelta(_ prev: Int64, _ current: Int64) -> Double {
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
