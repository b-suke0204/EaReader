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
    
    @Test("リストの項目が選択されるとアラートが表示される")
    func selectFeedCandidateList() async {
        let listFeedStore = await TestStore(initialState: SearchViewFeature.State(), reducer: {
            SearchViewFeature()
        })
        if let url = URL(string: "https://qiita.com") {
            let candidate = FeedCandidate(feedURL: url, title: "テスト", source: .direct)
            await listFeedStore.send(.selectListTapped(candidate: candidate)) {
                $0.selectedCandidate = candidate
                $0.alertRegistration = .init(title: {
                    TextState("\(candidate.title) を登録しますか？")
                }, actions: {
                    ButtonState(role: .cancel, action: .cancel) {
                        TextState("キャンセル")
                    }
                    ButtonState(role: .none, action: .register) {
                        TextState("OK")
                    }
                })
                #expect($0.alertRegistration != nil)
            }
            #expect(candidate.title == listFeedStore.state.selectedCandidate?.title)
        }
    }
}
