//
//  AchievementsView.swift
//  FreshChiken
//
//  Created by D K on 07.04.2025.
//

import SwiftUI

// MARK: - Data Structures
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String // What the achievement IS
    let unlockCondition: String // How to GET the achievement
    let imageName: String
    var isUnlocked: Bool = false // All start locked
}

// MARK: - Achievement Item View
struct AchievementItemView: View {
    let achievement: Achievement

    let itemBackgroundColor = Color(red: 0.28, green: 0.31, blue: 0.45)
    let itemBorderColor = Color.yellow.opacity(0.7)
    let lockedBorderColor = Color.gray.opacity(0.5)
    let cornerRadius: CGFloat = 10
    let imageSize: CGFloat = 60

    var body: some View {
        VStack(spacing: 4) {
            Image(achievement.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .padding(.top, 10)
                .grayscale(achievement.isUnlocked ? 0 : 1.0) // Apply grayscale if locked
                .opacity(achievement.isUnlocked ? 1.0 : 0.6) // Make dimmer if locked

            Text(achievement.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .opacity(achievement.isUnlocked ? 1.0 : 0.7)

            Text("(\(achievement.description))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .opacity(achievement.isUnlocked ? 1.0 : 0.6)


            Spacer(minLength: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(itemBackgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                // Use different border color based on lock state
                .stroke(achievement.isUnlocked ? itemBorderColor : lockedBorderColor, lineWidth: 2)
        )
        .aspectRatio(1.0, contentMode: .fit)
        // Apply grayscale/opacity to the whole item if desired, instead of individual elements
        // .grayscale(achievement.isUnlocked ? 0 : 0.8)
        // .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Custom Alert View
struct AchievementAlertView: View {
    let achievement: Achievement
    @Binding var isPresented: Bool

    let alertBackgroundColor = Color(red: 0.2, green: 0.2, blue: 0.35).opacity(0.95)
    let borderColor = Color.yellow.opacity(0.7)
    let closeButtonColor = Color(red: 0.3, green: 0.3, blue: 0.5)

    var body: some View {
        VStack(spacing: 15) {
            Image(achievement.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            
                // Don't apply grayscale here, show the full color icon in the alert
                .padding(.top)

            Text(achievement.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            

            Divider().background(Color.white.opacity(0.3))

            VStack(alignment: .leading, spacing: 5) {
                 Text("How to Unlock:")
                      .font(.headline)
                      .foregroundColor(.white)
                 Text(achievement.unlockCondition)
                      .font(.subheadline)
                      .foregroundColor(.white.opacity(0.8))
                      .multilineTextAlignment(.leading) // Align condition text left
                      .frame(maxWidth: .infinity, alignment: .leading) // Ensure it takes width
                      .lineLimit(3)
                      .frame(height: 50)
            }


            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPresented = false
                }
            } label: {
                Text("OK")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(closeButtonColor)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .background(alertBackgroundColor)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(borderColor, lineWidth: 2))
        .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 5)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85) // Limit width
        .transition(.scale.combined(with: .opacity)) // Add transition
    }
}


// MARK: - Main Achievements View
struct AchievementsView: View {

    var sideMenu: () -> ()

    // MARK: - Achievement Data (All start locked)
    @State private var achievementsData: [Achievement] = [
        Achievement(title: "Product \nPioneer", description: "First 50 Scans", unlockCondition: "Successfully scan and save 50 products with expiration dates.", imageName: "ach1"),
        Achievement(title: "Inventory \nMaster", description: "100 Products Logged", unlockCondition: "Scan and save a total of 100 products.", imageName: "ach2"),
        Achievement(title: "Waste \nWatcher", description: "50 Products Expired", unlockCondition: "Have 50 products reach their expiration date while logged in the app.", imageName: "ach3"),
        Achievement(title: "List \nLegend", description: "Shopping Spree", unlockCondition: "Add a total of 100 items to your shopping lists.", imageName: "ach4"),
        Achievement(title: "Checkmate \nChampion", description: "100 Items Checked", unlockCondition: "Mark 100 items as completed (checked) in your shopping lists.", imageName: "ach5"),
        Achievement(title: "Future \nProof", description: "Year+ Expiry", unlockCondition: "Scan and save a product that expires more than one year from the date it was added.", imageName: "ach6"),
        Achievement(title: "Close \nCall", description: "Expires Soon", unlockCondition: "Scan and save a product that expires within the next 3 days.", imageName: "ach7"),
        Achievement(title: "Scanning \nStreak", description: "10 in a Day", unlockCondition: "Scan and save 10 different products within a single 24-hour period.", imageName: "ach8"),
        Achievement(title: "Deadline \nDefender", description: "Saved on Last Day", unlockCondition: "Save 5 products exactly on their expiration date (before they become spoiled).", imageName: "ach9")
    ]

    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 15), count: 3)
    let screenBackgroundColor = Color(red: 0.2, green: 0.2, blue: 0.35)
    let topBarButtonColor = Color.orange

    // MARK: - State for Custom Alert
    @State private var selectedAchievement: Achievement? = nil
    @State private var showingAchievementAlert = false

    var body: some View {
        ZStack {
            Image("back")
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: sideMenu) {
                        Image("sideBarIcon")
                            .resizable().scaledToFit().frame(width: 40, height: 40)
                    }
                    Spacer()
                    Text("Achievements")
                        .foregroundStyle(.white).font(.system(size: 28, weight: .black))
                    Spacer()
                    // Keep the trailing space consistent if needed for centering
                    Rectangle().fill(Color.clear).frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.bottom)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(achievementsData) { achievement in
                            Button {
                                // Action to show the custom alert
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    selectedAchievement = achievement

                                    showingAchievementAlert.toggle()
                                }
                            } label: {
                                AchievementItemView(achievement: achievement)
                            }
                            .buttonStyle(.plain) // Use plain style to avoid default button visuals interfering
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                 Spacer()
            } // End Main VStack

            // MARK: - Custom Alert Overlay
            if showingAchievementAlert {
                 // Background Dimming
                 Color.black.opacity(0.6)
                      .ignoresSafeArea()
                      .onTapGesture { // Allow dismissing by tapping background
                           withAnimation(.easeOut(duration: 0.2)) {
                               showingAchievementAlert.toggle()
                           }
                      }
                      .transition(.opacity) // Fade in/out background

                 // Alert Content
                 if let achievementToShow = selectedAchievement {
                      AchievementAlertView(achievement: achievementToShow, isPresented: $showingAchievementAlert)
                         .animation(.easeIn, value: showingAchievementAlert)
                 }
            }

        }
        .animation(.easeInOut, value: showingAchievementAlert)
    } 
}

// MARK: - Preview
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsView(sideMenu: {})
            .preferredColorScheme(.dark)
    }
}
