//
//  CourseLocationViewModel.swift
//  MiniMate
//
//  Created by Your Name on 2/28/25.
//

import SwiftUI
import MapKit
import Combine

/// An enum representing the state of the Look Around feature.
/// This is platform-agnostic and could be part of a shared KMP module.
enum LookAroundState: Equatable {
    case idle
    case loading
    case available
    case unavailable
    case error(String)
}

@MainActor
class CourseLocationViewModel: ObservableObject {
    // MARK: - Published State for the View
    @Published private(set) var courseName: String = ""
    @Published private(set) var postalAddress: String = ""
    @Published private(set) var phoneNumber: String?
    @Published private(set) var phoneNumberURL: URL?
    @Published private(set) var websiteURL: URL?
    @Published private(set) var course: Course?
    
    @Published private(set) var lookAroundScene: MKLookAroundScene?
    @Published private(set) var lookAroundState: LookAroundState = .idle
    
    @Published private(set) var isLoading: Bool = false

    // MARK: - Dependencies
    private let locationHandler: LocationHandler
    private let courseViewModel: CourseViewModel
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
        // This would eventually open a URL, a platform-specific action
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
        
        // Immediately clear the old course data to prevent showing stale information
        // while the new data is being fetched.
        self.course = nil

        
        isLoading = true
        // --- Asynchronous Data Fetching ---
        // Fetch course details by name to ensure data is in sync.
        // This avoids the race condition of relying on another view model.
        courseRepository.fetchCourseByName(name) { [weak self] fetchedCourse in
            self?.course = fetchedCourse
            self?.isLoading = false
        }

        // --- Platform-Specific Action ---
        // This triggers a platform-native API call.
        fetchLookAroundScene(for: mapItem)
    }
    
    func fetchCourse() {
        guard let mapItem = locationHandler.selectedItem, let name = mapItem.name else {
            clearState()
            return
        }
        
        isLoading = true
        // --- Asynchronous Data Fetching ---
        // Fetch course details by name to ensure data is in sync.
        // This avoids the race condition of relying on another view model.
        courseRepository.fetchCourseByName(name) { [weak self] fetchedCourse in
            self?.course = fetchedCourse
            self?.isLoading = false
        }
    }
    
    private func clearState() {
        courseName = ""
        postalAddress = ""
        phoneNumber = nil
        phoneNumberURL = nil
        websiteURL = nil
        course = nil
        lookAroundScene = nil
        lookAroundState = .idle
    }
    
    // MARK: - Private Platform-Specific Implementation
    
    private func fetchLookAroundScene(for mapItem: MKMapItem) {
        self.lookAroundState = .loading
        self.lookAroundScene = nil
        
        let request = MKLookAroundSceneRequest(mapItem: mapItem)

        Task {
            do {
                let sceneResult = try await request.scene
                if let sceneResult {
                    self.lookAroundScene = sceneResult
                    self.lookAroundState = .available
                } else {
                    self.lookAroundState = .unavailable
                }
            } catch {
                self.lookAroundState = .error(error.localizedDescription)
            }
        }
    }
}
