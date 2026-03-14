//
//  UserLocalDataSource.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation
import SwiftData

class UserLocalRepository{
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func fetch(id: String) -> UserModel? {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.googleId == id }
        )
        
        do {
            return try context.fetch(descriptor).first
        } catch {
            print("❌ Local fetch error: \(error)")
            return nil
        }
    }
    
    func save(model: UserModel, updatedLastUpdated: Bool = true, completion: @escaping (Bool) -> Void) {
        if updatedLastUpdated {
            model.lastUpdated = Date()
        }
        do {
            context.insert(model)
            try context.save()
            print("📦 Local save successful")
            completion(true)
        } catch {
            print("❌ Local save error: \(error)")
            completion(false)
        }
    }
    
    func delete(id: String, completion: @escaping (Bool) -> Void) {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.googleId == id }
        )
        
        do {
            if let user = try context.fetch(descriptor).first {
                context.delete(user)
                try context.save()
                print("🗑️ Local delete successful for id: \(id)")
                completion(true)
            } else {
                print("⚠️ No local user found with id: \(id)")
                completion(true)
            }
        } catch {
            print("❌ Local delete error: \(error)")
            completion(false)
        }
    }
}
