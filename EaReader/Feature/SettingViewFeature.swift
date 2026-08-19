//
//  SettingViewFeature.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import Foundation
import ComposableArchitecture

@Reducer
struct SettingViewFeature {
    
    @ObservableState
    struct State: Equatable {
        var navSettingPath = StackState<Path.State>()
    }
    
    @Dependency(\.isPresented)
    var isPresented
    
    @Dependency(\.dismiss)
    var dismiss
    
    @Reducer
    enum Path {
        case maxLengthMenu
    }
    
    enum Action: BindableAction {
        case closeButtonTapped
        case setMaxLengthMenu(num: Int, device: Device?)
        case closeMaxLengthMenu(device: Device?)
        case maxLengthMenuButtonTapped
        case binding(BindingAction<State>)
        case navSettingPath(StackActionOf<Path>)
        case delegate(Delegate)
        
        public enum Delegate {
            case updateMaxLength(device: Device)
            case storeLatestDevice(device: Device)  // 最新のデバイス情報保存
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
            case .setMaxLengthMenu(let num, let device):
                // ここでDeviceを更新させる
                return .run { send in
                    guard var device = device else {
                        await send(.closeMaxLengthMenu(device: nil))
                        return
                    }
                    device.articleDisplayCount = num
                    print("ディスプレイ数: \(device.articleDisplayCount)")
                    let urlString = "http://localhost/api/devices/\(EaReaderConfig.deviceId)"
                    if let jsonEncode = await APISession.jsonEncode(from: device) {
                        let result: Result<Device, SessionErrorType> = await APISession.connect(
                            from: urlString,
                            data: jsonEncode,
                            httpMethod: .PATCH
                        )
                        
                        switch result {
                        case .success(let latestDevice):
                            print("最新ディスプレイ数: \(latestDevice.articleDisplayCount)")
                            await send(.closeMaxLengthMenu(device: latestDevice))
                            return
                        case .failure(let message):
                            print("更新に失敗しました: \(message)")
                        }
                    }
                    await send(.closeMaxLengthMenu(device: nil))
                }
            case .closeMaxLengthMenu(let device):
                state.navSettingPath.removeLast()
                guard let device = device else { return .none }
                return .send(.delegate(.updateMaxLength(device: device)))
            case .maxLengthMenuButtonTapped:
                state.navSettingPath.append(.maxLengthMenu)
                return .none
            case .navSettingPath:
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
        .forEach(\.navSettingPath, action: \.navSettingPath)
    }
}

extension SettingViewFeature.Path.State: Equatable {}
