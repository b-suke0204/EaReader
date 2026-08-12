//
//  URLExtension.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation

extension URL {
    // フィードやHTMLから取得した文字列をURLに変換する。
    // "//example.com/foo.jpg" のようなプロトコル相対URLには "https:" を補う。
    static func makeAbsolute(_ string: String, relativeTo base: URL? = nil) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("//") {
            return URL(string: "https:\(trimmed)")
        }
        if let url = URL(string: trimmed, relativeTo: base) {
            return url.absoluteURL
        }
        return nil
    }
}




