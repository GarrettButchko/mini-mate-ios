//
//  CourseLeaderboardRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

/// Handles all Firestore operations for All-Time Course Leaderboards
final class CourseLeaderboardRepository {
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // MARK: - Internal References
    
    private func allTimeEntriesRef(courseID: String) -> CollectionReference {
        db.collection("courses").document(courseID)
            .collection("allTimeLeaderboard")
    }
    
    // MARK: - Fetch Data
    
    func fetchTopAllTime(courseID: String, limit: Int = 25, completion: @escaping ([LeaderboardEntry]) -> Void) {
        allTimeEntriesRef(courseID: courseID)
            .order(by: "totalStrokes", descending: false)
            .limit(to: limit)
            .getDocuments { snap, err in
                guard let docs = snap?.documents, err == nil else {
                    Task { @MainActor in completion([]) }
                    return
                }

                Task { @MainActor in
                    let items: [LeaderboardEntry] = docs.compactMap {
                        try? $0.data(as: LeaderboardEntry.self)
                    }
                    completion(items)
                }
            }
    }

    // MARK: - Live Listening
    
    func listenTopAllTime(courseID: String, limit: Int = 25, onUpdate: @escaping ([LeaderboardEntry]) -> Void) {
        listener?.remove()
        
        listener = allTimeEntriesRef(courseID: courseID)
            .order(by: "totalStrokes", descending: false)
            .limit(to: limit)
            .addSnapshotListener { snap, err in
                guard let docs = snap?.documents, err == nil else {
                    DispatchQueue.main.async { onUpdate([]) }
                    return
                }
                let items: [LeaderboardEntry] = docs.compactMap { try? $0.data(as: LeaderboardEntry.self) }
                DispatchQueue.main.async { onUpdate(items) }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Submit Score
    
    func submitScore(courseID: String, player: Player, completion: @escaping (Bool) -> Void) {
        guard let entry = player.toDTO().convertToLBREP() else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        
        let docRef = allTimeEntriesRef(courseID: courseID).document(entry.userId)
        
        db.runTransaction({ tx, errPtr -> Any? in
            let snap: DocumentSnapshot
            do { snap = try tx.getDocument(docRef) }
            catch let e as NSError { errPtr?.pointee = e; return nil }
            
            let oldBest = snap.data()?["totalStrokes"] as? Int ?? Int.max
            
            // 1. Create a copy of the entry with the best score
            var finalEntry = entry
            finalEntry.totalStrokes = min(oldBest, entry.totalStrokes)
            
            // 2. Encode the entry to a dictionary automatically
            do {
                // Firestore provides a way to convert Codable objects to dictionaries
                let data = try Firestore.Encoder().encode(finalEntry)
                tx.setData(data, forDocument: docRef, merge: true)
            } catch let e as NSError {
                errPtr?.pointee = e
                return nil
            }
            
            return nil
        }) { _, err in
            DispatchQueue.main.async { completion(err == nil) }
        }
    }
    
    // MARK: - Delete Entry
    
    /// Deletes a specific player's entry from the All-Time leaderboard
    func deleteEntry(courseID: String, playerID: String, completion: @escaping (Bool) -> Void) {
        allTimeEntriesRef(courseID: courseID)
            .document(playerID)
            .delete { error in
                DispatchQueue.main.async {
                    completion(error == nil)
                }
            }
    }
    
    // MARK: - Bulk Delete
    
    /// Deletes every entry in the leaderboard for a specific course
    func deleteAllEntries(courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = allTimeEntriesRef(courseID: courseID)
        
        // 1. Fetch all document references in the collection
        ref.getDocuments { snap, err in
            guard let docs = snap?.documents, err == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            // If it's already empty, we're technically done
            if docs.isEmpty {
                DispatchQueue.main.async { completion(true) }
                return
            }
            
            // 2. Use a Write Batch to delete all docs in one network call
            let batch = self.db.batch()
            docs.forEach { batch.deleteDocument($0.reference) }
            
            batch.commit { batchErr in
                DispatchQueue.main.async {
                    completion(batchErr == nil)
                }
            }
        }
    }
}
