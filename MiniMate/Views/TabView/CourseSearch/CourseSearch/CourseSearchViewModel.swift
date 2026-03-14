//
//  CourseSearchViewModel.swift
//  MiniMate
//
//  Created by Your Name on 2/28/25.
//

import SwiftUI
import MapKit
import Combine

@MainActor
class CourseSearchViewModel: ObservableObject {
    // MARK: - Dependencies
    private let locationHandler: LocationHandler
    private let courseViewModel: CourseViewModel

    // MARK: - Published State for the View
    @Published var mapCameraPosition: MapCameraPosition = .automatic
    @Published var selectedMapItem: MKMapItem?
    @Published var mapItems: [MKMapItem] = []
    @Published var nameExists: [String: Bool] = [:]
    @Published var isSearchPanelVisible: Bool = false
    @Published var hasLocationAccess: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(locationHandler: LocationHandler, courseViewModel: CourseViewModel) {
        self.locationHandler = locationHandler
        self.courseViewModel = courseViewModel
        setupSubscriptions()
    }
    
    /// Sets up Combine pipelines to keep the ViewModel's state in sync with its dependencies.
    private func setupSubscriptions() {
        // --- Sync from LocationHandler to this ViewModel ---
        
        locationHandler.$mapItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.mapItems = items
                // Business logic is now triggered from the ViewModel
                self?.courseViewModel.preloadNameChecks(for: items)
            }
            .store(in: &cancellables)

        locationHandler.$hasLocationAccess
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasLocationAccess)
            
        // --- Sync from the original CourseViewModel to this ViewModel ---
        
        courseViewModel.$isUpperHalf
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSearchPanelVisible)

        courseViewModel.$position
            .receive(on: DispatchQueue.main)
            .assign(to: &$mapCameraPosition)
            
        courseViewModel.$nameExists
            .receive(on: DispatchQueue.main)
            .assign(to: &$nameExists)
            
        // --- Two-way binding for map item selection ---

        // When the View updates `selectedMapItem`...
        $selectedMapItem
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main) // Prevent rapid updates
            .sink { [weak self] item in
                // ...update the original models so subviews see the change.
                self?.locationHandler.setSelectedItem(item)
                self?.courseViewModel.setPosition(self?.locationHandler.updateCameraPosition(item) ?? .automatic)
            }
            .store(in: &cancellables)
            
        // When the original `locationHandler` updates its selected item...
        locationHandler.$selectedItem
            .receive(on: DispatchQueue.main)
            //...update this ViewModel's state to keep the UI in sync.
            .assign(to: &$selectedMapItem)
    }

    // MARK: - User Intent Handlers
    
    /// Called when the view appears to set up its initial state.
    func onAppear() {
        courseViewModel.onAppearance(locationHandler: locationHandler)
    }

    /// Recalculates the camera position to focus on the user or selected item.
    func recenterMap() {
        let newPosition = locationHandler.updateCameraPosition(selectedMapItem)
        withAnimation {
            courseViewModel.setPosition(newPosition)
        }
    }
}
