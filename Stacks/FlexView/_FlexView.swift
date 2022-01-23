// From https://github.com/berbschloe/FlexView/blob/main/FlexView/SizeReader.swift
//  - 2021-07-05 Created by Brandon Erbschloe

import SwiftUI

struct _FlexView<Data: Collection, Content: View>: View where Data.Element: Hashable {

  let availableWidth: CGFloat
  let data: Data
  let alignment: HorizontalAlignment
  let horizontalSpacing: CGFloat
  let verticalSpacing: CGFloat
  let content: (Data.Element) -> Content

  @State var elementsSize: [Data.Element: CGSize] = [:]

  var body: some View {
    VStack(alignment: alignment, spacing: verticalSpacing) {
      ForEach(computeRows(), id: \.self) { rowElements in
        HStack(spacing: horizontalSpacing) {
          ForEach(rowElements, id: \.self) { element in
            content(element)
              .fixedSize()
              .readSize { size in
                elementsSize[element] = size
              }
          }
        }
      }
    }
  }

  func computeRows() -> [[Data.Element]] {
    var rows: [[Data.Element]] = [[]]
    var currentRow = 0
    var remainingWidth = availableWidth
    for element in data {
      let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 0)]
      var horizontalSpacing = rows[currentRow].count != 0 ? self.horizontalSpacing : 0
      if remainingWidth - (elementSize.width + horizontalSpacing) >= 0 {
        rows[currentRow].append(element)
      } else {
        currentRow += 1
        rows.append([element])
        remainingWidth = availableWidth
        horizontalSpacing = 0
      }
      remainingWidth -= (elementSize.width + horizontalSpacing)
    }
    return rows
  }

}
