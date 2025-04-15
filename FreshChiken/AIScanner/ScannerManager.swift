//
//  ScannerManager.swift
//  FreshChiken
//
//  Created by D K on 08.04.2025.
//

import Foundation
import UIKit

class GeminiService {

    private let apiKey = "AIzaSyDeKZRT21892LO6NjoSWdWgq3OfXeiOG1c"
    private let modelName = "gemini-1.5-flash-latest"
    private lazy var baseURL = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"

    enum GeminiError: Error, LocalizedError {
        case invalidUrl
        case invalidImageData
        case networkError(Error)
        case apiError(String)
        case decodingError(Error)
        case noContentGenerated
        case resultJsonDecodingError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidUrl: return "Неверный URL API."
            case .invalidImageData: return "Не удалось преобразовать изображение в данные."
            case .networkError(let underlyingError): return "Ошибка сети: \(underlyingError.localizedDescription)"
            case .apiError(let message): return "Ошибка API Gemini: \(message)"
            case .decodingError(let underlyingError): return "Ошибка декодирования ответа API: \(underlyingError.localizedDescription)"
            case .noContentGenerated: return "Модель не сгенерировала контент."
            case .resultJsonDecodingError(let underlyingError): return "Ошибка декодирования JSON с результатом: \(underlyingError.localizedDescription)"
            }
        }
    }

    // --- Структуры для запроса к API Gemini ---
    struct GeminiRequest: Encodable {
        let contents: [Content]
        // Можно добавить generationConfig для настройки ответа
    }

    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String?
        let inlineData: InlineData?

        // Инициализаторы для удобства
        init(text: String) {
            self.text = text
            self.inlineData = nil
        }
        init(imageData: Data, mimeType: String = "image/jpeg") {
            self.text = nil
            self.inlineData = InlineData(mimeType: mimeType, data: imageData.base64EncodedString())
        }
    }

    struct InlineData: Encodable {
        let mimeType: String
        let data: String // base64 encoded image
    }

    // --- Структуры для ответа от API Gemini ---
    struct GeminiResponse: Decodable {
        let candidates: [Candidate]?
        let promptFeedback: PromptFeedback? // Полезно для отладки блокировок
    }

    struct Candidate: Decodable {
        let content: ResponseContent?
        let finishReason: String?
        let safetyRatings: [SafetyRating]?
    }

    struct ResponseContent: Decodable {
        let parts: [ResponsePart]?
        let role: String?
    }

    struct ResponsePart: Decodable {
        let text: String?
        // Могут быть и другие типы частей, но нам нужен text
    }
    
    struct PromptFeedback: Decodable {
        let blockReason: String?
        let safetyRatings: [SafetyRating]?
    }

    struct SafetyRating: Decodable {
        let category: String
        let probability: String
    }
    // --- Конец структур для API ---


    func analyzeImage(_ image: UIImage) async -> Result<ProductInfo, GeminiError> {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            return .failure(.invalidUrl)
        }

        // 1. Подготовить данные изображения (сжать и конвертировать в Base64)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return .failure(.invalidImageData)
        }

        // 2. Создать промпт
        let promptText = """
        Analyze the food product label image provided.
        Extract the product name and the expiration date.
        If the text on the label is in Russian or Ukrainian, translate the product name into English. Use the most common English name for the product.
        Format the expiration date strictly as YYYY-MM-DD. If you find a date like "DD.MM.YYYY" or "MM/DD/YY", convert it to YYYY-MM-DD. If only month and year are present (e.g., "DEC 2024"), represent it as the last day of that month (e.g., "2024-12-31"). If the exact day cannot be determined but month and year are clear, use the last day of the month.
        Return the result ONLY as a valid JSON object containing two keys:
        1. "product_name": A string with the product name in English. If the name cannot be determined, use the string "Unknown Product".
        2. "expiration_date": A string with the date in YYYY-MM-DD format, or null if the expiration date cannot be found or reliably parsed.

        Example of expected JSON output:
        {"product_name": "Sour Cream", "expiration_date": "2024-12-31"}

        Another example if date is not found:
        {"product_name": "Milk", "expiration_date": null}

        Strictly adhere to this JSON format in your response. Do not add any text before or after the JSON object.
        """

        // 3. Сформировать тело запроса
        let requestPayload = GeminiRequest(
            contents: [
                Content(parts: [
                    Part(text: promptText),
                    Part(imageData: imageData)
                ])
            ]
        )

        // 4. Создать URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestPayload)
        } catch {
            return .failure(.decodingError(error)) // Ошибка кодирования запроса
        }

        // 5. Выполнить запрос
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Проверка HTTP статуса
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                // Попытаемся прочитать тело ошибки от API
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                return .failure(.apiError("HTTP Status \(statusCode). Body: \(errorBody)"))
            }

            // 6. Декодировать основной ответ Gemini
            let geminiResponse: GeminiResponse
            do {
                 geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            } catch {
                 return .failure(.decodingError(error))
            }
            
            // Проверим не заблокирован ли ответ
            if let feedback = geminiResponse.promptFeedback, let reason = feedback.blockReason {
                return .failure(.apiError("Запрос заблокирован по причине: \(reason)"))
            }


            // 7. Извлечь текстовую часть ответа (ожидаем там наш JSON)
            guard let candidate = geminiResponse.candidates?.first,
                  let responsePart = candidate.content?.parts?.first,
                  let resultText = responsePart.text else {
                return .failure(.noContentGenerated)
            }

            // 8. Очистить и декодировать JSON *внутри* текстового ответа
            print("--- Gemini Raw Text Response ---")
            print(resultText)
            print("-----------------------------")

            // --- Начало изменений ---
            // Удаляем Markdown форматирование (```json ... ```) и лишние пробелы/переносы
            var cleanedText = resultText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if cleanedText.hasPrefix("```json") {
                cleanedText = String(cleanedText.dropFirst(7)) // Удаляем ```json\n
            } else if cleanedText.hasPrefix("```") {
                 cleanedText = String(cleanedText.dropFirst(3)) // Удаляем ```
            }
            
            if cleanedText.hasSuffix("```") {
                cleanedText = String(cleanedText.dropLast(3)) // Удаляем ```
            }
            
            // Еще раз очищаем пробелы/переносы после удаления маркеров
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)

            print("--- Cleaned Text for JSON Parsing ---")
            print(cleanedText)
            print("-----------------------------------")

            guard let resultData = cleanedText.data(using: .utf8) else {
                 return .failure(.resultJsonDecodingError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось конвертировать ОЧИЩЕННЫЙ текст ответа в данные UTF-8"])))
            }
            // --- Конец изменений ---

            let productResponse: GeminiProductResponse
            do {
                productResponse = try JSONDecoder().decode(GeminiProductResponse.self, from: resultData) // Используем resultData из cleanedText
            } catch {
                // Если декодирование не удалось, возможно модель вернула не JSON или очистка не помогла
                 print("Ошибка декодирования ОЧИЩЕННОГО JSON результата: \(error)")
                 print("Очищенный текст, который не удалось декодировать: \(cleanedText)") // Логируем очищенный текст
                 print("Оригинальный текст от модели: \(resultText)") // Логируем оригинальный для сравнения
                 return .failure(.resultJsonDecodingError(error))
            }


            // 9. Создать финальный объект ProductInfo
            let finalProductInfo = ProductInfo(
                productName: productResponse.product_name,
                expirationDate: productResponse.expiration_date // он уже опциональный
            )

            return .success(finalProductInfo)

        } catch {
            return .failure(.networkError(error))
        }
    }
}
