//
//  AnalyticsRepo.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/21/26.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine

final class AnalyticsRepository {
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    let collectionName: String = "courses"
    
    // MARK: - Update Day Analytics
    func updateDayAnalytics(
        emails: [String],
        courseID: String,
        game: Game, // Ensure your Game model has 'players' and 'holes'
        startTime: Date,
        endTime: Date,
        completion: @escaping (Bool) -> Void
    ) {
        
        print("Running updateDayAnalytics")
        let updatedAt = Date()
        let todayID = makeDayID()
        let currentHour = Calendar.current.component(.hour, from: updatedAt)
        
        let courseRef = db.collection(collectionName).document(courseID)
        let dayRef = courseRef.collection("dailyDocs").document(todayID)
        let emailRef = courseRef.collection("emails")
        
        let uniqueEmails = Array(Set(
            emails
                .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        ))
        
        guard !uniqueEmails.isEmpty else {
            print("Empty Emails")
            DispatchQueue.main.async { completion(true) }
            return
        }
        
        db.runTransaction({ tx, errPtr -> Any? in
            // --- 1. READ PHASE ---
            var emailSnapshots: [String: DocumentSnapshot] = [:]
            var resultDay: DailyDoc? = nil
            
            do {
                for email in uniqueEmails {
                    let docRef = emailRef.document(self.emailKey(email))
                    emailSnapshots[email] = try tx.getDocument(docRef)
                }
                let daySnap = try tx.getDocument(dayRef)
                if daySnap.exists {
                    resultDay = try daySnap.data(as: DailyDoc.self)
                }
            } catch let err as NSError {
                errPtr?.pointee = err
                return nil
            }
            
            // --- 2. LOGIC PHASE (No tx calls here) ---
            var newCount = 0
            var returningCount = 0
            var emailUpdates: [(DocumentReference, CourseEmail)] = []
            
            for email in uniqueEmails {
                let docRef = emailRef.document(self.emailKey(email))
                let snap = emailSnapshots[email]
                
                if let snap = snap, snap.exists, let data = try? snap.data(as: CourseEmail.self) {
                    var lastPlayed = data.lastPlayed ?? todayID
                    var secondSeen = data.secondSeen
                    let playCount = data.playCount
                    
                    if lastPlayed != todayID {
                        returningCount += 1
                        lastPlayed = todayID
                    }
                    if playCount == 1 && secondSeen == nil {
                        secondSeen = todayID
                    }
                    
                    let updated = CourseEmail(firstSeen: data.firstSeen ?? todayID, secondSeen: secondSeen, lastPlayed: lastPlayed, playCount: playCount + 1)
                    emailUpdates.append((docRef, updated))
                } else {
                    newCount += 1
                    let updated = CourseEmail(firstSeen: todayID, secondSeen: nil, lastPlayed: todayID, playCount: 1)
                    emailUpdates.append((docRef, updated))
                }
            }
            
            // Analytics calculations
            let roundLengthSeconds = max(0, Int(endTime.timeIntervalSince(startTime)))
            var totalStrokes = resultDay?.holeAnalytics.totalStrokesPerHole ?? [:]
            var playsPerHole = resultDay?.holeAnalytics.playsPerHole ?? [:]
            var hourlyCounts = resultDay?.hourlyCounts ?? [:]
            
            for player in game.players {
                for h in player.holes {
                    guard h.strokes != 0 else { continue }
                    let key = String(h.number)
                    totalStrokes[key, default: 0] += h.strokes
                    playsPerHole[key, default: 0] += 1
                }
            }
            hourlyCounts[String(currentHour), default: 0] += 1
            
            let finalDailyDoc = DailyDoc(
                dayID: todayID,
                totalRoundSeconds: (resultDay?.totalRoundSeconds ?? 0) + Int64(roundLengthSeconds),
                gamesPlayed: (resultDay?.gamesPlayed ?? 0) + 1,
                newPlayers: (resultDay?.newPlayers ?? 0) + newCount,
                returningPlayers: (resultDay?.returningPlayers ?? 0) + returningCount,
                holeAnalytics: HoleAnalytics(totalStrokesPerHole: totalStrokes, playsPerHole: playsPerHole),
                hourlyCounts: hourlyCounts,
                updatedAt: updatedAt
            )
            
            // --- 3. WRITE PHASE (All at the very end) ---
            do {
                for (ref, obj) in emailUpdates {
                    try tx.setData(from: obj, forDocument: ref, merge: true)
                }
                try tx.setData(from: finalDailyDoc, forDocument: dayRef, merge: true)
            } catch let err as NSError {
                errPtr?.pointee = err
                return nil
            }
            
            return true
        }) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ updateDayAnalytics failed: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func emailKey(_ email: String) -> String {
        email
            .lowercased()
            .replacingOccurrences(of: ".", with: ",")
    }
    
    func emailFromKey(_ key: String) -> String {
        key.replacingOccurrences(of: ",", with: ".")
    }
    
    func fetchDailyAnalytics(
        courseID: String,
        range: AnalyticsRange,
        existingDocs: [DailyDoc]
    ) async -> [DailyDoc] {
        // 1. Determine the full date range (Current Period + Previous Period)
        let startDate = range.startDate
        let endDate = range.endDate
        let extendedForData = Calendar.current.date(byAdding: .day, value: -range.daysBetween, to: startDate)!
        
        // Create a list of every single DayID we expect to have
        let allDaysInFullRange = daysInRange(from: extendedForData, to: endDate)
        
        // 2. Identify what we already have vs. what we need to fetch
        let existingDayIDs = Set(existingDocs.map { $0.dayID })
        let missingDays = allDaysInFullRange.filter { !existingDayIDs.contains($0) }
        
        var fetchedDocs: [DailyDoc] = []
        
        // 3. Fetch only the missing days from Firestore
        if !missingDays.isEmpty {
            let dailyDocsRef = db.collection(collectionName).document(courseID).collection("dailyDocs")
            
            do {
                // Chunking into 30s because Firestore 'in' query limit
                let chunks = stride(from: 0, to: missingDays.count, by: 30).map {
                    Array(missingDays[$0..<min($0 + 30, missingDays.count)])
                }
                
                for chunk in chunks {
                    let snapshot = try await dailyDocsRef
                        .whereField("dayID", in: chunk)
                        .getDocuments()
                    
                    let docs = snapshot.documents.compactMap { try? $0.data(as: DailyDoc.self) }
                    fetchedDocs.append(contentsOf: docs)
                }
            } catch {
                print("❌ Firestore fetch failed: \(error.localizedDescription)")
                // We continue so we can still provide zeroed-out docs for the missing slots
            }
        }
        
        // 4. Create a "Source of Truth" map from existing and fetched data
        let combinedFoundDocs = existingDocs + fetchedDocs
        let docLookup = Dictionary(uniqueKeysWithValues: combinedFoundDocs.map { ($0.dayID, $0) })
        
        // 5. RECONCILIATION: Map the timeline to ensure NO gaps
        let finalTimeline = allDaysInFullRange.map { dayID -> DailyDoc in
            if let actualDoc = docLookup[dayID] {
                return actualDoc
            } else {
                // Generate a zeroed-out placeholder for this session
                // Your DailyDoc init handles the weekID/weekDay auto-calculation
                return DailyDoc(dayID: dayID)
            }
        }
        
        // Sort to ensure the split logic (prefix/suffix) is mathematically sound
        return finalTimeline.sorted { $0.dayID < $1.dayID }
    }
    
    private func daysInRange(from startDate: Date, to endDate: Date) -> [String] {
        var days: [String] = []
        var current = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        
        while current <= end {
            days.append(makeDayID(from: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        
        return days
    }
    
    
    
    // MARK: - Debug Helpers
    func uploadDebugDailyDocs(
        courseID: String,
        days: Int = 90,
        completion: @escaping (Bool) -> Void
    ) {
        let calendar : Calendar = .current
        
        let end = calendar.startOfDay(for: Date())
        
        let docs = makeDebugDailyDocs(from: calendar.date(byAdding: .day, value: -(days - 1), to: end)!, to: end)
        
        guard !docs.isEmpty else {
            DispatchQueue.main.async { completion(true) }
            return
        }
        
        let courseRef = db.collection(collectionName).document(courseID)
        let dailyDocsRef = courseRef.collection("dailyDocs")
        let batch = db.batch()
        
        for doc in docs {
            let docRef = dailyDocsRef.document(doc.dayID)
            do {
                try batch.setData(from: doc, forDocument: docRef, merge: true)
            } catch {
                DispatchQueue.main.async {
                    print("❌ Failed to encode debug daily doc: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }
        }
        
        batch.commit { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to upload debug daily docs: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func makeDebugDailyDocs(
        from startDate: Date,
        to endDate: Date,
        holes: Int = 18
    ) -> [DailyDoc] {
        var docs: [DailyDoc] = []
        let calendar = Calendar.current
        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        while current <= end {
            let weekday = calendar.component(.weekday, from: current)
            
            // --- TREND: Day of Week Multipliers ---
            // Sunday = 1, Saturday = 7
            var dayWeight: Double = 1.0
            switch weekday {
            case 7, 1: dayWeight = Double.random(in: 1.8...2.5) // Busy Weekends
            case 6:    dayWeight = Double.random(in: 1.3...1.6) // Friday spike
            default:   dayWeight = Double.random(in: 0.7...1.1) // Normal Weekdays
            }
            
            // Scale the base game range by the day's weight
            let gamesPlayed = Int(Double(Int.random(in: 15...25)) * dayWeight)
            let players = Int.random(in: 2...4)
            let totalPlayers = gamesPlayed * players
            let newPlayers = Int(Double(totalPlayers) * Double.random(in: 0.4...0.7))
            let returningPlayers = totalPlayers - newPlayers
            
            let doc = makeDebugDailyDoc(
                dayID: makeDayID(from: current),
                holes: holes,
                players: players,
                gamesPlayed: gamesPlayed,
                newPlayers: newPlayers,
                returningPlayers: returningPlayers,
                updatedAt: current,
                dayWeight: dayWeight // Passed to distribute hours
            )
            
            docs.append(doc)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? end.addingTimeInterval(86400)
        }
        
        return docs
    }
    
    func makeDebugDailyDoc(
        dayID: String,
        holes: Int,
        players: Int,
        gamesPlayed: Int,
        newPlayers: Int,
        returningPlayers: Int,
        updatedAt: Date,
        dayWeight: Double = 1.0
    ) -> DailyDoc {
        // 1. Hole Difficulty Trends (Static variance so some holes are always harder)
        var totalStrokes: [String: Int] = [:]
        var playsPerHole: [String: Int] = [:]
        
        for hole in 1...holes {
            let key = String(hole)
            let plays = players * gamesPlayed
            playsPerHole[key] = plays
            
            // TREND: Make Holes 6, 9, and 18 naturally "harder"
            let difficultyBias = [6: 2, 9: 1, 18: 2][hole] ?? 0
            let avgStrokes = Int.random(in: 3...5) + difficultyBias
            totalStrokes[key] = avgStrokes * plays
        }
        
        // 2. TREND: Hourly "Rush Hour" Distribution
        var hourlyCounts: [String: Int] = [:]
        let weights: [Int: Double] = [
            0: 0.1, 1: 0.0, 7: 0.2, 8: 0.8, 9: 1.5, 10: 2.0,
            11: 3.0, 12: 4.5, 13: 4.0, 14: 4.5, 15: 5.0, 16: 7.0,
            17: 9.0, 18: 10.0, 19: 8.5, 20: 6.0, 21: 3.5, 22: 1.5, 23: 0.5
        ]
        
        var gamesToDistribute = gamesPlayed
        
        // Fill all hours with 0 first
        for h in 0...23 { hourlyCounts["\(h)"] = 0 }
        
        // Randomly assign games based on the weights
        while gamesToDistribute > 0 {
            let hour = (0...23).randomElement() ?? 18
            let chance = weights[hour] ?? 0.0
            
            // Higher weight = higher probability of a game being assigned here
            if Double.random(in: 0...10) < chance {
                hourlyCounts["\(hour)", default: 0] += 1
                gamesToDistribute -= 1
            }
        }
        
        return DailyDoc(
            dayID: dayID,
            totalRoundSeconds: Int64(Int.random(in: 70...100) * 60 * gamesPlayed),
            gamesPlayed: gamesPlayed,
            newPlayers: newPlayers,
            returningPlayers: returningPlayers,
            holeAnalytics: HoleAnalytics(totalStrokesPerHole: totalStrokes, playsPerHole: playsPerHole),
            hourlyCounts: hourlyCounts,
            updatedAt: updatedAt
        )
    }
    
    func fetchEmails(
        courseID: String
    ) async -> [String: CourseEmail] {
        let emailsRef = db.collection(collectionName).document(courseID).collection("emails")
        
        var emailsMap: [String: CourseEmail] = [:]
        var lastDoc: DocumentSnapshot? = nil
        let pageSize: Int = 30
        
        do {
            while true {
                let query = emailsRef.limit(to: pageSize)
                let queryWithStart = lastDoc != nil ? query.start(afterDocument: lastDoc!) : query
                
                let snapshot = try await queryWithStart.getDocuments()
                
                guard !snapshot.documents.isEmpty else { break }
                
                for document in snapshot.documents {
                    if let email = try? document.data(as: CourseEmail.self) {
                        let emailAddress = emailFromKey(document.documentID)
                        emailsMap[emailAddress] = email
                    }
                }
                
                lastDoc = snapshot.documents.last
                
                if snapshot.documents.count < pageSize { break }
            }
            
            return emailsMap
        } catch {
            print("❌ Firestore fetch emails failed: \(error.localizedDescription)")
            return [:]
        }
    }
}

enum AnalyticsRange: Equatable {
    case last7
    case last30
    case last90
    case custom(start: Date, end: Date)
    
    var title: String {
        switch self {
        case .last7: return "Last 7 days"
        case .last30: return "Last 30 days"
        case .last90: return "Last 90 days"
        case .custom: return "Custom"
        }
    }
    
    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
    
    /// Returns the concrete date range for this selection.
    /// End date is "today" for last7/30/90.
    func dates(now: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date, dStart: Date, dEnd: Date) {
        let end = calendar.startOfDay(for: now)
        
        switch self {
        case .last7:
            let start = calendar.date(byAdding: .day, value: -7, to: end)! // inclusive 7 days
            
            let deltaStart = calendar.date(byAdding: .day, value: -14, to: end)!
            let deltaEnd = calendar.date(byAdding: .day, value: -1, to: start)!
            return (start, end, deltaStart, deltaEnd)
            
        case .last30:
            let start = calendar.date(byAdding: .day, value: -30, to: end)! // inclusive 30 days
            
            let deltaStart = calendar.date(byAdding: .day, value: -60, to: end)!
            let deltaEnd = calendar.date(byAdding: .day, value: -1, to: start)!
            return (start, end, deltaStart, deltaEnd)
            
        case .last90:
            let start = calendar.date(byAdding: .day, value: -90, to: end)! // inclusive 90 days
            
            
            let deltaStart = calendar.date(byAdding: .day, value: -180, to: end)!
            let deltaEnd = calendar.date(byAdding: .day, value: -1, to: start)!
            return (start, end, deltaStart, deltaEnd)
            
        case .custom(let customStart, let customEnd):
            let start = calendar.startOfDay(for: customStart)
            let end = calendar.startOfDay(for: customEnd)
            
            let dayCount = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            let deltaEnd = calendar.date(byAdding: .day, value: -1, to: start)!
            let deltaStart = calendar.date(byAdding: .day, value: -(dayCount), to: deltaEnd)!
            
            return (start, end, deltaStart, deltaEnd)
        }
    }
    
    var startDate: Date { dates().start }
    var endDate: Date { dates().end }
    
    var startDelta: Date { dates().dStart }
    var endDelta: Date { dates().dEnd }
    
    var daysBetween: Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: startDate)
        let e = cal.startOfDay(for: endDate)
        return cal.dateComponents([.day], from: s, to: e).day ?? 0
    }
    
    var daysInMainRange : [String] {
        var days: [String] = []
        var current = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        
        while current <= end {
            days.append(makeDayID(from: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        
        return days
    }
    
    var daysInDeltaRange : [String] {
        var days: [String] = []
        var current = Calendar.current.startOfDay(for: startDelta)
        let end = Calendar.current.startOfDay(for: endDelta)
        
        while current <= end {
            days.append(makeDayID(from: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        
        return days
    }
}
