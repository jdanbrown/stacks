// From https://github.com/berbschloe/FlexView/blob/main/FlexView/SizeReader.swift
//  - 2021-07-05 Created by Brandon Erbschloe

import SwiftUI

extension View {
  func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
    background(
      GeometryReader { geometryProxy in
        Rectangle()
          .foregroundColor(Color.clear)
          .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
      }
    )
      .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
  }
}

struct SizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
