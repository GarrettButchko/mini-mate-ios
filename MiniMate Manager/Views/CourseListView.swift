//
//  CourseListView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI
import FirebaseAuth

struct CourseListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewManager: ViewManager
    @EnvironmentObject var viewModel: CourseViewModel
    
    private var userRepo: UserRepository { UserRepository(context: context)}
    
    @State private var isSheetPresented: Bool = false
    @State private var showUnsuccessfulAlert: Bool = false
    @State private var isRotating: Bool = false
    
    var body: some View {
        
        
        Group{
            if viewModel.hasCourse {
                multiCourse
                    .contentMargins(.horizontal, 16)
                    .transition(.opacity)
            } else {
                firstCourse
                    .padding()
                    .transition(.opacity)
            }
        }
        .animation(.bouncy, value: viewModel.hasCourse)
        .onReceive(viewModel.timer) { _ in
            viewModel.tick()
        }
        .alert("Add Course", isPresented: $viewModel.showAddCourseAlert) {
            TextField("Password", text: $viewModel.password)
            
            Button("Add", role: .none) {
                viewModel.tryPassword { _ in
                    viewModel.password = ""
                    viewModel.showAddCourseAlert = false
                }
            }
            .disabled(viewModel.password.isEmpty)
            
            Button("Cancel", role: .cancel) {
                viewModel.password = ""
                viewModel.showAddCourseAlert = false
            }
        } message: {
            Text("Enter course password to begin.")
        }
        .onAppear {
            viewModel.bind(authModel: authModel)
            userRepo.loadOrCreateUser(id: authModel.currentUserIdentifier!, authModel: authModel) { _, done2,_  in
                if done2 {
                    if viewModel.userCourses.isEmpty {
                        if authModel.userModel?.adminCourses.count ?? 0 > 1 {
                            viewModel.getCourses()
                        } else if authModel.userModel?.adminCourses.count == 1{
                            viewModel.getCourse {
                                viewManager.navigateToCourseTab(1)
                            }
                        } else {
                            viewModel.loadingCourse = false
                        }
                    }
                }
            }
        }
        .background(.bg)
    }
    
    var multiCourse: some View{
        VStack{
            HStack{
                Text("Courses")
                    .font(.title).fontWeight(.bold)
                Spacer()
                
                Button(action: {
                    withAnimation(){
                        isRotating = true
                        viewModel.getCourses()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isRotating = false
                        }
                    }
                }) {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 30, height: 30)
                }
                
                Button(action: {
                    isSheetPresented = true
                }) {
                    if let photoURL = authModel.firebaseUser?.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image("logoOpp")
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image("logoOpp")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    ProfileView(
                        viewManager: viewManager,
                        authModel: authModel,
                        isSheetPresent: $isSheetPresented, context: context
                    )
                }
            }
            .padding([.horizontal, .top], 16)
            
            if viewModel.loadingCourse {
                VStack{
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                ScrollView{
                    VStack(spacing: 16){
                        if let message = viewModel.message {
                            VStack(spacing: 6) {
                                if viewModel.timeRemaining > 0 {
                                    Text(message)
                                        .font(.headline)
                                        .foregroundStyle(.blue)
                                    
                                    Text("Try again in \(max(0, Int(ceil(viewModel.timeRemaining)))) seconds")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(message)
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(viewModel.timeRemaining > 0 ? .blue.opacity(0.2) : .red.opacity(0.2))
                                    .cardShadow()
                            )
                        }
                        
                        ForEach(viewModel.userCourses) { course in
                            CourseButtonView(viewModel: viewModel, course: course)
                        }
                        
                        Button {
                            viewModel.showAddCourseAlert = true
                        } label: {
                            ZStack{
                                RoundedRectangle(cornerRadius: 25)
                                    .foregroundStyle(.blue)
                                    .frame(height: 60)
                                HStack(alignment: .center){
                                    Image(systemName: "plus")
                                        .foregroundStyle(.white)
                                    Text("Add a new course")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                }
                            }
                            .opacity(viewModel.timeRemaining > 0 ? 0.5 : 1)
                        }
                        .disabled(viewModel.timeRemaining > 0)
                        Spacer()
                    }
                }
            }
            
            Button {
                // later: open URL
            } label: {
                HStack {
                    Image(systemName: "safari.fill")
                    Text("Get another course password")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background{
                    RoundedRectangle(cornerRadius: 18).fill(.sub)
                        .cardShadow()
                }
                .foregroundStyle(.mainOpp)
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    var firstCourse: some View {
        VStack{
            HStack{
                Spacer()
                
                Button(action: {
                    isSheetPresented = true
                }) {
                    if let photoURL = authModel.firebaseUser?.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image("logoOpp")
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image("logoOpp")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    ProfileView(
                        viewManager: viewManager,
                        authModel: authModel,
                        isSheetPresent: $isSheetPresented, context: context
                    )
                }
            }
            
            
            VStack(spacing: 18) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add your first course")
                        .font(.largeTitle.bold())
                    
                    Text("Mini Manager lets you customize your scorecard, run leaderboards/tournaments, and view course analytics.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 30) {
                    Label("Customize your scorecard look", systemImage: "paintpalette.fill")
                        .foregroundStyle(.red)
                    Label("Collect emails + see analytics", systemImage: "chart.bar.fill")
                        .foregroundStyle(.green)
                    Label("Leaderboards and tournaments", systemImage: "trophy.fill")
                        .foregroundStyle(.blue)
                    Label("Run promos with your own in-app ad", systemImage: "megaphone.fill")
                        .foregroundStyle(.orange)
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background{
                    RoundedRectangle(cornerRadius: 25).fill(.sub)
                        .cardShadow()
                }
                
                
                Label("And More!", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background{
                        RoundedRectangle(cornerRadius: 25).fill(.sub)
                            .cardShadow()
                    }
                
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Need your course password?")
                        .font(.headline)
                    
                    Text("Visit our website to request it and we’ll email your course password to the address on file.")
                        .foregroundStyle(.secondary)
                    
                    // Placeholder until you have the site
                    Button {
                        // later: open URL
                    } label: {
                        HStack {
                            Image(systemName: "safari.fill")
                            Text("Get my course password")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 18).fill(.sub))
                        .foregroundStyle(.mainOpp)
                        .cardShadow()
                    }
                }
                .padding(.top, 6)
                
                Button {
                    viewModel.showAddCourseAlert = true // ✅ same alert as the list button
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(.blue)
                            .frame(height: 60)
                        HStack {
                            Image(systemName: "plus")
                                .foregroundStyle(.white)
                            Text("Add a course")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .opacity(viewModel.timeRemaining > 0 ? 0.5 : 1)
                .disabled(viewModel.timeRemaining > 0)
                
                if let message = viewModel.message {
                    VStack(spacing: 6) {
                        Text(message).font(.headline)
                        if viewModel.timeRemaining > 0 {
                            Text("Try again in \(max(0, Int(ceil(viewModel.timeRemaining)))) seconds")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background{
                        RoundedRectangle(cornerRadius: 25).fill(.sub)
                            .cardShadow()
                    }
                }
            }
        }
    }
}

