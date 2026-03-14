//
//  CourseDetailCards.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/27/25.
//

import SwiftUI
import MapKit
import MarqueeText

// MARK: - Result View Header
struct CourseResultViewHeader: View {
    @EnvironmentObject var locationHandler: LocationHandler
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button {
                withAnimation {
                    locationHandler.setSelectedItem(nil)
                }
            } label: {
                Image(systemName: "arrow.left")
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue)
                    }
                    .foregroundStyle(.white)
            }
            
            MarqueeText(
                text: locationHandler.selectedItem?.name ?? "",
                font: UIFont.preferredFont(forTextStyle: .title3),
                leftFade: 16,
                rightFade: 16,
                startDelay: 2,
                alignment: .center
            )
            .foregroundStyle(.mainOpp)
            .font(.title3).fontWeight(.bold)
            .padding(.horizontal)
            
            Image(systemName: "arrow.left")
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.blue)
                }
                .opacity(0.0)
        }
    }
}

// MARK: - Directions Button
struct CourseDirectionsButton: View {
    @EnvironmentObject var courseViewModel: CourseViewModel
    @EnvironmentObject var locationHandler: LocationHandler
    
    var body: some View {
        Button(action: {
            courseViewModel.getDirections(locationHandler: locationHandler)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue)
                VStack {
                    Image(systemName: "arrow.turn.up.right")
                        .foregroundColor(.white)
                    Text("Get Directions")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                .padding()
            }
        }
    }
}

// MARK: - Supported Location Card
struct CourseSupportedLocationCard: View {
    let course: Course
    let locationName: String?
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image("logo_svg")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.mainOpp)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Supported Location")
                    .font(.headline)
                
                if let name = locationName {
                    Text("\(name) has official MiniMate data (par + more).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(.sub.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.5), lineWidth: 2)
        )
        .cardShadow()
    }
}

// MARK: - Social Media Card
struct CourseSocialMediaCard: View {
    let course: Course
    
    var body: some View {
        socialMediaContent
    }
    
    private var socialMediaContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                Text("Social Media")
                    .font(.headline)
            }
            
            socialLinksScrollView
        }
        .padding()
        .background(backgroundShape)
    }
    
    private var socialLinksScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ForEach(course.socialLinks) { link in
                socialLinkButton(for: link)
            }
        }
    }
    
    private func socialLinkButton(for link: SocialLink) -> some View {
        Link(destination: URL(string: link.url) ?? URL(string: "https://apple.com")!) {
            HStack(spacing: 8) {
                Text(link.platform.rawValue.capitalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                link.platformImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.subTwo)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.sub)
            .cardShadow()
    }
}

// MARK: - Contact Info Card
struct CourseContactInfoCard: View {
    let selectedItem: MKMapItem?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                    Text("Contact")
                        .font(.headline)
                }
                
                if let selected = selectedItem {
                    if let phone = selected.phoneNumber,
                       let phoneURL = URL(string: "tel://\(phone.filter { $0.isNumber })") {
                        Link(destination: phoneURL) {
                            HStack {
                                Spacer()
                                Label("Call \(phone)", systemImage: "phone")
                                    .font(.callout)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    if let url = selected.url {
                        Link(destination: url) {
                            HStack {
                                Spacer()
                                Label("Visit Website", systemImage: "safari")
                                    .font(.callout)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 10)
            Spacer()
        }
        .padding()
        .background(.sub)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .cardShadow()
    }
}

// MARK: - Location Info Card
struct CourseLocationInfoCard: View {
    @EnvironmentObject var locationHandler: LocationHandler
    let selectedItem: MKMapItem?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin")
                    Text("Location")
                        .font(.headline)
                }
                if let name = selectedItem?.name {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                if let selectedResult = selectedItem {
                    Text(locationHandler.getPostalAddress(from: selectedResult))
                        .font(.callout)
                }
            }
            Spacer()
        }
        .padding()
        .background(.sub)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .cardShadow()
    }
}

// MARK: - Claim Course Button
struct CourseClaimButton: View {
    var body: some View {
        Button {
            // later: open URL
        } label: {
            HStack {
                Image(systemName: "safari.fill")
                Text("This your Course? Click to Claim!")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.subheadline.weight(.semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(.mainOpp)
            .background(.sub)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .cardShadow()
        }
    }
}
