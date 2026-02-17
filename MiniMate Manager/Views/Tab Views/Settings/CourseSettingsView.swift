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
        VStack{
            headerView
                .padding()
            
            formView
        }
    }
    
    private var headerView: some View {
        VStack{
            
            HStack {
                Text("Settings")
                    .font(.title).fontWeight(.bold)
                Spacer()
                Button("User View"){
                    viewModel.showReviewSheet = true
                }
                .sheet(isPresented: $viewModel.showReviewSheet){
                    if let course = courseViewModel.selectedCourse {
                        let holeCount = course.pars.count == 0 ? 18 : course.pars.count
                        
                        let holes1 = (1...holeCount).map { number in
                            Hole(number: number, strokes: Int.random(in: 1...6))
                        }
                        let holes2 = (1...holeCount).map { number in
                            Hole(number: number, strokes: Int.random(in: 1...6))
                        }
                        
                        GameReviewView(game:
                                        Game(
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
                                       showBackToStatsButton: true, isInCourseSettings: true)
                        .presentationDragIndicator(.visible)
                    }
                }
            }
        }
    }
    
    private var formView: some View {
        
        Form{
            if let courseTier = courseViewModel.selectedCourse?.tier,
               let course = courseViewModel.selectedCourse,
               courseTier >= 1 {
                Section("Course") {
                    
                    // -----
                    
                    HStack {
                        Text("Id:")
                        Spacer()
                        Text(course.id)
                    }
                    
                    // -----
                    
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text(course.name)
                    }
                    
                    // -----
                    
                    HStack {
                        Text("Tier:")
                        Spacer()
                        Text(String(courseTier))
                    }
                }
                Section("Password") {
                    HStack{
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
                
                Section("Appearance") {
                    HStack {
                        Text("Logo:")
                        Spacer()
                        Button {
                            withAnimation{
                                viewModel.showingPickerLogo = true
                            }
                        } label: {
                            if let courseLogo = courseViewModel.selectedCourse?.logo{
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
                    
                    
                    HStack{
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
                    
                    VStack{
                        HStack{
                            Text("Course Colors")
                        }
                        ScrollView(.horizontal) {
                            HStack{
                                if let colors = courseViewModel.selectedCourse?.courseColorsDT {
                                    ForEach(Array(colors.enumerated()), id: \.offset) { index, dt in
                                        let color = viewModel.stringToColor(dt)
                                        
                                        ColorHolderView(color: color)
                                        { /* For adding Only */}
                                        deleteFunction: {
                                            viewModel.deleteTarget = .courseColor(index: index)
                                        }
                                    }
                                }
                                
                                ColorHolderView() {
                                    courseViewModel.addTarget = .courseColor
                                    courseViewModel.showColor = true
                                } deleteFunction: { /* For deleting Only */}
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
                    
                    
                    HStack {
                        Text("Link:")
                        Spacer()
                        TextField("Link", text: viewModel.optionalBinding(for: $courseViewModel.selectedCourse, keyPath: \.link, deleteKey: "link"))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                            )
                    }
                }
            }
            
            if let courseTier = courseViewModel.selectedCourse?.tier, courseTier >= 2 {
                Section("Ad") {
                    
                    if let activeBinding = viewModel.binding(for: $courseViewModel.selectedCourse, keyPath: \.customAdActive) {
                        Toggle("Ad Active:", isOn: activeBinding)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    
                    if courseViewModel.selectedCourse?.customAdActive == true {
                        VStack {
                            HStack{
                                Text("Ad Title:")
                                Spacer()
                            }
                            
                            Spacer()
                            TextEditor(text: viewModel.limitedTextBinding(for: $courseViewModel.selectedCourse, keyPath: \.adTitle, deleteKey: "adTitle", limit: 40))
                                .frame(minHeight: 40, maxHeight: 80)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                )
                        }
                        VStack {
                            HStack{
                                Text("Ad Description:")
                                Spacer()
                            }
                            Spacer()
                            TextEditor(text: viewModel.limitedTextBinding(for: $courseViewModel.selectedCourse, keyPath: \.adDescription, deleteKey: "adDescription", limit: 80))
                                .frame(minHeight: 60, maxHeight: 120)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                )
                        }
                        
                        HStack {
                            Text("Ad Link:")
                            Spacer()
                            TextField("Ad Link", text: viewModel.optionalBinding(for: $courseViewModel.selectedCourse, keyPath: \.adLink, deleteKey: "adLink"))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                )
                        }
                        HStack {
                            Text("Ad Image:")
                            Spacer()
                            Button {
                                withAnimation{
                                    viewModel.showingPickerAd = true
                                }
                            } label: {
                                if let courseImage = courseViewModel.selectedCourse?.adImage{
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
            }
            
            Section ("Par Settings"){
                
                Toggle("Custom Pars", isOn: viewModel.customParBinding(for: $courseViewModel.selectedCourse))
                
                if let customPar = courseViewModel.selectedCourse?.customPar, customPar == true {
                    
                    HStack{
                        Text("Number Of Holes")
                        NumberPickerView(selectedNumber: viewModel.numHolesBinding(for: $courseViewModel.selectedCourse), minNumber: 9, maxNumber: 21)
                            .frame(height: 60)
                    }
                    
                }
            }
            Section ("Par Configuration"){
                if let pars = courseViewModel.selectedCourse?.pars, pars.count > 0 {
                    ForEach(pars.indices, id: \.self) { index in
                        HStack {
                            Text("Hole \(index + 1):")
                            Spacer()
                            
                            NumberPickerView(
                                selectedNumber: viewModel.parBinding(for: $courseViewModel.selectedCourse, index: index),
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

