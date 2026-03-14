//
//  ProfileService.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation
import FirebaseAuth
import SwiftUI
import AuthenticationServices

class ProfileService {
    private let authModel: AuthViewModel
    private let userRepo: UserRepository
    private let userRemoteRepo: UserRemoteRepository

    private let localGameRepo: LocalGameRepository
    private let authRepository = FirebaseAuthRepository()

    init(
        authModel: AuthViewModel,
        userRepo: UserRepository,
        userRemoteRepo: UserRemoteRepository,
        localGameRepo: LocalGameRepository
    ) {
        self.authModel = authModel
        self.userRepo = userRepo
        self.userRemoteRepo = userRemoteRepo
        self.localGameRepo = localGameRepo
    }

    func deleteAccount(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        authRepository.deleteAccount(credential: credential) { result in
            if case .success = result {
                self.cleanupLocalData()
            }
            completion(result)
        }
    }
    
    func deleteAppleAccount(using authorization: ASAuthorization, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let appleCred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = authModel.currentNonce,
              let tokenData = appleCred.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else {
            return completion(.failure(NSError(
                domain: "ProfileService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"]
            )))
        }
        
        let oauthCred = OAuthProvider.credential(
            providerID: .apple,
            idToken: idToken,
            rawNonce: nonce,
            accessToken: nil
        )
        
        deleteAccount(credential: oauthCred) { result in
            if case .success = result {
                if let userModel = self.authModel.userModel {
                    let model = UserModel(googleId: userModel.googleId, appleId: userModel.appleId, name: userModel.name, photoURL: nil, email: userModel.email, gameIDs: [], accountType: ["apple"])
                    self.userRemoteRepo.save(id: self.authModel.currentUserIdentifier!, userModel: model) { _ in }
                }
            }
            completion(result)
        }
    }

    private func cleanupLocalData() {
        guard let userModel = authModel.userModel else { return }
        let gameIDs = userModel.gameIDs
        let userID = userModel.googleId

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.localGameRepo.deleteAll(ids: gameIDs) { completed in
                if completed {
                    print("🗑️ Deleted all local games for user")
                }
            }
            self.userRepo.deleteUnified(id: userID)
        }
    }

    func managePictureChange(newImage: UIImage?, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let img = newImage, let userId = authModel.currentUserIdentifier else {
            completion(.failure(NSError(domain: "ProfileService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing image or user ID"])))
            return
        }
        userRepo.uploadProfilePhoto(id: userId, img, completion: completion)
    }

    func saveName(newName: String, oldName: String?) {
        if oldName != newName, let userModel = authModel.userModel, let userId = authModel.currentUserIdentifier {
            authModel.updateUserName(newName)
            userRemoteRepo.save(id: userId, userModel: userModel) { _ in }
        }
    }

    func passwordReset(user: UserModel, completion: @escaping (Error?) -> Void) {
        guard let targetEmail = user.email else {
            completion(NSError(domain: "ProfileService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User has no email"]))
            return
        }
        authRepository.sendPasswordReset(withEmail: targetEmail, completion: completion)
    }

    func logOut() {
        authModel.logout()
    }

    func getDeleteAlertType(for user: UserModel) -> DeleteAlertType {
        if user.accountType.contains("google") {
            return .google
        } else if user.accountType.contains("apple") {
            return .apple
        } else {
            return .email
        }
    }
}
