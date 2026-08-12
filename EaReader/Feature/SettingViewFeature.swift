//
//  SettingViewFeature.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/08.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct SettingViewFeature {
    
    @ObservableState
    struct State: Equatable {
        var navSettingPath = StackState<Path.State>()
    }
    
    @Dependency(\.isPresented) var isPresented
    @Dependency(\.dismiss) var dismiss
    
    @Reducer
    enum Path {
        case maxLengthMenu
    }
    
    enum Action: BindableAction {
        case closeButtonTapped
        case closeMaxLengthMenu(num: Int)
        case maxLengthMenuButtonTapped
        case binding(BindingAction<State>)
        case navSettingPath(StackActionOf<Path>)
        case delegate(Delegate)
        
        public enum Delegate {
            case updateMaxLength(num: Int)
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
            case .closeMaxLengthMenu(let num):
                state.navSettingPath.removeLast()
                return .send(.delegate(.updateMaxLength(num: num)))  // HomeViewに伝播
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
