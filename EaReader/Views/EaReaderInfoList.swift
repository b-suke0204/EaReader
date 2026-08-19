//
//  EaReaderInfoList.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/11.
//

import SwiftUI
import ComposableArchitecture

// 26.08.11 B EaReader情報リスト
struct EaReaderInfoList: View {
    var body: some View {
        List {
            VStack {
                EaReaderInfoHeader()
                EaReaderInfo()
                // メンテナンス機能は、アップデートで対応
//                Divider()
//                VStack {
//                    AppMaintenanceHeader()
//                    DeleteCacheButton {
//                        print("キャッシュ削除ボタン")
//                    }
//                }
            }
        }
        .scrollDisabled(true)
//        .frame(height: 200)  // メンテナンスありの場合の高さ
        .frame(height: 150)
    }
}

// 26.08.11 B アプリヘッダー
struct EaReaderInfoHeader: View {
    var body: some View {
        HStack {
            Text("このアプリについて")
                .font(.caption2)
                .foregroundStyle(.gray)
            Spacer()
        }
    }
}

// 26.08.11 B EaReaderのアイコンやアプリ情報
struct EaReaderInfo: View {
    var body: some View {
        HStack {
            Image("EaReaderIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
            VStack {
                Text("EaReader")
                    .font(.body)
                    .foregroundStyle(.black)
                Text("version: 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.leading, 5)
            Spacer()
        }
    }
}

// 26.08.11 B メンテナンスヘッダー
struct AppMaintenanceHeader: View {
    var body: some View {
        HStack {
            Text("メンテナンス")
                .font(.footnote)
                .bold()
                .foregroundStyle(.gray)
            Spacer()
        }
    }
}

// 26.08.11 B キャッシュ削除ボタン
struct DeleteCacheButton: View {
    let btnAction: () -> Void
    var body: some View {
        Button(action: {
            // キャッシュ削除処理
            btnAction()
        }) {
            HStack {
                Text("キャッシュとクッキーを削除")
                    .foregroundStyle(.black)
                    .font(.body)
                Spacer()
            }
        }
        .buttonStyle(.borderless)
        .padding(.top, 1)
    }
}
