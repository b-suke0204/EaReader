// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public struct CapsuleSegment<
    SegmentType: CapsuleSegmentType,
    Content: View
>: View where SegmentType.AllCases == [SegmentType] {
    public let segmentSize: CGSize
    @Binding var selectedSegment: SegmentType
    public var configuration: SegmentConfiguration<SegmentType>
    private let spacing: CGFloat = 5
    @ViewBuilder let Text: (String) -> Content
    
    public init(
        segmentSize: CGSize,
        selectedSegment: Binding<SegmentType>,
        configuration: SegmentConfiguration<SegmentType> = SegmentConfiguration(),
        Text: @escaping (String) -> Content
    ) {
        self.segmentSize = segmentSize
        self._selectedSegment = selectedSegment
        self.configuration = configuration
        self.Text = Text
    }
    
    public var body: some View {
        let cases = configuration.targetSegmentType ?? SegmentType.allCases
        let segmentWidth = (segmentSize.width - spacing * 3) / CGFloat(cases.count) - spacing / 2
        ZStack {
            CapsuleSegmentBackground(
                segmentSize: segmentSize,
                configuration: configuration,
                spacing: spacing
            )
            CapsuleSegmentSelectedItem(
                segmentSize: segmentSize,
                selectedSegment: $selectedSegment,
                configuration: configuration,
                segmentWidth: segmentWidth,
                spacing: spacing
            )
            CapsuleSegmentItem(
                segmentSize: segmentSize,
                selectedSegment: $selectedSegment,
                configuration: configuration,
                segmentWidth: segmentWidth,
                spacing: spacing,
                Text: Text
            )
        }
        .frame(width: segmentSize.width, height: segmentSize.height)
    }
}

// カスタムセグメントの背景
struct CapsuleSegmentBackground<SegmentType: CapsuleSegmentType>: View {
    let segmentSize: CGSize
    var configuration: SegmentConfiguration<SegmentType>
    let spacing: CGFloat
    var body: some View {
        let radius = configuration.supportsRect ? (spacing) : (segmentSize.height - 2) / 2
        RoundedRectangle(cornerRadius: radius)
            .fill(configuration.backgroundColor)
    }
}

// セグメント選択時の背景ビュー
struct CapsuleSegmentSelectedItem<SegmentType: CapsuleSegmentType>: View where SegmentType.AllCases == [SegmentType] {
    let segmentSize: CGSize
    @Binding var selectedSegment: SegmentType
    var configuration: SegmentConfiguration<SegmentType>
    let segmentWidth: CGFloat
    let spacing: CGFloat
    var body: some View {
        let radius = configuration.supportsRect ? (spacing) : (segmentSize.height - 2) / 2
        RoundedRectangle(cornerRadius: radius)
            .fill(.white)
            .stroke(Color(red: 213 / 255, green: 213 / 255, blue: 213 / 255), style: StrokeStyle(lineWidth: 1))
            .frame(width: segmentWidth, height: segmentSize.height - 8)
            .offset(x: selectedOffset(segmentWidth: segmentWidth))
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.75), value: selectedSegment)
    }
    
    // 選択された位置までの差分
    private func selectedOffset(segmentWidth: CGFloat) -> CGFloat {
        let cases = configuration.targetSegmentType ?? SegmentType.allCases
        guard let index = cases.firstIndex(of: selectedSegment) else { return 0 }
        let baseOffset = CGFloat(index) * (segmentWidth + spacing)
        let centerAdjustment = -(CGFloat(cases.count - 1) * (segmentWidth + spacing) / 2)
        return baseOffset + centerAdjustment
    }
}

// カスタムセグメントの中身
struct CapsuleSegmentItem<
    SegmentType: CapsuleSegmentType,
    Content: View
>: View where SegmentType.AllCases == [SegmentType] {
    let segmentSize: CGSize
    @Binding var selectedSegment: SegmentType
    var configuration: SegmentConfiguration<SegmentType>
    let segmentWidth: CGFloat
    let spacing: CGFloat
    @ViewBuilder let Text: (String) -> Content
    var body: some View {
        let cases = configuration.targetSegmentType ?? SegmentType.allCases
        HStack(spacing: spacing) {
            ForEach(cases) { segment in
                Button(action: {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.75)) {
                        selectedSegment = segment
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: (segmentSize.height - 2) / 2)
                            .fill(.clear)
                        Text(segment.title)
                            .font(.system(size: configuration.fontSize ?? 15))
                            .foregroundStyle(.black)
                    }
                    .frame(width: segmentWidth, height: segmentSize.height - spacing)
                }
                .background(Color.clear)
            }
        }
    }
}
