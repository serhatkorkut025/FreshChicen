//
//  InitialPointView.swift
//  FreshChiken
//
//  Created by D K on 08.04.2025.
//

import SwiftUI

struct InitialPointView: View {
    
    init() {
           requestNotificationPermissions()
       }
    
    var body: some View {
        MainView()
    }
    
    func requestNotificationPermissions() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    print("Notification permission granted.")
                } else if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                } else {
                    print("Notification permission denied.")
                }
            }
        }
}

#Preview {
    InitialPointView()
}
