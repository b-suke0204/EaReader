//
//  SettingView.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import SwiftUI
import ComposableArchitecture

// 26.08.08 B 設定ビュー
struct SettingView: View {
    let homeStore: StoreOf<HomeViewFeature>
    @Bindable var settingStore: StoreOf<SettingViewFeature>
    var body: some View {
        NavigationStack(path: $settingStore.scope(state: \.navSettingPath, action: \.navSettingPath)) {
            VStack {
                HeaderView(headerTitle: "設定", identifier: "SettingTitle", closeButtonAction: {
                    settingStore.send(.closeButtonTapped)
                })
                VStack(spacing: 0) {
                    EaReaderSettingList(homeStore: homeStore, settingStore: settingStore)
                    EaReaderInfoList()
                }
                .cornerRadius(15)
                .frame(height: 400)
                Spacer()
            }
            .padding()
        } destination: { store in
            switch store.case {
            case .maxLengthMenu:
                ArticleListLengthMenu(settingStore: settingStore)
            }
        }
    }
}

// 26.08.11 B 記事一覧表示の最大数を選択するメニュー
struct ArticleListLengthMenu: View {
    private let limits: [Int] = [10, 20, 30, 50, 100, 150, 200]
    let settingStore: StoreOf<SettingViewFeature>
    var body: some View {
        VStack {
            List {
                ForEach(0..<limits.count, id: \.self) { index in
                    Button(action: {
                        let selectedNum = limits[index]
                        settingStore.send(.closeMaxLengthMenu(num: selectedNum))
                    }) {
                        VStack {
                            Text("最大\(limits[index])件 表示")
                                .foregroundStyle(.black)
                                .font(.body)
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .navigationTitle("記事数設定")
    }
}

