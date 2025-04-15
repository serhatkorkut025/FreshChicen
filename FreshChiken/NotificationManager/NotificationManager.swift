//
//  NotificationManager.swift
//  FreshChiken
//
//  Created by D K on 08.04.2025.
//

// NotificationManager.swift
import Foundation
import UserNotifications
import RealmSwift // Импортируем Realm для доступа внутри менеджера

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // --- ИЗМЕНЕНО: Принимаем ID и данные, а не объект ---
    func scheduleNotification(productID: UUID, productName: String, expirationDate: Date) {

        // 1. Отменяем предыдущее уведомление (если оно было)
        // Нам нужно сначала получить объект, чтобы узнать старый ID уведомления
        // Делаем это в главном потоке, чтобы безопасно читать из Realm
        DispatchQueue.main.async { // Переключаемся в главный поток для чтения из Realm
            guard let realm = try? Realm() else {
                 print("Error accessing Realm on main thread to check for existing notification.")
                 return // Не можем продолжить без Realm
            }
            var existingNotificationId: String? = nil
            if let product = realm.object(ofType: StoredProduct.self, forPrimaryKey: productID) {
                 existingNotificationId = product.notificationId
            }

             // Теперь, когда мы в главном потоке и прочитали ID, выполняем остальную логику
             // (отмена старого и планирование нового)
            
            if let oldId = existingNotificationId {
                 self.cancelNotification(identifier: oldId) // Отменяем старое
            }

            // 2. Проверяем, что дата еще не прошла
            guard expirationDate > Date() else {
                print("Expiration date is in the past. No notification scheduled for \(productName).")
                return
            }

            // 3. Создаем контент (используем переданные данные)
            let content = UNMutableNotificationContent()
            content.title = "Срок годности истекает!"
            content.body = "Продукт \"\(productName)\" скоро испортится." // Используем productName
            content.sound = UNNotificationSound.default

            // 4. Создаем триггер (используем переданные данные)
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: expirationDate) // Используем expirationDate
            dateComponents.hour = 10
            dateComponents.minute = 0

            guard let triggerDate = Calendar.current.date(from: dateComponents), triggerDate > Date() else {
                  print("Trigger time is in the past. No notification scheduled for \(productName).")
                  return
             }
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            // 5. Создаем уникальный ID для запроса (используем переданный ID продукта)
            let notificationIdentifier = productID.uuidString // Используем productID

            // 6. Создаем и добавляем запрос
            let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                // --- ВАЖНО: Completion Handler ---
                // Он выполняется в фоновом потоке!
                if let error = error {
                    print("Error scheduling notification for \(productName): \(error.localizedDescription)")
                } else {
                    print("Successfully scheduled notification for \(productName) with ID: \(notificationIdentifier)")
                    // --- ОБНОВЛЕНИЕ Realm в ГЛАВНОМ потоке ---
                    DispatchQueue.main.async { // Переключаемся в главный поток
                        guard let realm = try? Realm() else {
                             print("Error accessing Realm on main thread to save notification ID.")
                             return
                        }
                         // Получаем объект по ID СНОВА, но уже в главном потоке
                        guard let productToUpdate = realm.object(ofType: StoredProduct.self, forPrimaryKey: productID) else {
                             print("Product \(productID) not found in Realm to save notification ID (maybe deleted?).")
                             return
                        }
                         // Выполняем запись в главном потоке
                        do {
                            try realm.write {
                                 productToUpdate.notificationId = notificationIdentifier // Обновляем ID
                            }
                            print("Saved notification ID \(notificationIdentifier) to Realm for product \(productName)")
                        } catch {
                             print("Error saving notification ID to Realm for product \(productName): \(error.localizedDescription)")
                        }
                    }
                    // --- Конец обновления Realm ---
                }
            } // Конец completion handler UNUserNotificationCenter
        } // Конец DispatchQueue.main.async для чтения старого ID
    }

    func cancelNotification(identifier: String) {
        // Эту операцию можно безопасно вызывать из любого потока
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Requested cancellation for notification ID: \(identifier)")
    }
}
