//
//  FeedCandidate.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import Foundation

// 26.08.08 B フィード候補がどこから見つかったかを表す種別
enum FeedSource: String, CaseIterable {
    case catalog = "定番サイト"
    case direct = "指定URL"
    case htmlDiscovery = "ページ内のリンク"
    case github = "GitHub"
    case qiita = "Qiita"
    case zenn = "Zenn"
    case hatenaBlog = "はてなブログ"
    case hatenaBookmark = "はてなブックマーク"
    case note = "note"
    case reddit = "Reddit"
    case devto = "DEV Community"
    case wordpress = "WordPress.com"
    case domainGuess = "ドメイン走査"
    
    // それぞれのサイトでSF Symbolsのアイコンを小さく表示する
    var systemImage: String {
        switch self {
        case .catalog: return "star.fill"
        case .direct: return "link"
        case .htmlDiscovery: return "doc.text.magnifyingglass"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .qiita: return "number"
        case .zenn: return "z.square"
        case .hatenaBlog, .hatenaBookmark: return "b.square"
        case .note: return "n.square"
        case .reddit: return "r.square"
        case .devto: return "d.square"
        case .wordpress: return "w.square"
        case .domainGuess: return "network"
        }
    }
}

// 26.08.08 B 検索結果として表示するフィード候補
struct FeedCandidate: Identifiable, Hashable {
    let feedURL: URL
    var title: String
    var siteURL: URL?
    var summary: String?
    var iconURL: URL?
    var source: FeedSource

//    var id: String { feedURL.absoluteString }
    var id: UUID = UUID()

    static func == (lhs: FeedCandidate, rhs: FeedCandidate) -> Bool {
        lhs.feedURL == rhs.feedURL
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(feedURL)
    }
    
    // 26.08.08 B 有効なアイコンURL取得
    func fetchEffectiveIconURL() -> URL? {
        if let iconURL = self.iconURL { return iconURL }
        guard let host = (self.siteURL ?? self.feedURL).host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(host)")
    }
}

// パース済みのフィード全体
struct ParsedFeed {
    var title: String = ""
    var link: URL?
    var description: String?
    var items: [Article] = []
}



