//
//  RetentionViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class RetentionViewModel: ObservableObject {
    
    @Published var allEmails: [String: CourseEmail] = [:]
    
    // Cached tier data - computed once and reused
    @Published var cachedNewPlayers: [String: CourseEmail] = [:]
    @Published var cachedMidTierPlayers: [String: CourseEmail] = [:]
    @Published var cachedFrequentPlayers: [String: CourseEmail] = [:]
    @Published var cachedAtRiskPlayers: [String: CourseEmail] = [:]
    
    // Cached metrics
    @Published var cachedAvgTimeToReturn: Int = 0
    @Published var cached30DayRetention: Double = 0.0
    
    // Date formatter instances (reuse to avoid creating new instances repeatedly)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Retention Tier Filtering
    
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
    func isRecentlyActive(_ lastPlayedString: String?, days: Int) -> Bool {
        guard let lastPlayedString = lastPlayedString else { return false }
        
        guard let lastPlayedDate = dateFormatter.date(from: lastPlayedString) else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
        
        return lastPlayedDate >= cutoffDate
    }
    
    // MARK: - Retention Metrics
    
    /// Calculate average days between firstSeen and secondSeen for returning players
    /// - Returns: Average number of days, or 0 if no returning players
    func avgTimeToReturn() -> Int {
        let returningPlayers = allEmails.filter { $0.value.secondSeen != nil }
        
        guard !returningPlayers.isEmpty else { return 0 }
        
        var totalDays = 0
        var count = 0
        
        for (_, data) in returningPlayers {
            guard let firstSeenStr = data.firstSeen,
                  let secondSeenStr = data.secondSeen,
                  let firstSeenDate = dateFormatter.date(from: firstSeenStr),
                  let secondSeenDate = dateFormatter.date(from: secondSeenStr) else {
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
        
        var retainedWithin30 = 0
        
        for (_, data) in allEmails {
            guard let firstStr = data.firstSeen,
                  let secondStr = data.secondSeen,
                  let firstDate = dateFormatter.date(from: firstStr),
                  let secondDate = dateFormatter.date(from: secondStr) else {
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
    
    /// Recompute all player tier caches in one pass
    /// This is called once after fetching emails to avoid repeated calculations
    func recomputePlayerTiers() {
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
    
    // MARK: - CSV Generation
    
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
}
