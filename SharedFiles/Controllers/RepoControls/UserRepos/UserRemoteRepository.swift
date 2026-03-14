//
//  UserRemoteDataSource.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class UserRemoteRepository {
    private let db = Firestore.firestore()
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }

    func fetch(id: String, completion: @escaping (UserModel?) -> Void) {
        let ref = usersCollection.document(id)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            
            Task{ @MainActor in
                do {
                    let dto = try snapshot.data(as: UserDTO.self)
                    let model = UserModel.fromDTO(dto)
                    completion(model)
                } catch {
                    print("❌ Firestore decoding error: \(error)")
                    completion(nil)
                }
            }
        }
    }

    func save(id: String, userModel: UserModel, updateLastUpdated: Bool = true, completion: @escaping (Bool) -> Void) {
        let ref = usersCollection.document(id)
        
        let updatedUser = userModel
        if updateLastUpdated {
            updatedUser.lastUpdated = Date()
        }
        
        do {
            try ref.setData(from: updatedUser.toDTO(), merge: true) { error in
                if let error = error {
                    print("❌ Firestore save error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } catch {
            print("❌ Firestore encoding error: \(error)")
            completion(false)
        }
    }

    func delete(id: String, completion: @escaping (Bool) -> Void) {
        let ref = usersCollection.document(id)

        ref.getDocument { snapshot, error in
            guard snapshot?.exists == true else {
                print("⚠️ User doc did not exist")
                completion(true)
                return
            }

            ref.delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Firestore delete error:", error)
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func uploadProfilePhoto(
        id: String,
        imageData: Data,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            return completion(.failure(NSError(
                domain: "UserRemoteDataSource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No signed-in user"]
            )))
        }
        
        let ref = Storage.storage()
            .reference()
            .child("profile_pictures")
            .child("\(id).jpg")
        
        ref.putData(imageData, metadata: nil) { meta, error in
            if let error = error {
                return completion(.failure(error))
            }
            ref.downloadURL { result in
                switch result {
                case .failure(let error):
                    return completion(.failure(error))
                case .success(let url):
                    let changeReq = user.createProfileChangeRequest()
                    changeReq.photoURL = url
                    changeReq.commitChanges { err in
                        if let err = err {
                            print("⚠️ Failed to set Auth photoURL:", err)
                        }
                        completion(.success(url))
                    }
                }
            }
        }
    }
}
