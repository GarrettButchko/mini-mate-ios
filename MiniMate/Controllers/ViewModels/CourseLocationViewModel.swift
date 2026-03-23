//
//  CourseLocationViewModel.swift
//  MiniMate
//
//  Created by Your Name on 2/28/25.
//

import SwiftUI
import MapKit
import Combine



@MainActor
class CourseLocationViewModel: ObservableObject {
    // MARK: - Published State for the View
    @Published private(set) var courseName: String = ""
    @Published private(set) var postalAddress: String = ""
    @Published private(set) var phoneNumber: String?
    @Published private(set) var phoneNumberURL: URL?
    @Published private(set) var websiteURL: URL?
    @Published private(set) var course: Course?
    
    @Published private(set) var isLoading: Bool = false
    
    private var lookAroundTask: Task<Void, Never>?

    // MARK: - Dependencies
    private let locationHandler: LocationHandler
    let courseViewModel: CourseViewModel
    private let courseRepository: CourseRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        locationHandler: LocationHandler,
        courseViewModel: CourseViewModel,
        courseRepository: CourseRepository = CourseRepository()
    ) {
        self.locationHandler = locationHandler
        self.courseViewModel = courseViewModel
        self.courseRepository = courseRepository
        
        // Subscribe to changes in the selected map item
        locationHandler.$selectedItem
            .removeDuplicates()
            .sink { [weak self] mapItem in
                self?.updateState(for: mapItem)
            }
            .store(in: &cancellables)
    }

    // MARK: - Business/Presentation Logic (Candidates for KMP)
    
    var isCourseSupported: Bool {
        course?.isSupported ?? false
    }
    
    var socialLinks: [SocialLink] {
        course?.socialLinks ?? []
    }
    
    // MARK: - User Intent Handlers (Called by the View)
    
    func getDirections() {
        // This is a platform-specific action (opens Apple Maps)
        courseViewModel.getDirections(locationHandler: locationHandler)
    }

    func close() {
        // This is a platform-specific action (interacts with another view model)
        withAnimation {
            locationHandler.setSelectedItem(nil)
        }
    }
    
    func claimCourse() {
        print("Claim course button tapped.")
    }
    
    // MARK: - Private Logic
    
    private func updateState(for mapItem: MKMapItem?) {
        guard let mapItem = mapItem, let name = mapItem.name else {
            clearState()
            return
        }

        // --- Presentation Logic: Data Transformation ---
        // This logic transforms raw model data into display-ready properties.
        // It's a good candidate for moving to a shared KMP presenter/viewmodel.
        courseName = name
        postalAddress = locationHandler.getPostalAddress(from: mapItem)
        phoneNumber = mapItem.phoneNumber
        if let phone = mapItem.phoneNumber {
            phoneNumberURL = URL(string: "tel://\(phone.filter { $0.isNumber })")
        } else {
            phoneNumberURL = nil
        }
        websiteURL = mapItem.url
    
        self.course = nil

        isLoading = true
    }
    
    private func clearState() {
        courseName = ""
        postalAddress = ""
        phoneNumber = nil
        phoneNumberURL = nil
        websiteURL = nil
        course = nil
    }
}
