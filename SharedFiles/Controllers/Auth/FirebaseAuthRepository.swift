//
//  FirebaseAuthRepository.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation
import FirebaseAuth

class FirebaseAuthRepository {
    func createUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error creating user."])))
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error signing in."])))
            }
        }
    }
    
    func signIn(with credential: AuthCredential, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error signing in with credential."])))
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("❌ Sign-out error: \(error.localizedDescription)")
        }
    }

    func deleteAccount(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"])))
            return
        }
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            user.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func reauthenticate(with credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"])))
            return
        }
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func sendEmailVerification(completion: @escaping (Error?) -> Void) {
        Auth.auth().currentUser?.sendEmailVerification(completion: completion)
    }
    
    func sendPasswordReset(withEmail email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }
    
    func refreshVerificationStatus(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }

        user.reload { error in
            if let error = error {
                print("Reload error:", error.localizedDescription)
                completion(false)
            } else {
                completion(user.isEmailVerified)
            }
        }
    }
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
}
