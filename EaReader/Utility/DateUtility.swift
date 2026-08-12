//
//  DateUtility.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import Foundation

// 26.08.04 B 日付のフォーマットタイプ
enum DateFormatType: String {
    case YMD = "yyyyMMdd"
    case YMDSlash = "yyyy/MM/dd"
    case YMDLine = "yyyy-MM-dd"
    
    case HMS = "HHmmss"
    case HMSColon = "HH:mm:ss"
    case YMDLineHMSColon = "yyyy-MM-dd HH:mm:ss"
}

// 26.08.04 B 日付用ユーティリティ
class DateUtility {
    
    // Dateの文字列取得
    static func getDateString(from date: Date, formatType: DateFormatType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = formatType.rawValue
        formatter.locale = Locale(identifier: "jp_JP")
        let dateString = formatter.string(from: date)
        return dateString
    }
    
}
