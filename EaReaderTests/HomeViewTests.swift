//
//  HomeViewTests.swift
//  EaReaderTests
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import Testing
@testable import EaReader
import ComposableArchitecture
import Foundation

struct HomeViewTests {
    
    @Test("検索ボタンを押すと検索画面のDestinationになっている")
    func showSearchView() async {
        let homeStore = await TestStore(initialState: HomeViewFeature.State(), reducer: { HomeViewFeature() })
        await homeStore.send(.searchButtonTapped) {
            $0.destination = .searchViewFeature(SearchViewFeature.State())
        }
    }
    
    @Test("設定ボタンを押すと設定画面のDestinationになっている")
    func showSettignView() async {
        let homeStore = await TestStore(initialState: HomeViewFeature.State(), reducer: { HomeViewFeature() })
        await homeStore.send(.settingButtonTapped) {
            $0.destination = .settingViewFeature(SettingViewFeature.State())
        }
    }
}



