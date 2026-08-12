//
//  Model.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/12.
//

import Foundation

// 26.08.12 B UserFeedファイルに書いていたものを移動
// モデルの入り口

// deviceの中にuserFeedの配列、userFeedの中にarticleの配列
struct DeviceModel<D, U, A>: Equatable where D: DeviceType, U: UserFeedType, A: ArticleType {
    var device: D
    var userFeeds: [UserFeedModel<U, A>]
}

struct UserFeedModel<U, A>: Equatable, Identifiable where U: UserFeedType, A: ArticleType {
    var id: UUID = UUID()
    var userFeed: U
    var articles: [ArticleModel<A>]
    var feedCandidate: FeedCandidate?
}

struct ArticleModel<A: ArticleType>: Equatable, Identifiable {
    var id: UUID = UUID()
    var article: A
}




