//
//  PopularFeedsCatalog.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation

// Feedカタログ情報
struct FeedCatalogEntry {
    let title: String
    let aliases: [String]
    let feedURLString: String
    let siteURLString: String?
    let summary: String?
}

// 有名な記事のカタログを用意 (AIから生成したものを使用)
enum PopularFeedsCatalog {
    private static let entries: [FeedCatalogEntry] = [
        FeedCatalogEntry(
            title: "Qiita 人気記事",
            aliases: [
                "qiita",
                "きーた",
                "キータ"
            ],
            feedURLString: "https://qiita.com/popular-items/feed",
            siteURLString: "https://qiita.com",
            summary: "Qiitaで話題の人気記事"
        ),
        FeedCatalogEntry(
            title: "Zenn トレンド",
            aliases: [
                "zenn",
                "ぜん"
            ],
            feedURLString: "https://zenn.dev/feed",
            siteURLString: "https://zenn.dev",
            summary: "Zennの新着記事"
        ),
        FeedCatalogEntry(
            title: "GitHub Blog",
            aliases: [
                "github",
                "ぎっとはぶ"
            ],
            feedURLString: "https://github.blog/feed/",
            siteURLString: "https://github.blog",
            summary: "GitHub公式ブログ"
        ),
        FeedCatalogEntry(
            title: "Hacker News",
            aliases: [
                "hacker news",
                "hackernews",
                "hn"
            ],
            feedURLString: "https://news.ycombinator.com/rss",
            siteURLString: "https://news.ycombinator.com",
            summary: "Hacker News フロントページ"
        ),
        FeedCatalogEntry(
            title: "BBC News",
            aliases: [
                "bbc",
                "bbc news",
                "びーびーしー"
            ],
            feedURLString: "https://feeds.bbci.co.uk/news/rss.xml",
            siteURLString: "https://www.bbc.co.uk/news",
            summary: "BBC ニュース トップストーリー"
        ),
        FeedCatalogEntry(
            title: "BBC Sport",
            aliases: [
                "bbc sport",
                "bbc スポーツ"
            ],
            feedURLString: "https://feeds.bbci.co.uk/sport/rss.xml",
            siteURLString: "https://www.bbc.co.uk/sport",
            summary: "BBC スポーツニュース"
        ),
        FeedCatalogEntry(
            title: "CNN Top Stories",
            aliases: [
                "cnn",
                "シーエヌエヌ"
            ],
            feedURLString: "http://rss.cnn.com/rss/cnn_topstories.rss",
            siteURLString: "https://www.cnn.com",
            summary: "CNN トップニュース"
        ),
        FeedCatalogEntry(
            title: "The New York Times",
            aliases: [
                "nytimes",
                "new york times",
                "nyt",
                "ニューヨークタイムズ"
            ],
            feedURLString: "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
            siteURLString: "https://www.nytimes.com",
            summary: "The New York Times ホームページ"
        ),
        FeedCatalogEntry(
            title: "TechCrunch",
            aliases: [
                "techcrunch",
                "テッククランチ"
            ],
            feedURLString: "https://techcrunch.com/feed/",
            siteURLString: "https://techcrunch.com",
            summary: "スタートアップ・テック系ニュース"
        ),
        FeedCatalogEntry(
            title: "The Verge",
            aliases: [
                "the verge",
                "verge",
                "ザ・バージ"
            ],
            feedURLString: "https://www.theverge.com/rss/index.xml",
            siteURLString: "https://www.theverge.com",
            summary: "テクノロジー・カルチャーメディア"
        ),
        FeedCatalogEntry(
            title: "Engadget",
            aliases: [
                "engadget",
                "エンガジェット"
            ],
            feedURLString: "https://www.engadget.com/rss.xml",
            siteURLString: "https://www.engadget.com",
            summary: "ガジェット・テックニュース"
        ),
        FeedCatalogEntry(
            title: "Ars Technica",
            aliases: [
                "ars technica",
                "arstechnica"
            ],
            feedURLString: "https://feeds.arstechnica.com/arstechnica/index",
            siteURLString: "https://arstechnica.com",
            summary: "テクノロジー専門メディア"
        ),
        FeedCatalogEntry(
            title: "WIRED",
            aliases: [
                "wired",
                "ワイアード"
            ],
            feedURLString: "https://www.wired.com/feed/rss",
            siteURLString: "https://www.wired.com",
            summary: "テクノロジー・カルチャー誌"
        ),
        FeedCatalogEntry(
            title: "ITmedia 総合",
            aliases: [
                "itmedia",
                "アイティメディア"
            ],
            feedURLString: "https://rss.itmedia.co.jp/rss/2.0/itmedia_all.xml",
            siteURLString: "https://www.itmedia.co.jp",
            summary: "ITmediaの総合ニュース"
        ),
        FeedCatalogEntry(
            title: "GIGAZINE",
            aliases: [
                "gigazine",
                "ギガジン"
            ],
            feedURLString: "https://gigazine.net/news/rss_2.0/",
            siteURLString: "https://gigazine.net",
            summary: "ガジェット・カルチャー系ニュースサイト"
        ),
        FeedCatalogEntry(
            title: "Publickey",
            aliases: [
                "publickey",
                "パブリックキー"
            ],
            feedURLString: "https://www.publickey1.jp/atom.xml",
            siteURLString: "https://www.publickey1.jp",
            summary: "エンタープライズ・クラウド技術系ブログ"
        ),
        FeedCatalogEntry(
            title: "NHKニュース",
            aliases: [
                "nhk",
                "エヌエイチケー",
                "えぬえいちけー"
            ],
            feedURLString: "https://www3.nhk.or.jp/rss/news/cat0.xml",
            siteURLString: "https://www3.nhk.or.jp/news/",
            summary: "NHK主要ニュース"
        ),
        FeedCatalogEntry(
            title: "Yahoo!ニュース 主要",
            aliases: [
                "yahoo",
                "yahoo news",
                "ヤフー",
                "ヤフーニュース"
            ],
            feedURLString: "https://news.yahoo.co.jp/rss/topics/top-picks.xml",
            siteURLString: "https://news.yahoo.co.jp",
            summary: "Yahoo!ニュース トピックス"
        ),
        FeedCatalogEntry(
            title: "Dev.to",
            aliases: [
                "dev.to",
                "devto"
            ],
            feedURLString: "https://dev.to/feed",
            siteURLString: "https://dev.to",
            summary: "開発者コミュニティ Dev.to の新着記事"
        ),
        FeedCatalogEntry(
            title: "Product Hunt",
            aliases: [
                "product hunt",
                "producthunt"
            ],
            feedURLString: "https://www.producthunt.com/feed",
            siteURLString: "https://www.producthunt.com",
            summary: "新しいプロダクトの投稿"
        ),
        FeedCatalogEntry(
            title: "Smashing Magazine",
            aliases: [
                "smashing magazine",
                "smashingmagazine"
            ],
            feedURLString: "https://www.smashingmagazine.com/feed/",
            siteURLString: "https://www.smashingmagazine.com",
            summary: "Web制作・デザイン系メディア"
        ),
        FeedCatalogEntry(
            title: "InfoQ",
            aliases: ["infoq"],
            feedURLString: "https://feed.infoq.com/",
            siteURLString: "https://www.infoq.com",
            summary: "ソフトウェア開発の専門ニュース"
        ),
        FeedCatalogEntry(
            title: "Apple Newsroom",
            aliases: [
                "apple",
                "アップル"
            ],
            feedURLString: "https://www.apple.com/newsroom/rss-feed.rss",
            siteURLString: "https://www.apple.com/newsroom/",
            summary: "Apple公式ニュースルーム"
        ),
        FeedCatalogEntry(
            title: "Google Blog (The Keyword)",
            aliases: [
                "google",
                "グーグル"
            ],
            feedURLString: "https://blog.google/rss/",
            siteURLString: "https://blog.google",
            summary: "Google公式ブログ"
        ),
        FeedCatalogEntry(
            title: "Google Cloud Blog",
            aliases: [
                "google cloud",
                "gcp"
            ],
            feedURLString: "https://cloud.google.com/blog/rss/",
            siteURLString: "https://cloud.google.com/blog",
            summary: "Google Cloud公式ブログ"
        ),
        FeedCatalogEntry(
            title: "はてなブックマーク 人気エントリー (IT)",
            aliases: [
                "はてな",
                "はてぶ",
                "はてなブックマーク",
                "hatena"
            ],
            feedURLString: "https://b.hatena.ne.jp/hotentry/it.rss",
            siteURLString: "https://b.hatena.ne.jp/hotentry/it",
            summary: "はてなブックマークのITカテゴリ人気エントリー"
        ),
        FeedCatalogEntry(
            title: "Stack Overflow Blog",
            aliases: [
                "stack overflow",
                "stackoverflow"
            ],
            feedURLString: "https://stackoverflow.blog/feed/",
            siteURLString: "https://stackoverflow.blog",
            summary: "Stack Overflow公式ブログ"
        ),
        FeedCatalogEntry(
            title: "Microsoft DevBlogs",
            aliases: [
                "microsoft",
                "ms",
                "マイクロソフト"
            ],
            feedURLString: "https://devblogs.microsoft.com/feed/",
            siteURLString: "https://devblogs.microsoft.com",
            summary: "Microsoft開発者向けブログ"
        ),
        FeedCatalogEntry(
            title: "AWS Blog",
            aliases: [
                "aws",
                "amazon web services"
            ],
            feedURLString: "https://aws.amazon.com/blogs/aws/feed/",
            siteURLString: "https://aws.amazon.com/blogs/aws/",
            summary: "AWS公式ブログ"
        ),
        FeedCatalogEntry(
            title: "OpenAI News",
            aliases: [
                "openai",
                "chatgpt",
                "オープンエーアイ"
            ],
            feedURLString: "https://openai.com/news/rss.xml",
            siteURLString: "https://openai.com/news/",
            summary: "OpenAI公式ニュース"
        ),
        FeedCatalogEntry(
            title: "CodeZine",
            aliases: [
                "codezine",
                "コードジン"
            ],
            feedURLString: "https://codezine.jp/rss/new/20/index.xml",
            siteURLString: "https://codezine.jp",
            summary: "開発者向け技術情報メディア"
        )
    ]
    
    // キーワードにあいまい一致するカタログエントリをスコア順に返す。
    static func search(keyword: String) -> [FeedCandidate] {
        let query = normalize(keyword)
        guard !query.isEmpty else { return [] }
        
        let scored: [(entry: FeedCatalogEntry, score: Int)] = entries.compactMap { entry in
            let names = [entry.title] + entry.aliases
            let best = names.map { matchScore(alias: normalize($0), query: query) }.max() ?? 0
            return best > 0 ? (entry, best) : nil
        }
        
        return scored
            .sorted { $0.score > $1.score }
            .compactMap { scoredEntry -> FeedCandidate? in
                guard let feedURL = URL(string: scoredEntry.entry.feedURLString) else { return nil }
                return FeedCandidate(
                    feedURL: feedURL,
                    title: scoredEntry.entry.title,
                    siteURL: scoredEntry.entry.siteURLString.flatMap { URL(string: $0) },
                    summary: scoredEntry.entry.summary,
                    iconURL: nil,
                    source: .catalog
                )
            }
    }
    
    private static func normalize(_ text: String) -> String {
        text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
    }
    
    private static func matchScore(alias: String, query: String) -> Int {
        guard !alias.isEmpty, !query.isEmpty else { return 0 }
        if alias == query { return 100 }
        if alias.hasPrefix(query) { return 85 }
        if query.hasPrefix(alias) { return 75 }
        if alias.contains(query) { return 60 }
        if query.contains(alias) { return 45 }
        return 0
    }
}

