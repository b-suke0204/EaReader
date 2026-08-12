//
//  FeedCandidateList.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import SwiftUI
import ComposableArchitecture

// 26.08.08 B Feed検索結果リスト
struct CandidateFeedList: View {
    let searchStore: StoreOf<SearchViewFeature>
    var body: some View {
        if searchStore.isLoading {
            VStack {
                Spacer()
                ProgressView("検索中…")
                Spacer()
            }
        } else if searchStore.candadateFeedsCount.isZero() {
            VStack {
                Spacer()
                ContentUnavailableView(
                    "見つかりませんでした",
                    systemImage: "link.circle",
                    description: Text("URLやキーワードを変えて再度お試しください。")
                )
                Spacer()
            }
        } else {
            List {
                ForEach(searchStore.candidates) { candidate in
                    CandidateListRowItem(candidate: candidate) { candidate in
                        print("押されました: \(candidate.title)")
                        searchStore.send(.selectListTapped(candidate: candidate))
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

// Feedリストの列
struct CandidateListRowItem: View {
    let candidate: FeedCandidate
    let btnAction: (FeedCandidate) -> Void
    var body: some View {
        Button(action: {
            btnAction(candidate)
        }) {
            HStack(alignment: .top, spacing: 12) {
                FeedListIconView(candidate: candidate)
                VStack {
                    Text("\(candidate.title)")
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// Feedリストのアイコン
struct FeedListIconView: View {
    let candidate: FeedCandidate
    var body: some View {
        if let iconURL = candidate.fetchEffectiveIconURL() {
            AsyncImage(url: iconURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else {
                    PlaceholderIcon(candidate: candidate)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            PlaceholderIcon(candidate: candidate)
        }
    }
}

// プレースホルダー用のアイコン
struct PlaceholderIcon: View {
    let candidate: FeedCandidate
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.accentColor.opacity(0.15))
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: candidate.source.systemImage)
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 14, weight: .medium))
            }
    }
}



