//
//  SideBar.swift
//  FreshChiken
//
//  Created by D K on 07.04.2025.
//

import SwiftUI

enum MenuItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case products = "Products"
    case shoppingList = "Shopping List"
    case achievements = "Achievements"
    case settings = "Settings"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .home: return "homeIcon"
        case .products: return "fridgeIcon"
        case .shoppingList: return "shopIcon"
        case .achievements: return "achIcon"
        case .settings: return "settingsIcon"
        }
        
    }
}

struct SideMenuView: View {
    @Binding var isMenuOpen: Bool
    let onMenuItemSelected: (MenuItem) -> Void
    
    let menuWidth: CGFloat = 270
    let buttonBackgroundColor = Color(red: 0.35, green: 0.38, blue: 0.5)
    let iconSize: CGFloat = 25
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.darkBlue)
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 24,
                        topTrailingRadius: 24
                    )
                )
            
            
            VStack(alignment: .leading, spacing: 0) {
                Image("chick2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                ForEach(MenuItem.allCases) { item in
                    Button {
                        onMenuItemSelected(item)
                        withAnimation {
                            isMenuOpen = false
                        }
                    } label: {
                        HStack(spacing: 15) {
                            Image(item.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: iconSize, height: iconSize)
                            
                            Text(item.rawValue)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal, 20)
                        .background(buttonBackgroundColor)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                }
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .frame(width: menuWidth)
        .offset(x: isMenuOpen ? 0 : -menuWidth)
    }
}


struct MainView: View {
    @State private var isMenuOpen = false
    @State private var selectedMenuItem: MenuItem? = .home
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Image("back")
                    .resizable()
                    .ignoresSafeArea()
                
                switch selectedMenuItem {
                case .home: HomeView() {
                    withAnimation(.easeInOut) {
                        isMenuOpen = true
                    }
                } switchToProducts: {
                    withAnimation {
                        selectedMenuItem = .products
                    }
                } switchToShopping: {
                    withAnimation {
                        selectedMenuItem = .shoppingList
                    }
                }
                case .products:
                    AllProductsView() {
                        withAnimation(.easeInOut) {
                            isMenuOpen = true
                        }
                    }
                case .shoppingList:
                    ShoppingListView {
                        withAnimation(.easeInOut) {
                            isMenuOpen = true
                        }
                    }
                case .achievements:
                    AchievementsView() {
                        withAnimation(.easeInOut) {
                            isMenuOpen = true
                        }
                    }
                case .settings:
                    SettingsView() {
                        withAnimation(.easeInOut) {
                            isMenuOpen = true
                        }
                    }
                    
                case .none:
                    Text("")
                }
                
                if isMenuOpen {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                isMenuOpen = false
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width < -50 {
                                        withAnimation(.easeInOut) {
                                            isMenuOpen = false
                                        }
                                    }
                                }
                        )
                }
                
                SideMenuView(isMenuOpen: $isMenuOpen) { selectedItem in
                    print("Callback received in MainView: \(selectedItem.rawValue)")
                    self.selectedMenuItem = selectedItem
                    
                }
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
    }
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
