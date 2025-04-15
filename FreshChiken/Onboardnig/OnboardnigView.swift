import SwiftUI

// Custom Color Extension (Place this outside your view struct or in a separate file)


// Represents a single step/page in the onboarding flow
struct OnboardingStep: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}

// The main Onboarding View
struct OnboardingView: View {

    @Environment(\.dismiss) var dismiss
    // State to control if onboarding is showing.
    @State private var isOnboardingActive: Bool = true

    // Data for the onboarding pages
    let onboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            imageName: "chick2", // Image for introduction
            title: "Welcome to Fresh Chicken!",
            description: "Your guide to food safety. Track freshness, plan shopping, reduce waste, and earn achievements along the way."
        ),
        OnboardingStep(
            imageName: "chick1", // Image for tracking expiration
            title: "Never Waste Food Again",
            description: "Easily add products manually or with a photo. We'll help you monitor expiration dates and see what's fresh, expiring soon, or needs to go."
        ),
        OnboardingStep(
            imageName: "chick3", // Image for shopping list
            title: "Smart Shopping Lists",
            description: "Create shopping lists, specify quantities, and check off items as you buy them. Stay organized and buy only what you need."
        ),
        // Add a 4th step if you want a dedicated achievement screen
        // OnboardingStep(imageName: "golden_egg_placeholder", title: "Earn Achievements", description: "Get motivated by unlocking fun achievements as you manage your food efficiently!")
    ]

    // State to keep track of the current tab index
    @State private var currentTab = 0

    // Total number of onboarding steps (used for button logic)
    var totalSteps: Int {
        onboardingSteps.count
    }

    var body: some View {
        if isOnboardingActive {
            ZStack {
                // --- Background ---
                Color.darkBlue
                    .ignoresSafeArea() // Extend background to screen edges

                // --- Main Content ---
                VStack {
                    // --- TabView for Swipeable Content ---
                    TabView(selection: $currentTab) {
                        ForEach(0..<onboardingSteps.count, id: \.self) { index in
                            EnhancedOnboardingPageView(step: onboardingSteps[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // Use page style, but hide default dots
                    .animation(.easeInOut, value: currentTab) // Animate tab transitions

                    // --- Custom Page Indicators (Dots) ---
                    HStack(spacing: 10) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Circle()
                                .fill(index == currentTab ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                                // Add animation if you want the dots to scale or change more dynamically
                                .animation(.spring(), value: currentTab) // Animate dot changes
                        }
                    }
                    .padding(.bottom, 25) // Space between dots and button

                    // --- Navigation Button ---
                    Button {
                        handleNextButton()
                    } label: {
                        Text(currentTab == totalSteps - 1 ? "Get Started" : "Next")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16) // Make button taller
                            .foregroundColor(Color.darkBlue)
                            .background(Color.white)
                            .cornerRadius(15) // Rounded corners
                            .shadow(radius: 5) // Subtle shadow
                    }
                    .padding(.horizontal, 30) // Side padding for the button
                    .padding(.bottom, 40) // Bottom padding for the button
                }
            }
            .transition(.move(edge: .trailing).combined(with: .opacity)) // Nicer transition
            .animation(.easeInOut, value: isOnboardingActive) // Animate dismissal
            .preferredColorScheme(.dark) // Hint to system controls (like status bar) to be light

        } else {
            // --- Placeholder for your main App Content View ---
            Text("Main App Content Goes Here")
                .font(.largeTitle)
            // --- End Placeholder ---
        }
    }

    // Function to handle the button tap
    func handleNextButton() {
        withAnimation { // Animate the page change
            if currentTab < totalSteps - 1 {
                currentTab += 1
            } else {
                // Last step - dismiss onboarding
                print("Onboarding Complete!")
               // isOnboardingActive = false
                dismiss()
                // In a real app:
                // UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        }
    }
}

// A reusable view for a single onboarding page - Enhanced for Dark BG
struct EnhancedOnboardingPageView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 25) { // Increased spacing
            Spacer()

            Image(step.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 220) // Slightly larger image frame
                .padding(.bottom, 40)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5) // Add subtle shadow to image

            Text(step.title)
                .font(.system(size: 28, weight: .bold, design: .rounded)) // Nicer font
                .foregroundColor(.white) // White text for contrast
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(step.description)
                .font(.system(size: 17, weight: .regular, design: .default)) // Standard body font
                .foregroundColor(.white.opacity(0.85)) // Slightly off-white
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(5) // Add line spacing for readability

            Spacer()
            Spacer() // Push content towards the vertical center/top
        }
        .padding(.bottom, 60) // Ensure space above custom controls
    }
}

// MARK: - Preview
struct EnhancedOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            // Ensure you have placeholder images named "chick1", "chick2", "chick3" in Assets
            // Or replace the names in the `onboardingSteps` array for previewing
    }
}
