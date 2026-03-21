//
//  ProfileViewModel+iOS.swift
//  MiniMate
//

import Foundation
import SwiftUI
import AuthenticationServices
import FirebaseAuth

extension ProfileViewModel {
    // MARK: - iOS Specific Logic (Moves)
    
    func startAppleReauthAndDelete(isSheetPresent: Binding<Bool>) {
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = []
        
        let nonce = randomNonceString()
        authModel.currentNonce = nonce
        request.nonce = sha256(nonce)
        
        // Install handler
        reauthCoordinator.onAuthorize = { result in
            switch result {
            case .failure(let err):
                self.botMessage = err.localizedDescription
                self.isRed = true
                
            case .success(let authorization):
                self.deleteAppleAccount(using: authorization) { deletionResult in
                    switch deletionResult {
                    case .success():
                        isSheetPresent.wrappedValue = false
                        self.viewManager.navigateToWelcome()
                    case .failure(let err):
                        self.botMessage = err.localizedDescription
                        self.isRed = true
                    }
                }
            }
        }
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = reauthCoordinator
        controller.presentationContextProvider = reauthCoordinator
        controller.performRequests()
    }
    
    private func deleteAppleAccount(using authorization: ASAuthorization, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let appleCred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = authModel.currentNonce,
              let tokenData = appleCred.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else {
            return completion(.failure(NSError(
                domain: "ProfileViewModel",
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
        
        authRepository.deleteAccount(credential: oauthCred) { result in
            if case .success = result {
                self.cleanupLocalData()
                if let userModel = self.authModel.userModel {
                    let model = UserModel(googleId: userModel.googleId, appleId: userModel.appleId, name: userModel.name, photoURL: nil, email: userModel.email, gameIDs: [], accountType: ["apple"])
                    self.userRemoteRepo.save(id: self.authModel.currentUserIdentifier!, userModel: model) { _ in }
                }
            }
            completion(result)
        }
    }
    
    func managePictureChange(newImage: UIImage?) {
        guard let img = newImage, let userId = authModel.currentUserIdentifier else {
            self.botMessage = "Photo upload failed: Missing image or user ID"
            self.isRed = true
            return
        }
        
        userRepo.uploadProfilePhoto(id: userId, img) { result in
            switch result {
            case .success(let url):
                print("✅ Photo URL:", url)
            case .failure(let error):
                self.botMessage = "Photo upload failed: \(error.localizedDescription)"
                self.isRed = true
            }
        }
    }
}
