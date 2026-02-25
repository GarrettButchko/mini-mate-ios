//
//  AnalyticsViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/1/26.
//

import Foundation
import Combine
import SwiftUI


enum AnalyticsSection: String, CaseIterable, Identifiable {
    case growth = "Growth"
    case retention = "Retention"
    case operations = "Operations"
    case experience = "Experience"
    
    var id: String { rawValue }
}

enum ChartTopic {
    case total
    case first
    case returning
    
    var title: String {
        switch self {
        case .total: return "Total Visits"
        case .first: return "First Time Visits"
        case .returning: return "Returning Visits"
        }
    }
    
    var color: Color {
        switch self {
        case .total: return .purple
        case .first: return .blue
        case .returning: return .pink
        }
    }
}

struct AnalyticsObject{
    var type: AnalyticsSection
    var icon: String
    var color: Color
}

struct DataPointObject {
    var value: String
    var delta: String?
    var deltaColor: Color
}

struct PlayerActivity: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

@MainActor
final class AnalyticsViewModel: ObservableObject {
    
    let analyticsRepo = AnalyticsRepository()
    
    @Published var range: AnalyticsRange = .last30
    @Published var selectedSection: AnalyticsSection = .growth
    
    // Docs
    @Published var allDailyDocs: [DailyDoc] = []
    
    @Published var growthChartTopic: ChartTopic = .total
    
    @Published var loadingDocs: Bool = true
    
    var deltaDailyDocs: [DailyDoc] {
        allDailyDocs.filter { range.daysInDeltaRange.contains($0.dayID) }
    }
    
    var rangeDailyDocs: [DailyDoc] {
        allDailyDocs.filter { range.daysInMainRange.contains($0.dayID) }
    }
    
    
    
    
    //MARK: Growth
    // Data Calc
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
    
    func deltaErrorCalc( delta: inout Double) {
        if deltaDailyDocs.count != rangeDailyDocs.count - 1 && deltaDailyDocs.count != rangeDailyDocs.count {
            delta = 0
        }
    }
    
    
    
    
    
    // Delta Calc
    func calcDelta(_ prev: Int, _ current: Int) -> Double {
        guard prev != 0 else { return 0 }
        return (Double(current - prev) / Double(prev)) * 100
    }
    
    func calcDelta(_ prev: Double, _ current: Double) -> Double {
        guard prev != 0 else { return 0 }
        return ((current - prev) / prev) * 100
    }
    
    
    

    
    // Prime (Data and delta and color)
    func activeUsersPrime() -> DataPointObject {
        let rangeUsers = getActiveUsers(rangeDailyDocs)
        let deltaUsers = getActiveUsers(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        deltaErrorCalc(delta: &delta)
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        return DataPointObject(value: String(rangeUsers), delta: deltaString, deltaColor: postive(good: true, delta))
    }
    
    func firstTimePrime() -> DataPointObject {
        let rangeUsers = getFirstTimeUsers(rangeDailyDocs)
        let deltaUsers = getFirstTimeUsers(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        deltaErrorCalc(delta: &delta)
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        return DataPointObject(value: String(rangeUsers), delta: deltaString, deltaColor: postive(good: true, delta))
    }
    
    func returningPrime() -> DataPointObject {
        let rangeUsers = getReturningUsers(rangeDailyDocs)
        let deltaUsers = getReturningUsers(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        deltaErrorCalc(delta: &delta)
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        return DataPointObject(value: String(rangeUsers), delta: deltaString, deltaColor: postive(good: true, delta))
    }
    
    func avgPlayersPerGamePrime() -> DataPointObject {
        let rangeUsers = avgPlayersPerGame(rangeDailyDocs)
        let deltaUsers = avgPlayersPerGame(deltaDailyDocs)
        var delta = calcDelta(deltaUsers, rangeUsers)
        
        deltaErrorCalc(delta: &delta)
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        return DataPointObject(value: String(format: "%.1f% / 1", rangeUsers), delta: deltaString, deltaColor: postive(good: true, delta))
    }
    
    func getDataForGrowthTrend() -> [PlayerActivity] {
        // 1. Sort the source data first so the line draws from left to right
        let sortedDocs = rangeDailyDocs.sorted { $0.dayID < $1.dayID }
        
        // 2. Create a dictionary for quick lookup of existing data
        let docsByDateString = Dictionary(uniqueKeysWithValues: sortedDocs.map { ($0.dayID, $0) })
        
        // 3. Generate all dates in the range and fill in missing days with count 0
        var result: [PlayerActivity] = []
        var currentDate = Calendar.current.startOfDay(for: range.startDate)
        let endDate = Calendar.current.startOfDay(for: range.endDate)
        
        while currentDate <= endDate {
            let dateString = formatDateToDateString(currentDate)
            
            if let doc = docsByDateString[dateString] {
                // Data exists for this day
                let count: Int
                switch growthChartTopic {
                case .total:
                    count = doc.totalCount
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
    }
    
    //MARK: Operations
    func getBusiestHour() -> DataPointObject {
        
        let fragments: [[String: Int]] = rangeDailyDocs.map(\.hourlyCounts)
        // 1. Initialize a dict with all hours set to 0
        var combinedCounts: [String: Int] = (0...23).reduce(into: [:]) { dict, hour in
            dict["\(hour)"] = 0
        }
        
        // 2. Merge your data into the master dict
        for fragment in fragments {
            for (hour, count) in fragment {
                combinedCounts[hour, default: 0] += count
            }
        }
        
        var busiestHour: Int = 0
        
        if let busiest = combinedCounts.max(by: { $0.value < $1.value }) {
            busiestHour = Int(busiest.key) ?? 0
        }
        
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
            suffix = "err"
        }
        
        let valueString = "\(displayHour)\(suffix)"
        
        return DataPointObject(value: valueString, delta: nil, deltaColor: .mainOpp)
    }
    
    func getBusiestDay() -> DataPointObject {
        
        // 1. Sum up games played by weekday
        let weeklyVolume = rangeDailyDocs.reduce(into: [Int: Int]()) { dict, doc in
            dict[doc.weekDay, default: 0] += doc.gamesPlayed
        }
        
        var valueString: String = "Err"

        // 2. To find the "Busiest Day" string (e.g., "Sat")
        if let busiestDayInt = weeklyVolume.max(by: { $0.value < $1.value })?.key {
            let dayLabels = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let busiestDayLabel = dayLabels[busiestDayInt]
            valueString = busiestDayLabel.capitalized
        }
        
        return DataPointObject(value: valueString, deltaColor: .mainOpp)
        
    }
    
    func getHardestHole() -> DataPointObject {
        let avgStrokesPerHole = getHoleCombined()
        
        let hardestHoleID = avgStrokesPerHole.max(by: { $0.value < $1.value })?.key ?? "Err"
        return DataPointObject(value: "Hole \(hardestHoleID)", delta: nil, deltaColor: .mainOpp)
    }
    
    func getEasiestHole() -> DataPointObject {
        let avgStrokesPerHole = getHoleCombined()
        
        let easiestHoleID = avgStrokesPerHole.min(by: { $0.value < $1.value })?.key ?? "Err"
        return DataPointObject(value: "Hole \(easiestHoleID)", delta: nil, deltaColor: .mainOpp)
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
    
    func getHoleDifficultyData() -> [HoleDifficultyData]{
        // In your Parent View / ViewModel
        let results = getHoleCombined()

        // Convert [String: Double] to [HoleDifficultyData] sorted by hole number
        let chartData = results.compactMap { (key, value) -> HoleDifficultyData? in
            guard let holeNum = Int(key) else { return nil }
            return HoleDifficultyData(holeNumber: holeNum, averageStrokes: value)
        }.sorted(by: { $0.holeNumber < $1.holeNumber })

        // Pass chartData to HoleDifficultyChart(difficultyData: chartData)
        return chartData
    }
    
    func prepareChartData() -> [HourData] {
        
        var chartData: [HourData] = []
        
        // Loop through each day (1-7)
        for day in 1...7 {
            // Find docs that match this weekday
            let dayDocs = rangeDailyDocs.filter { $0.weekDay == day }
            
            // Loop through each hour (0-23)
            for hour in 0...23 {
                // Sum up all games played at this hour across all filtered docs
                let totalForHour = dayDocs.reduce(0) { $0 + ($1.hourlyCounts["\(hour)"] ?? 0) }
                
                chartData.append(HourData(weekday: day, hour: hour, count: totalForHour))
            }
        }
        return chartData
    }
    
    
    func postive(good: Bool, _ delta: Double, ) -> Color {
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
    
    let analyticsObjects: [String: AnalyticsObject] = [
        AnalyticsSection.growth.rawValue: AnalyticsObject(
            type: .growth,
            icon: "chart.line.uptrend.xyaxis",
            color: .green
        ),
        
        AnalyticsSection.retention.rawValue: AnalyticsObject(
            type: .retention,
            icon: "arrow.triangle.2.circlepath",
            color: .orange
        ),
        
        AnalyticsSection.operations.rawValue: AnalyticsObject(
            type: .operations,
            icon: "clock",
            color: .purple
        ),
        
        AnalyticsSection.experience.rawValue: AnalyticsObject(
            type: .experience,
            icon: "star",
            color: .pink
        )
    ]
    
    func onAppear(course: Course?) {
        guard let course else { return }
        
        withAnimation{
            loadingDocs = true
        }
        
        
        Task {
            allDailyDocs = await analyticsRepo.fetchDailyAnalytics(
                courseID: course.id,
                range: .last30,
                existingDocs: allDailyDocs
            )
            withAnimation{
                loadingDocs = false
            }
        }
    }
    
    func onChange(old: AnalyticsRange, new: AnalyticsRange, course: Course?) {
        guard let course, old != new else { return }
        
        loadingDocs = true
        
        Task {
            allDailyDocs = await analyticsRepo.fetchDailyAnalytics(
                courseID: course.id,
                range: new,
                existingDocs: allDailyDocs
            )
            
            loadingDocs = false
        }
    }
    
    func daysBetween(_ range: AnalyticsRange) -> Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: range.startDate)
        let e = cal.startOfDay(for: range.endDate)
        return cal.dateComponents([.day], from: s, to: e).day ?? 0
    }
    
    func daysBetween(_ start: Date, _ end: Date) -> Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        return cal.dateComponents([.day], from: s, to: e).day ?? 0
    }
    
    /// Converts a Date object to "MMM d" format (e.g., Feb 9)
    /// - Parameter date: Date object to format
    /// - Returns: Formatted date string in "MMM d" format
    func formatDateToMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Converts a Date object to "yyyy-MM-dd" format
    /// - Parameter date: Date object to format
    /// - Returns: Formatted date string in "yyyy-MM-dd" format
    func formatDateToDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func formatDateStringToMonthDay(_ dateString: String) -> Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        return inputFormatter.date(from: dateString)!
    }
    
    func getDateRangeString() -> String {
        
        let startS = formatDateToMonthDay(range.startDate)
        let endS = formatDateToMonthDay(range.endDate)
        
        return "\(startS) - \(endS)"
    }
}


