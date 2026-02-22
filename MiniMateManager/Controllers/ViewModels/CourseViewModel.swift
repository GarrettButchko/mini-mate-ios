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
    
    // MARK: - Dependencies
    private var saveWorkItem: DispatchWorkItem?
    
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
    
    // MARK: - Save Methods
    
    func debouncedSave(delay: TimeInterval = 0.5) {
        guard let course = selectedCourse else { return }
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.courseRepo.addOrUpdateCourse(course) { _ in }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    func immediateSave() {
        guard let course = selectedCourse else { return }
        saveWorkItem?.cancel()
        courseRepo.addOrUpdateCourse(course) { _ in }
    }
    
    // MARK: - Binding Helpers
    
    func binding<T>(
        keyPath: WritableKeyPath<Course, T>,
        onSet: @escaping (T) -> Void = { _ in },
        debounce: Bool = false
    ) -> Binding<T>? {
        guard selectedCourse != nil else { return nil }
        return Binding(
            get: {
                guard let value = self.selectedCourse else {
                    fatalError("Course became nil unexpectedly")
                }
                return value[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                guard var updatedCourse = self?.selectedCourse else { return }
                updatedCourse[keyPath: keyPath] = newValue
                self?.selectedCourse = updatedCourse
                onSet(newValue)
                if debounce {
                    self?.debouncedSave()
                } else {
                    self?.immediateSave()
                }
            }
        )
    }
    
    func optionalBinding(
        keyPath: WritableKeyPath<Course, String?>,
        deleteKey: String,
        debounce: Bool = true
    ) -> Binding<String> {
        Binding(
            get: {
                self.selectedCourse?[keyPath: keyPath] ?? ""
            },
            set: { [weak self] newValue in
                guard var updatedCourse = self?.selectedCourse else { return }
                
                updatedCourse[keyPath: keyPath] = newValue.isEmpty ? nil : newValue
                self?.selectedCourse = updatedCourse
                
                if newValue.isEmpty {
                    self?.courseRepo.deleteCourseItem(courseID: updatedCourse.id, dataName: deleteKey)
                } else {
                    if debounce {
                        self?.debouncedSave()
                    } else {
                        self?.immediateSave()
                    }
                }
            }
        )
    }
    
    func socialPlatformBinding(
        index: Int,
        debounce: Bool = false
    ) -> Binding<SocialPlatform> {
        Binding(
            get: {
                guard let courseValue = self.selectedCourse,
                      index < courseValue.socialLinks.count else {
                    return .instagram
                }
                return courseValue.socialLinks[index].platform
            },
            set: { [weak self] newValue in
                guard var updatedCourse = self?.selectedCourse,
                      index < updatedCourse.socialLinks.count else { return }
                
                updatedCourse.socialLinks[index].platform = newValue
                self?.selectedCourse = updatedCourse
                
                if debounce {
                    self?.debouncedSave()
                } else {
                    self?.immediateSave()
                }
            }
        )
    }
    
    
    func limitedTextBinding(
        keyPath: WritableKeyPath<Course, String?>,
        deleteKey: String,
        limit: Int,
        debounce: Bool = true
    ) -> Binding<String> {
        Binding(
            get: {
                self.selectedCourse?[keyPath: keyPath] ?? ""
            },
            set: { [weak self] newValue in
                guard var updatedCourse = self?.selectedCourse else { return }
                let limited = String(newValue.prefix(limit))
                updatedCourse[keyPath: keyPath] = limited.isEmpty ? nil : limited
                self?.selectedCourse = updatedCourse
                
                if limited.isEmpty {
                    self?.courseRepo.deleteCourseItem(courseID: updatedCourse.id, dataName: deleteKey)
                } else {
                    if debounce {
                        self?.debouncedSave()
                    } else {
                        self?.immediateSave()
                    }
                }
            }
        )
    }
    
    func customParBinding() -> Binding<Bool> {
        Binding(
            get: { self.selectedCourse?.customPar ?? false },
            set: { [weak self] newValue in
                guard var updatedCourse = self?.selectedCourse else { return }
                updatedCourse.customPar = newValue
                if newValue {
                    updatedCourse.numHoles = 18
                    updatedCourse.pars = Array(repeating: 2, count: 18)
                } else {
                    updatedCourse.numHoles = 18
                    updatedCourse.pars = []
                }
                self?.selectedCourse = updatedCourse
                self?.immediateSave()
            }
        )
    }
    
    func numHolesBinding() -> Binding<Int> {
        Binding(
            get: { self.selectedCourse?.numHoles ?? 18 },
            set: { [weak self] newValue in
                guard var updatedCourse = self?.selectedCourse else { return }
                withAnimation {
                    updatedCourse.numHoles = newValue
                    
                    var pars = updatedCourse.pars
                    if newValue > pars.count {
                        let difference = newValue - pars.count
                        pars.append(contentsOf: Array(repeating: 2, count: difference))
                    } else if newValue < pars.count {
                        pars = Array(pars.prefix(newValue))
                    }
                    updatedCourse.pars = pars
                    self?.selectedCourse = updatedCourse
                }
                self?.immediateSave()
            }
        )
    }
    
    func parBinding(index: Int) -> Binding<Int> {
        Binding(
            get: {
                guard let courseValue = self.selectedCourse,
                      index < courseValue.pars.count else { return 2 }
                return courseValue.pars[index]
            },
            set: { [weak self] newValue in
                guard var updatedCourse = self?.selectedCourse,
                      index < updatedCourse.pars.count else { return }
                updatedCourse.pars[index] = newValue
                self?.selectedCourse = updatedCourse
                self?.debouncedSave(delay: 0.3)
            }
        )
    }
}
