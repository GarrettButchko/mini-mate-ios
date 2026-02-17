//
//  CourseViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/6/25.
//

import MapKit
import SwiftUI

@MainActor
final class CourseViewModel: ObservableObject {

    @Published var nameExists: [String: Bool] = [:]
    @Published var position: MapCameraPosition = .automatic
    @Published var isUpperHalf: Bool = false
    @Published var hasAppeared = false
    @Published var isLoadingCourses = false
    
    @Published var selectedCourse: Course? = nil
    
    private let courseRepo: CourseRepository

    init(courseRepo: CourseRepository = CourseRepository()) {
        self.courseRepo = courseRepo
    }
    
    func getCourse(name: String) {
        courseRepo.fetchCourseByName(name) { [weak self] course in
            Task { @MainActor in
                self?.selectedCourse = course
            }
        }
    }

    // MARK: - Marker Coloring
    func preloadNameChecks(for items: [MKMapItem]) {
        for item in items {
            guard
                let name = item.name,
                nameExists[name] == nil
            else { continue }

            courseRepo.courseNameExistsAndSupported(name) { [weak self] exists in
                self?.nameExists[name] = exists
            }
        }
    }
    
    func onAppearance(locationHandler: LocationHandler) {
        if !hasAppeared {
            hasAppeared = true
            isUpperHalf = false
            locationHandler.mapItems = []
            locationHandler.selectedItem = nil
            position = locationHandler.updateCameraPosition()
        }
    }
    
    func setPosition(_ position: MapCameraPosition) {
        self.position = position
    }
    
    func searchNearby(locationHandler: LocationHandler){
        
        isLoadingCourses = true
        
        withAnimation {
            isUpperHalf = true
            
            locationHandler.searchNearbyCourses { success, newPosition in
                if let newPosition {
                    withAnimation {
                        self.position = newPosition
                    }
                }
                self.isLoadingCourses = !success
            }
        }
    }
    
    func cancel(locationHandler: LocationHandler){
        withAnimation {
            isUpperHalf = false
            locationHandler.mapItems = []
            self.position = locationHandler.updateCameraPosition()
        }
    }
    
    func updatePosition(mapItem: MKMapItem, locationHandler: LocationHandler) {
        withAnimation(){
            locationHandler.setSelectedItem(mapItem)
            position = locationHandler.updateCameraPosition(locationHandler.bindingForSelectedItem().wrappedValue)
        }
    }
    
    func getDirections(locationHandler: LocationHandler){
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        locationHandler.bindingForSelectedItem().wrappedValue?.openInMaps(launchOptions: launchOptions)
    }
    
    func getPostalAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
        var components: [String] = []
        
        if let subThoroughfare = placemark.subThoroughfare { components.append(subThoroughfare) }
        if let thoroughfare = placemark.thoroughfare { components.append(thoroughfare) }
        if let locality = placemark.locality { components.append(locality) }
        if let administrativeArea = placemark.administrativeArea { components.append(administrativeArea) }
        
        return components.joined(separator: ", ")
    }
}
