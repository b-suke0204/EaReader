//
//  FeedHistoryStore.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation

// 26.08.10 B 記事の履歴
// 過去に取得した記事をローカルに保存しておき、表示する件数を多くする
// DBサーバーに保存した後は、ローカル保存のデータは削除するようにする
final class FeedHistoryStore {
    static let shared = FeedHistoryStore()

    // 1フィードあたりに保持する記事数の上限(無制限に増え続けないようにするため)
    private let maxItemsPerFeed = 300

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.searchrss.feedhistorystore")
    private var cache: [String: [Article]] = [:]
    private var isLoaded = false

    private init() {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        fileURL = baseDirectory.appendingPathComponent("feed_history.json")
    }

    // これまで蓄積した履歴に `newItems` をマージし、結果を返しつつディスクに保存する。
    // 同じ記事(id基準)は重複させず、日付の新しい順に並べ替えたうえで上限件数に丸める。
    @discardableResult
    func merge(feedURL: URL, newItems: [Article]) -> [Article] {
        queue.sync {
            loadIfNeeded()

            let key = feedURL.absoluteString
            var merged = cache[key] ?? []
            var seenIDs = Set(merged.map(\.id))

            for item in newItems where seenIDs.insert(item.id).inserted {
                merged.append(item)
            }

            merged.sort { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
            if merged.count > maxItemsPerFeed {
                merged = Array(merged.prefix(maxItemsPerFeed))
            }

            cache[key] = merged
            persist()
            return merged
        }
    }

    // 蓄積せず、保存済みの履歴だけを読み出す(即座に表示したい場合などに利用)。
    func history(feedURL: URL) -> [Article] {
        queue.sync {
            loadIfNeeded()
            return cache[feedURL.absoluteString] ?? []
        }
    }

    private func loadIfNeeded() {
        guard !isLoaded else { return }
        isLoaded = true
        guard let data = try? Data(contentsOf: fileURL) else { return }
        cache = (try? JSONDecoder().decode([String: [Article]].self, from: data)) ?? [:]
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}




