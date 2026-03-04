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
    var deltaColor: Color?
}

struct PlayerActivity: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct GameDurationActivity: Identifiable {
    let id = UUID()
    let date: Date
    let avgMinutes: Double
}

// MARK: - Health Rating Models

struct SectionHealthRating {
    let section: AnalyticsSection
    let score: Double // 0.0 to 100.0
    let grade: HealthGrade
    let insights: [String]
    let metrics: [String: Double] // Raw metric values for transparency
}

enum HealthGrade: String {
    case excellent = "A+"
    case great = "A"
    case good = "B+"
    case satisfactory = "B"
    case fair = "C+"
    case needsImprovement = "C"
    case poor = "D"
    case critical = "F"
    
    var color: Color {
        switch self {
        case .excellent, .great: return .green
        case .good, .satisfactory: return .blue
        case .fair, .needsImprovement: return .orange
        case .poor, .critical: return .red
        }
    }
    
    static func from(score: Double) -> HealthGrade {
        switch score {
        case 95...100: return .excellent
        case 85..<95: return .great
        case 75..<85: return .good
        case 65..<75: return .satisfactory
        case 55..<65: return .fair
        case 45..<55: return .needsImprovement
        case 30..<45: return .poor
        default: return .critical
        }
    }
}

struct CourseHealthReport {
    let overallScore: Double // 0.0 to 100.0
    let overallGrade: HealthGrade
    let growthHealth: SectionHealthRating
    let operationsHealth: SectionHealthRating
    let experienceHealth: SectionHealthRating
    let retentionHealth: SectionHealthRating
    let topInsights: [String]
    let timestamp: Date
}

@MainActor
final class AnalyticsViewModel: ObservableObject {
    
    let analyticsRepo = AnalyticsRepository()
    
    @Published var range: AnalyticsRange = .last30
    @Published var selectedSection: AnalyticsSection = .growth
    
    @Published var pickedSection: String = "Day Range"
    let pickerSections: [String] = ["Day Range", "Retention"]
    
    // Course reference for experience metrics
    @Published var currentCourse: Course?
    
    // Docs
    @Published var allDailyDocs: [DailyDoc] = []
    
    var deltaDailyDocs: [DailyDoc] {
        allDailyDocs.filter { range.daysInDeltaRange.contains($0.dayID) }
    }
    
    var rangeDailyDocs: [DailyDoc] {
        allDailyDocs.filter { range.daysInMainRange.contains($0.dayID) }
    }
    
    @Published var allEmails: [String : CourseEmail] = [:]
    
    @Published var growthChartTopic: ChartTopic = .total
    
    @Published var loadingDocs: Bool = true
    @Published var loadingEmails: Bool = true
    
    // Cached tier data - computed once and reused
    @Published var cachedNewPlayers: [String: CourseEmail] = [:]
    @Published var cachedMidTierPlayers: [String: CourseEmail] = [:]
    @Published var cachedFrequentPlayers: [String: CourseEmail] = [:]
    @Published var cachedAtRiskPlayers: [String: CourseEmail] = [:]
    
    // Cached metrics
    @Published var cachedAvgTimeToReturn: Int = 0
    @Published var cached30DayRetention: Double = 0.0
    
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
    
    func deltaErrorCalc(delta: inout Double, positiveGood: Bool) -> (deltaS: String?, deltaC: Color?) {
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
    
    // Delta Calc
    func calcDelta(_ prev: Int, _ current: Int) -> Double {
        guard prev != 0 else { return 0 }
        return (Double(current - prev) / Double(prev)) * 100
    }
    
    func calcDelta(_ prev: Int64, _ current: Int64) -> Double {
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
    
    func getHoleHeatmapForParData(course: Course) -> [HoleHeatmapData] {
        let combinedResults = getHoleCombined() // [String: Double] (HoleID: AvgStrokes)
        
        return combinedResults.compactMap { (key, avgStrokes) -> HoleHeatmapData? in
            guard let holeNum = Int(key) else { return nil }
            
            // Ensure we don't go out of bounds of the pars array (Index is holeNum - 1)
            let index = holeNum - 1
            guard index >= 0 && index < course.pars.count else { return nil }
            
            let par = Double(course.pars[index])
            let offset = avgStrokes - par
            
            return HoleHeatmapData(holeNumber: holeNum, relativeToPar: offset)
        }
        .sorted(by: { $0.holeNumber < $1.holeNumber })
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
    
    //MARK: Experience Metrics
    
    /// Calculate average strokes relative to par across all holes
    func getAvgRelativeToPar() -> DataPointObject {
        guard let course = getCourseFromDocs() else {
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
        guard let course = getCourseFromDocs() else {
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
        guard let course = getCourseFromDocs() else {
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
        return DataPointObject(value: String(format: "%.1f%%", percentage), delta: nil, deltaColor: .blue)
    }
    
    /// Calculate percentage of holes completed over par
    func getOverParPercentage() -> DataPointObject {
        guard let course = getCourseFromDocs() else {
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
        return DataPointObject(value: String(format: "%.1f%%", percentage), delta: nil, deltaColor: .blue)
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
    
    /// Helper to get course from docs
    private func getCourseFromDocs() -> Course? {
        return currentCourse
    }
    
    //MARK: Game Duration Metrics
    
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
    func getDataForDurationTrend() -> [GameDurationActivity] {
        // Sort the source data first
        let sortedDocs = rangeDailyDocs.sorted { $0.dayID < $1.dayID }
        
        // Create a dictionary for quick lookup
        let docsByDateString = Dictionary(uniqueKeysWithValues: sortedDocs.map { ($0.dayID, $0) })
        
        // Generate all dates in the range
        var result: [GameDurationActivity] = []
        var currentDate = Calendar.current.startOfDay(for: range.startDate)
        let endDate = Calendar.current.startOfDay(for: range.endDate)
        
        while currentDate <= endDate {
            let dateString = formatDateToDateString(currentDate)
            
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
    
    func onAppearDailyAnalytics(course: Course?) {
        guard let course else { return }
        
        currentCourse = course
        
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
    
    func refreshAnalytics(course: Course?) {
        guard let course else { return }
        
        withAnimation{
            loadingDocs = true
        }
        
        
        Task {
            allDailyDocs = await analyticsRepo.fetchDailyAnalytics(
                courseID: course.id,
                range: .last30,
                existingDocs: []
            )
            
            withAnimation{
                loadingDocs = false
            }
        }
    }
    
    func onAppearRetention(course: Course?) {
        guard let course else { return }
        
        withAnimation{
            loadingEmails = true
        }
        
        Task {
            allEmails = await analyticsRepo.fetchEmails(courseID: course.id)
            
            // Compute all tier data and metrics once
            recomputePlayerTiers()
            
            withAnimation{
                loadingEmails = false
            }
        }
    }
    
    /// Recompute all player tier caches in one pass
    /// This is called once after fetching emails to avoid repeated calculations
    private func recomputePlayerTiers() {
        // Calculate avgTimeToReturn once and reuse it
        let avgDays = avgTimeToReturn()
        cachedAvgTimeToReturn = avgDays
        cached30DayRetention = calculate30DayRetention()
        
        // Filter players into tiers using the precomputed avgDays
        cachedNewPlayers = allEmails.filter { $0.value.playCount == 1 }
        
        cachedMidTierPlayers = allEmails.filter { email, data in
            let isInPlayRange = (2...5).contains(data.playCount)
            let isActive = isRecentlyActive(data.lastPlayed, days: avgDays)
            return isInPlayRange && isActive
        }
        
        cachedFrequentPlayers = allEmails.filter { email, data in
            let isHighPlayCount = data.playCount > 5
            let isActive = isRecentlyActive(data.lastPlayed, days: avgDays)
            return isHighPlayCount && isActive
        }
        
        cachedAtRiskPlayers = allEmails.filter { email, data in
            let hasPlayedBefore = data.playCount > 1
            let isInactive = !isRecentlyActive(data.lastPlayed, days: avgDays)
            return hasPlayedBefore && isInactive
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
    
    //MARK: Retention Tier Filtering
    
    /// Filter players into the "New" tier (🎉)
    /// Criteria: playCount == 1
    func getNewPlayers() -> [String: CourseEmail] {
        allEmails.filter { $0.value.playCount == 1 }
    }
    
    /// Filter players into the "Mid-Tier" tier (🥈)
    /// Criteria: playCount between 2-5 AND active within last 38 days
    func getMidTierPlayers() -> [String: CourseEmail] {
        allEmails.filter { email, data in
            let isInPlayRange = (2...5).contains(data.playCount)
            let isActive = isRecentlyActive(data.lastPlayed, days: avgTimeToReturn())
            return isInPlayRange && isActive
        }
    }
    
    /// Filter players into the "Frequent" tier (💎)
    /// Criteria: playCount > 5 AND active within last 38 days
    func getFrequentPlayers() -> [String: CourseEmail] {
        allEmails.filter { email, data in
            let isHighPlayCount = data.playCount > 5
            let isActive = isRecentlyActive(data.lastPlayed, days: avgTimeToReturn())
            return isHighPlayCount && isActive
        }
    }
    
    /// Filter players into the "At Risk" tier (⚠️)
    /// Criteria: playCount > 1 AND lastPlayed is more than 38 days ago
    func getAtRiskPlayers() -> [String: CourseEmail] {
        allEmails.filter { email, data in
            let hasPlayedBefore = data.playCount > 1
            let isInactive = !isRecentlyActive(data.lastPlayed, days: avgTimeToReturn())
            return hasPlayedBefore && isInactive
        }
    }
    
    /// Determine if a player is active within a specified number of days
    /// - Parameters:
    ///   - lastPlayedString: Date string in "yyyy-MM-dd" format
    ///   - days: Number of days to check (e.g., 38)
    /// - Returns: True if the player was active within the specified days, false otherwise
    private func isRecentlyActive(_ lastPlayedString: String?, days: Int) -> Bool {
        guard let lastPlayedString = lastPlayedString else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let lastPlayedDate = formatter.date(from: lastPlayedString) else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
        
        return lastPlayedDate >= cutoffDate
    }
    
    //MARK: CSV Generation
    
    /// Generate a CSV file from an array of email addresses
    /// - Parameter emails: Array of email addresses to include in CSV
    /// - Returns: URL to the temporary CSV file, or nil if generation fails
    func generateCSVFile(from emails: [String]) -> URL? {
        var csvContent = "Email\n"
        
        for email in emails {
            csvContent += "\(email)\n"
        }
        
        do {
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = "players_\(UUID().uuidString).csv"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("❌ Failed to generate CSV file: \(error)")
            return nil
        }
    }
    
    //MARK: Retention Metrics
    
    /// Calculate average days between firstSeen and secondSeen for returning players
    /// - Returns: Average number of days, or 0 if no returning players
    func avgTimeToReturn() -> Int {
        let returningPlayers = allEmails.filter { $0.value.secondSeen != nil }
        
        guard !returningPlayers.isEmpty else { return 0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var totalDays = 0
        var count = 0
        
        for (_, data) in returningPlayers {
            guard let firstSeenStr = data.firstSeen,
                  let secondSeenStr = data.secondSeen,
                  let firstSeenDate = formatter.date(from: firstSeenStr),
                  let secondSeenDate = formatter.date(from: secondSeenStr) else {
                continue
            }
            
            let daysBetween = Calendar.current.dateComponents([.day], from: firstSeenDate, to: secondSeenDate).day ?? 0
            totalDays += daysBetween
            count += 1
        }
        
        return count > 0 ? totalDays / count : 0
    }
    
    /// Get average time to return as a DataPointObject for UI display
    /// - Returns: DataPointObject with average days formatted
    func getAvgTimeToReturn() -> DataPointObject {
        let avgDays = avgTimeToReturn()
        return DataPointObject(
            value: "\(avgDays)",
            delta: nil,
            deltaColor: nil
        )
    }
    
    /// Calculate 30-day retention percentage
    /// Criteria: % of players whose firstSeen is in range AND secondSeen <= firstSeen + 30 days
    /// - Returns: Percentage as a Double (0.0 to 1.0)
    func calculate30DayRetention() -> Double {
        let totalPlayers = allEmails.count
        guard totalPlayers > 0 else { return 0.0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var retainedWithin30 = 0
        
        for (_, data) in allEmails {
            guard let firstStr = data.firstSeen,
                  let secondStr = data.secondSeen,
                  let firstDate = formatter.date(from: firstStr),
                  let secondDate = formatter.date(from: secondStr) else {
                continue
            }
            
            let daysBetween = Calendar.current.dateComponents([.day], from: firstDate, to: secondDate).day ?? 0
            
            if daysBetween <= 30 {
                retainedWithin30 += 1
            }
        }
        
        return Double(retainedWithin30) / Double(totalPlayers)
    }
    
    /// Get 30-day retention as a DataPointObject for UI display
    /// - Returns: DataPointObject with percentage formatted
    func get30DayRetention() -> DataPointObject {
        let retentionPercentage = calculate30DayRetention() * 100
        return DataPointObject(
            value: String(format: "%.0f%%", retentionPercentage),
            delta: nil,
            deltaColor: nil
        )
    }
    
    //MARK: - Health Rating System
    
    /// Calculate comprehensive health rating for the entire course
    /// - Returns: CourseHealthReport with overall and section-specific health metrics
    func calculateCourseHealth() -> CourseHealthReport {
        let growthHealth = calculateGrowthHealth()
        let operationsHealth = calculateOperationsHealth()
        let experienceHealth = calculateExperienceHealth()
        let retentionHealth = calculateRetentionHealth()
        
        // Calculate weighted overall score
        // Growth: 30%, Operations: 20%, Experience: 20%, Retention: 30%
        let overallScore = (
            growthHealth.score * 0.30 +
            operationsHealth.score * 0.20 +
            experienceHealth.score * 0.20 +
            retentionHealth.score * 0.30
        )
        
        let overallGrade = HealthGrade.from(score: overallScore)
        
        // Compile top insights from all sections
        let topInsights = compileTopInsights(
            growth: growthHealth,
            operations: operationsHealth,
            experience: experienceHealth,
            retention: retentionHealth
        )
        
        return CourseHealthReport(
            overallScore: overallScore,
            overallGrade: overallGrade,
            growthHealth: growthHealth,
            operationsHealth: operationsHealth,
            experienceHealth: experienceHealth,
            retentionHealth: retentionHealth,
            topInsights: topInsights,
            timestamp: Date()
        )
    }
    
    /// Calculate Growth section health rating
    private func calculateGrowthHealth() -> SectionHealthRating {
        var score: Double = 0
        var insights: [String] = []
        var metrics: [String: Double] = [:]
        
        // Metric 1: Active user growth (40 points)
        let activeUsers = getActiveUsers(rangeDailyDocs)
        let activeUsersDelta = getActiveUsers(deltaDailyDocs)
        let growthRate = activeUsersDelta > 0 ? calcDelta(activeUsersDelta, activeUsers) : 0
        metrics["growthRate"] = growthRate
        
        switch growthRate {
        case 20...:
            score += 40
            insights.append("🚀 Exceptional growth! Active users up \(String(format: "%.1f%%", growthRate))")
        case 10..<20:
            score += 35
            insights.append("📈 Strong growth trend with \(String(format: "%.1f%%", growthRate)) increase")
        case 5..<10:
            score += 30
            insights.append("✅ Steady growth at \(String(format: "%.1f%%", growthRate))")
        case 0..<5:
            score += 20
            insights.append("⚠️ Slow growth at \(String(format: "%.1f%%", growthRate))")
        case -10..<0:
            score += 10
            insights.append("⚠️ Declining users by \(String(format: "%.1f%%", abs(growthRate)))")
        default:
            score += 0
            insights.append("🚨 Significant decline of \(String(format: "%.1f%%", abs(growthRate)))")
        }
        
        // Metric 2: New player acquisition (30 points)
        let newPlayerPercentage = firstTimePercOfTotal() * 100
        metrics["newPlayerRate"] = newPlayerPercentage
        
        switch newPlayerPercentage {
        case 30...:
            score += 30
            insights.append("🎉 Excellent new player acquisition at \(String(format: "%.0f%%", newPlayerPercentage))")
        case 20..<30:
            score += 25
            insights.append("✨ Good new player rate at \(String(format: "%.0f%%", newPlayerPercentage))")
        case 10..<20:
            score += 20
            insights.append("💡 Moderate new player acquisition")
        default:
            score += 10
            insights.append("📊 Focus needed on attracting new players")
        }
        
        // Metric 3: Returning player ratio (30 points)
        let returningPercentage = returningPercOfTotal() * 100
        metrics["returningPlayerRate"] = returningPercentage
        
        switch returningPercentage {
        case 50...:
            score += 30
            insights.append("💎 Outstanding player return rate at \(String(format: "%.0f%%", returningPercentage))")
        case 30..<50:
            score += 25
            insights.append("✅ Healthy returning player base")
        case 15..<30:
            score += 15
            insights.append("⚠️ Below-average return rate")
        default:
            score += 5
            insights.append("🚨 Critical: Very low player retention")
        }
        
        let grade = HealthGrade.from(score: score)
        return SectionHealthRating(
            section: .growth,
            score: score,
            grade: grade,
            insights: insights,
            metrics: metrics
        )
    }
    
    /// Calculate Operations section health rating
    private func calculateOperationsHealth() -> SectionHealthRating {
        var score: Double = 0
        var insights: [String] = []
        var metrics: [String: Double] = [:]
        
        // Metric 1: Game volume (40 points)
        let totalGames = rangeDailyDocs.reduce(0) { $0 + $1.gamesPlayed }
        let avgGamesPerDay = Double(totalGames) / max(1, Double(rangeDailyDocs.count))
        metrics["avgGamesPerDay"] = avgGamesPerDay
        
        switch avgGamesPerDay {
        case 50...:
            score += 40
            insights.append("🔥 High volume: \(String(format: "%.0f", avgGamesPerDay)) games/day")
        case 25..<50:
            score += 35
            insights.append("📊 Good activity with \(String(format: "%.0f", avgGamesPerDay)) games/day")
        case 10..<25:
            score += 25
            insights.append("✅ Moderate activity level")
        case 5..<10:
            score += 15
            insights.append("⚠️ Low game volume")
        default:
            score += 5
            insights.append("🚨 Very low operational activity")
        }
        
        // Metric 2: Course utilization (30 points)
        let avgPlayersPerGameValue = avgPlayersPerGame(rangeDailyDocs)
        metrics["avgPlayersPerGame"] = avgPlayersPerGameValue
        
        switch avgPlayersPerGameValue {
        case 3...:
            score += 30
            insights.append("👥 Excellent group sizes averaging \(String(format: "%.1f", avgPlayersPerGameValue)) players")
        case 2..<3:
            score += 25
            insights.append("✅ Good social play with groups of \(String(format: "%.1f", avgPlayersPerGameValue))")
        case 1.5..<2:
            score += 15
            insights.append("💡 Opportunity to encourage group play")
        default:
            score += 10
            insights.append("🎯 Promote social features to increase group sizes")
        }
        
        // Metric 3: Game duration efficiency (30 points)
        let totalSeconds = rangeDailyDocs.reduce(0) { $0 + $1.totalRoundSeconds }
        let avgGameMinutes = totalGames > 0 ? Double(totalSeconds) / Double(totalGames) / 60.0 : 0
        metrics["avgGameMinutes"] = avgGameMinutes
        
        switch avgGameMinutes {
        case 15...45:
            score += 30
            insights.append("⏱️ Optimal game duration at \(String(format: "%.0f", avgGameMinutes)) minutes")
        case 10..<15:
            score += 25
            insights.append("⚡ Quick games averaging \(String(format: "%.0f", avgGameMinutes)) minutes")
        case 45..<60:
            score += 20
            insights.append("⏰ Longer games may indicate engagement or pacing issues")
        default:
            if avgGameMinutes > 0 {
                score += 10
                insights.append("⚠️ Review game duration patterns")
            } else {
                score += 15
            }
        }
        
        let grade = HealthGrade.from(score: score)
        return SectionHealthRating(
            section: .operations,
            score: score,
            grade: grade,
            insights: insights,
            metrics: metrics
        )
    }
    
    /// Calculate Experience section health rating
    private func calculateExperienceHealth() -> SectionHealthRating {
        var score: Double = 0
        var insights: [String] = []
        var metrics: [String: Double] = [:]
        
        guard let course = currentCourse else {
            return SectionHealthRating(
                section: .experience,
                score: 50,
                grade: .needsImprovement,
                insights: ["⚠️ Course data not available"],
                metrics: [:]
            )
        }
        
        // Metric 1: Course difficulty balance (35 points)
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
        
        let avgRelativeToPar = validHoleCount > 0 ? totalOffset / Double(validHoleCount) : 0
        metrics["avgRelativeToPar"] = avgRelativeToPar
        
        switch avgRelativeToPar {
        case -0.5...0.5:
            score += 35
            insights.append("🎯 Perfect difficulty balance! Players score near par")
        case 0.5...1.5:
            score += 30
            insights.append("✅ Well-balanced challenge for players")
        case 1.5...2.5:
            score += 20
            insights.append("⚠️ Course may be slightly too difficult")
        case 2.5...:
            score += 10
            insights.append("🚨 Course difficulty may frustrate players")
        case ...(-0.5):
            score += 25
            insights.append("💡 Course may be too easy - consider adding challenges")
        default:
            score += 15
        }
        
        // Metric 2: Player success rate (35 points)
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
                
                if avgStrokes <= par {
                    underParCount += plays
                }
                totalHolesPlayed += plays
            }
        }
        
        let successRate = totalHolesPlayed > 0 ? (Double(underParCount) / Double(totalHolesPlayed)) * 100 : 0
        metrics["successRate"] = successRate
        
        switch successRate {
        case 30...:
            score += 35
            insights.append("🌟 Excellent player success rate at \(String(format: "%.0f%%", successRate))")
        case 20..<30:
            score += 30
            insights.append("✅ Good success rate keeps players engaged")
        case 10..<20:
            score += 20
            insights.append("💡 Moderate success rate - room for improvement")
        default:
            score += 10
            insights.append("⚠️ Low success rate may impact satisfaction")
        }
        
        // Metric 3: Course variety & engagement (30 points)
        let holeVariety = holeCombined.values.sorted()
        if holeVariety.count >= 2 {
            let range = holeVariety.last! - holeVariety.first!
            metrics["difficultyVariety"] = range
            
            switch range {
            case 2...:
                score += 30
                insights.append("🎨 Excellent hole variety creates engaging experience")
            case 1..<2:
                score += 25
                insights.append("✅ Good variety across holes")
            default:
                score += 15
                insights.append("💡 Consider adding more variety to hole difficulty")
            }
        } else {
            score += 15
        }
        
        let grade = HealthGrade.from(score: score)
        return SectionHealthRating(
            section: .experience,
            score: score,
            grade: grade,
            insights: insights,
            metrics: metrics
        )
    }
    
    /// Calculate Retention section health rating
    private func calculateRetentionHealth() -> SectionHealthRating {
        var score: Double = 0
        var insights: [String] = []
        var metrics: [String: Double] = [:]
        
        let totalPlayers = Double(allEmails.count)
        guard totalPlayers > 0 else {
            return SectionHealthRating(
                section: .experience,
                score: 0,
                grade: .critical,
                insights: ["⚠️ No player data available"],
                metrics: [:]
            )
        }
        
        // Metric 1: 30-day retention rate (40 points)
        let retention30Day = cached30DayRetention * 100
        metrics["retention30Day"] = retention30Day
        
        switch retention30Day {
        case 40...:
            score += 40
            insights.append("💎 Outstanding 30-day retention at \(String(format: "%.0f%%", retention30Day))")
        case 25..<40:
            score += 35
            insights.append("✅ Strong retention rate of \(String(format: "%.0f%%", retention30Day))")
        case 15..<25:
            score += 25
            insights.append("📊 Moderate retention - opportunities exist")
        case 10..<15:
            score += 15
            insights.append("⚠️ Below-average retention needs attention")
        default:
            score += 5
            insights.append("🚨 Critical: Very low player retention")
        }
        
        // Metric 2: Player tier distribution (30 points)
        let frequentCount = Double(cachedFrequentPlayers.count)
        let midTierCount = Double(cachedMidTierPlayers.count)
        let _ = Double(cachedNewPlayers.count)
        let atRiskCount = Double(cachedAtRiskPlayers.count)
        
        let engagedRatio = (frequentCount + midTierCount) / totalPlayers * 100
        metrics["engagedPlayerRatio"] = engagedRatio
        
        switch engagedRatio {
        case 40...:
            score += 30
            insights.append("🏆 Exceptional engaged player base at \(String(format: "%.0f%%", engagedRatio))")
        case 25..<40:
            score += 25
            insights.append("✅ Healthy mix of engaged players")
        case 15..<25:
            score += 15
            insights.append("💡 Focus on moving players to higher tiers")
        default:
            score += 8
            insights.append("⚠️ Low engagement - activate dormant players")
        }
        
        // Metric 3: At-risk player management (30 points)
        let atRiskRatio = atRiskCount / totalPlayers * 100
        metrics["atRiskRatio"] = atRiskRatio
        
        switch atRiskRatio {
        case ..<15:
            score += 30
            insights.append("✨ Excellent retention - minimal at-risk players")
        case 15..<30:
            score += 25
            insights.append("✅ Manageable at-risk player count")
        case 30..<50:
            score += 15
            insights.append("⚠️ \(String(format: "%.0f%%", atRiskRatio)) players at risk - re-engagement needed")
        default:
            score += 5
            insights.append("🚨 High churn risk: \(String(format: "%.0f%%", atRiskRatio)) players at risk")
        }
        
        // Add insight about avg return time
        let avgReturn = cachedAvgTimeToReturn
        metrics["avgReturnDays"] = Double(avgReturn)
        
        if avgReturn < 7 {
            insights.append("⚡ Players return quickly (avg \(avgReturn) days)")
        } else if avgReturn < 14 {
            insights.append("📅 Good return frequency at \(avgReturn) days")
        } else if avgReturn < 30 {
            insights.append("💡 Consider incentives to shorten \(avgReturn)-day return cycle")
        } else {
            insights.append("⏰ Long return time (\(avgReturn) days) indicates engagement opportunity")
        }
        
        let grade = HealthGrade.from(score: score)
        return SectionHealthRating(
            section: .experience,
            score: score,
            grade: grade,
            insights: insights,
            metrics: metrics
        )
    }
    
    /// Compile the most critical insights from all sections
    private func compileTopInsights(
        growth: SectionHealthRating,
        operations: SectionHealthRating,
        experience: SectionHealthRating,
        retention: SectionHealthRating
    ) -> [String] {
        var allInsights: [(section: String, insight: String, priority: Int)] = []
        
        // Prioritize critical and warning insights
        for insight in growth.insights {
            let priority = insight.contains("🚨") ? 1 : insight.contains("⚠️") ? 2 : insight.contains("🚀") || insight.contains("💎") ? 3 : 4
            allInsights.append(("Growth", insight, priority))
        }
        
        for insight in operations.insights {
            let priority = insight.contains("🚨") ? 1 : insight.contains("⚠️") ? 2 : insight.contains("🔥") ? 3 : 4
            allInsights.append(("Operations", insight, priority))
        }
        
        for insight in experience.insights {
            let priority = insight.contains("🚨") ? 1 : insight.contains("⚠️") ? 2 : insight.contains("🎯") || insight.contains("🌟") ? 3 : 4
            allInsights.append(("Experience", insight, priority))
        }
        
        for insight in retention.insights {
            let priority = insight.contains("🚨") ? 1 : insight.contains("⚠️") ? 2 : insight.contains("💎") || insight.contains("🏆") ? 3 : 4
            allInsights.append(("Retention", insight, priority))
        }
        
        // Sort by priority and take top 5-7 insights
        allInsights.sort { $0.priority < $1.priority }
        return allInsights.prefix(7).map { "[\($0.section)] \($0.insight)" }
    }
}
