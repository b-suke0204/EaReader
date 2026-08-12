//
//  ArticleThumnailFeature.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation
import ComposableArchitecture
import Combine

@Reducer
struct ArticleThumnailFeature {
    
    @ObservableState
    struct State: Equatable {
        var resolveURL: URL? = nil
        var didFinishResolving = false
    }
    
    enum Action {
        case onAppear(item: Article)
        case resolvedThumbnail(url: URL?)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear(let item):
                // サムネイル解決処理実行
                return .run { send in
                    let url = await resolveThumbnail(for: item/*, state: &state*/)
                    return await send(.resolvedThumbnail(url: url))
                }
            case .resolvedThumbnail(let url):
                state.didFinishResolving = true
                state.resolveURL = url
                return .none
            }
        }
    }
    
    // サムネイルのURL解決
    private func resolveThumbnail(for item: Article) async -> URL? {
        var resolveURL: URL? = item.thumbnailURL
        
        guard item.thumbnailURL == nil else {
            return nil
        }
        guard let link = item.articleLink else { return nil }
        let cached = await ArticleThumbnailCache.shared.lookup(for: link)
        if cached.isCached {  // キャッシュされている場合
            resolveURL = cached.resolvedValue
            return resolveURL
        }
        
        for await value in ArticleThumbnailResolver.resolveThumbnail(for: link).values {
            await ArticleThumbnailCache.shared.store(value, for: link)
            resolveURL = value
            break
        }
        return resolveURL
    }
}




