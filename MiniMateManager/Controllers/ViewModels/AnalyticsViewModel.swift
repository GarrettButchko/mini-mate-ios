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

struct AnalyticsObject{
    var type: AnalyticsSection
    var icon: String
    var color: Color
}

@MainActor
final class AnalyticsViewModel: ObservableObject {

    let analyticsRepo = AnalyticsRepository()
    
    @Published var range: AnalyticsRange = .last30
    @Published var selectedSection: AnalyticsSection = .growth
    
    // Docs
    @Published var allDailyDocs: [DailyDoc] = []
    
    @Published var loadingDocs: Bool = false
    
    var deltaDailyDocs: [DailyDoc] {
        allDailyDocs.filter { range.daysInDeltaRange.contains($0.dayID) }
    }
    
    var rangeDailyDocs: [DailyDoc] {
        allDailyDocs.filter { range.daysInMainRange.contains($0.dayID) }
    }
    
    // Data Calc
    func getActiveUsers(_ docs: [DailyDoc]) -> Int {
        docs.reduce(0) { $0 + $1.totalCount }
    }
    
    func activeUsersPrime() -> (value: String, delta: String, dColor: Color) {
        let rangeUsers = getActiveUsers(rangeDailyDocs)
        let deltaUsers = getActiveUsers(deltaDailyDocs)
        let delta = calcDelta(deltaUsers, rangeUsers)
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        return (String(rangeUsers), deltaString, postive(good: true, delta))
    }
    
    func getFirstTimeUsers(_ docs: [DailyDoc]) -> Int {
        docs.reduce(0) { $0 + $1.newPlayers }
    }
    
    func firstTimePrime() -> (value: String, delta: String, dColor: Color) {
        let rangeUsers = getFirstTimeUsers(rangeDailyDocs)
        let deltaUsers = getFirstTimeUsers(deltaDailyDocs)
        let delta = calcDelta(deltaUsers, rangeUsers)
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        return (String(rangeUsers), deltaString, postive(good: true, delta))
    }
    
    func getReturningUsers(_ docs: [DailyDoc]) -> Int {
        docs.reduce(0) { $0 + $1.returningPlayers }
    }
    
    func returningPrime() -> (value: String, delta: String, dColor: Color) {
        let rangeUsers = getReturningUsers(rangeDailyDocs)
        let deltaUsers = getReturningUsers(deltaDailyDocs)
        let delta = calcDelta(deltaUsers, rangeUsers)
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        return (String(rangeUsers), deltaString, postive(good: true, delta))
    }
    
    func avgPlayersPerGame(_ docs: [DailyDoc]) -> Double {
        
        let totalGames = docs.reduce(0) { $0 + $1.gamesPlayed }
        let players = getActiveUsers(docs)
        
        return players > 0 ? Double(players) / Double(totalGames) : 0
    }
    
    func avgPlayersPerGamePrime() -> (value: String, delta: String, dColor: Color) {
        let rangeUsers = avgPlayersPerGame(rangeDailyDocs)
        let deltaUsers = avgPlayersPerGame(deltaDailyDocs)
        let delta = calcDelta(deltaUsers, rangeUsers)
        
        let isDeltaPositive = delta > 0
        
        var deltaString = String(format: "%.1f%%", delta)
        
        if isDeltaPositive {
            deltaString = "+" + deltaString
        }
        
        return (String(rangeUsers), deltaString, postive(good: true, delta))
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

        loadingDocs = true
        
        Task {
            
                allDailyDocs = await analyticsRepo.fetchDailyAnalytics(
                    courseID: course.id,
                    range: .last30,
                    existingDocs: allDailyDocs
                )
            
            loadingDocs = false
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
}


