//
//  SearchViewTests.swift
//  EaReaderTests
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import Testing
@testable import EaReader
import ComposableArchitecture
import Foundation

struct SearchViewTests {
    
    @Test("リストの項目が選択される")
    func selectFeedCandidateList() async {
        let listFeedStore = await TestStore(initialState: SearchViewFeature.State(), reducer: {
            SearchViewFeature()
        })
        if let url = URL(string: "https://qiita.com") {
            let candidate = FeedCandidate(feedURL: url, title: "テスト", source: .direct)
            await listFeedStore.send(.selectListTapped(candidate: candidate))
            #expect(candidate.title == "テスト")
        }
    }
}



