//
//  CourseDetailCards.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/27/25.
//

import SwiftUI
import MapKit
import MarqueeText

/// A container view responsible for creating and providing the `CourseLocationViewModel`
/// to the `CourseResultView`. This pattern is useful for injecting dependencies
/// from the environment into a @StateObject.
struct CourseResultViewContainer: View {
    @EnvironmentObject var locationHandler: LocationHandler
    @EnvironmentObject var courseViewModel: CourseViewModel

    var body: some View {
        CourseResultView(viewModel: CourseLocationViewModel(
            locationHandler: locationHandler,
            courseViewModel: courseViewModel
        ))
    }
}


// MARK: - Course Result View
struct CourseResultView: View {
    @StateObject var viewModel: CourseLocationViewModel
    @State private var titleHeight: CGFloat = 30
    @State private var showRetryButton: Bool = false
    
    var body: some View {
        
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CourseDirectionsButton()
                        
                        if let course = viewModel.courseViewModel.selectedCourse, course.isSupported {
                            CourseSupportedLocationCard(
                                course: course,
                                locationName: viewModel.courseName
                            )
                            
                            if !course.socialLinks.isEmpty {
                                CourseSocialMediaCard(course: course)
                            }
                        } else {
                            CourseClaimButton()
                        }
                        
                        CourseContactInfoCard()
                        
                        CourseLocationInfoCard()
                    }
                }
                .mask {
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: titleHeight)
                        
                        Rectangle().fill(.black)
                    }
                }
                .contentMargins([.horizontal, .bottom], 16)
                .contentMargins(.top, 62)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                
                VStack {
                    CourseResultViewHeader()
                        .padding()
                        .padding(.bottom, 16)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .task(id: proxy.size) {
                                        titleHeight = proxy.size.height
                                    }
                            }
                        }
                    Spacer()
                }
            }
            .environmentObject(viewModel)
            .onDisappear(){
                viewModel.close()
            }
    }
}

// MARK: - Result View Header
struct CourseResultViewHeader: View {
    @EnvironmentObject var viewModel: CourseLocationViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: viewModel.close) {
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
                text: viewModel.courseName,
                font: UIFont.preferredFont(forTextStyle: .title3),
                leftFade: 16,
                rightFade: 16,
                startDelay: 2,
                alignment: .center
            )
            .foregroundStyle(.primary)
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
    @EnvironmentObject var viewModel: CourseLocationViewModel
    
    var body: some View {
        Button(action: viewModel.getDirections) {
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
                    .foregroundStyle(.primary)
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
        .background(Material.regular)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.5), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .cardShadow()
    }
}

// MARK: - Social Media Card
struct CourseSocialMediaCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                Text("Social Media")
                    .font(.headline)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(course.socialLinks) { link in
                        socialLinkButton(for: link)
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.regular)
                .cardShadow()
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
                    .fill(Material.ultraThick)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact Info Card
struct CourseContactInfoCard: View {
    @EnvironmentObject var viewModel: CourseLocationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                Text("Contact")
                    .font(.headline)
            }
            
            if let phone = viewModel.phoneNumber, let phoneURL = viewModel.phoneNumberURL {
                Link(destination: phoneURL) {
                    HStack {
                        Spacer()
                        Label("Call \(phone)", systemImage: "phone")
                            .font(.callout)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            if let url = viewModel.websiteURL {
                Link(destination: url) {
                    HStack {
                        Spacer()
                        Label("Visit Website", systemImage: "safari")
                            .font(.callout)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .cardShadow()
    }
}

// MARK: - Location Info Card
struct CourseLocationInfoCard: View {
    @EnvironmentObject var viewModel: CourseLocationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "mappin")
                Text("Location")
                    .font(.headline)
            }
            
            Text(viewModel.courseName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(viewModel.postalAddress)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .cardShadow()
    }
}

// MARK: - Claim Course Button
struct CourseClaimButton: View {
    @EnvironmentObject var viewModel: CourseLocationViewModel
    
    var body: some View {
        Button(action: viewModel.claimCourse) {
            HStack {
                Image(systemName: "safari.fill")
                Text("Is this your course? Click to Claim!")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.subheadline.weight(.semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(.mainOpp)
            .background(Material.regular)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .cardShadow()
        }
    }
}
// MARK: - Placeholder View Modifier
// This is a placeholder for your custom .cardShadow() modifier
private struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

private extension View {
    func cardShadow() -> some View {
        self.modifier(CardShadow())
    }
}

