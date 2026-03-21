//
//  RemoteCourseRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine

final class CourseRepository {
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    let collectionName: String = "courses"
    
    
    // MARK: General Course
    func addOrUpdateCourse(_ course: Course, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(course.id)
        
        // Update computed properties before saving
        var updatedCourse = course
        updatedCourse.updateComputedProperties()
        
        do {
            try ref.setData(from: updatedCourse, merge: true) { error in
                completion(error == nil)
            }
        } catch {
            print("❌ Firestore encoding error: \(error)")
            completion(false)
        }
    }
    
    func deleteCourseItem(courseID: String, dataName: String) {
        Firestore.firestore()
            .collection("courses")
            .document(courseID)
            .updateData([
                dataName: FieldValue.delete()
            ])
    }
    
    func setCourseItem(courseID: String, dataName: String, object: Any) {
        Firestore.firestore()
            .collection("courses")
            .document(courseID)
            .updateData([
                dataName: object
            ])
    }
    
    func listenToCourse(
        id: String,
        onUpdate: @escaping (Course?) -> Void
    ) {
        stopListening()
        
        listener = db.collection("courses")
            .document(id)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("❌ Listener error:", error)
                    onUpdate(nil)
                    return
                }
                
                guard let snapshot, snapshot.exists else {
                    onUpdate(nil)
                    return
                }
                
                Task { @MainActor in
                    do {
                        let course = try snapshot.data(as: Course.self)
                        onUpdate(course)
                    } catch {
                        print("❌ Decode error:", error)
                        onUpdate(nil)
                    }
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    /// Fetches a Course by ID from Firestore
    func fetchCourse(id: String, mapItem: MapItemDTO? = nil, completion: @escaping (Course?) -> Void) {
        let ref = db.collection(collectionName).document(id)
        
        ref.getDocument { [self] snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("Course with ID \(id) does not exist.")
                if let mapItem {
                    createCourseWithMapItem(courseID: id, location: mapItem) { course in
                        if let course {
                            completion(course)
                        } else {
                            completion(nil)
                        }
                    }
                } else {
                    completion(nil)
                }
                return
            }
            
            // Decode the document directly into your Course model on the main actor
            Task { @MainActor in
                do {
                    let course = try snapshot.data(as: Course.self)
                    completion(course)
                } catch {
                    print("❌ Firestore decoding error: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    /// Fetches multiple Courses by their document IDs
    func fetchCourses(ids: [String], completion: @escaping ([Course]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }
        
        let group = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "CourseRepository.fetchCourses.resultsQueue")
        var results: [String: Course] = [:]
        
        for id in ids {
            group.enter()
            
            let ref = db.collection(collectionName).document(id)
            ref.getDocument { snapshot, error in
                defer { group.leave() }
                
                guard
                    error == nil,
                    let snapshot,
                    snapshot.exists
                else {
                    return
                }
                
                Task { @MainActor in
                    do {
                        let course = try snapshot.data(as: Course.self)
                        resultsQueue.sync {
                            results[id] = course
                        }
                    } catch {
                        // Ignore decoding failures for this document
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            // Preserve original order of IDs
            let orderedCourses = ids.compactMap { results[$0] }
            completion(orderedCourses)
        }
    }
    
    func fetchCourseByName(_ name: String, completion: @escaping (Course?) -> Void) {
        db.collection(collectionName)
            .whereField("name", isEqualTo: name)
            .limit(to: 1)   // just in case multiple exist
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(nil)
                    return
                }
                
                Task { @MainActor in
                    do {
                        let course = try document.data(as: Course.self)
                        completion(course)
                    } catch {
                        print("❌ Firestore decoding error: \(error)")
                        completion(nil)
                    }
                }
            }
    }
    
    func courseNameExistsAndSupported(_ name: String, completion: @escaping (Bool) -> Void) {
        db.collection(collectionName)
            .whereField("name", isEqualTo: name)
            .whereField("isSupported", isEqualTo: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let exists = snapshot?.documents.isEmpty == false
                completion(exists)
            }
    }
    

    func createCourseWithMapItem(courseID: String, location: MapItemDTO, completion: @escaping (Course?) -> Void) {
        let ref = db.collection(collectionName).document(courseID)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error)")
                completion(nil)
                return
            }
            
            // Create new course
            let newCourse = Course(
                id: courseID,
                name: location.name ?? "N/A",
                password: PasswordGenerator.generate(.strong()),
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            Task { @MainActor in
                do {
                    try ref.setData(from: newCourse)
                    print("Created new course: \(courseID)")
                    completion(newCourse)
                } catch {
                    print("❌ Firestore write error: \(error)")
                    completion(nil)
                }
            }
        }
    }

    
    
    func findCourseIDWithPassword(withPassword password: String, completion: @escaping (String?) -> Void) {
        db.collection(collectionName)
            .whereField("password", isEqualTo: password)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let doc = snapshot?.documents.first else {
                    completion(nil)   // No course has this password
                    return
                }
                
                completion(doc.documentID)
            }
    }
    
    func fetchCourseIDs(prefix: String, completion: @escaping ([SmallCourse]) -> Void) {
        let end = prefix + "\u{f8ff}"
        db.collection(collectionName)
            .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: prefix)
            .whereField(FieldPath.documentID(), isLessThanOrEqualTo: end)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let courses: [SmallCourse] = docs.map { doc in
                    let name = doc["name"] as? String ?? "Unnamed"
                    return SmallCourse(id: doc.documentID, name: name)
                }
                
                completion(courses)
            }
    }
    
    // MARK: Email
    func removeEmail(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)
        let key = emailKey(email)
        
        // No transaction needed with map structure
        ref.updateData([
            "emails.\(key)": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("❌ Failed to remove email: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func emailKey(_ email: String) -> String {
        email
            .lowercased()
            .replacingOccurrences(of: ".", with: ",")
    }
    
    
    // MARK: Admin Id
    func addAdminIDtoCourse(adminID: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)
        
        ref.updateData([
            "adminIDs": FieldValue.arrayUnion([adminID]),
            "isClaimed": true  // Update computed stored property
        ]) { error in
            if let error = error {
                print("❌ Failed to add email: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func removeAdminIDfromCourse(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)
        
        // First remove the admin ID
        ref.updateData([
            "adminIDs": FieldValue.arrayRemove([email])
        ]) { error in
            if error != nil {
                completion(false)
                return
            }
            
            // Then check if adminIDs is now empty and update isClaimed
            ref.getDocument { snapshot, fetchError in
                guard let data = snapshot?.data(), fetchError == nil else {
                    completion(false)
                    return
                }
                
                let adminIDs = data["adminIDs"] as? [String] ?? []
                let isClaimed = !adminIDs.isEmpty
                
                ref.updateData(["isClaimed": isClaimed]) { updateError in
                    completion(updateError == nil)
                }
            }
        }
    }
    
    
    func keepOnlyAdminID(id: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection(collectionName).document(courseID)
        
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                completion(false)
                return
            }
            
            // Get current adminIDs array
            let adminIDs = data["adminIDs"] as? [String] ?? []
            
            // Keep only the one you want
            let updatedAdminIDs = adminIDs.contains(id) ? [id] : []
            
            // Update the document
            docRef.updateData([
                "adminIDs": updatedAdminIDs,
                "isClaimed": !updatedAdminIDs.isEmpty  // Update computed stored property
            ]) { error in
                completion(error == nil)
            }
        }
    }
    
    func uploadCourseImages(id: String, imageData: Data, key: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let ref = Storage.storage()
            .reference()
            .child(id)
            .child("\(key).png")
        
        ref.putData(imageData, metadata: nil) { meta, error in
            if let error = error {
                return completion(.failure(error))
            }
            ref.downloadURL { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let url):
                    completion(.success(url))
                }
            }
        }
    }
}
