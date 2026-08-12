//
//  GitHubAPIService.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation
import Combine

enum GitHubAPIService: PaginatedFeedProvider {
    // API応答用のモデル (Release)
    private struct Release: Decodable {
        let id: Int
        let name: String?
        let tagName: String
        let htmlURL: URL
        let publishedAt: String?
        let body: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case body
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case publishedAt = "published_at"
        }
        
        // Article.guid として利用
        var guid: String {
            htmlURL.absoluteString
        }
    }
    
    // API応答用のモデル (Commit)
    private struct Commit: Decodable {
        let sha: String
        let htmlURL: URL
        let commit: CommitDetail
        
        enum CodingKeys: String, CodingKey {
            case sha
            case commit
            case htmlURL = "html_url"
        }
        
        // Article.guid として利用
        var guid: String {
            sha
        }
    }
    
    private struct CommitDetail: Decodable {
        let message: String
        let author: CommitAuthor
    }
    
    private struct CommitAuthor: Decodable {
        let date: String
    }
    
    // API応答用のモデル (UserEvent)
    private struct UserEvent: Decodable {
        let id: String
        let type: String
        let repo: EventRepo
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case repo
            case createdAt = "created_at"
        }
        
        // Article.guid として利用
        var guid: String {
            id
        }
    }
    
    private struct EventRepo: Decodable {
        let name: String
    }
    
    // Github Feed種別
    private enum Kind {
        case releases(owner: String, repo: String)
        case commits(owner: String, repo: String)
        case userActivity(user: String)
    }
    
    private static func kind(fromFeedURL url: URL) -> Kind? {
        guard let host = url.host, host.contains("github.com") else {
            return nil
        }
        
        let components = url.pathComponents.filter { $0 != "/" }
        if components.count == 3 {
            if components[2] == "releases.atom" {
                return .releases(
                    owner: components[0],
                    repo: components[1]
                )
            }
            
            if components[2] == "commits.atom" {
                return .commits(
                    owner: components[0],
                    repo: components[1]
                )
            }
        }
        
        if components.count == 1, components[0].hasSuffix(".atom") {
            let user = String(
                components[0].dropLast(".atom".count)
            )
            guard !user.isEmpty else {
                return nil
            }
            return .userActivity(user: user)
        }
        return nil
    }
    
    // PaginatedFeedProviderの処理 ここから
    
    static func canHandle(feedURL: URL) -> Bool {
        kind(fromFeedURL: feedURL) != nil
    }
    
    static func fallbackTitle(feedURL: URL) -> String {
        switch kind(fromFeedURL: feedURL) {
        case .releases(let owner, let repo):
            return "\(owner)/\(repo) のリリース"
        case .commits(let owner, let repo):
            return "\(owner)/\(repo) のコミット"
        case .userActivity(let user):
            return "GitHub: \(user) のアクティビティ"
        case nil:
            return "GitHub"
        }
    }
    
    @MainActor
    static func fetchItems(feedURL: URL) -> AnyPublisher<[Article], Never> {
        switch kind(fromFeedURL: feedURL) {
        case .releases(let owner, let repo):
            return fetchPaged(path: "/repos/\(owner)/\(repo)/releases") { (releases: [Release]) in
                releases.map(makeArticle)
            }
        case .commits(let owner, let repo):
            return fetchPaged(path: "/repos/\(owner)/\(repo)/commits") { (commits: [Commit]) in
                commits.map(makeArticle)
            }
        case .userActivity(let user):
            return fetchPaged(path: "/users/\(user)/events/public") { (events: [UserEvent]) in
                events.map { article in
                    makeArticle(from: article)
                }
            }
        case nil:
            return Just([])
                .eraseToAnyPublisher()
        }
    }
    
    // PaginatedFeedProviderの処理 ここまで
    
    // API Requestを送信
    
    private static func fetchPaged<T: Decodable>(
        path: String,
        maxPages: Int = 2,
        perPage: Int = 30,
        transform: @escaping ([T]) -> [Article]
    ) -> AnyPublisher<[Article], Never> {
        let pagePublishers: [AnyPublisher<[T], Never>] = (1...maxPages).map { page in
            fetchPage(path: path, page: page, perPage: perPage)
        }
        
        return Publishers.MergeMany(pagePublishers)
            .collect()
            .map { pages in
                transform(pages.flatMap { $0 })
            }
            .eraseToAnyPublisher()
    }
    
    private static func fetchPage<T: Decodable>(path: String, page: Int, perPage: Int) -> AnyPublisher<[T], Never> {
        guard var components = URLComponents(string: "https://api.github.com\(path)") else {
            return Just([])
                .eraseToAnyPublisher()
        }
        
        components.queryItems = [
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        guard let url = components.url else {
            return Just([]).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("SearchRSS/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    throw FeedFetchError.invalidResponse
                }
                return data
            }
            .decode(type: [T].self, decoder: JSONDecoder())
            .catch { _ in
                Just([])
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: Articleに変換
    
    // ReleaseからArticle作成
    @MainActor
    private static func makeArticle(from release: Release) -> Article {
        let now = Date()
        let title = release.name?.isEmpty == false ? (release.name ?? "") : release.tagName
        
        return Article(
            id: UUID(),
            feedId: 0,
            articleTitle: TextSanitizer.cleanTitle(title),
            articleLink: release.htmlURL,
            summary: release.body
                .map {
                    TextSanitizer.cleanSummary(
                        String($0.prefix(400))
                    )
                }
                .flatMap {
                    $0.isEmpty ? nil : $0
                },
            guid: release.guid,
            isRead: false,
            isFavorite: false,
            isHidden: false,
            publishedAt: release.publishedAt.flatMap(RSSDateParser.parse) ?? Date(),
            contentUpdatedAt: now,
            fetchedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // CommitからArticle作成
    @MainActor
    private static func makeArticle(from commit: Commit) -> Article {
        let now = Date()
        let firstLine =
            commit.commit.message
                .split(separator: "\n", maxSplits: 1)
                .first
                .map(String.init)
            ?? commit.commit.message
        
        return Article(
            id: UUID(),
            feedId: 0,
            articleTitle: TextSanitizer.cleanTitle(firstLine),
            articleLink: commit.htmlURL,
            summary: nil,
            guid: commit.guid,
            isRead: false,
            isFavorite: false,
            isHidden: false,
            publishedAt: RSSDateParser.parse(commit.commit.author.date) ?? Date(),
            contentUpdatedAt: now,
            fetchedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // UserEventからArticle作成
    private static func makeArticle(from event: UserEvent) -> Article {
        let now = Date()
        let link = URL(
            string: "https://github.com/\(event.repo.name)"
        )
        return Article(
            id: UUID(),
            feedId: 0,
            articleTitle: TextSanitizer.cleanTitle(eventTitle(type: event.type, repo: event.repo.name)),
            articleLink: link,
            summary: nil,
            guid: event.guid,
            isRead: false,
            isFavorite: false,
            isHidden: false,
            publishedAt: RSSDateParser.parse(event.createdAt) ?? Date(),
            contentUpdatedAt: now,
            fetchedAt: now,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // GithubのEventタイトルを取得
    private static func eventTitle(type: String, repo: String) -> String {
        let titles: [String: String] = [
            "PushEvent": "\(repo) にpushしました",
            "CreateEvent": "\(repo) でブランチ/タグを作成しました",
            "DeleteEvent": "\(repo) でブランチ/タグを削除しました",
            "PullRequestEvent": "\(repo) のプルリクエストを操作しました",
            "PullRequestReviewEvent": "\(repo) のプルリクエストをレビューしました",
            "PullRequestReviewCommentEvent": "\(repo) のプルリクエストをレビューしました",
            "IssuesEvent": "\(repo) のIssueを操作しました",
            "IssueCommentEvent": "\(repo) のIssueにコメントしました",
            "WatchEvent": "\(repo) にStarを付けました",
            "ForkEvent": "\(repo) をフォークしました",
            "ReleaseEvent": "\(repo) でリリースを公開しました",
            "PublicEvent": "\(repo) を公開リポジトリにしました"
        ]

        return titles[type] ?? "\(repo) で \(type) が発生しました"
    }
    
    // MARK: 条件が16個あるので、Dictionary形式に変更 (swiftlintエラー対策)
    // いつか直すかも？
//    private static func eventTitle(type: String, repo: String) -> String {
//        switch type {
//        case "PushEvent":
//            return "\(repo) にpushしました"
//        case "CreateEvent":
//            return "\(repo) でブランチ/タグを作成しました"
//        case "DeleteEvent":
//            return "\(repo) でブランチ/タグを削除しました"
//        case "PullRequestEvent":
//            return "\(repo) のプルリクエストを操作しました"
//        case "PullRequestReviewEvent",
//             "PullRequestReviewCommentEvent":
//            return "\(repo) のプルリクエストをレビューしました"
//        case "IssuesEvent":
//            return "\(repo) のIssueを操作しました"
//        case "IssueCommentEvent":
//            return "\(repo) のIssueにコメントしました"
//        case "WatchEvent":
//            return "\(repo) にStarを付けました"
//        case "ForkEvent":
//            return "\(repo) をフォークしました"
//        case "ReleaseEvent":
//            return "\(repo) でリリースを公開しました"
//        case "PublicEvent":
//            return "\(repo) を公開リポジトリにしました"
//        default:
//            return "\(repo) で \(type) が発生しました"
//        }
//    }
}
