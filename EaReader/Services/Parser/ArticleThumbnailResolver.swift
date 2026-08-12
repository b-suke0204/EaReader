//
//  ArticleThumbnailResolver.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation
import Combine

// 記事URLごとのog:image解決結果をアプリ実行中だけキャッシュする。
// 同じ記事が複数のフィード/画面から参照されても再取得しないようにするため。
actor ArticleThumbnailCache {
    static let shared = ArticleThumbnailCache()
    
    // キー: 記事URL、値: 見つかった画像URL(未検出の場合は明示的にnilを保持)
    private var cache: [String: URL?] = [:]
    
    // キャッシュ済みなら true 未検索なら false を返す。見つかった値(nilもありうる)は resolvedValue で返す。
    func lookup(for articleURL: URL) -> (isCached: Bool, resolvedValue: URL?) {
        if let value = cache[articleURL.absoluteString] {
            return (true, value)
        }
        return (false, nil)
    }
    
    func store(_ imageURL: URL?, for articleURL: URL) {
        cache[articleURL.absoluteString] = imageURL
    }
}

enum ArticleThumbnailResolver {
    // 記事ページを取得し、og:image / twitter:image をサムネイルURLとして返す。
    // 見つからない場合、あるいは取得に失敗した場合は nil を返す(キャッシュにも記録する)。
    static func resolveThumbnail(for articleURL: URL) -> AnyPublisher<URL?, Never> {
        FeedFetcher.fetchHTML(url: articleURL, timeout: 8)
            .map { result in extractImageURL(fromHTML: result.html, baseURL: result.finalURL) }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    static func extractImageURL(fromHTML html: String, baseURL: URL) -> URL? {
        let head = String(html.prefix(200_000)) // og:imageは通常<head>内。巨大なHTML全文の走査を避ける。
        for property in ["og:image:secure_url", "og:image:url", "og:image", "twitter:image"] {
            if let content = metaContent(forProperty: property, in: head),
               let url = URL.makeAbsolute(TextSanitizer.decodeHTMLEntities(content), relativeTo: baseURL) {
                return url
            }
        }
        return nil
    }
    
    private static func metaContent(forProperty property: String, in html: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: property)
        let patterns = [
            "<meta\\b[^>]*(?:property|name)\\s*=\\s*[\"']\(escaped)[\"'][^>]*content\\s*=\\s*[\"']([^\"']*)[\"']",
            "<meta\\b[^>]*content\\s*=\\s*[\"']([^\"']*)[\"'][^>]*(?:property|name)\\s*=\\s*[\"']\(escaped)[\"']"
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let ns = html as NSString
            if let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: ns.length)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound {
                    return ns.substring(with: range)
                }
            }
        }
        return nil
    }
}
