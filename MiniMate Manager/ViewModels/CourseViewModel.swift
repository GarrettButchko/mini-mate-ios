//
//  CourseListViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth

@MainActor
final class CourseViewModel: ObservableObject {

    @Published var password: String = ""
    @Published var message: String? = nil
    @Published var showAddCourseAlert: Bool = false
    
    @Published var loadingCourse: Bool = false
    
    private var authModel: AuthViewModel?
    @Published var userCourses: [Course] = []
    private let courseRepo = CourseRepository()
    private let userRepo = UserRepository()
    
    @Published var selectedCourse: Course? = nil
    
    @Published var timeRemaining: TimeInterval = 0
    @Published var failedAttempts: Int = 0
    
    @Published var addTarget: ColorAddTarget? = nil
    @Published var showColor: Bool = false
    
    let failedLimit: Int = 5
    private let ttl: TimeInterval = 30
    private var lastUpdated = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var hasCourse: Bool {
        if let adminCourses = authModel?.userModel?.adminCourses, !adminCourses.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    var blockAddingCourse: Bool {
        return (failedAttempts >= failedLimit)
    }
    
    func tick() {
        guard timeRemaining > 0 else { return }

        let expire = lastUpdated.addingTimeInterval(ttl)
        timeRemaining = max(0, expire.timeIntervalSinceNow)

        if timeRemaining == 0 {
            withAnimation(){
                message = nil
                failedAttempts = 0
            }
        }
    }

    func startTimer() {
        guard timeRemaining == 0 else { return } // ⬅️ critical
        lastUpdated = Date()
        timeRemaining = ttl
    }

    
    func bind(authModel: AuthViewModel) {
        self.authModel = authModel
    }
    
    func setCourse(course: Course?) {
        self.selectedCourse = course
    }
    
    func getCourses() {
        loadingCourse = true
        guard hasCourse, let ids = authModel?.userModel?.adminCourses else {
            loadingCourse = false
            return
        }

        courseRepo.fetchCourses(ids: ids) { courses in
            Task { @MainActor in
                withAnimation {
                    self.userCourses = courses
                    self.loadingCourse = false
                }
            }
        }
    }

    func getCourse(completion: @escaping () -> Void){
        loadingCourse = true
        guard hasCourse,
              let firstCourseID = authModel?.userModel?.adminCourses.first else {
            loadingCourse = false
            completion()
            return
        }
        
        courseRepo.fetchCourse(id: firstCourseID) { course in
            if let course = course{
                withAnimation(){
                    self.userCourses.append(course)
                }
                self.selectedCourse = course
                self.loadingCourse = false
                completion()
            } else {
                self.loadingCourse = false
                completion()
            }
        }
    }
    
    func tryPassword(completion: @escaping (Bool) -> Void) {
        courseRepo.findCourseIDWithPassword(withPassword: password) { [self] courseID in
            Task { @MainActor in
                if let courseID, self.authModel != nil {
                    // Update model on main thread
                    
                    if self.authModel!.userModel?.adminCourses.contains(courseID) == true {
                        withAnimation(){
                            self.message = "Course Already Added"
                        }
                        completion(false)
                    } else {
                        // Add course to user's admin courses
                        self.authModel?.userModel?.adminCourses.append(courseID)
                        self.userRepo.saveRemote(id: authModel!.currentUserIdentifier!, userModel: authModel!.userModel!) { _ in }
                        
                        // Claim the course and add email to adminIDs
                        if let email = authModel!.firebaseUser?.email {
                            self.courseRepo.addAdminIDtoCourse(adminID: email, courseID: courseID) { success in
                                if success {
                                    print("✅ Course claimed and email added to adminIDs")
                                } else {
                                    print("❌ Failed to add email to course adminIDs")
                                }
                            }
                        }
                        
                        self.getCourses()
                        self.message = nil
                        completion(true)
                    }
                    
                } else {
                    self.failedAttempts += 1
                    
                    if self.failedAttempts < self.failedLimit {
                        withAnimation(){
                            self.message = "Unsuccessful attempt. Please try again."
                        }
                    } else {
                        withAnimation(){
                            self.message = "Too many attempts"
                            self.startTimer()
                        }
                    }
                    completion(false)
                }
            }
        }
    }
    
    func start() {
        if let course = selectedCourse {
            courseRepo.listenToCourse(id: course.id) { [weak self] newCourse in
                guard let self else { return }

                if self.selectedCourse != newCourse {
                    self.selectedCourse = newCourse
                }
            }
        }
    }

    func stop() {
            // tiny delay prevents teardown race
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.courseRepo.stopListening()
        }
    }
}
