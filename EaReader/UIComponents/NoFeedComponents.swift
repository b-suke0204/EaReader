//
//  NoFeedComponents.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/04.
//

import SwiftUI
import ComposableArchitecture

struct NoFeedView: View {
    let homeStore: StoreOf<HomeViewFeature>
    var body: some View {
        VStack {
            Spacer()
            NoFeedText()
            PlusButton(btnSize: 60, btnAction: {
                homeStore.send(.searchButtonTapped)
            })
            Spacer()
        }
        .padding()
    }
}

// Feedが追加されていない時のテキスト
struct NoFeedText: View {
    var body: some View {
        Text("まだフィードは追加されていません")
            .fontWeight(.bold)
            .foregroundStyle(.gray)
    }
}

struct PlusButton: View {
    let btnSize: CGFloat
    let btnAction: () -> Void
    var body: some View {
        ImageButton(imageName: "plus.app", btnSize: CGSize(width: btnSize, height: btnSize), btnColor: .blue) {
            btnAction()
        }
    }
}



