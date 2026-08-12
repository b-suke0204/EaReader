//
//  SafariWebView.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import SwiftUI
import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

import ComposableArchitecture

@Reducer
struct SafariWebFeature {
    
    @ObservableState
    struct State: Equatable {
        
    }
    
    enum Action {
        
    }
    
    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
