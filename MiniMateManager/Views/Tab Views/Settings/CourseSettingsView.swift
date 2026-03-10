//
//  CourseSettingsView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/10/25.
//
import SwiftUI
import MarqueeText

struct CourseSettingsView: View {
    
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    @StateObject private var viewModel = CourseSettingsViewModel()
    
    var body: some View {
        VStack {
            CourseSettingsHeaderView()
                .padding([.horizontal, .top])
            
            formView
        }
        .environmentObject(viewModel)
    }
    
    private var formView: some View {
        Form {
            if let courseTier = courseViewModel.selectedCourse?.tier,
               let course = courseViewModel.selectedCourse,
               courseTier >= 1 {
                
                CourseSectionView(course: course)
                PasswordSectionView(course: course)
                AppearanceSectionView()
                SocialLinksSectionView()
            }
            
            AdSectionView()
            ParSettingsSectionView()
            ParConfigurationSectionView()
        }
        .contentMargins(.top, 16)
    }
}

// MARK: - Header View
struct CourseSettingsHeaderView: View {
    
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.title).fontWeight(.bold)
                Spacer()
                Button("User View") {
                    viewModel.showReviewSheet = true
                }
                .sheet(isPresented: $viewModel.showReviewSheet) {
                    if let course = courseViewModel.selectedCourse {
                        let holeCount = course.pars.count == 0 ? 18 : course.pars.count
                        
                        let holes1 = (1...holeCount).map { number in
                            Hole(number: number, strokes: Int.random(in: 1...6))
                        }
                        let holes2 = (1...holeCount).map { number in
                            Hole(number: number, strokes: Int.random(in: 1...6))
                        }
                        
                        GameReviewView(
                            game: Game(
                                id: "EXAMPLE",
                                date: Date(),
                                completed: true,
                                numberOfHoles: course.numHoles,
                                started: true,
                                dismissed: false,
                                live: false,
                                lastUpdated: Date(),
                                courseID: course.id,
                                players: [
                                    Player(id: "1", userId: "Example 1", name: "Garrett", inGame: false, holes: holes1),
                                    Player(id: "2", userId: "Example 2", name: "Joey", inGame: false, holes: holes2)
                                ],
                                locationName: course.name
                            ),
                            showBackToStatsButton: true,
                            isInCourseSettings: true
                        )
                        .presentationDragIndicator(.visible)
                    }
                }
            }
        }
    }
}

// MARK: - Course Section
struct CourseSectionView: View {
    let course: Course
    
    var body: some View {
        Section("Course") {
            HStack {
                Text("Id:")
                Spacer()
                Text(course.id)
            }
            
            HStack {
                Text("Name:")
                Spacer()
                Text(course.name)
            }
            
            HStack {
                Text("Tier:")
                Spacer()
                Text(String(course.tier))
            }
        }
    }
}

// MARK: - Password Section
struct PasswordSectionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    let course: Course
    
    var body: some View {
        Section("Password") {
            HStack {
                Text("Password:")
                
                if viewModel.showPassword {
                    Text(course.password)
                } else {
                    Text("••••••••••")
                }
                Spacer()
                Button {
                    viewModel.showPassword.toggle()
                } label: {
                    !viewModel.showPassword ? Image(systemName: "eye").foregroundColor(.blue) : Image(systemName: "eye.slash").foregroundColor(.blue)
                }
            }
            
            Button {
                viewModel.showChangePasswordAlert.toggle()
            } label: {
                Text("Change Password")
                    .foregroundColor(.blue)
            }
            .alert("Change Password", isPresented: $viewModel.showChangePasswordAlert) {
                SecureField("New Password", text: $viewModel.newPassword)
                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                Button("Cancel", role: .cancel) {
                    viewModel.resetPasswordFields()
                }
                Button("Save") {
                    viewModel.changePassword(course: $courseViewModel.selectedCourse, userID: authModel.userModel?.googleId)
                }
                .disabled(!viewModel.isValidPassword)
            } message: {
                Text("Enter and confirm your new password")
            }
        }
    }
}

// MARK: - Logo Section
struct LogoSectionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        HStack {
            Text("Logo:")
            Spacer()
            Button {
                withAnimation {
                    viewModel.showingPickerLogo = true
                }
            } label: {
                if let courseLogo = courseViewModel.selectedCourse?.logo {
                    AsyncImage(url: URL(string: courseLogo)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60)
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.2))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.2))
                }
            }
            .sheet(isPresented: $viewModel.showingPickerLogo) {
                PhotoPicker(image: $viewModel.image)
                    .onChange(of: viewModel.image) { old, newImage in
                        guard let img = newImage else { return }
                        viewModel.uploadLogoImage(img, course: $courseViewModel.selectedCourse)
                    }
            }
        }
    }
}

// MARK: - Scorecard Color Section
struct ScorecardColorSectionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        HStack {
            Text("Scorecard Color:")
            Spacer()
            
            ColorHolderView(
                color: courseViewModel.selectedCourse?.scoreCardColor
            ) {
                courseViewModel.addTarget = .scoreCardColor
                courseViewModel.showColor = true
            } deleteFunction: {
                viewModel.deleteTarget = .scoreCardColor
            }
        }
    }
}

// MARK: - Course Colors Section
struct CourseColorsSectionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Course Colors")
            }
            ScrollView(.horizontal) {
                HStack {
                    if let colors = courseViewModel.selectedCourse?.courseColorsDT {
                        ForEach(Array(colors.enumerated()), id: \.offset) { index, dt in
                            let color = viewModel.stringToColor(dt)
                            
                            ColorHolderView(color: color)
                            { /* For adding Only */ }
                            deleteFunction: {
                                viewModel.deleteTarget = .courseColor(index: index)
                            }
                        }
                    }
                    
                    ColorHolderView() {
                        courseViewModel.addTarget = .courseColor
                        courseViewModel.showColor = true
                    } deleteFunction: { /* For deleting Only */ }
                }
            }
            .alert(item: $viewModel.deleteTarget) { target in
                Alert(
                    title: Text("Delete Color"),
                    message: Text("Are you sure?"),
                    primaryButton: .destructive(Text("Delete")) {
                        viewModel.deleteColor(target: target, course: $courseViewModel.selectedCourse)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// MARK: - Appearance Section
struct AppearanceSectionView: View {
    var body: some View {
        Section("Appearance") {
            LogoSectionView()
            ScorecardColorSectionView()
            CourseColorsSectionView()
        }
    }
}

// MARK: - Social Links Section
struct SocialLinksSectionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        Section("Social Links") {
            if let course = courseViewModel.selectedCourse {
                ForEach(course.socialLinks.indices, id: \.self) { index in
                    // Check if index is still valid to prevent out-of-range crashes
                    if index < courseViewModel.selectedCourse?.socialLinks.count ?? 0 {
                        VStack(spacing: 12) {
                            // Platform Picker
                            Picker("Platform", selection: Binding(
                                get: {
                                    courseViewModel.selectedCourse?.socialLinks[index].platform ?? .instagram
                                },
                                set: { newValue in
                                    guard index < courseViewModel.selectedCourse?.socialLinks.count ?? 0 else { return }
                                    courseViewModel.selectedCourse?.socialLinks[index].platform = newValue
                                    courseViewModel.immediateSave()
                                }
                            )) {
                                ForEach(SocialPlatform.allCases) { platform in
                                    Text(platform.rawValue.capitalized)
                                        .tag(platform)
                                }
                            }
                            .pickerStyle(.menu)
                        
                            TextField("URL", text: Binding(
                                get: {
                                    guard index < courseViewModel.selectedCourse?.socialLinks.count ?? 0 else { return "" }
                                    return courseViewModel.selectedCourse?.socialLinks[index].url ?? ""
                                },
                                set: { newValue in
                                    guard index < courseViewModel.selectedCourse?.socialLinks.count ?? 0 else { return }
                                    courseViewModel.selectedCourse?.socialLinks[index].url = newValue
                                    courseViewModel.debouncedSave()
                                }
                            ))
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color(.subTwo))
                            )
                        }
                        .padding(.vertical, 8)
                    }
                }
                .onDelete { indexSet in
                    courseViewModel.selectedCourse?.socialLinks.remove(atOffsets: indexSet)
                    courseViewModel.immediateSave()
                }
            }
            // Add Button
            Button {
                withAnimation {
                    courseViewModel.selectedCourse?.socialLinks.append(
                        SocialLink(platform: .instagram, url: "")
                    )
                }
                courseViewModel.immediateSave()
            } label: {
                Label("Add Social Link", systemImage: "plus.circle.fill")
            }
        }
    }
}


// MARK: - Ad Section
struct AdSectionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        if let courseTier = courseViewModel.selectedCourse?.tier, courseTier >= 2 {
            Section("Ad") {
                
                
                Toggle("Ad Active:", isOn: courseViewModel.binding(keyPath: \.customAdActive) ?? Binding.constant(false))
                    .toggleStyle(SwitchToggleStyle())
                
                
                if courseViewModel.selectedCourse?.customAdActive == true {
                    AdTitleView()
                    AdDescriptionView()
                    AdLinkView()
                    AdImageView()
                }
            }
        }
    }
}

// MARK: - Ad Subviews
struct AdTitleView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Ad Title:")
                Spacer()
            }
            
            Spacer()
            
            TextEditor(text: courseViewModel.limitedTextBinding(keyPath: \.adTitle, deleteKey: "adTitle", limit: 40))
                .frame(minHeight: 40, maxHeight: 80)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                )
        }
    }
}

struct AdDescriptionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("Ad Description:")
                Spacer()
            }
            Spacer()
            TextEditor(text: courseViewModel.limitedTextBinding(keyPath: \.adDescription, deleteKey: "adDescription", limit: 80))
                .frame(minHeight: 60, maxHeight: 120)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                )
        }
    }
}

struct AdLinkView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        HStack {
            Text("Ad Link:")
            Spacer()
            TextField("Ad Link", text: courseViewModel.optionalBinding(keyPath: \.adLink, deleteKey: "adLink"))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(.subTwo)
                )
        }
    }
}

struct AdImageView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        HStack {
            Text("Ad Image:")
            Spacer()
            Button {
                withAnimation {
                    viewModel.showingPickerAd = true
                }
            } label: {
                if let courseImage = courseViewModel.selectedCourse?.adImage {
                    AsyncImage(url: URL(string: courseImage)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60)
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: $viewModel.showingPickerAd) {
                PhotoPicker(image: $viewModel.image)
                    .onChange(of: viewModel.image) { old, newImage in
                        guard let img = newImage else { return }
                        viewModel.uploadAdImage(img, course: $courseViewModel.selectedCourse)
                    }
            }
        }
    }
}

// MARK: - Par Settings Section
struct ParSettingsSectionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        Section("Par Settings") {
            Toggle("Custom Pars", isOn: courseViewModel.customParBinding())
            
            if let customPar = courseViewModel.selectedCourse?.customPar, customPar == true {
                HStack {
                    Text("Number Of Holes")
                    NumberPickerView(selectedNumber: courseViewModel.numHolesBinding(), minNumber: 9, maxNumber: 21)
                        .frame(height: 60)
                }
            }
        }
    }
}

// MARK: - Par Configuration Section
struct ParConfigurationSectionView: View {
    @EnvironmentObject var viewModel: CourseSettingsViewModel
    @EnvironmentObject var courseViewModel: CourseViewModel
    
    var body: some View {
        Section("Par Configuration") {
            if let pars = courseViewModel.selectedCourse?.pars, pars.count > 0 {
                // Par Preview
                VStack(spacing: 12) {
                    HStack {
                        Text("Par Preview")
                        Spacer()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(pars.enumerated()), id: \.offset) { index, par in
                                VStack(spacing: 4) {
                                    Text("H\(index + 1)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                    Text("\(par)")
                                        .font(.headline)
                                }
                                .frame(width: 40, height: 50)
                                .background(.subThree)
                                .cornerRadius(8)
                                .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Toggle to show/hide detailed configuration
                Toggle("Show Configuration", isOn: $viewModel.showParConfiguration)
                    .toggleStyle(SwitchToggleStyle())
                
                // Detailed Par Configuration
                if viewModel.showParConfiguration {
                    ForEach(Array(pars.enumerated()), id: \.offset) { index, par in
                        HStack {
                            Text("Hole \(index + 1):")
                            Spacer()
                            
                            NumberPickerView(
                                selectedNumber: courseViewModel.parBinding(index: index),
                                minNumber: 0,
                                maxNumber: 10
                            )
                            .frame(width: 75)
                        }
                    }
                }
            }
        }
    }
}

