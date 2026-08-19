//
//  DeleteFeedAlertFeature.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/19.
//

import Foundation
import ComposableArchitecture

// HomeViewFeatureが長いので削除アラート関連の処理を別Featureに変更
@Reducer
struct DeleteFeedAlertFeature {
    
    @ObservableState
    struct State: Equatable {
        @Presents var deleteAlert: AlertState<Action.Alert>?
        
        var deviceModel: DeviceModel<Device, UserFeed, Article>?
        var targetUserFeed: UserFeedModel<UserFeed, Article>?
    }
    
    enum Action {
        case getDeleteIndex(feed: UserFeedModel<UserFeed, Article>, device: DeviceModel<Device, UserFeed, Article>)
        // Feed削除アラート表示
        case showDeleteItemAlert(
            feed: UserFeedModel<UserFeed, Article>,
            device: DeviceModel<Device, UserFeed, Article>
        )
        case showErrorAlert(message: String)
        case deleteAlert(PresentationAction<Alert>)
        case delegate(Delegate)
        
        public enum Alert: Equatable {
            case ok
            case delete(feed: UserFeedModel<UserFeed, Article>, device: DeviceModel<Device, UserFeed, Article>)
            case cancel
        }
        
        public enum Delegate {
            case deleteFeedItem(targetIndex: Int)
        }
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .showDeleteItemAlert(let feed, let device):
                // 削除用アラート表示
                let alertMessage = "このフィードを削除しますか？\n削除したら、元に戻せません \(feed.userFeed.feedTitle)"
                state.deleteAlert = .init(title: {
                    TextState(alertMessage)
                }, actions: {
                    ButtonState(role: .cancel, action: .cancel) {
                        TextState("キャンセル")
                    }
                    ButtonState(role: .none, action: .delete(feed: feed, device: device)) {
                        TextState("OK")
                    }
                })
                return .none
            case .showErrorAlert(let message):
                state.deleteAlert = .init(title: {
                    TextState(message)
                }, actions: {
                    ButtonState(role: .none, action: .ok) {
                        TextState("OK")
                    }
                })
                return .none
            case .deleteAlert(.presented(.delete(let feed, let deviceModel))):
                // FeedのIDからサーバー送信用のJSONデータ作成用にCodableの構造体に入れる
                let feedId = feed.userFeed.id
                let id = JSONID(id: feedId)
                guard let jsonEncodeID = APISession.jsonEncode(from: id) else {
                    return .none
                }
                
                return .run { send in
                    let deleteFeedURLString = "http://localhost/api/userFeeds/\(feedId)"
                    async let resultFeed: Result<JSONID, SessionErrorType> = APISession.connect(
                        from: deleteFeedURLString,
                        data: jsonEncodeID,
                        httpMethod: .DELETE
                    )
                    
                    // 記事削除用URL
                    let deleteArticlesURLString = "http://localhost/api/articles/\(feedId)"
                    async let resultArticles: Result<JSONID, SessionErrorType> = APISession.connect(
                        from: deleteArticlesURLString,
                        data: jsonEncodeID,
                        httpMethod: .DELETE
                    )
                    // 記事とFeedが削除されるまで待つ
                    // (Result<UserFeed, SessionErrorType>, Result<Article, SessionErrorType>)
                    let allResult = await (resultFeed, resultArticles)
                    
                    switch allResult {
                    case (.success, .success):
                        await send(.getDeleteIndex(feed: feed, device: deviceModel))
                    case (.failure, .failure):
                        print("どちらも失敗しています")
                        await send(.showErrorAlert(message: "データ削除に失敗しました"))
                    case (.failure(let errorType), _):
                        print("失敗しています FEED")
                        if case let .error(message: message, code: code) = errorType {
                            let codeStr: String = code != nil ? ": \(String(describing: code))" : ""
                            let alertMessage = "\(message)\(codeStr)"
                            await send(.showErrorAlert(message: alertMessage))
                        }
                        return
                    case (_, .failure(let errorType)):
                        print("失敗しています ARTICLE")
                        if case let .error(message: message, code: code) = errorType {
                            let codeStr: String = code != nil ? ": \(String(describing: code))" : ""
                            let alertMessage = "\(message)\(codeStr)"
                            await send(.showErrorAlert(message: alertMessage))
                        }
                        return
                    }
                }
            case .getDeleteIndex(let feed, let deviceModel):
                guard let targetIndex = deviceModel.userFeeds.firstIndex(where: { $0.id == feed.id }) else {
                    return .none
                }
                return .send(.delegate(.deleteFeedItem(targetIndex: targetIndex)))
            case .deleteAlert(.presented(.cancel)):
                return .none
            default:
                return .none
            }
        }
        .ifLet(\.$deleteAlert, action: \.deleteAlert)
    }
}
