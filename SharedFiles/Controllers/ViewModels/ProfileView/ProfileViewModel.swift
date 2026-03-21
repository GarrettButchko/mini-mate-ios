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
    let authModel: AuthViewModel
    let viewManager: ViewManager
    let userRepo: UserRepository
    let userRemoteRepo: UserRemoteRepository
    let localGameRepo: LocalGameRepository
    let authRepository = FirebaseAuthRepository()
    
    // Note: Stored properties must remain in the main class declaration in Swift.
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
        self.userRepo = userRepo
        self.userRemoteRepo = userRemoteRepo
        self.localGameRepo = localGameRepo
        self.viewManager = viewManager
    }
    
    // MARK: - Core Logic (Kotlin Multiplatform Candidates)
    
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
    
    func handleDeleteAccount(using credential: AuthCredential, isSheetPresent: Binding<Bool>) {
        authRepository.deleteAccount(credential: credential) { result in
            switch result {
            case .success:
                self.cleanupLocalData()
                isSheetPresent.wrappedValue = false
                self.viewManager.navigateToWelcome()
            case .failure(let error):
                self.botMessage = error.localizedDescription
                self.isRed = true
            }
        }
    }
    
    func cleanupLocalData() {
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
    
    func saveName(user: UserModel) {
        if oldName != name, let userModel = authModel.userModel, let userId = authModel.currentUserIdentifier {
            authModel.updateUserName(name)
            userRemoteRepo.save(id: userId, userModel: userModel) { _ in }
        }
    }
    
    func passwordReset(user: UserModel) {
        guard let targetEmail = user.email else {
            self.botMessage = "User has no email"
            self.isRed = true
            return
        }
        
        authRepository.sendPasswordReset(withEmail: targetEmail) { error in
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
    
    func deleteAccount(user: UserModel) {
        activeDeleteAlert = getDeleteAlertType(for: user)
    }
}
