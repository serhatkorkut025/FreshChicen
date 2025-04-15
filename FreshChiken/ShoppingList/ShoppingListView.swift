//
//  ShoppingListView.swift
//  FreshChiken
//
//  Created by D K on 07.04.2025.
//


import SwiftUI
import RealmSwift

// MARK: - Realm Model for Shopping Item
class StoredShoppingItem: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var name: String = ""
    @Persisted var count: Int = 1
    @Persisted var isChecked: Bool = false
    @Persisted var addedDate: Date = Date() // Optional: for sorting or other logic

    convenience init(id: UUID = UUID(), name: String, count: Int, isChecked: Bool = false) {
        self.init()
        self.id = id
        self.name = name
        self.count = count
        self.isChecked = isChecked
        self.addedDate = Date()
    }
}

// MARK: - Main Shopping List View
struct ShoppingListView: View {
    @ObservedResults(
        StoredShoppingItem.self,
        // Используем ОДИН SortDescriptor для проверки
        sortDescriptor: SortDescriptor(keyPath: "isChecked", ascending: true)
    ) var shoppingItems // Auto-updating results from Realm

    @State private var showAddItemSheet = false

    var sideMenu: () -> ()

    let screenBackgroundColor = Color(red: 0.2, green: 0.2, blue: 0.35)
    let topButtonColor = Color.orange
    let emptyTextColor = Color.white.opacity(0.9)
    let emptyTextBackgroundColor = Color(red: 0.25, green: 0.28, blue: 0.4).opacity(0.9)
    let mainAddButtonColor = Color(red: 0.3, green: 0.3, blue: 0.5)

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
                    
                    Text("Shopping List")
                        .foregroundStyle(.white).font(.system(size: 28, weight: .black))
                    
                    Spacer()
                    
                    Button {
                        deleteAllItems()
                    } label: {
                        Image("deleteIcon")
                            .resizable().scaledToFit().frame(width: 40, height: 40)
                    }
                    .disabled(shoppingItems.isEmpty)
                    .opacity(shoppingItems.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal)
                
               

                if shoppingItems.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                         Text("Your shopping list is empty.")
                         Text("Add something!")
                    }
                    .font(.headline)
                    .foregroundColor(emptyTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 30).padding(.horizontal, 40)
                    .background(emptyTextBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                    .padding(.horizontal, 40)
                    Spacer()
                    Spacer()

                } else {
                    // --- ИЗМЕНЕНО: Явно создаем Array из filter ---
                    let uncheckedItemsArray = Array(shoppingItems.filter { !$0.isChecked })
                    let checkedItemsArray = Array(shoppingItems.filter { $0.isChecked })
                    // --- Конец изменений ---

                    List {
                        Section {
                            // Используем Array, созданный выше
                            ForEach(uncheckedItemsArray) { item in
                                ShoppingItemRow(item: item)
                                    .listRowSeparatorTint(.white.opacity(0.2))
                                    .listRowBackground(Color.clear)
                            }
                        }

                        if !checkedItemsArray.isEmpty {
                             Section(header: Text("Completed").foregroundColor(.white.opacity(0.6)).padding(.leading, -8)) {
                                // Используем Array, созданный выше
                                ForEach(checkedItemsArray) { item in
                                    ShoppingItemRow(item: item)
                                        .listRowSeparatorTint(.white.opacity(0.2))
                                        .listRowBackground(Color.clear)
                                }
                             }
                        }
                    }
                    // ... (остальная часть List и View без изменений) ...
                    .listStyle(.plain)
                    .background(Color.clear)
                    .padding(.top, 10)
                    .onAppear {
                       UITableView.appearance().backgroundColor = .clear
                       UITableViewCell.appearance().backgroundColor = .clear
                    }
                }

                Button {
                    showAddItemSheet = true
                } label: {
                    Text("Add")
                        .font(.title2).fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(mainAddButtonColor).foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
                        .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                }
                .padding(.horizontal, 40).padding(.bottom, 30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddItemSheetView(isPresented: $showAddItemSheet) { name, count in
                // Add item to Realm here
                addItem(name: name, count: count)
            }
            .presentationDetents([.height(500)])
        }
    }
    
    private func addItem(name: String, count: Int) {
         let newItem = StoredShoppingItem(name: name, count: count)
         do {
              let realm = try Realm()
              try realm.write {
                   realm.add(newItem)
              }
         } catch {
              print("Error adding shopping item to Realm: \(error.localizedDescription)")
              // Handle error appropriately
         }
    }

    private func deleteAllItems() {
         do {
              let realm = try Realm()
              // Fetch all items again specifically for deletion within the transaction
              let allItems = realm.objects(StoredShoppingItem.self)
              if !allItems.isEmpty {
                   try realm.write {
                        realm.delete(allItems)
                   }
              }
         } catch {
              print("Error deleting all shopping items: \(error.localizedDescription)")
              // Handle error appropriately
         }
    }
}

// MARK: - Add Item Sheet View
struct AddItemSheetView: View {
    @State private var itemName: String = ""
    @State private var itemCountString: String = "1" // Default to 1

    @Binding var isPresented: Bool

    let onAdd: (String, Int) -> Void // Closure now passes raw data

    let textFieldBackgroundColor = Color(red: 0.7, green: 0.65, blue: 0.4)
    let buttonColor = Color(red: 0.3, green: 0.3, blue: 0.5)
    let cancelTextColor = Color.white.opacity(0.7)

    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            Image("chick3") // Ensure this asset exists
                .resizable().scaledToFit().frame(width: 100, height: 100)
            
            Text("Add New Item")
                .font(.title2).fontWeight(.semibold).foregroundColor(.white).padding(.top)

            VStack(alignment: .leading, spacing: 5) {
                Text("Name").foregroundColor(.white.opacity(0.8)).padding(.leading, 5)
                TextField("Type here...", text: $itemName)
                    .textFieldStyle(PlainTextFieldStyle()).padding(12)
                    .background(.softBlue).foregroundColor(.white).cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Count").foregroundColor(.white.opacity(0.8)).padding(.leading, 5)
                TextField("1", text: $itemCountString) // Placeholder "1"
                    .keyboardType(.numberPad)
                    .textFieldStyle(PlainTextFieldStyle()).padding(12)
                    .background(.softBlue).foregroundColor(.white).cornerRadius(10)
            }

            HStack(spacing: 15) {
                Button { isPresented = false } label: {
                    Text("Cancel")
                        .font(.headline).padding(.vertical, 12).padding(.horizontal, 30)
                        .foregroundColor(cancelTextColor).background(buttonColor.opacity(0.6))
                        .clipShape(Capsule())
                }

                Button {
                    if let count = Int(itemCountString), !itemName.isEmpty, count > 0 {
                        onAdd(itemName, count) // Pass data back
                        isPresented = false
                    } else {
                        print("Invalid input for shopping item")
                        // Optionally show an alert to the user
                    }
                } label: {
                     Text("Add")
                        .font(.headline).fontWeight(.semibold)
                        .padding(.vertical, 12).padding(.horizontal, 50)
                        .background(buttonColor).foregroundColor(.white).clipShape(Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                 }
                 .disabled(itemName.isEmpty || (Int(itemCountString) ?? 0) <= 0)
            }
            .padding(.top)

            Spacer()
        }
        .padding(.horizontal).padding(.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.2, green: 0.2, blue: 0.35).ignoresSafeArea())
    }
}


// MARK: - Shopping Item Row View
struct ShoppingItemRow: View {
    @ObservedRealmObject var item: StoredShoppingItem // Observe the Realm object directly

    let rowBackgroundColor = Color.clear
    let textColor = Color.white
    let quantityColor = Color.white.opacity(0.8)
    let checkboxBorderColor = Color.white.opacity(0.9)
    let checkmarkColor = Color.green

    var body: some View {
        HStack {
            Text(item.name)
                .font(.title3)
                .foregroundColor(textColor)
                .strikethrough(item.isChecked, color: textColor.opacity(0.7))

            Spacer()

            Text("x\(item.count)")
                .font(.headline)
                .foregroundColor(quantityColor)
                .opacity(item.isChecked ? 0.5 : 1.0)

            Button {
                 // Toggle isChecked directly. @ObservedRealmObject handles the write transaction.
                 // No need for explicit realm.write here.
                 $item.isChecked.wrappedValue.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(checkboxBorderColor, lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .background(item.isChecked ? checkmarkColor.opacity(0.8) : Color.clear)
                        .cornerRadius(5)

                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain) // Prevents the whole row highlighting on tap
            .padding(.leading, 15)
        }
        // Removed padding from here, rely on List's padding or add if needed
        .background(rowBackgroundColor)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView(){}
            .previewDisplayName("Shopping List (Realm)")
            // Note: Previews with Realm might require additional setup
            // or show empty state if no Realm DB is configured for previews.
    }
}


//import SwiftUI
//
//struct ShoppingItem: Identifiable, Equatable {
//    let id = UUID()
//    var name: String
//    var count: Int
//    var isChecked: Bool = false
//}
//
//struct ShoppingListView: View {
//    @State private var shoppingItems: [ShoppingItem] = []
//
//    @State private var showAddItemSheet = false
//    
//    var sideMenu: () -> ()
//
//
//    let screenBackgroundColor = Color(red: 0.2, green: 0.2, blue: 0.35)
//    let topButtonColor = Color.orange
//    let emptyTextColor = Color.white.opacity(0.9)
//    let emptyTextBackgroundColor = Color(red: 0.25, green: 0.28, blue: 0.4).opacity(0.9)
//    let mainAddButtonColor = Color(red: 0.3, green: 0.3, blue: 0.5)
//
//    var body: some View {
//        ZStack {
//            Image("back")
//                 .resizable()
//                 .ignoresSafeArea()
//
//            VStack(spacing: 0) {
//                
//                HStack {
//                    Button {
//                        sideMenu()
//                    } label: {
//                        Image("sideBarIcon")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 40, height: 40)
//                    }
//                    
//                    Spacer()
//                    
//                    Text("Shopping List")
//                        .foregroundStyle(.white)
//                        .font(.system(size: 28, weight: .black))
//                    
//                    Spacer()
//                    
//                    Button {
//                        print("Trash button tapped")
//                        withAnimation {
//                           shoppingItems.removeAll()
//                        }
//                    } label: {
//                         Image("trashIcon")
//                             .resizable().scaledToFit().frame(width: 20, height: 20)
//                             .foregroundColor(.white)
//                             .padding(10)
//                             .background(Circle().fill(topButtonColor).shadow(radius: 3))
//                    }
//                    .disabled(shoppingItems.isEmpty)
//                    .opacity(shoppingItems.isEmpty ? 0.5 : 1.0)
//                }
//                .padding(.horizontal)
//                
//               
//
//                if shoppingItems.isEmpty {
//                    Spacer()
//                    VStack(spacing: 8) {
//                         Text("Your shopping list is empty.")
//                         Text("Add something!")
//                    }
//                    .font(.headline)
//                    .foregroundColor(emptyTextColor)
//                    .multilineTextAlignment(.center)
//                    .padding(.vertical, 30)
//                    .padding(.horizontal, 40)
//                    .background(emptyTextBackgroundColor)
//                    .clipShape(RoundedRectangle(cornerRadius: 25))
//                    .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
//                    .padding(.horizontal, 40)
//
//                    Spacer()
//                    Spacer()
//
//                } else {
//                    ScrollView {
//                        let uncheckedItems = shoppingItems.filter { !$0.isChecked }
//                        let checkedItems = shoppingItems.filter { $0.isChecked }
//
//                        ForEach(uncheckedItems) { item in
//                            if let index = shoppingItems.firstIndex(where: { $0.id == item.id }) {
//                                ShoppingItemRow(item: $shoppingItems[index])
//                                Divider().background(Color.white.opacity(0.2)).padding(.horizontal)
//                            }
//                        }
//
//                        if !checkedItems.isEmpty && !uncheckedItems.isEmpty {
//                            Text("Completed")
//                                .font(.caption)
//                                .foregroundColor(.white.opacity(0.6))
//                                .padding(.top, 15)
//                                .padding(.horizontal)
//                        }
//
//                        ForEach(checkedItems) { item in
//                            if let index = shoppingItems.firstIndex(where: { $0.id == item.id }) {
//                                ShoppingItemRow(item: $shoppingItems[index])
//                                Divider().background(Color.white.opacity(0.2)).padding(.horizontal)
//                            }
//                        }
//                    }
//                    .padding(.top, 10)
//                }
//
//                Button {
//                    showAddItemSheet = true
//                } label: {
//                    Text("Add")
//                        .font(.title2)
//                        .fontWeight(.semibold)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 15)
//                        .background(mainAddButtonColor)
//                        .foregroundColor(.white)
//                        .clipShape(Capsule())
//                        .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
//                        .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
//                }
//                .padding(.horizontal, 40)
//                .padding(.bottom, 30)
//                .transition(.move(edge: .bottom).combined(with: .opacity))
//
//            }
//        }
//        .sheet(isPresented: $showAddItemSheet) {
//            AddItemSheetView(isPresented: $showAddItemSheet) { newItem in
//                withAnimation {
//                    shoppingItems.append(newItem)
//                }
//            }
//            .presentationDetents([.height(500)])
//        }
//    }
//}
//
//// MARK: - Preview
//struct ShoppingListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ShoppingListView(){}
//            .preferredColorScheme(.dark)
//            .previewDisplayName("Empty List")
//
//    }
//}
//
//
//
//
//struct AddItemSheetView: View {
//    @State private var itemName: String = ""
//    @State private var itemCountString: String = ""
//
//    @Binding var isPresented: Bool
//
//    let onAdd: (ShoppingItem) -> Void
//
//    let textFieldBackgroundColor = Color(red: 0.7, green: 0.65, blue: 0.4) // Khaki/Yellowish
//    let buttonColor = Color(red: 0.3, green: 0.3, blue: 0.5) // Darker blue/purple
//    let cancelTextColor = Color.white.opacity(0.7)
//
//    var body: some View {
//        VStack(spacing: 20) {
//            
//            Spacer()
//            
//            Image("chick3")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 100, height: 100)
//            
//            Text("Add New Item") // Optional: Add a title to the sheet
//                .font(.title2)
//                .fontWeight(.semibold)
//                .foregroundColor(.white)
//                .padding(.top)
//
//            // Name Field
//            VStack(alignment: .leading, spacing: 5) {
//                Text("Name")
//                    .foregroundColor(.white.opacity(0.8))
//                    .padding(.leading, 5)
//                TextField("Type here...", text: $itemName)
//                    .textFieldStyle(PlainTextFieldStyle())
//                    .padding(12)
//                    .background(textFieldBackgroundColor)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//
//            // Count Field
//            VStack(alignment: .leading, spacing: 5) {
//                Text("Count")
//                    .foregroundColor(.white.opacity(0.8))
//                    .padding(.leading, 5)
//                TextField("Type here...", text: $itemCountString)
//                    .keyboardType(.numberPad) // Use number pad for count
//                    .textFieldStyle(PlainTextFieldStyle())
//                    .padding(12)
//                    .background(textFieldBackgroundColor)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//
//            // Add / Cancel Buttons
//            HStack(spacing: 15) {
//                 // Cancel Button
//                Button {
//                    isPresented = false // Just dismiss
//                } label: {
//                    Text("Cancel")
//                        .font(.headline)
//                        .padding(.vertical, 12)
//                        .padding(.horizontal, 30)
//                        .foregroundColor(cancelTextColor) // Less prominent color
//                        .background(buttonColor.opacity(0.6)) // Slightly different bg
//                        .clipShape(Capsule())
//                }
//
//                // Add Button
//                Button {
//                    // Basic validation and conversion
//                    if let count = Int(itemCountString), !itemName.isEmpty, count > 0 {
//                        let newItem = ShoppingItem(name: itemName, count: count)
//                        onAdd(newItem) // Call the closure to add the item
//                        isPresented = false // Dismiss the sheet
//                    } else {
//                        // Handle error (e.g., show an alert) - Optional
//                        print("Invalid input")
//                    }
//                } label: {
//                     Text("Add")
//                        .font(.headline)
//                        .fontWeight(.semibold)
//                        .padding(.vertical, 12)
//                        .padding(.horizontal, 50) // Make Add more prominent
//                        .background(buttonColor)
//                        .foregroundColor(.white)
//                        .clipShape(Capsule())
//                        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
//                 }
//                 // Disable Add button if input is not valid
//                 .disabled(itemName.isEmpty || (Int(itemCountString) ?? 0) <= 0)
//            }
//            .padding(.top) // Add space above buttons
//
//            Spacer() // Push content to top
//        }
//        .padding(.horizontal)
//        .padding(.bottom) // Overall padding
//        .frame(maxWidth: .infinity, maxHeight: .infinity) // Take available space
//        .background(Color(red: 0.2, green: 0.2, blue: 0.35).ignoresSafeArea()) // Sheet background
//    }
//}
//
//
//
//struct ShoppingItemRow: View {
//    @Binding var item: ShoppingItem
//
//    let rowBackgroundColor = Color.clear
//    let textColor = Color.white
//    let quantityColor = Color.white.opacity(0.8)
//    let checkboxBorderColor = Color.white.opacity(0.9)
//    let checkmarkColor = Color.green
//
//    var body: some View {
//        HStack {
//            Text(item.name)
//                .font(.title3)
//                .foregroundColor(textColor)
//                .strikethrough(item.isChecked, color: textColor.opacity(0.7))
//
//            Spacer()
//
//            // Quantity (fade if checked)
//            Text("x\(item.count)")
//                .font(.headline)
//                .foregroundColor(quantityColor)
//                .opacity(item.isChecked ? 0.5 : 1.0) // Fade when checked
//
//            // Checkbox Button
//            Button {
//                // Toggle the checked state directly via binding
//                withAnimation(.easeInOut(duration: 0.2)) {
//                    item.isChecked.toggle()
//                }
//            } label: {
//                ZStack {
//                    // Background square
//                    RoundedRectangle(cornerRadius: 5)
//                        .stroke(checkboxBorderColor, lineWidth: 2)
//                        .frame(width: 28, height: 28)
//                        .background(item.isChecked ? checkmarkColor.opacity(0.8) : Color.clear) // Fill when checked
//                        .cornerRadius(5) // Ensure bg corner radius matches stroke
//
//                    // Checkmark icon (only visible when checked)
//                    if item.isChecked {
//                        Image(systemName: "checkmark")
//                            .font(.system(size: 16, weight: .bold))
//                            .foregroundColor(.white)
//                             .transition(.scale.combined(with: .opacity)) // Add animation
//                    }
//                }
//            }
//            .padding(.leading, 15) // Space between quantity and checkbox
//        }
//        .padding(.vertical, 10) // Padding within the row
//        .padding(.horizontal) // Padding for row content edges
//        .background(rowBackgroundColor) // Row background (clear to show main bg)
//        .contentShape(Rectangle()) // Ensures entire row area is tappable if needed later
//    }
//}
