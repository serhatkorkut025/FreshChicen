//
//  StoredProduct.swift
//  FreshChiken
//
//  Created by D K on 08.04.2025.
//

import Foundation
// StoredProduct.swift
import Foundation
import RealmSwift

class StoredProduct: Object, ObjectKeyIdentifiable { // ObjectKeyIdentifiable для ForEach
    @Persisted(primaryKey: true) var id: UUID // Уникальный ID, первичный ключ
    @Persisted var name: String = ""
    @Persisted var expirationDate: Date = Date()
    @Persisted var addedDate: Date = Date() // Дата добавления для возможной сортировки
    @Persisted var imageData: Data? = nil // Опциональные данные изображения
    @Persisted var notificationId: String? = nil // ID запланированного уведомления

    // Convenience initializer (не обязательно, но может быть удобно)
    convenience init(id: UUID = UUID(), name: String, expirationDate: Date, imageData: Data?, notificationId: String? = nil) {
        self.init()
        self.id = id
        self.name = name
        self.expirationDate = expirationDate
        self.addedDate = Date() // Устанавливаем при создании
        self.imageData = imageData
        self.notificationId = notificationId
    }

    // Вычисляемое свойство для статуса (НЕ хранится в Realm)
    var status: ProductStatus {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDay = calendar.startOfDay(for: expirationDate)
        let daysDifference = calendar.dateComponents([.day], from: today, to: expiryDay).day ?? 0

        if daysDifference < 0 {
            return .spoiled
        } else if daysDifference <= 3 { // "Скоро испортится" - за 3 дня или меньше (включая сегодня)
            return .warning
        } else {
            return .fresh
        }
    }
}

