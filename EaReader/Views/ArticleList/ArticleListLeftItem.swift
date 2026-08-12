//
//  ArticleListLeftItem.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/12.
//

import SwiftUI
import ComposableArchitecture

// 記事一覧の左側アイテム
struct ArticleListLeftItem: View {
    let item: ArticleModel<Article>
    let articleListFeature: StoreOf<ArticleListFeature>
    var body: some View {
        VStack(alignment: .leading) {
            ArticleThumbnailView(article: item.article)
            HStack(alignment: .center) {
                NotReadMark(item: item)
                // いいね
                FavoriteButton(item: item, articleListFeature: articleListFeature)
                // アーカイブ
                ArchiveButton(item: item, articleListFeature: articleListFeature)
            }
        }
    }
}

// 未読マーク
struct NotReadMark: View {
    let item: ArticleModel<Article>
    var body: some View {
        if !item.article.isRead {
            Circle()
                .fill(.blue)
                .frame(width: 10, height: 10)
                .padding(.trailing, 3)
        }
    }
}

// いいねボタン
struct FavoriteButton: View {
    let item: ArticleModel<Article>
    let articleListFeature: StoreOf<ArticleListFeature>
    var body: some View {
        ImageButton(
            imageName: item.article.isFavorite ? "heart.fill" : "heart",
            btnSize: CGSize(width: 15, height: 15),
            btnColor: Color.favorite,
            btnAction: {
                articleListFeature.send(.updateFavoriteStatus(articleModel: item))
            }
        )
        .buttonStyle(.borderless)
    }
}

// アーカイブボタン
struct ArchiveButton: View {
    let item: ArticleModel<Article>
    let articleListFeature: StoreOf<ArticleListFeature>
    var body: some View {
        ImageButton(
            imageName: item.article.isHidden ? "eye.slash" : "eye",
            btnSize: CGSize(width: 15, height: 15),
            btnColor: Color.archive,
            btnAction: {
                articleListFeature.send(.updateArchiveStatus(articleModel: item))
            }
        )
        .buttonStyle(.borderless)
    }
}
