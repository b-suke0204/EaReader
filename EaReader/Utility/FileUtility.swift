//
//  FileUtility.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/13.
//

import Foundation

nonisolated struct EaReaderConfig {
    static var deviceId: UUID = UUID()
}

// 26.08.013 B ファイル関係処理
final class FileUtility {
    
    private static let jsonFileName: String = "userData.json"
    
    // テストでデバイス情報ファイル削除
    static func deleteDeviceInfoJSONFile() {
        do {
            if let fileURL = try getTargertURL(for: .applicationSupportDirectory, of: jsonFileName) {
                if FileManager.default.fileExists(atPath: fileURL.path()) {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch {
            print("ファイルの削除に失敗しました: \(error)")
        }
    }
    
    private static func getTargertURL(
        for directory: FileManager.SearchPathDirectory,
        of fileName: String
    ) throws -> URL? {
        do {
            let directory = try FileManager.default.url(
                for: directory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let fileURL = directory.appendingPathComponent(fileName)
            return fileURL
        } catch {
            print("ファイルURLの取得に失敗しました")
            return nil
        }
    }
    
    // デバイス情報保存
    static func saveDeviceInfo(of jsonData: Data) throws {
        do {
            if let fileURL = try getTargertURL(for: .applicationSupportDirectory, of: jsonFileName) {
                try jsonData.write(to: fileURL, options: .atomic)
            }
        } catch {
            print("データの保存に失敗しました: \(error)")
        }
    }
    
    // デバイス情報読み込み
    static func loadDeviceInfo<T: AnyJSONType>() throws -> T? {
        do {
            if let fileURL = try getTargertURL(for: .applicationSupportDirectory, of: jsonFileName) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let data = try Data(contentsOf: fileURL)
                let jsonData = try decoder.decode(T.self, from: data)
                return jsonData
            }
            return nil
        } catch {
            return nil
        }
    }
    
}
