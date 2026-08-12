//
//  RSSSearchView.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import SwiftUI
import SegmentKit
import ComposableArchitecture

// TODO: RSSにFeatureを作成しないと検索後の処理が伝播できない

// 26.08.08 B 検索ビュー
struct RSSSearchView: View {
    @Bindable var searchStore: StoreOf<SearchViewFeature>
    var body: some View {
        VStack {
            HeaderView(headerTitle: "検索", identifier: "SearchTitle", closeButtonAction: {
                searchStore.send(.closeButtonTapped)
            })
            CapsuleSegment(
                segmentSize: CGSize(width: 200, height: 30),
                selectedSegment: $searchStore.searchKind,
                Text: { title in
                    Text(title)
                }
            )
            SearchField(searchStore: searchStore)
            // リスト表示
            CandidateFeedList(searchStore: searchStore)
            Spacer()
        }
        .padding()
        .alert(store: searchStore.scope(state: \.$alertRegistration, action: \.registerAlert))
    }
}

struct SearchField: View {
    @Bindable var searchStore: StoreOf<SearchViewFeature>
    var body: some View {
        VStack {
            TextField(placeholder, text: $searchStore.text)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .padding()
                .onSubmit {
                    searchStore.send(.searchFeed)
                }
        }
    }
    
    private var placeholder: String {
        let searchKind = searchStore.searchKind
        switch searchKind {
        case .url:
            return "Feed URLを入力"
        case .keyword:
            return "キーワードを入力 例) Qiita, github"
        }
    }
}

enum SearchKind: LocalizedStringKey, CapsuleSegmentType {
    var title: String {
        self.getTitle()
    }
    
    var id: Self {
        self
    }
    
    case url = "URL"
    case keyword = "KEYWORD"
    
    func getTitle() -> String {
        switch self {
        case .url:
            return "URL"
        case .keyword:
            return "キーワード"
        }
    }
}



