//
//  SettingsView.swift
//  FreshChiken
//
//  Created by D K on 08.04.2025.
//

import SwiftUI
import StoreKit


struct SettingsView: View {
    
    var sideMenu: () -> ()
    
    @State private var isShareSheetShowing = false
    
    private let appStoreID = "YOUR_APP_ID" // <-- !!! ВАЖНО: ЗАМЕНИТЬ !!!
    private var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }
    private let shareText = "Check out this cool app for tracking food expiration dates!"
    
    func privacyAction() {
        if let url = URL(string: "https://sites.google.com/view/freshchickensite/privacy-policy") {
            UIApplication.shared.open(url)
        }
    }
    
    func contactAction() {
        if let url = URL(string: "https://sites.google.com/view/freshchickensite/contact-us") {
            UIApplication.shared.open(url)
        }
    }
    
    func rateAction() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func shareAction() {
        if appStoreURL != nil {
            isShareSheetShowing = true
        } else {
            print("Error: App Store URL is not configured correctly. Replace YOUR_APP_ID.")
        }
    }
    
    func openAppSettings() {
        print("Opening App Settings")
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            print("Cannot open settings URL")
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
    
    var body: some View {
        ZStack {
            Image("back")
                .resizable()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
                    Button {
                        sideMenu()
                    } label: {
                        Image("sideBarIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .foregroundStyle(.white)
                        .font(.system(size: 28, weight: .black))
                    
                    Spacer()
                    
                    Image("chick1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    
                    SettingsButton(title: "Privacy policy", action: privacyAction)
                    SettingsButton(title: "Contact us", action: contactAction)
                    SettingsButton(title: "Rate the app", action: rateAction)
                    SettingsButton(title: "Share the app", action: shareAction)
                    SettingsButton(title: "Enable notifications", action: openAppSettings) // Changed to button
                    
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                Text("Version 1.0")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom)
                
            }
        }
        .sheet(isPresented: $isShareSheetShowing) {
            if let url = appStoreURL {
                ShareSheet(activityItems: [shareText, url])
            } else {
                Text("Error generating share link.")
            }
        }
    }
}

struct SettingsButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 18))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .padding(.horizontal)
            .background(
                Color.black.opacity(0.15)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(){}
    }
}


struct ShareSheet: UIViewControllerRepresentable {
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil // Можно добавить кастомные действия, если нужно
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil // Можно исключить системные действия
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        // controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
        //     // Здесь можно добавить код, который выполнится после закрытия листа
        //     print("Share sheet completed: \(completed), activity: \(activityType?.rawValue ?? "none")")
        // }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Обычно оставляем пустым для этого случая
    }
}
