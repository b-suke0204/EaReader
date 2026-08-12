//
//  UIComponents.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/05.
//

import SwiftUI

// 26.08.05 B 共通で使っているビュー部品

// 26.08.05 B 画像ボタン
struct ImageButton: View {
    let imageName: String
    let btnSize: CGSize
    let isSystem: Bool
    var btnColor: Color = .gray
    let btnAction: () -> Void
    
    init(imageName: String, btnSize: CGSize, isSystem: Bool = true, btnColor: Color = .gray, btnAction: @escaping () -> Void) {
        self.imageName = imageName
        self.btnSize = btnSize
        self.isSystem = isSystem
        self.btnColor = btnColor
        self.btnAction = btnAction
    }
    
    var body: some View {
        Button(action: {
            btnAction()
        }) {
            BImage()
                .resizable()
                .scaledToFit()
                .foregroundStyle(btnColor)
                .frame(width: btnSize.width, height: btnSize.height)
        }
    }
    
    private func BImage() -> Image {
        isSystem ? Image(systemName: imageName) : Image(imageName)
    }
}

struct TextButton: View {
    let btnTitle: String
    let btnColor: Color
    let btnSize: CGSize
    let btnAction: () -> Void
    var body: some View {
        Button(action: {
            btnAction()
        }) {
            Text(btnTitle)
                .foregroundStyle(btnColor)
                .frame(width: btnSize.width, height: btnSize.height)
        }
    }
}

// 26.08.12 B ツールバー画像ボタン
struct ToolbarImageButton: ToolbarContent {
    let imageName: String
    let btnColor: Color
    let placement: ToolbarItemPlacement
    let isSystem: Bool
    let btnAction: () -> Void
    
    init(imageName: String, btnColor: Color, placement: ToolbarItemPlacement, isSystem: Bool = true, btnAction: @escaping () -> Void) {
        self.imageName = imageName
        self.btnColor = btnColor
        self.placement = placement
        self.isSystem = isSystem
        self.btnAction = btnAction
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button(action: {
                btnAction()
            }) {
                BImage()
                    .scaledToFit()
                    .foregroundStyle(btnColor)
            }
        }
    }
    
    private func BImage() -> Image {
        isSystem ? Image(systemName: imageName) : Image(imageName)
    }
}

// 26.08.05 B アイコンビュー
struct IconView: View {
    var number: Int
    let iconName: String
    let iconColor: Color
    var isTextIcon: Bool = false
    
    init(number: Int, iconName: String, iconColor: Color, isTextIcon: Bool = false) {
        self.number = number
        self.iconName = iconName
        self.iconColor = iconColor
        self.isTextIcon = isTextIcon
    }
    
    var body: some View {
        HStack(spacing: 5) {
            if isTextIcon {
                Text(iconName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(iconColor)
                    .frame(width: 35, height: 15)
            } else {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(iconColor)
                    .frame(width: 25, height: 15)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 7.5)
                    .fill(iconColor)
                Text("\(number)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .frame(width: 25, height: 15)
        }
    }
}

// ヘッダービュー 26.08.08 B
struct HeaderView: View {
    let headerTitle: String
    let identifier: String
    let closeButtonAction: () -> Void
    var body: some View {
        HStack {
            CloseButton(buttonId: identifier) {
                closeButtonAction()
            }
            Spacer()
            Text(headerTitle)
                .accessibilityIdentifier(identifier)
            Spacer()
            CustomEmptyView(size: CGSize(width: 60, height: 30))
        }
    }
}


// 26.08.06 B 閉じるボタン
struct CloseButton: View {
    let buttonId: String
    let btnAction: () -> Void
    private let btnSize: CGSize = CGSize(width: 60, height: 30)
    var body: some View {
        TextButton(btnTitle: "閉じる", btnColor: .blue, btnSize: btnSize, btnAction: btnAction)
            .accessibilityIdentifier("\(buttonId)CloseButton")
    }
}

// 26.08.06 B カスタムEmptyView作成
// 見えない長方形を置いて、サイズがある透明ビューを貼って位置調整できるようにするために使用
struct CustomEmptyView: View {
    let size: CGSize
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0))
            .frame(width: size.width, height: size.height)
    }
}

