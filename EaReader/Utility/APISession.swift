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
    case error(message: String, code: Int?)
}

// 26.08.12 B レスポンスエラーメッセージ
nonisolated struct ErrorResponse: AnyJSONType {
    var message: String
}

// 26.08.18 B IDのみをJSONで送りたい場合
nonisolated struct JSONID: AnyJSONType {
    var id: Int
}

// 26.08.16 B URL設定 (環境によって変更するために作成)
enum APIEnvironment {
    case ci  // ci環境
    case local  // ローカル環境
    case production  // 本番
    
    func getURL(from environment: Self) -> String {
        switch environment {
        case .ci:
            return "http://127.0.0.1"
        case .local:
            return "http://localhost"
        case .production:
            return "https://example.com"
        }
    }
}

// エラーメッセージ
nonisolated struct ResponseMessage {
    static let fetchURLError: String = "URLの取得に失敗しました"
    static let decodeError: String = "デコードまたは通信に失敗しました"
    static let notFoundError: String = "該当データがありませんでした"
    static let failResponseError: String = "応答がありませんでした"
}

final class APISession {
    
    // 26.08.12 B 1件取得
    static func fetch<T: AnyJSONType>(
        from urlString: String,
        httpMethod: HTTPMethod = .GET
    ) async -> Result<T, SessionErrorType> {
        guard let url = URL(string: urlString) else {
            return .failure(.error(message: ResponseMessage.fetchURLError, code: nil))
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
            print(error.localizedDescription)
            return .failure(.error(message: ResponseMessage.decodeError, code: nil))
        }
    }
    
    // 26.08.12 B 複数取得
    static func fetchAll<T: AnyJSONType>(
        from urlString: String,
        httpMethod: HTTPMethod = .GET
    ) async -> Result<[T], SessionErrorType> {
        guard let url = URL(string: urlString) else {
            return .failure(.error(message: ResponseMessage.fetchURLError, code: nil))
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
            print(error.localizedDescription)
            return .failure(
                .error(message: ResponseMessage.decodeError, code: nil)
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
            return .failure(.error(message: ResponseMessage.fetchURLError, code: nil))
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
            print(error.localizedDescription)
            return .failure(.error(message: ResponseMessage.decodeError, code: nil))
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
            return .error(message: ResponseMessage.notFoundError, code: statusCode)
        default:
            print("原因不明のエラー: \(statusCode)")
            return getErrorMessage(from: data, code: statusCode)
        }
    }
    
    nonisolated private static func getErrorMessage(from data: Data?, code: Int) -> SessionErrorType {
        guard let responseData = data,
              let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: responseData)
        else {
            return .error(message: ResponseMessage.failResponseError, code: code)
        }
        return .error(message: "\(errorResponse.message)", code: code)
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
