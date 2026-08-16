//
//  SearchViewFeature.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import SwiftUI
import ComposableArchitecture
import Combine

// 26.08.08 B Feed検索候補のFeature作成
@Reducer
struct SearchViewFeature {
    
    @ObservableState
    struct State: Equatable {
        @Presents var alertRegistration: AlertState<Action.Alert>?
        // 検索候補Feeds
        var candidates: [FeedCandidate] = FeedCandidateMockModel.getMockData()
        var selectedCandidate: FeedCandidate?  // 選択されたFeed候補
        
        // 検索ビューでの処理
        var searchKind: SearchKind = .keyword
        var text: String = ""
        var isLoading: Bool = false
        
        var candadateFeedsCount: Int {
            self.candidates.count
        }
    }
    
    @Dependency(\.isPresented)
    var isPresented
    
    @Dependency(\.dismiss)
    var dismiss
    
    enum Action: BindableAction {
        case closeButtonTapped
        case selectListTapped(candidate: FeedCandidate)
        case registerAlert(PresentationAction<Alert>)
        case searchedFeed
        case searchFeed
        case searchCompleted([FeedCandidate])
        case showRegistrationAlert  // 登録失敗アラート
        case delegate(Delegate)
        case binding(BindingAction<State>)
        
        public enum Alert: Equatable {
            case register
            case cancel
        }
        
        public enum Delegate {
            case updateItem(UserFeedModel<UserFeed, Article>)
        }
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                guard isPresented else { return .none }
                return .run { _ in
                    await dismiss()
                }
            case .selectListTapped(let candidate):
                state.selectedCandidate = candidate
                state.alertRegistration = .init(title: {
                    TextState("\(candidate.title) を登録しますか？")
                }, actions: {
                    ButtonState(role: .cancel, action: .cancel) {
                        TextState("キャンセル")
                    }
                    ButtonState(role: .none, action: .register) {
                        TextState("OK")
                    }
                })
                return .none
            case .searchFeed:
                return self.searchFeed(&state)
            case .searchCompleted(let candidates):
                state.isLoading = false
                state.candidates.removeAll()
                state.candidates = candidates
                return .none
            case .registerAlert(.presented(.register)):
                print("Feedを登録します。")
                print("\(String(describing: state.selectedCandidate))")
                
//                guard let feed = state.selectedCandidate else { return .none }
                guard let feedCandidate = state.selectedCandidate else { return .none }
                
                let now = Date()
                let userFeed = UserFeed(
                    id: 0,  // このidは、DBにあるIDに置き換えるので、0でOK
                    deviceId: EaReaderConfig.deviceId,
                    feedTitle: feedCandidate.title,
                    link: feedCandidate.feedURL,
                    summary: feedCandidate.summary,
                    iconURL: feedCandidate.iconURL,
                    source: feedCandidate.source.rawValue,
                    lastUpdatedAt: now,
                    createdAt: now,
                    updatedAt: now,
                    deletedAt: nil
                )
                
                // 処理をまとめてデータをHomeViewに送信後に画面を閉じるようにする
                return .run { send in
                    if let jsonEncode = await APISession.jsonEncode(from: userFeed) {
                        let urlString = "http://localhost/api/userFeeds"
                        let result: Result<UserFeed, SessionErrorType> = await APISession.connect(
                            from: urlString,
                            data: jsonEncode
                        )
                        switch result {
                        case .success(let feed):
                            print("終わりました: \(feed)")
                            let targetFeed: UserFeedModel<UserFeed, Article> = UserFeedModel(
                                userFeed: feed,
                                articles: [],
                                feedCandidate: feedCandidate
                            )
                            await send(.delegate(.updateItem(targetFeed)))
                            await dismiss()
                        case .failure:
                            await send(.showRegistrationAlert)
                            return
                        }
                    }
                    await dismiss()
                }
                
//                return .merge(
//                    .send(.delegate(.updateItem(targetFeed))),
//                    .run { _ in
//                        if let jsonEncode = await APISession.jsonEncode(from: userFeed) {
//                            let urlString = "http://localhost/api/userFeeds"
//                            let result: Result<UserFeed, SessionErrorType> = await APISession.connect(
//                                from: urlString,
//                                data: jsonEncode
//                            )
//                            switch result {
//                            case .success(let feed):
//                                print("終わりました: \(feed)")
//                                await dismiss()
//                            case .failure:
//                                await dismiss()
//                            }
//                        }
//                        await dismiss()
//                    }
//                )
            case .registerAlert(.presented(.cancel)):
                state.selectedCandidate = nil
                print("Feed登録をキャンセルしました")
                return .none
            case .showRegistrationAlert:  // フィード登録エラーアラート
                state.alertRegistration = .init(title: {
                    TextState("フィード登録に失敗しました")
                }, actions: {
                    ButtonState(role: .none, action: .cancel) {
                        TextState("OK")
                    }
                })
                return .none
            case .registerAlert(.dismiss):
                state.selectedCandidate = nil
                return .none
            case .delegate:
                return .none
            case .binding:
                return .none
            default: return .none
            }
        }
        // ifLetをつけてPresentation処理がReducerに組み込まれるようにする
        // そうしないとregisterAlertがずっと残り続けてしまう
        .ifLet(\.$alertRegistration, action: \.registerAlert)
    }
    
    private let searchCancellationID = "SearchViewFeature.search"
    
    private func searchFeed(_ state: inout State) -> Effect<Action> {
        let trimmed = state.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state.isLoading = false
            return .none
        }
        
        state.isLoading = true
        
        let publisher: AnyPublisher<[FeedCandidate], Never>
        
        switch state.searchKind {
        case .url:
            publisher = FeedSearchOrchestrator.searchByURL(trimmed)
        case .keyword:
            publisher = FeedSearchOrchestrator.searchByKeyword(trimmed)
        }
        
        return .publisher {
            publisher
                .map(Action.searchCompleted)
        }
        .cancellable(id: self.searchCancellationID, cancelInFlight: true)
    }
}
