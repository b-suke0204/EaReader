//
//  TextSanitizer.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation

// 文字列を有効なものに変換する処理
enum TextSanitizer {
    private static let namedEntities: [String: String] = [
        "&amp;": "&",
        "&lt;": "<",
        "&gt;": ">",
        "&quot;": "\"",
        "&#39;": "'", 
        "&apos;": "'",
        "&nbsp;": " "
    ]
    
    private static let numericEntityRegex = try? NSRegularExpression(pattern: "&#(x?[0-9A-Fa-f]+);")
    private static let tagRegex = try? NSRegularExpression(pattern: "<[^>]+>")
    
    static func decodeHTMLEntities(_ input: String) -> String {
        var result = input
        for (entity, replacement) in namedEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        guard let regex = numericEntityRegex else { return result }
        let ns = result as NSString
        let matches = regex.matches(in: result, range: NSRange(location: 0, length: ns.length))
        for match in matches.reversed() {
            let codeRange = match.range(at: 1)
            let codeString = ns.substring(with: codeRange)
            let scalarValue: UInt32?
            if codeString.lowercased().hasPrefix("x") {
                scalarValue = UInt32(codeString.dropFirst(), radix: 16)
            } else {
                scalarValue = UInt32(codeString)
            }
            if let scalarValue, let scalar = Unicode.Scalar(scalarValue) {
                result = (result as NSString).replacingCharacters(in: match.range, with: String(Character(scalar)))
            }
        }
        return result
    }
    
    static func stripHTMLTags(_ input: String) -> String {
        guard let regex = tagRegex else { return input }
        let ns = input as NSString
        let range = NSRange(location: 0, length: ns.length)
        let stripped = regex.stringByReplacingMatches(in: input, range: range, withTemplate: "")
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func cleanSummary(_ input: String) -> String {
        stripHTMLTags(decodeHTMLEntities(input))
    }
    
    static func cleanTitle(_ input: String) -> String {
        decodeHTMLEntities(input).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
