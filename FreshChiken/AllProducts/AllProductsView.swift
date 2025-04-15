//
//  AllProductsView.swift
//  FreshChiken
//
//  Created by D K on 07.04.2025.
//

import SwiftUI
import RealmSwift


struct AllProductsView: View {

    @ObservedResults(StoredProduct.self, sortDescriptor: SortDescriptor(keyPath: "expirationDate", ascending: true)) var allProducts

    @State private var selectedStatus: ProductStatus = .fresh
    @State private var isAddShown = false
    private var filteredProducts: Results<StoredProduct> {
       
        
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let warningStartDate = calendar.date(byAdding: .day, value: 4, to: todayStart)!

        switch selectedStatus {
        case .fresh:
             return allProducts.where { $0.expirationDate >= warningStartDate }
        case .warning:
             return allProducts.where { $0.expirationDate >= todayStart && $0.expirationDate < warningStartDate }
        case .spoiled:
            return allProducts.where { $0.expirationDate < todayStart }
        }
    }

    var sideMenu: () -> ()

    var body: some View {
        ZStack {
             Image("back") // Убедитесь, что ассет есть
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
                                
                                Text("All Products")
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
                            .padding(.bottom)
                
                HStack(spacing: 10) {
                     ForEach(ProductStatus.allCases) { status in
                         Button {
                             withAnimation(.easeInOut(duration: 0.2)) {
                                 selectedStatus = status
                             }
                         } label: {
                             HStack(spacing: 5) {
                                 Image(status.iconName) // Иконка статуса
                                     .resizable()
                                     .scaledToFit()
                                     .frame(width: 18, height: 18)

                                 Text(status.rawValue) // Название статуса
                                     .font(.caption)
                                     .fontWeight(.medium)
                                     .lineLimit(1)
                                     .minimumScaleFactor(0.8)
                             }
                             .padding(.vertical, 8)
                             .padding(.horizontal, 12)
                             .frame(minWidth: 0)
                              // Используем оранжевый цвет для кнопок
                             .background(
                                 Color.orange.opacity(selectedStatus == status ? 1.0 : 0.6)
                             )
                             .foregroundColor(.white)
                             .cornerRadius(24)
                             .shadow(color: .black.opacity(selectedStatus == status ? 0.3 : 0.1),
                                     radius: selectedStatus == status ? 4 : 2, y: 2)
                         }
                     }
                 }
                 .padding(.horizontal)
                 .padding(.bottom, 15)


                ScrollView {
                    VStack(spacing: 10) {
                        // --- ИЗМЕНЕНО: Используем filteredProducts ---
                        if filteredProducts.isEmpty {
                            Text("No products in this category.")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 50)
                        } else {
                            // Используем filteredProducts, которые уже типа Results<StoredProduct> или [StoredProduct]
                            ForEach(filteredProducts) { product in
                                // Передаем объект StoredProduct и замыкание для удаления
                                ProductRowView(product: product) {
                                    // Вызываем функцию удаления при нажатии на 'x'
                                    deleteProduct(product) // Передаем сам объект
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 5)
                }

                Spacer()
            }
        }
        .overlay {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button {
                        isAddShown.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.yellow, .customOrange], startPoint: .top, endPoint: .bottom))
                                .frame(width: 50, height: 50)
                            
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 15)
                    .padding(.trailing, 15)
                }
            }
        }
        .fullScreenCover(isPresented: $isAddShown) {
            AddProductView() {
               
            }
        }
    }

    // --- ИЗМЕНЕНО: Функция удаления ---
    private func deleteProduct(_ product: StoredProduct) {
         // 1. Отменяем уведомление, если оно было запланировано
        if let notificationId = product.notificationId {
             NotificationManager.shared.cancelNotification(identifier: notificationId)
        }

         // 2. Находим объект в Realm для удаления.
         // Важно: используем ID продукта, чтобы получить актуальную ссылку на объект в текущем потоке/Realm инстансе.
         // Пытаемся получить объект через его первичный ключ.
         guard let realm = try? Realm() else { // Получаем инстанс Realm
              print("Error: Could not access Realm for deletion.")
              // Можно показать ошибку пользователю
              return
         }

         guard let productToDelete = realm.object(ofType: StoredProduct.self, forPrimaryKey: product.id) else {
              print("Error: Product with ID \(product.id) not found in Realm for deletion.")
              // Объект мог быть уже удален
              return
         }


         // 3. Удаляем объект из Realm в транзакции записи
         do {
              try realm.write {
                   realm.delete(productToDelete)
                   print("Successfully deleted product: \(product.name)")
              }
         } catch {
              print("Error deleting product \(product.name) from Realm: \(error.localizedDescription)")
              // Можно показать ошибку пользователю
         }

         // --- УДАЛЕН НЕПРАВИЛЬНЫЙ БЛОК ---
         // Блок с $allProducts.remove(at: index) был удален,
         // так как удаление происходит через realm.delete(object),
         // а @ObservedResults автоматически обновит UI.
    }
}

// --- Preview Provider ---
struct AllProductsView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview может потребовать настройки для работы с Realm
        // Либо используйте #if DEBUG с sample data, не основанным на Realm
        AllProductsView() { print("Side Menu Tapped") }
            .preferredColorScheme(.dark)
            // .environment(\.realm, ...) // Можно подсунуть тестовый Realm in-memory
    }
}





enum ProductStatus: String, CaseIterable, Identifiable {
    case fresh = "Fresh"
    case warning = "About to spoil"
    case spoiled = "Spoiled"

    var id: String { self.rawValue }

    var iconName: String {
        switch self {
        case .fresh: return "clock1"
        case .warning: return "clock2"
        case .spoiled: return "clock3"
        }
    }


    var buttonColor: Color {
        return .orange
    }
}

// Struct for Product Data
struct Product: Identifiable {
    let id = UUID()
    var title: String
    var tag: String
    var dateString: String
    var status: ProductStatus
    var imageName: String?
}



struct ProductRowView: View {
    // --- ИЗМЕНЕНО: Принимаем StoredProduct ---
    let product: StoredProduct
    let onDelete: () -> Void

    // ... (все константы цветов остаются) ...

    // --- NEW: Форматтер для даты в строке ---
    private let rowDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy" // Формат 01.01.25
        return formatter
    }()

    var body: some View {
        HStack(spacing: 0) {

            // --- ИЗМЕНЕНО: Отображение изображения из Data ---
            if let imageData = product.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill() // Или .scaledToFit()
                    .frame(width: 45, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 5)) // Скругляем углы
                    .padding(.horizontal, 10)
            } else {
                // Плейсхолдер, если изображения нет
                Image(systemName: "photo") // Или ваш ассет
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 45, height: 45)
                    .background(Color.gray.opacity(0.3)) // Фон для плейсхолдера
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.horizontal, 10)
            }
            // --- Конец изменений изображения ---

            VStack(alignment: .leading, spacing: 2) {
                // --- ИЗМЕНЕНО: Используем поля из StoredProduct ---
                Text(product.name) // Имя из Realm
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                // Убрал product.tag, так как его нет в StoredProduct
                // Можно добавить поле "notes" или "tags" в StoredProduct, если нужно
                Text("Added: \(product.addedDate, style: .date)") // Показываем дату добавления
                   .font(.caption)
                   .foregroundColor(.gray)
                   .lineLimit(1)
            }

            Spacer()

            // --- ИЗМЕНЕНО: Форматируем дату из StoredProduct ---
            Text(rowDateFormatter.string(from: product.expirationDate))
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 10)

            // --- ИЗМЕНЕНО: Получаем статус динамически ---
            Image(product.status.iconName) // Используем вычисляемый статус
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(.horizontal, 8)

            Rectangle()
                .fill(.white)
                 .frame(width: 1, height: 30)
                 .padding(.horizontal, 5)

            // Кнопка удаления (действие передается из AllProductsView)
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 40, height: 45)
                    .contentShape(Rectangle())
            }

        }
        .padding(.vertical, 8)
        .background(.softBlue)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.gray, lineWidth: 1)
        )
    }
}

//#Preview {
//    ProductRowView(product: StoredProduct(name: "Hahaha", expirationDate: Date(), imageData: nil), onDelete: {})
//}
