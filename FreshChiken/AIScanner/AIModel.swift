//
//  AIModel.swift
//  FreshChiken
//
//  Created by D K on 08.04.2025.
//

import Foundation

// Структура для хранения распознанной информации
struct ProductInfo: Identifiable {
    let id = UUID()
    let productName: String
    let expirationDate: String? // Может быть nil, если дата не найдена/не распознана
}

// Структура для декодирования JSON ответа, который *внутри* ответа Gemini
struct GeminiProductResponse: Decodable {
    let product_name: String
    let expiration_date: String? // Ожидаем строку или null
}
