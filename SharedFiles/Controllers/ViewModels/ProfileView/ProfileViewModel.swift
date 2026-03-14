//
//  ProfileViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/17/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import SwiftUI
import Combine

enum DeleteAlertType: Identifiable {
    case google
    case apple
    case email
    
    var id: Int {
        switch self {
        case .google: return 0
        case .apple:  return 1
        case .email:  return 2
        }
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - Published UI State
    @Published var editProfile = false
    @Published var botMessage = ""
    @Published var isRed = true
    @Published var name = ""
    @Published var email = ""
    @Published var activeDeleteAlert: DeleteAlertType?
    var oldName: String? = nil
    
    // MARK: - Dependencies
    private let authModel: AuthViewModel
    private let viewManager: ViewManager
    private let profileService: ProfileService
    
    let reauthCoordinator = AppleReauthCoordinator { _ in }
    
    // MARK: - Init
    init(
        authModel: AuthViewModel,
        userRepo: UserRepository,
        userRemoteRepo: UserRemoteRepository,
        localGameRepo: LocalGameRepository,
        viewManager: ViewManager
    ) {
        self.authModel = authModel
        self.viewManager = viewManager
        self.profileService = ProfileService(
            authModel: authModel,
            userRepo: userRepo,
            userRemoteRepo: userRemoteRepo,
            localGameRepo: localGameRepo
        )
    }
    
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
                self.profileService.deleteAppleAccount(using: authorization) { deletionResult in
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
    
    func googleReauthAndDelete(isSheetPresent: Binding<Bool>) {
        authModel.reauthenticateWithGoogle { reauthResult in
            switch reauthResult {
            case .success(let credential):
                self.handleDeleteAccount(using: credential, isSheetPresent: isSheetPresent)
            case .failure(let error):
                self.botMessage = error.localizedDescription
                self.isRed = true
            }
        }
    }
    
    func emailReauthAndDelete(email: String, password: String, isSheetPresent: Binding<Bool>) {
        authModel.reauthenticateWithEmail(email: email, password: password){ reauthResult in
            switch reauthResult {
            case .success(let credential):
                self.handleDeleteAccount(using: credential, isSheetPresent: isSheetPresent)
            case .failure(let error):
                self.botMessage = error.localizedDescription
                self.isRed = true
            }
        }
    }
    
    private func handleDeleteAccount(using credential: AuthCredential, isSheetPresent: Binding<Bool>) {
        profileService.deleteAccount(credential: credential) { result in
            switch result {
            case .success:
                isSheetPresent.wrappedValue = false
                self.viewManager.navigateToWelcome()
            case .failure(let error):
                self.botMessage = error.localizedDescription
                self.isRed = true
            }
        }
    }
    
    func managePictureChange(newImage: UIImage?) {
        profileService.managePictureChange(newImage: newImage) { result in
            switch result {
            case .success(let url):
                print("✅ Photo URL:", url)
            case .failure(let error):
                self.botMessage = "Photo upload failed: \(error.localizedDescription)"
                self.isRed = true
            }
        }
    }
    
    func saveName(user: UserModel) {
        profileService.saveName(newName: name, oldName: oldName)
    }
    
    func passwordReset(user: UserModel) {
        profileService.passwordReset(user: user) { error in
            if let error = error {
                self.botMessage = error.localizedDescription
                self.isRed = true
            } else {
                self.botMessage = "Password reset email sent!"
                self.isRed = false
            }
        }
    }
    
    func logOut() {
        withAnimation {
            viewManager.navigateToWelcome()
        }
        profileService.logOut()
    }
    
    func deleteAccount(user: UserModel) {
        activeDeleteAlert = profileService.getDeleteAlertType(for: user)
    }
}
