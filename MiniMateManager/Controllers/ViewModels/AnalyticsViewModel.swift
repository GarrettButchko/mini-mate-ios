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

@MainActor
final class AnalyticsViewModel: ObservableObject {
    
    let analyticsRepo = AnalyticsRepository()
    
    @Published var range: AnalyticsRange = .last30
    @Published var selectedSection: AnalyticsSection = .growth
    
    @Published var pickedSection: String = "Day Range"
    let pickerSections: [String] = ["Day Range", "Retention"]
    
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
}
