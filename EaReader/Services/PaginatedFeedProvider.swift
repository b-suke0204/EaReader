//
//  PaginatedFeedProvider.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation
import Combine

protocol PaginatedFeedProvider {
    // 該当Feed URLをAPI経由で処理できるかどうか
    static func canHandle(feedURL: URL) -> Bool
    // ページネーションAPIを複数ページで叩いて記事一覧を取得する (APIが叩けなければ、空配列で返す)
    static func fetchItems(feedURL: URL) -> AnyPublisher<[Article], Never>
    // RSS側のタイトル取得に失敗した場合に使う
    static func fallbackTitle(feedURL: URL) -> String
}

/*
 公開されているRSSやAtomだけだと検索が少ないことが多いので、それとは別にページネーション用のAPIが公開されているwebサイトが多い
 そのAPIが公開されていれば、それを使って検索結果を多めにヒットするようにする
*/

// ページネーション用プロバイダを登録
enum PaginatedFeedProviderRegistry {
    
    // ページネーションありAPIの
    static let all: [PaginatedFeedProvider.Type] = [
        DevToAPIService.self,
        GitHubAPIService.self,
        QiitaAPIService.self,
        ZennAPIService.self,
    ]
    
    // ページネーション対応APIが公開されているプロバイダを返す
    static func provider(for feedURL: URL) -> PaginatedFeedProvider.Type? {
        all.first { $0.canHandle(feedURL: feedURL) }
    }
    
}



