//
//  EaReaderSettingList.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/11.
//

import SwiftUI
import ComposableArchitecture

struct EaReaderSettingList: View {
    let homeStore: StoreOf<HomeViewFeature>
    let settingStore: StoreOf<SettingViewFeature>
    var body: some View {
        List {
            DisplaySettingButton(settingStore: settingStore, articleMaxLength: homeStore.articleMaxLength)
            AddArticleButton(homeStore: homeStore)
        }
        .scrollDisabled(true)
        .frame(height: 140)
    }
}

struct DisplaySettingButton: View {
    let settingStore: StoreOf<SettingViewFeature>
    let articleMaxLength: Int
    var body: some View {
        Button(action: {
            settingStore.send(.maxLengthMenuButtonTapped)
        }) {
            HStack {
                Text("表示設定")
                    .foregroundStyle(.black)
                Spacer()
                Text("最新\(articleMaxLength)件")
                    .foregroundStyle(.gray)
                    .font(.body)
                    .padding(.trailing, 30)
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.gray)
                    .frame(width: 15, height: 15)
            }
        }
    }
}

struct AddArticleButton: View {
    let homeStore: StoreOf<HomeViewFeature>
    var body: some View {
        Button(action: {
            // 検索画面へ移動
            homeStore.send(.searchButtonTapped)
        }) {
            HStack {
                Text("記事追加")
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.gray)
                    .frame(width: 15, height: 15)
            }
        }
    }
}





