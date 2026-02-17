//
//  UnifiedGameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//
import SwiftData
import Dispatch

class UnifiedGameRepository {
    let local: LocalGameRepository
    let remote = FirestoreGameRepository()
    
    init(context: ModelContext) {
        self.local = LocalGameRepository(context: context)
    }
    
    func saveAllLocally(_ gameIds: [String], context: ModelContext, completion: @escaping (Bool) -> Void) {
        print("start of save all locally")
        fetchAll(ids: gameIds) { games in
            print("Fetched \(games.count) games")
            
            let group = DispatchGroup()
            var allSuccess = true
            
            for game in games {
                group.enter()
                DispatchQueue.global().async {
                    do {
                        context.insert(Game.fromDTO(game))
                        try context.save()
                        print("💾 Inserted new game: \(game.id)")
                    } catch {
                        print("❌ Failed to save locally:", error)
                        allSuccess = false
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(allSuccess)
            }
        }
    }
    
    func save(_ game: Game, completion: @escaping (Bool, Bool) -> Void) {
        let group = DispatchGroup()
        var localComplete = false
        var remoteComplete = false
        
        // 1️⃣ Save locally
        group.enter()
        local.save(game) { success in
            localComplete = success
            group.leave()
        }
        
        // 2️⃣ Save remotely
        group.enter()
        remote.save(game) { remoteSuccess in
            remoteComplete = remoteSuccess
            group.leave()
        }
        
        // 3️⃣ Call completion only after both finish
        group.notify(queue: .main) {
            completion(localComplete, remoteComplete)
        }
    }
    
    func fetch(id: String, completion: @escaping (GameDTO?) -> Void) {
        // Try local first
        local.fetch(id: id) { localGame in
            if let game = localGame {
                completion(game.toDTO())
            } else {
                self.remote.fetch(id: id, completion: completion)
            }
        }
    }
    
    func fetchAll(ids: [String], completion: @escaping ([GameDTO]) -> Void) {
        // 1️⃣ Fetch local immediately
        local.fetchAll(ids: ids) { localGames in
            
            let localDTOs = localGames.map { $0.toDTO() }
            
            // Begin remote fetch in parallel, but with timeout
            var remoteReturned = false
            var remoteDTOs: [GameDTO] = []
            
            // 2️⃣ Start a timeout timer (e.g., 5 seconds)
            let timeoutSeconds = 5.0
            let timer = DispatchSource.makeTimerSource()
            timer.schedule(deadline: .now() + timeoutSeconds)
            timer.setEventHandler {
                if !remoteReturned {
                    remoteReturned = true
                    timer.cancel()
                    print("⏰ Remote fetch timed out — using local only")
                    finish()
                }
            }
            timer.resume()
            
            // 3️⃣ Remote fetch
            self.remote.fetchAll(withIDs: ids) { fetchedRemote in
                if !remoteReturned {
                    remoteReturned = true
                    timer.cancel()
                    remoteDTOs = fetchedRemote
                    finish()
                }
            }
            
            // 4️⃣ Merge + complete (shared helper)
            func finish() {
                var seen = Set<String>()
                var combined: [GameDTO] = []
                
                for game in localDTOs + remoteDTOs {
                    if seen.insert(game.id).inserted {
                        combined.append(game)
                    }
                }
                
                completion(combined)
            }
        }
    }

}
