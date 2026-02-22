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
        existingDocs: [DailyDoc],
    ) async -> [DailyDoc] {
        let startDate = range.startDate
        let endDate = range.endDate
        let exendedForData = Calendar.current.date(byAdding: .day, value: -range.daysBetween, to: startDate)!
        let existingDayIDs = Set(existingDocs.map { $0.dayID })
        let allDaysInRange = daysInRange(from: exendedForData, to: endDate)
        let missingDays = allDaysInRange.filter { !existingDayIDs.contains($0) }
        
        guard !missingDays.isEmpty else { return existingDocs }
        
        let courseRef = db.collection(collectionName).document(courseID)
        let dailyDocsRef = courseRef.collection("dailyDocs")
        
        do {
            // Firestore 'in' query supports up to 30 values — chunk accordingly
            let chunks = stride(from: 0, to: missingDays.count, by: 30).map {
                Array(missingDays[$0..<min($0 + 30, missingDays.count)])
            }
            
            var allNewDocs: [DailyDoc] = []
            for chunk in chunks {
                let snapshot = try await dailyDocsRef
                    .whereField("dayID", in: chunk)
                    .getDocuments()
                let docs = snapshot.documents.compactMap { try? $0.data(as: DailyDoc.self) }
                allNewDocs.append(contentsOf: docs)
            }
            
            let combined = (existingDocs + allNewDocs).filter { allDaysInRange.contains($0.dayID) }
            return combined
        } catch {
            print("❌ Failed to fetch daily analytics: \(error.localizedDescription)")
            return existingDocs
        }
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
        holes: Int = 18,
        playersRange: ClosedRange<Int> = 3...5,
        gamesRange: ClosedRange<Int> = 1...4,
        avgStrokesRange: ClosedRange<Int> = 3...5,
        durationMinutesRange: ClosedRange<Int> = 70...110,
        newPlayersRange: ClosedRange<Int> = 0...3,
        returningPlayersRange: ClosedRange<Int> = 1...5
    ) -> [DailyDoc] {
        var docs: [DailyDoc] = []
        var current = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)
        
        while current <= end {
            let gamesPlayed = Int.random(in: gamesRange)
            let players = Int.random(in: playersRange)
            let totalPlayers = max(1, players * max(1, gamesPlayed))
            let newPlayers = min(Int.random(in: newPlayersRange), totalPlayers)
            let returningPlayers = min(Int.random(in: returningPlayersRange), max(0, totalPlayers - newPlayers))
            let avgStrokes = Int.random(in: avgStrokesRange)
            let durationMinutes = Int.random(in: durationMinutesRange)
            
            let doc = makeDebugDailyDoc(
                dayID: makeDayID(from: current),
                holes: holes,
                players: players,
                gamesPlayed: gamesPlayed,
                avgStrokesPerHole: avgStrokes,
                durationMinutes: durationMinutes,
                newPlayers: newPlayers,
                returningPlayers: returningPlayers,
                updatedAt: current
            )
            docs.append(doc)
            
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? end.addingTimeInterval(86400)
        }
        
        return docs
    }
    
    func makeDebugDailyDoc(
        dayID: String = makeDayID(),
        holes: Int = 18,
        players: Int = 4,
        gamesPlayed: Int = 1,
        avgStrokesPerHole: Int = 4,
        durationMinutes: Int = 90,
        newPlayers: Int = 2,
        returningPlayers: Int = 2,
        updatedAt: Date = Date()
    ) -> DailyDoc {
        var totalStrokes: [String: Int] = [:]
        var playsPerHole: [String: Int] = [:]
        
        let plays = max(0, players * max(1, gamesPlayed))
        let strokes = max(0, avgStrokesPerHole) * plays
        
        for hole in 1...max(1, holes) {
            let key = String(hole)
            totalStrokes[key] = strokes
            playsPerHole[key] = plays
        }
        
        let currentHour = Calendar.current.component(.hour, from: updatedAt)
        let hourlyCounts = [String(currentHour): max(1, gamesPlayed)]
        
        return DailyDoc(
            dayID: dayID,
            totalRoundSeconds: Int64(max(0, durationMinutes * 60) * max(1, gamesPlayed)),
            gamesPlayed: max(1, gamesPlayed),
            newPlayers: max(0, newPlayers),
            returningPlayers: max(0, returningPlayers),
            holeAnalytics: HoleAnalytics(totalStrokesPerHole: totalStrokes, playsPerHole: playsPerHole),
            hourlyCounts: hourlyCounts,
            updatedAt: updatedAt
        )
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
            let start = calendar.date(byAdding: .day, value: -6, to: end)! // inclusive 7 days
            
            let deltaStart = calendar.date(byAdding: .day, value: -13, to: end)!
            let deltaEnd = calendar.date(byAdding: .day, value: -7, to: end)!
            return (start, end, deltaStart, deltaEnd)
            
        case .last30:
            let start = calendar.date(byAdding: .day, value: -29, to: end)! // inclusive 30 days
            
            let deltaStart = calendar.date(byAdding: .day, value: -59, to: end)!
            let deltaEnd = calendar.date(byAdding: .day, value: -30, to: end)!
            return (start, end, deltaStart, deltaEnd)
            
        case .last90:
            let start = calendar.date(byAdding: .day, value: -89, to: end)! // inclusive 90 days
            
            
            let deltaStart = calendar.date(byAdding: .day, value: -179, to: end)!
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
