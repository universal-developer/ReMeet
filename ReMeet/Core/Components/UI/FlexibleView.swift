//
//  FlexibleView.swift
//  ReMeet
//
//  Created by Artush on 12/05/2025.
//

import SwiftUI

struct FlexibleView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            self.generateContent()
        }
        .frame(height: totalHeight)
    }

    private func generateContent() -> some View {
        return GeometryReader { geometry in
            self.generateWrappedContent(in: geometry)
        }
    }

    private func generateWrappedContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(Array(self.data), id: \.self) { item in
                content(item)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .alignmentGuide(.leading) { dimension in
                        if (abs(width - dimension.width) > g.size.width) {
                            width = 0
                            height -= dimension.height + spacing
                        }
                        let result = width
                        if item == self.data.last {
                            width = 0 // reset for next redraw
                        } else {
                            width -= dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in height }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geometry.size.height
            }
            return Color.clear
        }
    }
}
