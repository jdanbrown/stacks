import SwiftUI

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

struct PinListView: View {

  var user: User
  var pins: [Pin]

  var body: some View {
    VStack {
      Text("\(pins.count) Pins")
      List(pins.sorted(key: \.createdAt, desc: true)) { pin in
        VStack(alignment: .leading) {
          Text(pin.title)
            .font(.subheadline)
          Text("\(showDateForTimeline(pin.createdAt)) • \(showUrlForTimeline(pin.url))")
            .font(.caption2)
            .foregroundColor(Color.gray)
          Text(pin.tags.joined(separator: "  "))
            .font(.footnote)
            .foregroundColor(Color.blue)
          if pin.notes.trim() != "" {
            // TODO Does markdown automatically work? Or do we need AttributedString?
            // Text(pin.notes)
            Text(.init(pin.notes))
              .font(.caption)
              .padding([.top], 1)
          }
        }
          .padding([.top, .bottom], 1)
      }
    }
  }

}

struct PinListView_Previews: PreviewProvider {
  static var previews: some View {
    PinListView(
      user: User.example0,
      pins: loadPreviewJson("personal/preview-pins.json")
    )
  }

}

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
