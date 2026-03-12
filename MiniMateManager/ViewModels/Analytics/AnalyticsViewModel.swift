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
    case retention = "Retention"
    
    var color: Color {
        switch self {
        case .growth:
            return Color.green
        case .operations:
            return Color.purple
        case .experience:
            return Color.red
        case .retention:
            return Color.blue
        }
    }
    
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

enum InsightType {
    case good
    case average
    case warning
    case critical
}

struct Insight {
    let descripton: String
    let insightType: InsightType
    
    var color: Color {
        switch insightType {
        case .good: return .green
        case .average: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var imageName: String {
        switch insightType {
        case .good: return "checkmark.circle.fill"
        case .average: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "x.circle.fill"
        }
    }
}

// MARK: - Health Rating Models
struct SectionHealthRating {
    let section: AnalyticsSection
    let score: Double // 0.0 to 100.0
    let grade: HealthGrade
    let insights: [Insight]
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
    let topInsights: [(insight: Insight, section: AnalyticsSection)]
    let timestamp: Date
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
    
    @Published var healthReport: CourseHealthReport?
    @Published var isLoadingHealth = false
    
    @Published var allEmails: [String : CourseEmail] = [:]
    
    @Published var loadingDocs: Bool = true
    @Published var loadingEmails: Bool = true
    
    // Store current course for experience metrics
    @Published var currentCourse: Course?
    
    // Child View Models
    @Published var growthVM = GrowthViewModel()
    @Published var operationsVM = OperationsViewModel()
    @Published var experienceVM = ExperienceViewModel()
    @Published var retentionVM = RetentionViewModel()
    
    // Date formatter instances (reuse to avoid creating new instances repeatedly)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    init() {
        // Set up synchronization between parent and child VMs
        setupChildViewModels()
    }
    
    private func setupChildViewModels() {
        // Synchronize data to child view models whenever allDailyDocs changes
        $allDailyDocs
            .sink { [weak self] docs in
                guard let self = self else { return }
                let rangeDocs = docs.filter { self.range.daysInMainRange.contains($0.dayID) }
                let deltaDocs = docs.filter { self.range.daysInDeltaRange.contains($0.dayID) }
                
                self.growthVM.rangeDailyDocs = rangeDocs
                self.growthVM.deltaDailyDocs = deltaDocs
                self.operationsVM.rangeDailyDocs = rangeDocs
                self.operationsVM.deltaDailyDocs = deltaDocs
                self.experienceVM.rangeDailyDocs = rangeDocs
            }
            .store(in: &cancellables)
        
        $range
            .sink { [weak self] range in
                guard let self = self else { return }
                self.growthVM.range = range
                self.operationsVM.range = range
                
                // Update filtered docs when range changes
                let rangeDocs = self.allDailyDocs.filter { range.daysInMainRange.contains($0.dayID) }
                let deltaDocs = self.allDailyDocs.filter { range.daysInDeltaRange.contains($0.dayID) }
                
                self.growthVM.rangeDailyDocs = rangeDocs
                self.growthVM.deltaDailyDocs = deltaDocs
                self.operationsVM.rangeDailyDocs = rangeDocs
                self.operationsVM.deltaDailyDocs = deltaDocs
                self.experienceVM.rangeDailyDocs = rangeDocs
            }
            .store(in: &cancellables)
        
        $currentCourse
            .assign(to: &experienceVM.$currentCourse)
        
        $allEmails
            .assign(to: &retentionVM.$allEmails)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadHealthData(course: Course? = nil) async {
        self.currentCourse = course
        guard let course else {
            print("No course to load health data for")
            await MainActor.run {
                healthReport = nil
            }
            return
        }
        
        await MainActor.run {
            withAnimation {
                isLoadingHealth = true
            }
        }
        
        // Load analytics data and wait for both to complete
        await onAppearDailyAnalytics(course: course)
        await onAppearRetention(course: course)
        
        // Calculate health report on background thread to avoid blocking UI
        let report = await Task.detached(priority: .userInitiated) {
            await self.calculateCourseHealthBackground()
        }.value
        
        await MainActor.run {
            healthReport = report
            withAnimation {
                isLoadingHealth = false
            }
        }
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
    
    func onAppearDailyAnalytics(course: Course? = nil) async {
        guard let course else { return }
        
        await MainActor.run {
            withAnimation {
                loadingDocs = true
            }
        }
        
        allDailyDocs = await analyticsRepo.fetchDailyAnalytics(
            courseID: course.id,
            range: .last30,
            existingDocs: allDailyDocs
        )
        
        await MainActor.run {
            withAnimation {
                loadingDocs = false
            }
        }
    }
    
    func refreshAnalytics(course: Course?) {
        guard let course else { return }
        
        withAnimation {
            loadingDocs = true
        }
        
        
        Task {
            allDailyDocs = await analyticsRepo.fetchDailyAnalytics(
                courseID: course.id,
                range: .last30,
                existingDocs: []
            )
            
            withAnimation {
                loadingDocs = false
            }
        }
    }
    
    func onAppearRetention(course: Course?) async {
        guard let course else { return }
        
        withAnimation{
            loadingEmails = true
        }
        
        allEmails = await analyticsRepo.fetchEmails(courseID: course.id)
        
        // Compute all tier data and metrics once using retentionVM
        retentionVM.recomputePlayerTiers()
        
        withAnimation{
            loadingEmails = false
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
        return monthDayFormatter.string(from: date)
    }
    
    /// Converts a Date object to "yyyy-MM-dd" format
    /// - Parameter date: Date object to format
    /// - Returns: Formatted date string in "yyyy-MM-dd" format
    func formatDateToDateString(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func formatDateStringToMonthDay(_ dateString: String) -> Date {
        return dateFormatter.date(from: dateString)!
    }
    
    func getDateRangeString() -> String {
        
        let startS = formatDateToMonthDay(range.startDate)
        let endS = formatDateToMonthDay(range.endDate)
        
        return "\(startS) - \(endS)"
    }
    
    // Helper function for delta calculation used by health system
    private func calcDelta(_ prev: Int, _ current: Int) -> Double {
        guard prev != 0 else { return 0 }
        return (Double(current - prev) / Double(prev)) * 100
    }
    
    //MARK: - Health Rating System
    
    /// Calculate comprehensive health rating on background thread
    private func calculateCourseHealthBackground() async -> CourseHealthReport {
        // Get snapshot of data to avoid accessing @Published on background thread
        let rangeDocs = await MainActor.run { rangeDailyDocs }
        let deltaDocs = await MainActor.run { deltaDailyDocs }
        let emails = await MainActor.run { allEmails }
        let course = await MainActor.run { currentCourse }
        let avgReturn = await MainActor.run { retentionVM.cachedAvgTimeToReturn }
        let retention30 = await MainActor.run { retentionVM.cached30DayRetention }
        let newPlayers = await MainActor.run { retentionVM.cachedNewPlayers }
        let midTier = await MainActor.run { retentionVM.cachedMidTierPlayers }
        let frequent = await MainActor.run { retentionVM.cachedFrequentPlayers }
        let atRisk = await MainActor.run { retentionVM.cachedAtRiskPlayers }
        
        // Perform calculations off main thread
        let growthHealth = calculateGrowthHealthBackground(rangeDocs: rangeDocs, deltaDocs: deltaDocs)
        let operationsHealth = calculateOperationsHealthBackground(rangeDocs: rangeDocs)
        let experienceHealth = calculateExperienceHealthBackground(rangeDocs: rangeDocs, course: course)
        let retentionHealth = calculateRetentionHealthBackground(
            emails: emails,
            avgReturn: avgReturn,
            retention30: retention30,
            newPlayers: newPlayers,
            midTier: midTier,
            frequent: frequent,
            atRisk: atRisk
        )
        
        // Calculate weighted overall score
        let overallScore = (
            growthHealth.score * 0.30 +
            operationsHealth.score * 0.20 +
            experienceHealth.score * 0.20 +
            retentionHealth.score * 0.30
        )
        
        let overallGrade = HealthGrade.from(score: overallScore)
        
        // Compile top insights
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
    
    /// Calculate comprehensive health rating for the entire course
    /// - Returns: CourseHealthReport with overall and section-specific health metrics
    func calculateCourseHealth() -> CourseHealthReport {
        let growthHealth = calculateGrowthHealth()
        let operationsHealth = calculateOperationsHealth()
        let experienceHealth = calculateExperienceHealth(course: currentCourse)
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
        return calculateGrowthHealthBackground(rangeDocs: rangeDailyDocs, deltaDocs: deltaDailyDocs)
    }
    
    /// Calculate Growth section health rating on background thread
    private func calculateGrowthHealthBackground(rangeDocs: [DailyDoc], deltaDocs: [DailyDoc]) -> SectionHealthRating {
        var score: Double = 0
        var insights: [Insight] = []
        var metrics: [String: Double] = [:]
        
        // Metric 1: Active user growth (40 points)
        let activeUsers = rangeDocs.reduce(0) { $0 + $1.totalCount }
        let activeUsersDelta = deltaDocs.reduce(0) { $0 + $1.totalCount }
        let growthRate = activeUsersDelta > 0 ? calcDelta(activeUsersDelta, activeUsers) : 0
        metrics["growthRate"] = growthRate
        
        switch growthRate {
        case 20...:
            score += 40
            insights.append(Insight(descripton: "Exceptional growth! Active users up +\(String(format: "%.1f%%", growthRate))", insightType: .good))
        case 10..<20:
            score += 35
            insights.append(Insight(descripton: "Strong growth trend with +\(String(format: "%.1f%%", growthRate)) increase", insightType: .good))
        case 5..<10:
            score += 30
            insights.append(Insight(descripton: "Steady growth at \(String(format: "%.1f%%", growthRate))", insightType: .average))
        case 0..<5:
            score += 20
            insights.append(Insight(descripton: "Slow growth at \(String(format: "%.1f%%", growthRate))", insightType: .warning))
        case -10..<0:
            score += 10
            insights.append(Insight(descripton: "Declining users by \(String(format: "%.1f%%", abs(growthRate)))", insightType: .warning))
        default:
            score += 0
            insights.append(Insight(descripton: "Significant decline of \(String(format: "%.1f%%", abs(growthRate)))", insightType: .critical))
        }
        
        // Metric 2: New player acquisition (30 points)
        let firstTimeUsers = rangeDocs.reduce(0) { $0 + $1.newPlayers }
        let newPlayerPercentage = activeUsers > 0 ? (Double(firstTimeUsers) / Double(activeUsers)) * 100 : 0
        metrics["newPlayerRate"] = newPlayerPercentage
        
        switch newPlayerPercentage {
        case 30...:
            score += 30
            insights.append(Insight(descripton: "Excellent new player acquisition at \(String(format: "%.0f%%", newPlayerPercentage))", insightType: .good))
        case 20..<30:
            score += 25
            insights.append(Insight(descripton: "Good new player rate at \(String(format: "%.0f%%", newPlayerPercentage))", insightType: .good))
        case 10..<20:
            score += 20
            insights.append(Insight(descripton: "Moderate new player acquisition", insightType: .average))
        default:
            score += 10
            insights.append(Insight(descripton: "Focus needed on attracting new players", insightType: .warning))
        }
        
        // Metric 3: Returning player ratio (30 points)
        let returningUsers = rangeDocs.reduce(0) { $0 + $1.returningPlayers }
        let returningPercentage = activeUsers > 0 ? (Double(returningUsers) / Double(activeUsers)) * 100 : 0
        metrics["returningPlayerRate"] = returningPercentage
        
        switch returningPercentage {
        case 50...:
            score += 30
            insights.append(Insight(descripton: "Outstanding player return rate at \(String(format: "%.0f%%", returningPercentage))", insightType: .good))
        case 30..<50:
            score += 25
            insights.append(Insight(descripton: "Healthy returning player base", insightType: .good))
        case 15..<30:
            score += 15
            insights.append(Insight(descripton: "Below-average return rate", insightType: .warning))
        default:
            score += 5
            insights.append(Insight(descripton: "Critical: Very low player retention", insightType: .critical))
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
        return calculateOperationsHealthBackground(rangeDocs: rangeDailyDocs)
    }
    
    /// Calculate Operations section health rating on background thread
    private func calculateOperationsHealthBackground(rangeDocs: [DailyDoc]) -> SectionHealthRating {
        var score: Double = 0
        var insights: [Insight] = []
        var metrics: [String: Double] = [:]
        
        // Metric 1: Game volume (40 points)
        let totalGames = rangeDocs.reduce(0) { $0 + $1.gamesPlayed }
        let avgGamesPerDay = Double(totalGames) / max(1, Double(rangeDocs.count))
        metrics["avgGamesPerDay"] = avgGamesPerDay
        
        switch avgGamesPerDay {
        case 50...:
            score += 40
            insights.append(Insight(descripton: "High volume: \(String(format: "%.0f", avgGamesPerDay)) games/day", insightType: .good))
        case 25..<50:
            score += 35
            insights.append(Insight(descripton: "Good activity with \(String(format: "%.0f", avgGamesPerDay)) games/day", insightType: .good))
        case 10..<25:
            score += 25
            insights.append(Insight(descripton: "Moderate activity level", insightType: .average))
        case 5..<10:
            score += 15
            insights.append(Insight(descripton: "Low game volume", insightType: .warning))
        default:
            score += 5
            insights.append(Insight(descripton: "Very low operational activity", insightType: .critical))
        }
        
        // Metric 2: Course utilization (30 points)
        let totalPlayers = rangeDocs.reduce(0) { $0 + $1.totalCount }
        let avgPlayersPerGameValue = totalGames > 0 ? Double(totalPlayers) / Double(totalGames) : 0
        metrics["avgPlayersPerGame"] = avgPlayersPerGameValue
        
        switch avgPlayersPerGameValue {
        case 3...:
            score += 30
            insights.append(Insight(descripton: "Excellent group sizes averaging \(String(format: "%.1f", avgPlayersPerGameValue)) players", insightType: .good))
        case 2..<3:
            score += 25
            insights.append(Insight(descripton: "Good social play with groups of \(String(format: "%.1f", avgPlayersPerGameValue))", insightType: .average))
        case 1.5..<2:
            score += 15
            insights.append(Insight(descripton: "Opportunity to encourage group play", insightType: .warning))
        default:
            score += 10
            insights.append(Insight(descripton: "Promote social features to increase group sizes", insightType: .warning))
        }
        
        // Metric 3: Game duration efficiency (30 points)
        let totalSeconds = rangeDocs.reduce(0) { $0 + $1.totalRoundSeconds }
        let avgGameMinutes = totalGames > 0 ? Double(totalSeconds) / Double(totalGames) / 60.0 : 0
        metrics["avgGameMinutes"] = avgGameMinutes
        
        switch avgGameMinutes {
        case 15...45:
            score += 30
            insights.append(Insight(descripton: "Optimal game duration at \(String(format: "%.0f", avgGameMinutes)) minutes", insightType: .good))
        case 10..<15:
            score += 25
            insights.append(Insight(descripton: "Quick games averaging \(String(format: "%.0f", avgGameMinutes)) minutes", insightType: .average))
        case 45..<60:
            score += 20
            insights.append(Insight(descripton: "Longer games may indicate engagement or pacing issues", insightType: .warning))
        default:
            if avgGameMinutes > 0 {
                score += 10
                insights.append(Insight(descripton: "Review game duration patterns", insightType: .warning))
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
    private func calculateExperienceHealth(course: Course? = nil) -> SectionHealthRating {
        return calculateExperienceHealthBackground(rangeDocs: rangeDailyDocs, course: course)
    }
    
    /// Calculate Experience section health rating on background thread
    private func calculateExperienceHealthBackground(rangeDocs: [DailyDoc], course: Course? = nil) -> SectionHealthRating {
        var score: Double = 0
        var insights: [Insight] = []
        var metrics: [String: Double] = [:]
        
        guard let course else {
            return SectionHealthRating(
                section: .experience,
                score: 50,
                grade: .needsImprovement,
                insights: [Insight(descripton: "Course data not available", insightType: .warning)],
                metrics: [:]
            )
        }
        
        // Compute hole combined locally
        var combinedTotalStrokes: [String: Int] = [:]
        var combinedPlays: [String: Int] = [:]
        
        for doc in rangeDocs {
            for (holeID, strokes) in doc.holeAnalytics.totalStrokesPerHole {
                combinedTotalStrokes[holeID, default: 0] += strokes
            }
            
            for (holeID, plays) in doc.holeAnalytics.playsPerHole {
                combinedPlays[holeID, default: 0] += plays
            }
        }
        
        let holeCombined: [String: Double] = combinedTotalStrokes.reduce(into: [:]) { dict, hole in
            return dict[hole.key] = Double(hole.value) / Double(combinedPlays[hole.key] ?? 1)
        }
        
        // Metric 1: Course difficulty balance (35 points)
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
            insights.append(Insight(descripton: "Perfect difficulty balance! Players score near par", insightType: .good))
        case 0.5...1.5:
            score += 30
            insights.append(Insight(descripton: "Well-balanced challenge for players", insightType: .average))
        case 1.5...2.5:
            score += 20
            insights.append(Insight(descripton: "Course may be slightly too difficult", insightType: .warning))
        case 2.5...:
            score += 10
            insights.append(Insight(descripton: "Course difficulty may frustrate players", insightType: .critical))
        case ...(-0.5):
            score += 25
            insights.append(Insight(descripton: "Course may be too easy - consider adding challenges", insightType: .warning))
        default:
            score += 15
        }
        
        // Metric 2: Player success rate (35 points)
        var totalHolesPlayed = 0
        var underParCount = 0
        
        for doc in rangeDocs {
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
            insights.append(Insight(descripton: "Excellent player success rate at \(String(format: "%.0f%%", successRate))", insightType: .good))
        case 20..<30:
            score += 30
            insights.append(Insight(descripton: "Good success rate keeps players engaged", insightType: .average))
        case 10..<20:
            score += 20
            insights.append(Insight(descripton: "Moderate success rate - room for improvement", insightType: .warning))
        default:
            score += 10
            insights.append(Insight(descripton: "Low success rate may impact satisfaction", insightType: .warning))
        }
        
        // Metric 3: Course variety & engagement (30 points)
        let holeVariety = holeCombined.values.sorted()
        if holeVariety.count >= 2 {
            let range = holeVariety.last! - holeVariety.first!
            metrics["difficultyVariety"] = range
            
            switch range {
            case 2...:
                score += 30
                insights.append(Insight(descripton: "Excellent hole variety creates engaging experience", insightType: .good))
            case 1..<2:
                score += 25
                insights.append(Insight(descripton: "Good variety across holes", insightType: .average))
            default:
                score += 15
                insights.append(Insight(descripton: "Consider adding more variety to hole difficulty", insightType: .warning))
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
        return calculateRetentionHealthBackground(
            emails: allEmails,
            avgReturn: retentionVM.cachedAvgTimeToReturn,
            retention30: retentionVM.cached30DayRetention,
            newPlayers: retentionVM.cachedNewPlayers,
            midTier: retentionVM.cachedMidTierPlayers,
            frequent: retentionVM.cachedFrequentPlayers,
            atRisk: retentionVM.cachedAtRiskPlayers
        )
    }
    
    /// Calculate Retention section health rating on background thread
    private func calculateRetentionHealthBackground(
        emails: [String: CourseEmail],
        avgReturn: Int,
        retention30: Double,
        newPlayers: [String: CourseEmail],
        midTier: [String: CourseEmail],
        frequent: [String: CourseEmail],
        atRisk: [String: CourseEmail]
    ) -> SectionHealthRating {
        var score: Double = 0
        var insights: [Insight] = []
        var metrics: [String: Double] = [:]
        
        let totalPlayers = Double(emails.count)
        guard totalPlayers > 0 else {
            return SectionHealthRating(
                section: .experience,
                score: 0,
                grade: .critical,
                insights: [Insight(descripton: "No player data available", insightType: .warning)],
                metrics: [:]
            )
        }
        
        // Metric 1: 30-day retention rate (40 points)
        let retention30Day = retention30 * 100
        metrics["retention30Day"] = retention30Day
        
        switch retention30Day {
        case 40...:
            score += 40
            insights.append(Insight(descripton: "Outstanding 30-day retention at \(String(format: "%.0f%%", retention30Day))", insightType: .good))
        case 25..<40:
            score += 35
            insights.append(Insight(descripton: "Strong retention rate of \(String(format: "%.0f%%", retention30Day))", insightType: .average))
        case 15..<25:
            score += 25
            insights.append(Insight(descripton: "Moderate retention - opportunities exist", insightType: .warning))
        case 10..<15:
            score += 15
            insights.append(Insight(descripton: "Below-average retention needs attention", insightType: .warning))
        default:
            score += 5
            insights.append(Insight(descripton: "Critical: Very low player retention", insightType: .critical))
        }
        
        // Metric 2: Player tier distribution (30 points)
        let frequentCount = Double(frequent.count)
        let midTierCount = Double(midTier.count)
        let _ = Double(newPlayers.count)
        let atRiskCount = Double(atRisk.count)
        
        let engagedRatio = (frequentCount + midTierCount) / totalPlayers * 100
        metrics["engagedPlayerRatio"] = engagedRatio
        
        switch engagedRatio {
        case 40...:
            score += 30
            insights.append(Insight(descripton: "Exceptional engaged player base at \(String(format: "%.0f%%", engagedRatio))", insightType: .good))
        case 25..<40:
            score += 25
            insights.append(Insight(descripton: "Healthy mix of engaged players", insightType: .average))
        case 15..<25:
            score += 15
            insights.append(Insight(descripton: "Focus on moving players to higher tiers", insightType: .warning))
        default:
            score += 8
            insights.append(Insight(descripton: "Low engagement - activate dormant players", insightType: .warning))
        }
        
        // Metric 3: At-risk player management (30 points)
        let atRiskRatio = atRiskCount / totalPlayers * 100
        metrics["atRiskRatio"] = atRiskRatio
        
        switch atRiskRatio {
        case ..<15:
            score += 30
            insights.append(Insight(descripton: "Excellent retention - minimal at-risk players", insightType: .good))
        case 15..<30:
            score += 25
            insights.append(Insight(descripton: "Manageable at-risk player count", insightType: .average))
        case 30..<50:
            score += 15
            insights.append(Insight(descripton: "\(String(format: "%.0f%%", atRiskRatio)) players at risk - re-engagement needed", insightType: .warning))
        default:
            score += 5
            insights.append(Insight(descripton: "High churn risk: \(String(format: "%.0f%%", atRiskRatio)) players at risk", insightType: .critical))
        }
        
        // Add insight about avg return time
        metrics["avgReturnDays"] = Double(avgReturn)
        
        if avgReturn < 7 {
            insights.append(Insight(descripton: "Players return quickly (avg \(avgReturn) days)", insightType: .good))
        } else if avgReturn < 14 {
            insights.append(Insight(descripton: "Good return frequency at \(avgReturn) days", insightType: .average))
        } else if avgReturn < 30 {
            insights.append(Insight(descripton: "Consider incentives to shorten \(avgReturn)-day return cycle", insightType: .warning))
        } else {
            insights.append(Insight(descripton: "Long return time (\(avgReturn) days) indicates engagement opportunity", insightType: .warning))
        }
        
        let grade = HealthGrade.from(score: score)
        return SectionHealthRating(
            section: .retention,
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
    ) -> [(insight: Insight, section: AnalyticsSection)] {
        var allInsights: [(insight: Insight, section: AnalyticsSection, priority: Int)] = []
        
        // Prioritize critical and warning insights
        for insight in growth.insights {
            let priority = insight.insightType == .critical ? 1 : insight.insightType == .warning ? 2 : 3
            allInsights.append((insight, .growth, priority))
        }
        
        for insight in operations.insights {
            let priority = insight.insightType == .critical ? 1 : insight.insightType == .warning ? 2 : 3
            allInsights.append((insight, .operations, priority))
        }
        
        for insight in experience.insights {
            let priority = insight.insightType == .critical ? 1 : insight.insightType == .warning ? 2 : 3
            allInsights.append((insight, .experience, priority))
        }
        
        for insight in retention.insights {
            let priority = insight.insightType == .critical ? 1 : insight.insightType == .warning ? 2 : 3
            allInsights.append((insight, .retention, priority))
        }
        
        // Sort by priority and take top 5-7 insights
        allInsights.sort { $0.priority < $1.priority }
        return allInsights.prefix(7).map { (insight: $0.insight, section: $0.section) }
    }
}
