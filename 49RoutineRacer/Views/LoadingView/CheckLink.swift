//
//  CheckLink.swift
//  BubblyBass
//
//  Created by Роман Главацкий on 26.10.2025.
//

import Foundation

class CheckURLService {
    
    // MARK: - Shared Instance
    static let shared = CheckURLService()
    private var currentTask: URLSessionDataTask?
    private var isCompletionCalled = false
    private var fallbackWorkItem: DispatchWorkItem?
    
    // MARK: - Configuration
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 8.0
        configuration.timeoutIntervalForResource = 12.0
        configuration.waitsForConnectivity = false // Убрано для предотвращения зависания
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Public Methods
    
    static func checkURLStatus(urlString: String, completion: @escaping (Bool) -> Void) {
        shared.performCheck(urlString: urlString, completion: completion)
    }
    
    // Альтернативный метод с URL
    static func checkURLStatus(url: URL, completion: @escaping (Bool) -> Void) {
        shared.performCheck(url: url, completion: completion)
    }
    
    func cancelCurrentCheck() {
        fallbackWorkItem?.cancel()
        fallbackWorkItem = nil
        currentTask?.cancel()
        currentTask = nil
        isCompletionCalled = false
    }
    
    // MARK: - Private Methods
    
    private func performCheck(urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            print("❌ CheckURLService: Invalid URL string: \(urlString)")
            DispatchQueue.main.async { completion(false) }
            return
        }
        performCheck(url: url, completion: completion)
    }
    
    private func performCheck(url: URL, completion: @escaping (Bool) -> Void) {
        cancelCurrentCheck()
        isCompletionCalled = false
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10.0
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        print("🔍 CheckURLService: Checking URL: \(url.absoluteString)")
        
        // Создаем защищенный completion handler
        let safeCompletion: (Bool) -> Void = { [weak self] result in
            guard let self = self else { return }
            
            // Защита от повторного вызова
            guard !self.isCompletionCalled else {
                print("⚠️ CheckURLService: Completion already called, ignoring duplicate call")
                return
            }
            
            self.isCompletionCalled = true
            self.fallbackWorkItem?.cancel()
            self.fallbackWorkItem = nil
            self.currentTask = nil
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Обрабатываем ошибки
            if let error = error {
                let errorMessage: String
                let shouldComplete: Bool
                
                switch (error as NSError).code {
                case NSURLErrorTimedOut:
                    errorMessage = "Request timed out"
                    shouldComplete = true
                case NSURLErrorNotConnectedToInternet:
                    errorMessage = "No internet connection"
                    shouldComplete = true
                case NSURLErrorNetworkConnectionLost:
                    errorMessage = "Network connection lost"
                    shouldComplete = true
                case NSURLErrorCancelled:
                    print("ℹ️ CheckURLService: Request cancelled")
                    return // Не вызываем completion для отмененных запросов
                default:
                    errorMessage = error.localizedDescription
                    shouldComplete = true
                }
                
                if shouldComplete {
                    print("❌ CheckURLService: Error: \(errorMessage)")
                    safeCompletion(false)
                }
                return
            }
            
            // Проверяем HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ CheckURLService: No HTTP response")
                safeCompletion(false)
                return
            }
            
            let statusCode = httpResponse.statusCode
            print("ℹ️ CheckURLService: Status code: \(statusCode) for URL: \(url.absoluteString)")
            
            // Более гибкая проверка статус кода
            let isValidResponse: Bool
            
            switch statusCode {
            case 200..<300:
                // Успешные коды (200-299)
                isValidResponse = true
            case 404:
                // Страница не найдена
                isValidResponse = false
            case 403, 401:
                // Доступ запрещен/неавторизован
                isValidResponse = false
            case 500..<600:
                // Ошибки сервера
                isValidResponse = false
            default:
                // Все остальные коды считаем невалидными
                isValidResponse = false
            }
            
            safeCompletion(isValidResponse)
        }
        
        currentTask = task
        
        // Fallback таймаут с улучшенной логикой
        let fallbackWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if !self.isCompletionCalled {
                print("⚠️ CheckURLService: Forcing timeout completion for URL: \(url.absoluteString)")
                self.currentTask?.cancel()
                safeCompletion(false)
            }
        }
        
        self.fallbackWorkItem = fallbackWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0, execute: fallbackWorkItem)
        
        task.resume()
    }
    
    deinit {
        cancelCurrentCheck()
        session.invalidateAndCancel()
        print("♻️ CheckURLService deinitialized")
    }
}
