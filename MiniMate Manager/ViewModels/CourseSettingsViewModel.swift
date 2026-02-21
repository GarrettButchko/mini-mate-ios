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
