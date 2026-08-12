//
//  KnownSiteFeedGuesser.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation

enum KnownSiteFeedGuesser {
    // URL入力からの推測する
    static func guess(forURL url: URL) -> [FeedCandidate] {
        guard let host = url.host?.lowercased() else { return [] }
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        // nilだったら、次のFeedを検索
        if let githubFeed = getGithubFeeds(host: host, pathComponents: pathComponents) {
            return githubFeed
        }
        
        if let qiitaFeed = getQiitaFeeds(host: host, pathComponents: pathComponents) {
            return qiitaFeed
        }
        
        if let zennFeed = getZennFeeds(host: host, pathComponents: pathComponents) {
            return zennFeed
        }
        
        if let hatenaFeed = getHatenaFeed(host: host, pathComponents: pathComponents, baseURL: url) {
            return hatenaFeed
        }
        
        if let noteFeed = getNoteFeeds(host: host, pathComponents: pathComponents) {
            return noteFeed
        }
        
        if let redditFeed = getRedditFeeds(host: host, pathComponents: pathComponents) {
            return redditFeed
        }
        
        if let devToFeed = getDevToFeeds(host: host, pathComponents: pathComponents) {
            return devToFeed
        }
        
        if let wordpressFeed = getWordpressFeeds(host: host, pathComponents: pathComponents) {
            return wordpressFeed
        }
        
        return []
    }
    
    private static func getGithubFeeds(host: String, pathComponents: [String]) -> [FeedCandidate]? {
        if host.contains("github.com") {
            if pathComponents.count >= 2 {
                return githubRepositoryCandidates(owner: pathComponents[0], repo: pathComponents[1])
            } else if pathComponents.count == 1 {
                return githubUserCandidates(user: pathComponents[0])
            }
        }
        return nil
    }
    
    private static func getQiitaFeeds(host: String, pathComponents: [String]) -> [FeedCandidate]? {
        if host.contains("qiita.com") {
            if pathComponents.count >= 2, pathComponents[0] == "tags" {
                return [qiitaTagCandidate(tag: pathComponents[1])].compactMap { $0 }
            }
            if pathComponents.count >= 2, pathComponents[0] == "organizations" {
                return [qiitaOrganizationCandidate(organization: pathComponents[1])].compactMap { $0 }
            }
            let qiitaPathCandidates: [String] = ["items", "drafts", "notifications", "settings"]
            if pathComponents.count >= 1, !qiitaPathCandidates.contains(pathComponents[0]) {
                return [qiitaUserCandidate(user: pathComponents[0])].compactMap { $0 }
            }
        }
        return nil
    }
    
    private static func getZennFeeds(host: String, pathComponents: [String]) -> [FeedCandidate]? {
        if host.contains("zenn.dev") {
            if pathComponents.count >= 2, pathComponents[0] == "topics" {
                return [zennTopicCandidate(topic: pathComponents[1])].compactMap { $0 }
            }
            if pathComponents.count >= 1, !["articles", "scraps", "books"].contains(pathComponents[0]) {
                return [zennUserCandidate(user: pathComponents[0])].compactMap { $0 }
            }
        }
        return nil
    }
    
    private static func getHatenaFeed(host: String, pathComponents: [String], baseURL: URL) -> [FeedCandidate]? {
        if host.contains("hatenablog.com") || host.contains("hatenablog.jp") || host.contains("hateblo.jp") {
            return [hatenaBlogCandidate(baseURL: baseURL)].compactMap { $0 }
        }
        return nil
    }
    
    private static func getNoteFeeds(host: String, pathComponents: [String]) -> [FeedCandidate]? {
        if host.contains("note.com"), pathComponents.count >= 1,
           !["search", "hashtag", "notes", "info"].contains(pathComponents[0]) {
            return [noteUserCandidate(user: pathComponents[0])].compactMap { $0 }
        }
        return nil
    }
    
    private static func getRedditFeeds(host: String, pathComponents: [String]) -> [FeedCandidate]? {
        if host.contains("reddit.com"), pathComponents.count >= 2, pathComponents[0] == "r" {
            return [redditSubredditCandidate(subreddit: pathComponents[1])].compactMap { $0 }
        }
        return nil
    }
    
    private static func getDevToFeeds(host: String, pathComponents: [String]) -> [FeedCandidate]? {
        if host == "dev.to", pathComponents.count >= 2, pathComponents[0] == "t" {
            return [devToTagCandidate(tag: pathComponents[1])].compactMap { $0 }
        }
        return nil
    }
    
    private static func getWordpressFeeds(host: String, pathComponents: [String]) -> [FeedCandidate]? {
        if host.contains("wordpress.com"), pathComponents.count >= 2, pathComponents[0] == "tag" {
            return [wordPressTagCandidate(tag: pathComponents[1])].compactMap { $0 }
        }
        return nil
    }
    
    // キーワード入力からFeedURLを推測する
    static func guess(forKeyword rawKeyword: String) -> [FeedCandidate] {
        let keyword = rawKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return [] }
        var candidates: [FeedCandidate] = []
        let hasWhitespace = keyword.contains(where: { $0.isWhitespace })
        let isSimpleASCIIToken = !hasWhitespace && keyword.allSatisfy {
            $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == ".")
        }
        
        // "owner/repo" のような形式はGitHubリポジトリとして解釈
        if !hasWhitespace, keyword.contains("/") {
            let parts = keyword.split(separator: "/", maxSplits: 1).map(String.init)
            if parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty {
                candidates += githubRepositoryCandidates(owner: parts[0], repo: parts[1])
            }
        }
        
        // スペースを含まない単語ならタグ/ユーザー名/サブレディット名の可能性がある
        if !hasWhitespace {
            candidates.append(contentsOf: [
                qiitaTagCandidate(tag: keyword),
                zennTopicCandidate(topic: keyword),
                wordPressTagCandidate(tag: keyword)
            ].compactMap { $0 })
            
            if isSimpleASCIIToken {
                candidates.append(contentsOf: [
                    githubUserActivityCandidate(user: keyword),
                    qiitaUserCandidate(user: keyword),
                    zennUserCandidate(user: keyword),
                    redditSubredditCandidate(subreddit: keyword),
                    noteUserCandidate(user: keyword),
                    hatenaBlogSubdomainCandidate(subdomain: keyword),
                    devToTagCandidate(tag: keyword)
                ].compactMap { $0 })
            }
        }
        
        // フレーズ全体としての検索(はてなブックマーク・Reddit検索)
        candidates.append(contentsOf: [
            hatenaBookmarkSearchCandidate(keyword: keyword),
            redditSearchCandidate(keyword: keyword)
        ].compactMap { $0 })
        
        return candidates
    }
    
    // GitHubからFeed候補を取得
    private static func githubRepositoryCandidates(owner: String, repo: String) -> [FeedCandidate] {
        let cleanRepo = repo.replacingOccurrences(of: ".git", with: "")
        let base = "https://github.com/\(owner)/\(cleanRepo)"
        return [
            makeCandidate("\(base)/releases.atom", title: "\(owner)/\(cleanRepo) のリリース", source: .github),
            makeCandidate("\(base)/tags.atom", title: "\(owner)/\(cleanRepo) のタグ", source: .github),
            makeCandidate("\(base)/commits.atom", title: "\(owner)/\(cleanRepo) のコミット", source: .github)
        ].compactMap { $0 }
    }
    
    private static func githubUserCandidates(user: String) -> [FeedCandidate] {
        [githubUserActivityCandidate(user: user)].compactMap { $0 }
    }
    
    private static func githubUserActivityCandidate(user: String) -> FeedCandidate? {
        makeCandidate("https://github.com/\(user).atom", title: "GitHub: \(user) のアクティビティ", source: .github)
    }
    
    // QiitaのFeed候補取得
    private static func qiitaTagCandidate(tag: String) -> FeedCandidate? {
        makeCandidate("https://qiita.com/tags/\(encodePathComponent(tag))/feed", title: "Qiita「\(tag)」タグの新着記事", source: .qiita)
    }
    
    private static func qiitaUserCandidate(user: String) -> FeedCandidate? {
        makeCandidate("https://qiita.com/\(encodePathComponent(user))/feed", title: "Qiita: \(user) の投稿", source: .qiita)
    }
    
    private static func qiitaOrganizationCandidate(organization: String) -> FeedCandidate? {
        makeCandidate("https://qiita.com/organizations/\(encodePathComponent(organization))/feed", title: "Qiita Organization: \(organization)", source: .qiita)
    }
    
    // ZennのFeed候補を取得
    private static func zennTopicCandidate(topic: String) -> FeedCandidate? {
        makeCandidate("https://zenn.dev/topics/\(encodePathComponent(topic))/feed", title: "Zenn「\(topic)」トピックの新着記事", source: .zenn)
    }
    
    private static func zennUserCandidate(user: String) -> FeedCandidate? {
        makeCandidate("https://zenn.dev/\(encodePathComponent(user))/feed", title: "Zenn: \(user) の投稿", source: .zenn)
    }
    
    // はてなのFeed候補取得
    private static func hatenaBlogCandidate(baseURL: URL) -> FeedCandidate? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/feed"
        components.query = nil
        components.fragment = nil
        guard let feedURL = components.url else { return nil }
        let candidate = FeedCandidate(
            feedURL: feedURL,
            title: "\(baseURL.host ?? "はてなブログ") のフィード",
            siteURL: baseURL,
            summary: nil,
            iconURL: nil,
            source: .hatenaBlog
        )
        return candidate
    }
    
    private static func hatenaBlogSubdomainCandidate(subdomain: String) -> FeedCandidate? {
        makeCandidate(
            "https://\(subdomain).hatenablog.com/feed",
            title: "\(subdomain).hatenablog.com のフィード",
            source: .hatenaBlog
        )
    }
    
    private static func hatenaBookmarkSearchCandidate(keyword: String) -> FeedCandidate? {
        makeCandidate(
            "https://b.hatena.ne.jp/search/text?q=\(encodeQueryComponent(keyword))&mode=rss&sort=recent",
            title: "はてなブックマーク検索「\(keyword)」",
            source: .hatenaBookmark
        )
    }
    
    // noteのFeed候補取得
    private static func noteUserCandidate(user: String) -> FeedCandidate? {
        makeCandidate("https://note.com/\(encodePathComponent(user))/rss", title: "note: \(user) の投稿", source: .note)
    }
    
    // Redditの候補取得
    private static func redditSubredditCandidate(subreddit: String) -> FeedCandidate? {
        makeCandidate("https://www.reddit.com/r/\(encodePathComponent(subreddit))/.rss", title: "r/\(subreddit)", source: .reddit)
    }
    
    private static func redditSearchCandidate(keyword: String) -> FeedCandidate? {
        makeCandidate("https://www.reddit.com/search.rss?q=\(encodeQueryComponent(keyword))", title: "Reddit検索「\(keyword)」", source: .reddit)
    }
    
    // DEV Community (dev.to)のFeed候補取得
    private static func devToTagCandidate(tag: String) -> FeedCandidate? {
        makeCandidate(
            "https://dev.to/feed/tag/\(encodePathComponent(tag.lowercased()))",
            title: "DEV Community「\(tag)」タグの新着記事",
            source: .devto
        )
    }
    
    // WordPress.comのFeed候補取得
    private static func wordPressTagCandidate(tag: String) -> FeedCandidate? {
        makeCandidate(
            "https://wordpress.com/tag/\(encodePathComponent(tag))/feed",
            title: "WordPress.com「\(tag)」タグの新着記事",
            source: .wordpress
        )
    }
    
    // ヘルパー処理群
    
    private static func makeCandidate(_ urlString: String, title: String, source: FeedSource) -> FeedCandidate? {
        guard let url = URL(string: urlString) else { return nil }
        return FeedCandidate(feedURL: url, title: title, siteURL: nil, summary: nil, iconURL: nil, source: source)
    }
    
    private static func encodePathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
    
    private static func encodeQueryComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}
