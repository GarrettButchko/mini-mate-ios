import SwiftUI

struct AddToLeaderBoardButton: View {
    
    @State var course: Course?
    @State var added: Bool = false
    // Track if the network request is currently in flight
    @State private var isSubmitting: Bool = false
    
    let player: Player
    let courseLeaderBoardRepo = CourseLeaderboardRepository()
    
    var body: some View {
        // Only show if all conditions are met
        if let course = course,
            !(ProfanityFilter.containsBlockedWord(player.name)) &&
            !player.incomplete &&
            course.tier >= 2 &&
            player.email != nil &&
            course.customPar &&
            course.leaderBoardActive{
            
            Group {
                if added {
                    // --- Confirmation View ---
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Added")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .frame(width: 120, height: 20)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // --- Action Button ---
                    Button {
                        submit()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .foregroundStyle(isSubmitting ? .gray : .blue)
                            
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus")
                                    Text("Leaderboard")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.white)
                        }
                        .frame(width: 120, height: 20)
                    }
                    .disabled(isSubmitting) // Prevent multiple taps
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.spring(), value: added)
            .animation(.spring(), value: isSubmitting)
        }
    }
    
    private func submit() {
        guard let courseID = course?.id else { return }
        
        isSubmitting = true
        
        courseLeaderBoardRepo.submitScore(courseID: courseID, player: player) { success in
            // Button is "once only" - if successful, switch to confirmation
            if success {
                withAnimation {
                    self.added = true
                }
            }
            self.isSubmitting = false
        }
    }
}

