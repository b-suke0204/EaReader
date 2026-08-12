//
//  HomeViewUITests.swift
//  EaReaderUITests
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

@testable import EaReader
import XCTest
import ComposableArchitecture

// Home Viewのテスト用
final class HomeViewUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        self.app = XCUIApplication()
        // テストデータで使うキーを追加する
        self.app.launchArguments.append("HomeViewUITest")
        self.app.launch()
    }
    
    @MainActor
    func test_HomeViewを開いた時にUserFeedがあればListが表示されるか確かめる() {
        let homeStore = TestStore(initialState: HomeViewFeature.State(), reducer: { HomeViewFeature() })
        if (homeStore.state.deviceModel?.userFeeds.count ?? 0) != 0 {
            let list = self.app.collectionViews["FeedList"]
            XCTAssertTrue(list.exists)
        }
    }
    
    func test_SearchViewが開きました() {
        let searchButton = self.app.buttons["SearchButton"]
        searchButton.tap()
        let search = self.app.staticTexts["SearchTitle"]
        XCTAssertTrue(search.waitForExistence(timeout: 3))
    }
    
    func test_SearchViewが閉じました() {
        let searchButton = self.app.buttons["SearchButton"]
        searchButton.tap()
        let closeButton = self.app.buttons["SearchTitleCloseButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3))
        closeButton.tap()
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3))
    }
}
