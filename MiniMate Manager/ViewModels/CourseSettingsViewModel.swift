//
//  CourseSettingsViewModel.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 2/16/26.
//

import SwiftUI
import Combine

enum ColorAddTarget {
    case scoreCardColor
    case courseColor
}

enum ColorDeleteTarget: Identifiable {
    case scoreCardColor
    case courseColor(index: Int)
    
    var id: Int {
        switch self {
        case .scoreCardColor: return -1
        case .courseColor(let i): return i
        }
    }
}

@MainActor
class CourseSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var editCourse: Bool = false
    @Published var showingPickerLogo: Bool = false
    @Published var showingPickerAd: Bool = false
    @Published var showReviewSheet: Bool = false
    @Published var image: UIImage? = nil
    @Published var deleteTarget: ColorDeleteTarget? = nil
    
    // Password related
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var showNewPassword = false
    @Published var showPassword: Bool = false
    @Published var showChangePasswordAlert: Bool = false
    
    // MARK: - Dependencies
    private let courseRepo = CourseRepository()
    private var saveWorkItem: DispatchWorkItem?
    
    // MARK: - Computed Properties
    var isValidPassword: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    // MARK: - Save Methods
    
    func debouncedSave(course: Course, delay: TimeInterval = 0.5) {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.courseRepo.addOrUpdateCourse(course) { _ in }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    func immediateSave(course: Course) {
        saveWorkItem?.cancel()
        courseRepo.addOrUpdateCourse(course) { _ in }
    }
    
    // MARK: - Binding Helpers
    
    func binding<T>(
        for course: Binding<Course?>,
        keyPath: WritableKeyPath<Course, T>,
        onSet: @escaping (T) -> Void = { _ in },
        debounce: Bool = false
    ) -> Binding<T>? {
        guard course.wrappedValue != nil else { return nil }
        return Binding(
            get: {
                guard let value = course.wrappedValue else {
                    fatalError("Course became nil unexpectedly")
                }
                return value[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                guard var updatedCourse = course.wrappedValue else { return }
                updatedCourse[keyPath: keyPath] = newValue
                course.wrappedValue = updatedCourse
                onSet(newValue)
                if debounce {
                    self?.debouncedSave(course: updatedCourse)
                } else {
                    self?.immediateSave(course: updatedCourse)
                }
            }
        )
    }
    
    func optionalBinding(
        for course: Binding<Course?>,
        keyPath: WritableKeyPath<Course, String?>,
        deleteKey: String,
        debounce: Bool = true
    ) -> Binding<String> {
        Binding(
            get: {
                course.wrappedValue?[keyPath: keyPath] ?? ""
            },
            set: { [weak self] newValue in
                guard var updatedCourse = course.wrappedValue else { return }
                
                updatedCourse[keyPath: keyPath] = newValue.isEmpty ? nil : newValue
                course.wrappedValue = updatedCourse
                
                if newValue.isEmpty {
                    self?.courseRepo.deleteCourseItem(courseID: updatedCourse.id, dataName: deleteKey)
                } else {
                    if debounce {
                        self?.debouncedSave(course: updatedCourse)
                    } else {
                        self?.immediateSave(course: updatedCourse)
                    }
                }
            }
        )
    }
    
    func limitedTextBinding(
        for course: Binding<Course?>,
        keyPath: WritableKeyPath<Course, String?>,
        deleteKey: String,
        limit: Int,
        debounce: Bool = true
    ) -> Binding<String> {
        Binding(
            get: {
                course.wrappedValue?[keyPath: keyPath] ?? ""
            },
            set: { [weak self] newValue in
                guard var updatedCourse = course.wrappedValue else { return }
                let limited = String(newValue.prefix(limit))
                updatedCourse[keyPath: keyPath] = limited.isEmpty ? nil : limited
                course.wrappedValue = updatedCourse
                
                if limited.isEmpty {
                    self?.courseRepo.deleteCourseItem(courseID: updatedCourse.id, dataName: deleteKey)
                } else {
                    if debounce {
                        self?.debouncedSave(course: updatedCourse)
                    } else {
                        self?.immediateSave(course: updatedCourse)
                    }
                }
            }
        )
    }
    
    func customParBinding(for course: Binding<Course?>) -> Binding<Bool> {
        Binding(
            get: { course.wrappedValue?.customPar ?? false },
            set: { [weak self] newValue in
                guard var updatedCourse = course.wrappedValue else { return }
                updatedCourse.customPar = newValue
                if newValue {
                    updatedCourse.numHoles = 18
                    updatedCourse.pars = Array(repeating: 2, count: 18)
                } else {
                    updatedCourse.numHoles = 18
                    updatedCourse.pars = []
                }
                course.wrappedValue = updatedCourse
                self?.immediateSave(course: updatedCourse)
            }
        )
    }
    
    func numHolesBinding(for course: Binding<Course?>) -> Binding<Int> {
        Binding(
            get: { course.wrappedValue?.numHoles ?? 18 },
            set: { [weak self] newValue in
                guard var updatedCourse = course.wrappedValue else { return }
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
                    course.wrappedValue = updatedCourse
                }
                self?.immediateSave(course: updatedCourse)
            }
        )
    }
    
    func parBinding(for course: Binding<Course?>, index: Int) -> Binding<Int> {
        Binding(
            get: {
                guard let courseValue = course.wrappedValue,
                      index < courseValue.pars.count else { return 2 }
                return courseValue.pars[index]
            },
            set: { [weak self] newValue in
                guard var updatedCourse = course.wrappedValue,
                      index < updatedCourse.pars.count else { return }
                updatedCourse.pars[index] = newValue
                course.wrappedValue = updatedCourse
                self?.debouncedSave(course: updatedCourse, delay: 0.3)
            }
        )
    }
    
    // MARK: - Image Upload
    
    func uploadLogoImage(_ image: UIImage, course: Binding<Course?>) {
        guard var updatedCourse = course.wrappedValue else { return }
        
        courseRepo.uploadCourseImages(id: updatedCourse.id, image, key: "logoImage") { [weak self] result in
            switch result {
            case .success(let url):
                updatedCourse.logo = url.absoluteString
                course.wrappedValue = updatedCourse
                self?.courseRepo.addOrUpdateCourse(updatedCourse) { _ in }
            case .failure(let error):
                print("❌ Photo upload failed:", error)
            }
        }
    }
    
    func uploadAdImage(_ image: UIImage, course: Binding<Course?>) {
        guard var updatedCourse = course.wrappedValue else { return }
        
        courseRepo.uploadCourseImages(id: updatedCourse.id, image, key: "adImage") { [weak self] result in
            switch result {
            case .success(let url):
                updatedCourse.adImage = url.absoluteString
                course.wrappedValue = updatedCourse
                self?.courseRepo.addOrUpdateCourse(updatedCourse) { _ in }
            case .failure(let error):
                print("❌ Photo upload failed:", error)
            }
        }
    }
    
    // MARK: - Password Change
    
    func changePassword(course: Binding<Course?>, userID: String?) {
        guard isValidPassword,
              var updatedCourse = course.wrappedValue else { return }
        
        updatedCourse.password = newPassword
        course.wrappedValue = updatedCourse
        
        courseRepo.addOrUpdateCourse(updatedCourse) { [weak self] complete in
            if complete {
                if let userID = userID {
                    self?.courseRepo.keepOnlyAdminID(id: userID, courseID: updatedCourse.id) { _ in }
                }
            }
        }
        
        resetPasswordFields()
    }
    
    func resetPasswordFields() {
        newPassword = ""
        confirmPassword = ""
        showNewPassword = false
        showChangePasswordAlert = false
    }
    
    // MARK: - Color Deletion
    
    func deleteColor(target: ColorDeleteTarget, course: Binding<Course?>) {
        guard var updatedCourse = course.wrappedValue else { return }
        
        switch target {
        case .scoreCardColor:
            withAnimation {
                updatedCourse.scoreCardColorDT = nil
                course.wrappedValue = updatedCourse
            }
            
            courseRepo.deleteCourseItem(
                courseID: updatedCourse.id,
                dataName: "scoreCardColorDT"
            )
            
        case .courseColor(let index):
            var colors = updatedCourse.courseColorsDT ?? []
            guard colors.indices.contains(index) else { return }
            
            colors.remove(at: index)
            
            withAnimation {
                updatedCourse.courseColorsDT = colors
                course.wrappedValue = updatedCourse
            }
            
            if colors.isEmpty {
                courseRepo.deleteCourseItem(
                    courseID: updatedCourse.id,
                    dataName: "courseColorsDT"
                )
            } else {
                courseRepo.setCourseItem(
                    courseID: updatedCourse.id,
                    dataName: "courseColorsDT",
                    object: colors
                )
            }
        }
    }
    
    // MARK: - Utility
    
    func stringToColor(_ string: String) -> Color {
        switch string.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        default:
            return .clear
        }
    }
}
