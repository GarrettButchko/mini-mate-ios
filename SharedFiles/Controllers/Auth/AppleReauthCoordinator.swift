//
//  AppleReauthCoordinator.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/4/25.
//


import AuthenticationServices
import FirebaseAuth

class AppleReauthCoordinator: NSObject, ASAuthorizationControllerDelegate,
                              ASAuthorizationControllerPresentationContextProviding {
    
    /// You’ll deliver the resulting ASAuthorization back here:
    var onAuthorize: (Result<ASAuthorization, Error>) -> Void
    
    init(onAuthorize: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.onAuthorize = onAuthorize
    }
    
    // ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        // return your app’s key window
        UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first { $0.isKeyWindow } }
            .first!
    }
    
    // ASAuthorizationControllerDelegate
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        onAuthorize(.success(authorization))
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        onAuthorize(.failure(error))
    }
}
