//
//  HomeView.swift
//  FreshChiken
//
//  Created by D K on 07.04.2025.
//

import SwiftUI
import RealmSwift


extension View {
    func size() -> CGSize {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .zero
        }
        return window.screen.bounds.size
    }
}

struct HomeView: View {

    // MARK: - Realm Data Access
    @ObservedResults(StoredProduct.self) var products
    @ObservedResults(StoredShoppingItem.self) var shoppingItems

    // MARK: - State
    @State private var isAddProductShown = false
    @State private var isOnboarded = false

    // MARK: - Callbacks
    var sideMenu: () -> ()
    var switchToProducts: () -> ()
    var switchToShopping: () -> ()

    // MARK: - Computed Properties for Counts
    private var totalProductCount: Int {
        products.count
    }

    private var shoppingListCount: Int {
        shoppingItems.count
    }

    private var expiringOrSpoiledCount: Int {
        // Filter products based on their computed status
        products.filter { $0.status == .warning || $0.status == .spoiled }.count
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Image("back")
                .resizable()
                .ignoresSafeArea()

            VStack {
                // MARK: - Header
                HStack {
                    Button(action: sideMenu) {
                        Image("sideBarIcon")
                            .resizable().scaledToFit().frame(width: 40, height: 40)
                    }
                    Spacer()
                    Text("Fresh Chicken") // Consider making this dynamic or a constant app name
                        .foregroundStyle(.white).font(.system(size: 28, weight: .black))
                    Spacer()
                    Image("chick1")
                        .resizable().scaledToFill().frame(width: 50, height: 50)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 10) // Add some padding below header

                // MARK: - Counters Section
                HStack(spacing: 15) {
                    CounterView(
                        count: totalProductCount,
                        label: "Products",
                        iconName: "cube.box.fill",
                        color: .blue
                    )
                    .onTapGesture {
                        switchToProducts()
                    }
                    CounterView(
                        count: shoppingListCount,
                        label: "Shopping",
                        iconName: "cart.fill",
                        color: .green
                    )
                    .onTapGesture {
                        switchToShopping()
                    }
                    CounterView(
                        count: expiringOrSpoiledCount,
                        label: "Expiring",
                        iconName: "exclamationmark.triangle.fill",
                        color: expiringOrSpoiledCount > 0 ? .orange : .gray // Highlight if > 0
                    )
                    .onTapGesture {
                        switchToProducts()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.2)) // Subtle background for counters
                .cornerRadius(15)
                .padding(.horizontal) // Outer padding for the counter section

                // MARK: - Main Content Spacer
                Spacer()

                // MARK: - Monitoring Cloud
                Image("cloudIcon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size().width - 40, height: 180)
                    .opacity(0.8)
                    .colorMultiply(.darkBlue)
                    .overlay {
                        Text("Start monitoring the freshness of your products!")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 70)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 24, weight: .bold))
                            .padding(.bottom, 40)
                    }

                // MARK: - Add Button Spacer
                Spacer()

                // MARK: - Add Product Button
                RoundedButton(width: 200, height: 60, text: "Add Product") {
                    isAddProductShown.toggle()
                }
                .padding(.bottom) // Add padding below button

                // MARK: - Bottom Spacer
                Spacer()

            } // End Main VStack
        } // End ZStack
        .fullScreenCover(isPresented: $isAddProductShown) {
            AddProductView() {
                switchToProducts()
            }
        }
        .fullScreenCover(isPresented: $isOnboarded) {
            OnboardingView()
        }
        .onAppear {
            if !UserDefaults.standard.bool(forKey: "onb") {
                UserDefaults.standard.setValue(true, forKey: "onb")
                isOnboarded = true
            }
        }
    } // End body
}

// MARK: - Counter Subview
struct CounterView: View {
    let count: Int
    let label: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .shadow(radius: 1)

            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .minimumScaleFactor(0.7) 
                .lineLimit(1)

            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}



#Preview {
    HomeView(){} switchToProducts: {} switchToShopping: {}
}
