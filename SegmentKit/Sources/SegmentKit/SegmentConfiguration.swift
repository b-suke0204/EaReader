//
//  SegmentConfiguration.swift
//  SegmentKit
//
//  Created by 野本瑛資 on 2025/11/03.
//

import SwiftUI

public struct SegmentConfiguration<SegmentType: CapsuleSegmentType> {
    public var backgroundColor: Color
    public var selectedColor: Color
    public var fontSize: CGFloat?
    public var targetSegmentType: [SegmentType]?  // 任意の条件を指定
    public var supportsRect: Bool  // 長方形にするかどうか
    
    public init(
        backgroundColor: Color = Color(red: 213 / 255, green: 213 / 255, blue: 213 / 255),
        selectedColor: Color = .white,
        fontSize: CGFloat? = nil,
        targetSegmentType: [SegmentType]? = nil,
        supportsRect: Bool = false
    ) {
        self.backgroundColor = backgroundColor
        self.selectedColor = selectedColor
        self.fontSize = fontSize
        self.targetSegmentType = targetSegmentType
        self.supportsRect = supportsRect
    }
}
