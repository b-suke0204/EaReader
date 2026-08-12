//
//  Protocol.swift
//  SegmentKit
//
//  Created by 野本瑛資 on 2025/11/03.
//

import SwiftUI

public protocol CapsuleSegmentType: CaseIterable, Identifiable, Equatable, Sendable {
    var title: String { get }
}
