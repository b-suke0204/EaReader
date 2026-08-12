//
//  FeedListViewModel.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/09.
//

import Foundation

// 26.08.09 B Feed一覧のビューモデル
class FeedListViewModel {
    
    // バッジ表示確認
    func isShowingBadge(
        _ item: UserFeedModel<UserFeed, Article>,
        _ path: KeyPath<Article, Bool>,
        condition: (Bool, Bool) -> Bool = { a, b in
            a == b
        }
    ) -> Bool {
        let favorites = item.articles.filter({ condition($0.article[keyPath: path], true) }).count
        return !favorites.isZero()
    }
    
    // バッジ数取得
    func getBadgeNumber(
        _ item: UserFeedModel<UserFeed, Article>,
        _ path: KeyPath<Article, Bool>,
        condition: (Bool, Bool) -> Bool = { a, b in
            a == b
        }
    ) -> Int {
        let favorites = item.articles.filter({ condition($0.article[keyPath: path], true) }).count
        return favorites
    }
    
}



