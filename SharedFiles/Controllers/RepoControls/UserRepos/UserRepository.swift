//
//  UserRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/4/25.
//
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import SwiftData
import Combine

final class UserRepository {
    
    @Published var firebaseUser: FirebaseAuth.User?
    
    let localRepo: UserLocalRepository
    let remoteRepo: UserRemoteRepository
    
    init(context: ModelContext) {
        self.localRepo = UserLocalRepository(context: context)
        self.remoteRepo = UserRemoteRepository()
    }
    
    func loadOrCreateUser(
        id: String,
        firebaseUser: User? = nil,
        name: String? = nil,
        authModel: AuthViewModel,
        signInMethod: SignInMethod? = nil,
        appleId: String? = nil,
        guestGame: Game? = nil,
        completion: @escaping (_ done1: Bool,_ done2: Bool,_ creation: Bool) -> Void
    ) {
        let local = localRepo.fetch(id: id)

        // 1️⃣ Immediate local phase
        if let local {
            DispatchQueue.main.async {
                print("✅ Found local user immediately")
                authModel.setUserModel(local)
                completion(true, false, false)
            }
        }

        // 2️⃣ Background reconcile phase - run on background queue
        DispatchQueue.global(qos: .userInitiated).async {
            self.remoteRepo.fetch(id: id) { remote in
                self.reconcile(
                    local: local,
                    remote: remote,
                    id: id,
                    firebaseUser: firebaseUser,
                    name: name,
                    authModel: authModel,
                    signInMethod: signInMethod,
                    appleId: appleId,
                    guestGame: guestGame
                ) { result in
                    completion(false, true, result) // ✅ reconcile finished
                }
            }
        }
    }
    
    // MARK: - Async/Await Version for Better Performance
    func loadOrCreateUserAsync(
        id: String,
        firebaseUser: User? = nil,
        name: String? = nil,
        authModel: AuthViewModel,
        signInMethod: SignInMethod? = nil,
        appleId: String? = nil,
        guestGame: Game? = nil
    ) async -> (immediate: Bool, reconciled: Bool, created: Bool) {
        await MainActor.run {
            authModel.isLoadingUser = true
        }
        defer {
            Task { @MainActor in
                authModel.isLoadingUser = false
            }
        }
        
        
        // 1️⃣ Immediate local phase - run synchronously on main
        let local = localRepo.fetch(id: id)
        
        if let local {
            print("✅ Found local user immediately")
            authModel.setUserModel(local)
            
            // 2️⃣ Background reconcile phase - use regular Task to stay on main actor
            Task(priority: .userInitiated) {
                let remote = await self.fetchRemoteAsync(id: id)
                _ = await self.reconcileAsync(
                    local: local,
                    remote: remote,
                    id: id,
                    firebaseUser: firebaseUser,
                    name: name,
                    authModel: authModel,
                    signInMethod: signInMethod,
                    appleId: appleId,
                    guestGame: guestGame
                )
            }
            
            return (true, false, false)
        }
        
        // No local user - need to fetch remote
        let remote = await fetchRemoteAsync(id: id)
        let created = await reconcileAsync(
            local: nil,
            remote: remote,
            id: id,
            firebaseUser: firebaseUser,
            name: name,
            authModel: authModel,
            signInMethod: signInMethod,
            appleId: appleId,
            guestGame: guestGame
        )
        
        return (false, true, created)
    }
    
    private func fetchRemoteAsync(id: String) async -> UserModel? {
        await withCheckedContinuation { continuation in
            remoteRepo.fetch(id: id) { user in
                continuation.resume(returning: user)
            }
        }
    }
    
    private func reconcileAsync(
        local: UserModel?,
        remote: UserModel?,
        id: String,
        firebaseUser: User?,
        name: String?,
        authModel: AuthViewModel,
        signInMethod: SignInMethod? = nil,
        appleId: String? = nil,
        guestGame: Game? = nil
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            reconcile(
                local: local,
                remote: remote,
                id: id,
                firebaseUser: firebaseUser,
                name: name,
                authModel: authModel,
                signInMethod: signInMethod,
                appleId: appleId,
                guestGame: guestGame
            ) { created in
                continuation.resume(returning: created)
            }
        }
    }

    private func reconcile(
        local: UserModel?,
        remote: UserModel?,
        id: String,
        firebaseUser: User?,
        name: String?,
        authModel: AuthViewModel,
        signInMethod: SignInMethod? = nil,
        appleId: String? = nil,
        guestGame: Game? = nil,
        creation: @escaping(Bool) -> Void
    ) {
        
        switch (local, remote) {
            
        case let (local?, remote?):
            
            let delta = abs(local.lastUpdated.timeIntervalSince(remote.lastUpdated))
            
            if delta < 0.5 {
                print("🔄 Already in sync")

                if let signInMethod = signInMethod?.rawValue,
                   !local.accountType.contains(signInMethod) {

                    local.accountType.append(signInMethod)
                    remoteRepo.save(id: id, userModel: local, updateLastUpdated: false) { _ in
                        creation(false)
                    }
                } else {
                    creation(false)
                }
            } else if local.lastUpdated > remote.lastUpdated {
                print("🔄 Local → Remote")
                
                if let signInMethod = signInMethod?.rawValue, !local.accountType.contains(signInMethod) {
                    local.accountType.append(signInMethod)
                }
                remoteRepo.save(id: id, userModel: local, updateLastUpdated: false) { _ in
                    creation(false)
                }
            } else {
                print("🔄 Remote → Local")
                
                if let signInMethod = signInMethod?.rawValue, !remote.accountType.contains(signInMethod) {
                    remote.accountType.append(signInMethod)
                }
                DispatchQueue.main.async {
                    self.localRepo.save(model: remote, updatedLastUpdated: false) { _ in
                        authModel.setUserModel(remote)
                        creation(false)
                    }
                }
            }
            
        case let (local?, nil):
            print("🔄 Local → Remote (no remote)")
            
            if let signInMethod = signInMethod?.rawValue, !local.accountType.contains(signInMethod) {
                local.accountType.append(signInMethod)
            }
            
            remoteRepo.save(id: id, userModel: local, updateLastUpdated: false) { _ in
                creation(false)
            }
            
        case let (nil, remote?):
            print("🔄 Remote → Local (no local)")
            
            if let signInMethod = signInMethod?.rawValue, !remote.accountType.contains(signInMethod) {
                remote.accountType.append(signInMethod)
            }
            DispatchQueue.main.async {
                self.localRepo.save(model: remote, updatedLastUpdated: false) { _ in
                    authModel.setUserModel(remote)
                    creation(false)
                }
            }
            
        case (nil, nil):
            createUser(id: id, firebaseUser: firebaseUser, name: name, authModel: authModel, signInMethod: signInMethod, guestGame: guestGame) {
                creation(true)
            }
        }
    }

    
    func createUser(id: String, firebaseUser: User?, name: String?, authModel: AuthViewModel, signInMethod: SignInMethod? = nil, appleId: String? = nil, guestGame: Game?, completion: @escaping () -> Void){
        
        let finalName  = name ?? firebaseUser?.displayName ?? "User#\(String(id.prefix(5)))"
        let finalEmail = firebaseUser?.email ?? "Email"
        
        let newUser = UserModel(googleId: id, appleId: appleId, name: finalName, photoURL: firebaseUser?.photoURL, email: finalEmail, gameIDs: [], accountType: [signInMethod!.rawValue])
        
        if let guestGame {
            newUser.gameIDs.append(guestGame.id)
        }
        
        localRepo.save(model: newUser) { _ in }
        remoteRepo.save(id: id, userModel: newUser) { _ in }
        DispatchQueue.main.async {
            authModel.setUserModel(newUser)
            print("✅ Created new user")
            completion()
        }
    }
    
    func addAccountTypeIfNeeded(_ type: String, to list: inout [String]) {
        if !list.contains(type) {
            list.append(type)
        }
    }
    
    func saveUnified(id: String, userModel: UserModel, completion: @escaping (Bool, Bool) -> Void) {
        var localSuccess: Bool?
        var remoteSuccess: Bool?
        
        func returnIfDone() {
            if let local = localSuccess, let remote = remoteSuccess {
                completion(local, remote)
            }
        }
        
        localRepo.save(model: userModel) { success in
            localSuccess = success
            returnIfDone()
        }
        
        remoteRepo.save(id: id, userModel: userModel) { success in
            remoteSuccess = success
            returnIfDone()
        }
    }

    func deleteUnified(id: String) {
        localRepo.delete(id: id) { _ in }
        remoteRepo.delete(id: id) { _ in }
    }

    
    func uploadProfilePhoto(
        id: String,
        _ image: UIImage,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return completion(.failure(NSError(
                domain: "UserRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"]
            )))
        }
        
        remoteRepo.uploadProfilePhoto(id: id, imageData: data) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let url):
                let local = self.localRepo.fetch(id: id)
                
                DispatchQueue.main.async {
                    local?.photoURL = url
                    local?.lastUpdated = Date()
                    
                    if let userModel = local {
                        self.saveUnified(id: id, userModel: userModel) { localOK, remoteOK in
                            if localOK && remoteOK {
                                print("Saved Photo Everywhere")
                            } else {
                                print("Failed to save photo URL to one or more data sources.")
                            }
                            completion(.success(url))
                        }
                    } else {
                        completion(.success(url))
                    }
                }
            }
        }
    }
}
