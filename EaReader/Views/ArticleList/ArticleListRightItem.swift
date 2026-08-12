//
//  ArticleListRightItem.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/12.
//

import SwiftUI
import ComposableArchitecture

// 記事一覧右側アイテム
struct ArticleListRightItem: View {
    let item: ArticleModel<Article>
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ArticleTitle(item: item)
            ArticlePuplishedDate(item: item)
            ArticleSummary(item: item)
        }
    }
}

// 記事タイトル
struct ArticleTitle: View {
    let item: ArticleModel<Article>
    var body: some View {
        Text(item.article.articleTitle)
            .font(.headline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
    }
}

// 出版日
struct ArticlePuplishedDate: View {
    let item: ArticleModel<Article>
    var body: some View {
        if let publishedDate = item.article.publishedAt {
            Text(publishedDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// 記事の要約
struct ArticleSummary: View {
    let item: ArticleModel<Article>
    var body: some View {
        if let summary = item.article.summary, !summary.isEmpty {
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
    }
}



