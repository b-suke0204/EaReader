//
//  RSSDateParser.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation

// RSSの日付を解析するクラス
// RSSとAtom形式で日付の形式が異なるため、ここでどちらの形式でも扱えるようにする
/*
 日付は、Feedごとにバラバラになるため、注意！
 RSS → RFC822
 Atom → ISO8601
*/
final class RSSDateParser {
    
    private static let iso8601Fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    // AIの回答で、どうやら以下の形式で保存されていることが多いらしい
    private static let fallbackFormats = [
        // RFC 822 / RFC 2822
        "EEE, dd MMM yyyy HH:mm:ss ZZZ",
        "EEE, d MMM yyyy HH:mm:ss ZZZ",
        "EEE, dd MMM yyyy HH:mm:ss zzz",
        "EEE, d MMM yyyy HH:mm:ss zzz",
        
        // RFC 822: seconds omitted
        "EEE, dd MMM yyyy HH:mm ZZZ",
        "EEE, d MMM yyyy HH:mm ZZZ",
        "EEE, dd MMM yyyy HH:mm zzz",
        "EEE, d MMM yyyy HH:mm zzz",
        
        // RFC 822 without weekday
        "dd MMM yyyy HH:mm:ss ZZZ",
        "d MMM yyyy HH:mm:ss ZZZ",
        "dd MMM yyyy HH:mm ZZZ",
        "d MMM yyyy HH:mm ZZZ",
        
        // ISO 8601 / RFC 3339
        "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        
        // ISO-like formats seen in feeds
        "yyyy-MM-dd HH:mm:ss Z",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd"
    ]
    
    // DateFormatを取得
    private static let fallbackFormatters: [DateFormatter] = fallbackFormats.map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = format
        return formatter
    }
    
    // Feedの日付を解析
    static func parse(_ rawValue: String) -> Date? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if let date = iso8601Fractional.date(from: trimmed) { return date }
        if let date = iso8601.date(from: trimmed) { return date }
        for formatter in fallbackFormatters {
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }
}
