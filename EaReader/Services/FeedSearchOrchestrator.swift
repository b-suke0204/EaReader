//
//  FeedSearchOrchestrator.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation
import Combine

// 26.08.09 B Feed検索の入口
// ここでキーワード検索とURL検索の処理を呼び出す
enum FeedSearchOrchestrator {
    
    // フィードURLの候補群を実際にフェッチして検証し、成功したものだけを
    // パース結果のタイトル・説明で更新して返す。
    // 検証は並行に走るため、結果は元の candidates の順序に並べ直して返す
    // (カタログ検索のスコア順などを崩さないため)。
    static func validate(
        _ candidates: [FeedCandidate],
        timeout: TimeInterval = 12
    ) -> AnyPublisher<[FeedCandidate], Never> {
        var seen = Set<String>()
        let uniqueCandidates = candidates.filter { seen.insert($0.feedURL.absoluteString).inserted }
        
        guard !uniqueCandidates.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }
        
        let originalOrder = Dictionary(
            uniqueKeysWithValues: uniqueCandidates.enumerated().map { ($1.feedURL.absoluteString, $0) }
        )
        
        let publishers: [AnyPublisher<FeedCandidate?, Never>] = uniqueCandidates.map { candidate in
            FeedFetcher.fetchAndParse(url: candidate.feedURL, timeout: timeout)
                .map { parsed -> FeedCandidate? in
                    var updated = candidate
                    if !parsed.title.isEmpty { updated.title = parsed.title }
                    if let link = parsed.link { updated.siteURL = link }
                    if let description = parsed.description, !description.isEmpty { updated.summary = description }
                    return updated
                }
                .catch { _ in Just(nil) }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { results in
                results
                    .compactMap { $0 }
                    .sorted {
                        let lhsURL = originalOrder[$0.feedURL.absoluteString] ?? 0
                        let rhsURL = originalOrder[$1.feedURL.absoluteString] ?? 0
                        return lhsURL < rhsURL
                    }
            }
            .eraseToAnyPublisher()
    }

    // URLを入力として、直接フィードかどうか・既知サイト形式・ページ内リンクを総当たりで探す。
    static func searchByURL(_ rawInput: String) -> AnyPublisher<[FeedCandidate], Never> {
        guard let url = normalizeToURL(rawInput) else {
            return Just([]).eraseToAnyPublisher()
        }
        
        let knownSiteGuesses = KnownSiteFeedGuesser.guess(forURL: url)
        let directCandidate = FeedCandidate(
            feedURL: url, title: url.absoluteString, siteURL: nil, summary: nil, iconURL: nil, source: .direct
        )
        
        let discoveryPublisher: AnyPublisher<[FeedCandidate], Never> = FeedFetcher.fetchHTML(url: url)
            .map { html, finalURL -> [FeedCandidate] in
                HTMLFeedLinkDiscovery.discoverFeedLinks(in: html, baseURL: finalURL).map { discovered in
                    FeedCandidate(
                        feedURL: discovered.url,
                        title: discovered.title ?? finalURL.host ?? discovered.url.absoluteString,
                        siteURL: finalURL,
                        summary: nil,
                        iconURL: nil,
                        source: .htmlDiscovery
                    )
                }
            }
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
        
        return discoveryPublisher
            .flatMap { discovered -> AnyPublisher<[FeedCandidate], Never> in
                let allCandidates = knownSiteGuesses + [directCandidate] + discovered
                return validate(allCandidates)
            }
            .map { results in
                results.sorted { lhs, rhs in
                    if (lhs.source == .direct) != (rhs.source == .direct) {
                        return lhs.source == .direct
                    }
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }
            }
            .eraseToAnyPublisher()
    }

    // キーワードを入力として、次の3つの自前ロジックを組み合わせる。外部の検索APIは一切使わない。
    //   1. PopularFeedsCatalog: 有名サイトの名前とのあいまい一致(例: "Qiita"→Qiita, "BBC"→BBC News)
    //   2. KnownSiteFeedGuesser: GitHubのowner/repoやQiitaのタグ名など、URL規則が分かっているサイト
    //   3. GenericDomainFeedGuesser: キーワードをドメイン名とみなして実際にアクセスして探す
    // 結果はこの優先順位でマージし、精度の高いものを上位に表示する。
    static func searchByKeyword(_ rawKeyword: String) -> AnyPublisher<[FeedCandidate], Never> {
        let keyword = rawKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }
        
        let catalogMatches = PopularFeedsCatalog.search(keyword: keyword)
        let validatedCatalog = validate(catalogMatches)
        
        let guessedCandidates = KnownSiteFeedGuesser.guess(forKeyword: keyword)
        let validatedGuesses = validate(guessedCandidates)
        
        let domainExploration = GenericDomainFeedGuesser.search(forKeyword: keyword)
        
        return Publishers.CombineLatest3(validatedCatalog, validatedGuesses, domainExploration)
            .map { catalog, guessed, domainResults -> [FeedCandidate] in
                var seen = Set<String>()
                var merged: [FeedCandidate] = []
                let candidates = catalog + guessed + domainResults
                for candidate in candidates where seen.insert(candidate.feedURL.absoluteString).inserted {
                    print("どのURLだ？: \(candidate.feedURL)")
                    merged.append(candidate)
                }
                return merged
            }
            .eraseToAnyPublisher()
    }
    
    private static func normalizeToURL(_ input: String) -> URL? {
        var trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()
        if !lower.hasPrefix("http://") && !lower.hasPrefix("https://") {
            trimmed = "https://" + trimmed
        }
        guard let url = URL(string: trimmed), url.host != nil else { return nil }
        return url
    }
}
