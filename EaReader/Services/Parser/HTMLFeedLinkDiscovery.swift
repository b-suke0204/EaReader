//
//  HTMLFeedLinkDiscovery.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation

/*
 一般的なサイトのHTMLに含まれる <link rel="alternate" type="application/rss+xml" ...>を
 正規表現で検出し、フィードURLを見つける。YouTubeのようにHTMLに埋め込まれたフィードリンクを持つサイトにも幅広く対応できる。
*/
final class HTMLFeedLinkDiscovery {
    struct DiscoveredLink {
        let title: String?
        let url: URL
    }
    
    private static let linkTagRegex = try? NSRegularExpression(
        pattern: "<link\\b[^>]*>",
        options: [.caseInsensitive]
    )
    
    static func discoverFeedLinks(in html: String, baseURL: URL) -> [DiscoveredLink] {
        guard let linkTagRegex else { return [] }
        let ns = html as NSString
        let matches = linkTagRegex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        
        var results: [DiscoveredLink] = []
        var seenURLs = Set<String>()
        
        for match in matches {
            let tag = ns.substring(with: match.range)
            let lowerTag = tag.lowercased()
            guard lowerTag.contains("alternate") else { continue }
            
            guard
                let type = attributeValue(named: "type", in: tag)?.lowercased(),
                 type.contains("rss") || type.contains("atom") || type.contains("xml") else { continue }
            
            guard let hrefRaw = attributeValue(named: "href", in: tag) else { continue }
            let href = TextSanitizer.decodeHTMLEntities(hrefRaw)
            guard let url = URL(string: href, relativeTo: baseURL)?.absoluteURL else { continue }
            
            let urlKey = url.absoluteString
            guard seenURLs.insert(urlKey).inserted else { continue }
            
            let title = attributeValue(named: "title", in: tag).map { TextSanitizer.decodeHTMLEntities($0) }
            results.append(DiscoveredLink(title: title, url: url))
        }
        return results
    }
    
    private static func attributeValue(named name: String, in tag: String) -> String? {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: name))\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = tag as NSString
        guard let match = regex.firstMatch(in: tag, range: NSRange(location: 0, length: ns.length)) else { return nil }
        
        for groupIndex in 1..<match.numberOfRanges {
            let range = match.range(at: groupIndex)
            if range.location != NSNotFound {
                return ns.substring(with: range).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}
