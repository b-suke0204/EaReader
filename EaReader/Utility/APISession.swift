//
//  APISession.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/13.
//

import Foundation
import ComposableArchitecture

protocol AnyJSONType: Codable {}  // 26.08.12 B 任意のJSONを使用可能にする

// 26.08.12 B HTTPメソッド種別
enum HTTPMethod: String {
    case POST
    case GET
    case PATCH
    case PUT
    case DELETE
}

// 26.08.12 B サーバーエラー種別
nonisolated enum SessionErrorType: Equatable, Error {
    case success
    case error(message: String)
}

// 26.08.12 B レスポンスエラーメッセージ
nonisolated struct ErrorResponse: AnyJSONType {
    var message: String
}

final class APISession {
    
    // 26.08.12 B 1件取得
    static func fetch<T: AnyJSONType>(
        from urlString: String,
        httpMethod: HTTPMethod = .GET
    ) async -> Result<T, SessionErrorType> {
        guard let url = URL(string: urlString) else {
            return .failure(.error(message: "URLの取得に失敗しました"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse {
                let errorType = checkStatusCode(from: response, data: data)
                if errorType != .success {
                    return .failure(errorType)
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let jsonData = try decoder.decode(T.self, from: data)
            return .success(jsonData)
        } catch {
            return .failure(.error(message: error.localizedDescription))
        }
    }
    
    // 26.08.12 B 複数取得
    static func fetchAll<T: AnyJSONType>(
        from urlString: String,
        httpMethod: HTTPMethod = .GET
    ) async -> Result<[T], SessionErrorType> {
        guard let url = URL(string: urlString) else {
            return .failure(.error(message: "URLの取得に失敗しました"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let response = response as? HTTPURLResponse {
                let errorType = checkStatusCode(from: response, data: data)
                if errorType != .success {
                    return .failure(errorType)
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let jsonData = try decoder.decode([T].self, from: data)
            return .success(jsonData)
        } catch {
            return .failure(
                .error(message: error.localizedDescription)
            )
        }
    }
    
    // 26.08.12 B 追加、更新、削除
    @discardableResult
    static func connect<T: AnyJSONType>(
        from urlString: String,
        data: Data,
        httpMethod: HTTPMethod = .POST
    ) async -> Result<T, SessionErrorType> {
        guard let url = URL(string: urlString) else {
            return .failure(.error(message: "URLの取得に失敗しました"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            if let response = response as? HTTPURLResponse {
                let errorType = checkStatusCode(
                    from: response,
                    data: responseData
                )
                
                if errorType != .success {
                    return .failure(errorType)
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let jsonData = try decoder.decode(T.self, from: responseData)
            return .success(jsonData)
        } catch {
            print("JSONのデコードまたは通信に失敗しました: \(error)")
            return .failure(.error(message: error.localizedDescription))
        }
    }
    
    // 26.08.12 B ステータスコード確認
    nonisolated private static func checkStatusCode(
        from response: HTTPURLResponse,
        data: Data?
    ) -> SessionErrorType {
        
        let statusCode = response.statusCode
        switch statusCode {
        case 200...299:
            print("正常: \(statusCode)")
            return .success
        case 404:
            print("該当データがありませんでした")
            return getErrorMessage(from: data)
        default:
            print("原因不明のエラー: \(statusCode)")
            return getErrorMessage(from: data)
        }
    }
    
    nonisolated private static func getErrorMessage(from data: Data?) -> SessionErrorType {
        guard let responseData = data,
              let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: responseData)
        else {
            return .error(message: "リスポンスの取得に失敗しました")
        }
        return .error(message: errorResponse.message)
    }
    
    // 26.08.12 B JSONにエンコード
    static func jsonEncode<T: AnyJSONType>(from jsonData: T) -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let json = try encoder.encode(jsonData)
            return json
        } catch {
            print("エラー: \(error)")
            return nil
        }
    }
}
