// import Down
// import MarkdownUI
import SwiftUI

// TODO WIP For markdown (https://github.com/johnxnguyen/Down)
//  - https://stackoverflow.com/a/59699263/397334
//  - https://developer.apple.com/forums/thread/653935
import WebKit
struct HTML: UIViewRepresentable {
  let htmlString: String
  init(_ htmlString: String) {
    self.htmlString = htmlString
  }
  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }
  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(htmlString, baseURL: nil)
  }
}

// // HACK Guessing...
// //  - https://github.com/johnxnguyen/Down/blob/master/Sources/Down/Views/DownView.swift
// struct DownViewView: UIViewRepresentable {
//   let frame: CGRect
//   let markdownString: String
//   func makeUIView(context: Context) -> WKWebView {
//     return try! DownView(frame: frame, markdownString: markdownString)
//   }
//   func updateUIView(_ uiView: WKWebView, context: Context) {
//     // uiView.loadHTMLString(markdown, baseURL: nil)
//   }
// }

// Font styles
//  - https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography
//  - https://useyourloaf.com/blog/using-a-custom-font-with-dynamic-type/
//
//    Style        Weight     Size  Leading
//    —————————————————————————————————————
//    largeTitle   regular    34    41
//    title1       regular    28    34
//    title2       regular    22    28
//    title3       regular    20    25
//    headline     semi-bold  17    22
//    body         regular    17    22
//    callout      regular    16    21
//    subheadline  regular    15    20
//    footnote     regular    13    18
//    caption      regular    12    16
//    caption2     regular    11    13

struct PinView: View {

  var pin: Pin

  let navigationPushTag: (String) -> Void

  var body: some View {
    VStack(alignment: .leading) {

      Text(pin.title)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .font(.subheadline)
        .foregroundColor(!pin.isRead ? nil : Color.gray)
      Text("\(showDateForTimeline(pin.createdAt)) • \(showUrlForTimeline(pin.url))")
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .font(.caption2)
        .foregroundColor(Color.gray)
      FlexView(pin.tags, alignment: .leading, horizontalSpacing: 8, verticalSpacing: 2) { tag in
        Text(tag)
          .font(.footnote)
          .foregroundColor(Color.blue)
          .onTapGesture {
            navigationPushTag(tag)
          }
      }

      if pin.notes.trim() != "" {
        // TODO Does markdown automatically work? Or do we need AttributedString?

        Text(pin.notes)
          .frame(maxWidth: .infinity, alignment: .leading)
          .contentShape(Rectangle())
          .font(.caption)
          .padding([.top], 1)
          .fixedSize(horizontal: false, vertical: true)

        // Markdown(Document(pin.notes))
        //   .markdownStyle(
        //     DefaultMarkdownStyle(
        //       font: .system(.caption1)
        //     )
        //   )
        //   .padding([.top], 1)

        // HTML(try! Down(markdownString: pin.notes).toHTML())
        //   .frame(height: 300) // XXX Hack

        // DownView(frame: self.bounds, markdownString: pin.notes)
        // DownViewView(frame: .zero, markdownString: pin.notes)

      }
    }
      .padding([.top, .bottom], 1)

  }

}

// TODO Update for Core Data
// struct PinView_Previews: PreviewProvider {
//   static var previews: some View {
//     let pins = Pin.previewPins
//     Group {
//
//       // TODO Down
//       //  - TODO Why does this display nothing inside the box?
//       //  - TODO How to size the frame to fit the content?
//       // HTML("<html><body><h1>bar</h1><div>foo</div></body></html>")
//         // .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//         // .frame(height: 300) // XXX Hack
//
//       // TODO MarkdownUI
//       // Text(Pin.previewMarkdown)
//       // Text(.init(Pin.previewMarkdown))
//       // let exmd0 = Pin.previewMarkdown
//       // let exmd1 = "This is **bold** and *italic*!"
//       // Text(.init(exmd0))
//       // Text(.init(exmd1))
//       // Markdown(exmd0)
//       // Markdown(Document(exmd1))
//       // Markdown(Document("This is **bold** and *italic*!"))
//       // Markdown(Document(Pin.previewMarkdown))
//
//       ForEach(pins[0..<15]) { pin in
//         PinView(pin: pin, navigationPushTag: { tag in () })
//       }
//
//     }
//       .previewLayout(.sizeThatFits)
//   }
// }

func showUrlForTimeline(_ url: String) -> String {
  return url.replacingOccurrences(of: #"^https?://"#, with: "", options: [.regularExpression])
}

func showDateForTimeline(_ t: Date) -> String {
  // Docs: https://nsdateformatter.com
  let now = Date()
  return t.format(
    t.year == now.year && t.month == now.month && t.day == now.day ?
      // "'today,' h a"
      "'today'"
    : t.year == now.year && t.month == now.month && t.day == now.day - 1 ?
      // "'yesterday,' h a"
      "'yesterday'"
    : t.year == now.year ?
      // "E MMM d"
      // "MMM d"
      "yyyy-MM-dd"
    :
      // "E MMM d, yyyy"
      // "yyyy E MMM d"
      // "yyyy MMM d"
      "yyyy-MM-dd"
  )
}
