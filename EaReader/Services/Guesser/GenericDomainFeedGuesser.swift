//
//  GenericDomainFeedGuesser.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation
import Combine

// FeedのDomainを推測する処理
enum GenericDomainFeedGuesser {
    private static let candidateTLDs = ["com", "net", "org", "io", "dev", "jp"]
    private static let commonFeedPaths = [
        "/feed", "/feed/", "/rss", "/rss/", "/rss.xml",
        "/feed.xml", "/atom.xml", "/index.xml",
        "/feeds/posts/default", "/blog/feed"
    ]
    private static let exploreTimeout: TimeInterval = 8
    
    // キーワードから「ドメインになりそうな」候補ホスト名を生成する。
    // 空白を含む・記号を含みすぎるなど、ドメインらしくない入力は空配列を返す。
    static func candidateHosts(forKeyword rawKeyword: String) -> [String] {
        let keyword = rawKeyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !keyword.isEmpty, !keyword.contains(where: { $0.isWhitespace }) else { return [] }
        let allowedScalars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-.")
        guard keyword.unicodeScalars.allSatisfy({ allowedScalars.contains($0) }) else { return [] }
        guard !keyword.hasPrefix("-"), !keyword.hasPrefix("."), !keyword.hasSuffix("-") else { return [] }
        
        // "swift.org" のようにすでにドメインらしい形ならそのまま1件だけ試す
        if keyword.contains(".") {
            return [keyword]
        }
        
        guard keyword.count >= 2 else { return [] }
        
        return candidateTLDs.map { "\(keyword).\($0)" }
    }
    
    // 1つの候補ホストについて、トップページのリンク発見 → 定番パス直叩きの順で探索する。
    static func explore(host: String) -> AnyPublisher<[FeedCandidate], Never> {
        guard let homepage = URL(string: "https://\(host)/") else {
            return Just([]).eraseToAnyPublisher()
        }
        
        let discovery = FeedFetcher.fetchHTML(url: homepage, timeout: exploreTimeout)
            .map { html, finalURL -> [FeedCandidate] in
                HTMLFeedLinkDiscovery.discoverFeedLinks(in: html, baseURL: finalURL).map { discovered in
                    FeedCandidate(
                        feedURL: discovered.url,
                        title: discovered.title ?? finalURL.host ?? discovered.url.absoluteString,
                        siteURL: finalURL,
                        summary: nil,
                        iconURL: nil,
                        source: .domainGuess
                    )
                }
            }
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
        
        return discovery
            .flatMap { discovered -> AnyPublisher<[FeedCandidate], Never> in
                guard discovered.isEmpty else {
                    return Just(discovered).eraseToAnyPublisher()
                }
                let directPathCandidates = commonFeedPaths.compactMap { path -> FeedCandidate? in
                    guard let url = URL(string: "https://\(host)\(path)") else { return nil }
                    let candidate = FeedCandidate(
                        feedURL: url,
                        title: host,
                        siteURL: nil,
                        summary: nil,
                        iconURL: nil,
                        source: .domainGuess
                    )
                    return candidate
                }
                return FeedSearchOrchestrator.validate(directPathCandidates, timeout: exploreTimeout)
            }
            .eraseToAnyPublisher()
    }

    // キーワードから生成した全候補ホストを並行して探索し、結果をまとめて返す。
    static func search(forKeyword keyword: String) -> AnyPublisher<[FeedCandidate], Never> {
        let hosts = candidateHosts(forKeyword: keyword)
        guard !hosts.isEmpty else { return Just([]).eraseToAnyPublisher() }
        let publishers = hosts.map {
            explore(host: $0)
        }
        
        // 全て取得されたら一つにまとめて返す
        return Publishers.MergeMany(publishers)
            .collect()
            .map { $0.flatMap { $0 } }
            .eraseToAnyPublisher()
    }
}
