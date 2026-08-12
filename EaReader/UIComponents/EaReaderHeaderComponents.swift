//
//  EaReaderHeaderComponents.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/05.
//

import SwiftUI
import ComposableArchitecture

// 26.08.04 B EaReaderのヘッダー
struct EaReaderHeader: View {
    let homeStore: StoreOf<HomeViewFeature>
    let headerText: String
    private let btnSize: CGSize = CGSize(width: 20, height: 20)
    
    var body: some View {
        VStack {
            HStack {
                SearchButton(homeStore: homeStore, btnSize: btnSize)
                    .padding(.leading, 10).accessibilityIdentifier("SearchButton")
                Spacer()
                Text(headerText)
                    .font(.headline)
                Spacer()
                SettingButton(homeStore: homeStore, btnSize: btnSize)
                    .padding(.trailing, 10)
            }
            if let latestUpdatedAt = homeStore.deviceModel?.device.latestUpdatedAt {
                BadgeView(date: latestUpdatedAt)
            }
        }
    }
}

// 26.08.04 B バッジビュー
struct BadgeView: View {
    let date: Date
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.blue)
                .frame(width: 10, height: 10)
            Text(dateString)
                .font(.caption2)
                .frame(height: 10)
        }
    }
    
    var dateString: String {
        DateUtility.getDateString(from: date, formatType: .YMDLineHMSColon)
    }
}

// 26.08.04 B 検索ボタン
struct SearchButton: View {
    let homeStore: StoreOf<HomeViewFeature>
    let btnSize: CGSize
    var body: some View {
        ImageButton(imageName: "magnifyingglass", btnSize: btnSize) {
            homeStore.send(.searchButtonTapped)
        }
    }
}

// 26.08.04 B 設定ボタン
struct SettingButton: View {
    let homeStore: StoreOf<HomeViewFeature>
    let btnSize: CGSize
    var body: some View {
        ImageButton(imageName: "gearshape", btnSize: btnSize) {
            homeStore.send(.settingButtonTapped)
        }
    }
}


