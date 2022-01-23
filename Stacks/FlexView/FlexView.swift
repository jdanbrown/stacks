// From https://github.com/berbschloe/FlexView/blob/main/FlexView/SizeReader.swift
//  - 2021-07-05 Created by Brandon Erbschloe

import SwiftUI

public struct FlexView<Data: Collection, Content: View>: View where Data.Element: Hashable {

  private let data: Data
  private let alignment: HorizontalAlignment
  private let horizontalSpacing: CGFloat
  private let verticalSpacing: CGFloat
  private let content: (Data.Element) -> Content

  @State private var availableWidth: CGFloat = 0

  public init(
    _ data: Data,
    alignment: HorizontalAlignment = .leading,
    horizontalSpacing: CGFloat = 8,
    verticalSpacing: CGFloat = 2,
    content: @escaping (Data.Element) -> Content
  ) {
    self.data = data
    self.horizontalSpacing = horizontalSpacing
    self.verticalSpacing = verticalSpacing
    self.alignment = alignment
    self.content = content
  }

  public var body: some View {
    ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
      Rectangle()
        .foregroundColor(Color.clear)
        .frame(height: 0)
        .readSize { size in availableWidth = size.width }
      _FlexView(
        availableWidth: availableWidth,
        data: data,
        alignment: alignment,
        horizontalSpacing: horizontalSpacing,
        verticalSpacing: verticalSpacing,
        content: content
      )
    }
  }

}
