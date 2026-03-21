//
//  MapItemDTO+MapKit.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//

import MapKit
import Contacts

extension MKMapItem {
    
    
    var idString: String {
        if #available(iOS 26.0, *) {
            "\(location.coordinate.latitude)-\(location.coordinate.longitude)-\(name ?? "")"
        } else {
            "\(placemark.coordinate.latitude)-\(placemark.coordinate.longitude)-\(name ?? "")"
        }
    }
    
    var newAddress: AddressDTO? {
        if #available(iOS 26.0, *), let address = self.address {
            return AddressDTO(fullAddress: address.fullAddress, shortAddress: address.shortAddress)
        } else if #unavailable(iOS 26.0) {
            if let postalAddress = placemark.postalAddress {
                let street: String = postalAddress.street
                let city: String = postalAddress.city
                let state: String = postalAddress.state
                let postalCode: String = postalAddress.postalCode
                let country: String = postalAddress.country
                
                
                let longAddress: String =
                """
                \(street)
                \(city), \(state) \(postalCode)
                \(country)
                """
                
                let shortAddress: String = "\(street), \(city)"
                
                return AddressDTO(fullAddress: longAddress, shortAddress: shortAddress)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func toDTO() -> MapItemDTO {
        
        if #available(iOS 26.0, *) {
            return MapItemDTO(
                name: self.name,
                phoneNumber: self.phoneNumber,
                url: self.url?.absoluteString,
                address: newAddress,
                coordinate: CoordinateDTO(latitude: self.location.coordinate.latitude, longitude: self.location.coordinate.longitude)
            )
        } else {
            return MapItemDTO(
                name: self.name,
                phoneNumber: self.phoneNumber,
                url: self.url?.absoluteString,
                address: newAddress,
                coordinate: CoordinateDTO(latitude: self.placemark.coordinate.latitude, longitude: self.placemark.coordinate.longitude)
            )
        }
    }
    
    func toCourse(isSupported: Bool = false) -> Course {
        Course(
            id: CourseIDGenerator.generateCourseID(from: self.toDTO()),
            name: self.name!,
            password: PasswordGenerator.generate(.strong()),
            latitude: self.placemark.coordinate.latitude,
            longitude: self.placemark.coordinate.longitude,
            isSupported: isSupported
        )
    }
}
