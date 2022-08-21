import SwiftUI
import XCGLogger

// XXX For fromFirestorePin, which is currently only used by previewPins
struct FirestorePin: Codable, Equatable {

  let schemaVersion: String
  let url: String
  let title: String
  let tags: [String]
  let notes: String
  let createdAt: Date
  let modifiedAt: Date
  let accessedAt: Date
  let isRead: Bool
  let progressPageScroll: Int = 0
  let progressPageScrollMax: Int = 0
  let progressPdfPage: Int = 0
  let progressPdfPageMax: Int = 0

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case url
    case title
    case tags
    case notes
    case createdAt = "created_at"
    case modifiedAt = "modified_at"
    case accessedAt = "accessed_at"
    case isRead = "is_read"
    case progressPageScroll = "progress_page_scroll"
    case progressPageScrollMax = "progress_page_scroll_max"
    case progressPdfPage = "progress_pdf_page"
    case progressPdfPageMax = "progress_pdf_page_max"
  }

}

struct Pin: Codable, Identifiable, Equatable {

  var id: String { return url }

  let url: String // NOTE When we need it: URL.absoluteString -> String
  let tombstone: Bool
  let title: String
  let tags: [String]
  let notes: String
  let createdAt: Date
  let modifiedAt: Date
  let accessedAt: Date
  let isRead: Bool

  // Progress data
  //  - Track a separate notion of progress for each different content type
  //  - Web pages scroll, pdfs flip pages, etc.
  //  - (Conflating all of these into one shared, unitless "number" would probably be more confusing than simplifying)
  let progressPageScroll: Int
  let progressPageScrollMax: Int
  let progressPdfPage: Int
  let progressPdfPageMax: Int
  // let progressVideoTime: Int
  // let progressVideoTimeMax: Int
  // let progressAudioTime: Int
  // let progressAudioTimeMax: Int

  enum CodingKeys: String, CodingKey {
    case url
    case tombstone
    case title
    case tags
    case notes
    case createdAt = "created_at"
    case modifiedAt = "modified_at"
    case accessedAt = "accessed_at"
    case isRead = "is_read"
    case progressPageScroll = "progress_page_scroll"
    case progressPageScrollMax = "progress_page_scroll_max"
    case progressPdfPage = "progress_pdf_page"
    case progressPdfPageMax = "progress_pdf_page_max"
  }

  // XXX Currently only used by previewPins
  static func fromFirestorePin(_ pin: FirestorePin) -> Pin {
    return Pin(
      url:                   pin.url,
      tombstone:             false,
      title:                 pin.title,
      tags:                  pin.tags,
      notes:                 pin.notes,
      createdAt:             pin.createdAt,
      modifiedAt:            pin.modifiedAt,
      accessedAt:            pin.accessedAt,
      isRead:                pin.isRead,
      progressPageScroll:    pin.progressPageScroll,
      progressPageScrollMax: pin.progressPageScrollMax,
      progressPdfPage:       pin.progressPdfPage,
      progressPdfPageMax:    pin.progressPdfPageMax
    )
  }

  // lazy because static [https://docs.swift.org/swift-book/LanguageGuide/Properties.html]
  static let previewPins: [Pin] = {
    // TODO Regenerate preview-pins.json so we can get rid of FirestorePin here
    let firestorePins: [FirestorePin] = loadPreviewJson("personal/preview-pins.json")
    let pins = firestorePins.map(Pin.fromFirestorePin)
    return pins.sorted(key: { $0.createdAt }, desc: true)
  }()

  // HACK For testing markdown rendering
  static let previewMarkdown = """
    # Heading 1
    ## Heading 2
    ### Heading 3
    #### Heading 4
    ##### Heading 5
    ###### Heading 6
    Some paragraph about stuff. Lorem ipsum. Things and more things and more things and more:
    - Normal x
    - *Em*
    - **Strong**
    - ~Strikethrough~
      - Sub-bullet 1
        - Sub-sub-bullet a
        - Sub-sub-bullet b
      - Sub-bullet 2
    - A [link to asdf](http://asdf.com)

    A numbered list
    1. one
    1. two
    1. three

    ---

    A checklist
    - [ ] Do a thing
    - [ ] Do another thing

    > Blockquote

    ```
    print('foo')
    ```
    """

}

class Pins {

  // Idempotent
  static func merge(_ x: Pin, _ y: Pin) -> Pin {
    assert(x.url == y.url, "x.url[\(x.url)] == y.url[\(y.url)]")
    let url     = x.url
    let earlier = x.modifiedAt <= y.modifiedAt ? x : y
    let later   = x.modifiedAt >  y.modifiedAt ? x : y
    return Pin(
      url:                   url,
      tombstone:             later.tombstone,
      title:                 later.title,
      tags:                  (x.tags + y.tags).unique(),
      notes:                 later.notes,
      createdAt:             earlier.createdAt,
      modifiedAt:            later.modifiedAt,
      accessedAt:            later.accessedAt,
      isRead:                later.isRead,
      progressPageScroll:    [x.progressPageScroll,    y.progressPageScroll]    .max() ?? 0,
      progressPageScrollMax: [x.progressPageScrollMax, y.progressPageScrollMax] .max() ?? 0,
      progressPdfPage:       [x.progressPdfPage,       y.progressPdfPage]       .max() ?? 0,
      progressPdfPageMax:    [x.progressPdfPageMax,    y.progressPdfPageMax]    .max() ?? 0
    )
  }

  // // Properties
  // //  - Idempotent
  // //  - Minimally destructive / maximally recoverable
  // //
  // // Examples
  // //  - Merge pinboard/firestore/stacks -> edit url X->Y in stacks -> merge pinboard/firestore/stacks
  // //    - Don't recreate pin with url X that was already moved to Y
  // //  - Merge pinboard/firestore/stacks -> manually de-dupe notes text in stacks -> merge pinboard/firestore/stacks
  // //    - Don't junk up notes text with more '==='
  // //    - Don't endlessly append '===' conflicts onto the already conflict-annotated notes text
  // //
  // static func mergeWithDiffs(_ xs: [Pin], _ ys: [Pin]) -> ([Pin], [PinDiff]) {
  //   let xd = Dictionary(uniqueKeysWithValues: xs.map { ($0.url, $0) }) // Fails if duplicates url's
  //   let yd = Dictionary(uniqueKeysWithValues: ys.map { ($0.url, $0) }) // Fails if duplicates url's
  //   var zs: [Pin] = []
  //   var diffs: [PinDiff] = []
  //   for k in Set(xd.keys).union(yd.keys) {
  //     let x = xd[k]
  //     let y = yd[k]
  //     if y == nil {
  //       zs.append(x!)
  //     } else if x == nil {
  //       zs.append(y!)
  //     } else if x == y {
  //       zs.append(x!)
  //     } else {
  //       let z = Pins.merge(x!, y!)
  //       zs.append(z)
  //       diffs.append(PinDiff(before: [x!, y!], after: z))
  //     }
  //   }
  //   log.info("xs.count[\(xs.count)], ys.count[\(ys.count)] -> zs.count[\(zs.count)], diffs.count[\(diffs.count)]")
  //   return (zs, diffs)
  // }

  // // TODO Store the PinDiff's
  // //  - Just printing them for now
  // static func printMergeDiffs(_ xs: [Pin], _ ys: [Pin]) {
  //   let (zs, diffs) = Pins.merge(xs, ys)
  //   log.info("diffs[\(diffs.count)]")
  //   for (i, diff) in diffs.enumerated() {
  //     print("  diff[\(i)].before")
  //     for x in diff.before {
  //       print("    \(x)")
  //     }
  //     print("  diff[\(i)].after")
  //     print("    \(diff.after)")
  //   }
  // }

  // TODO Where to slot this back in?
  //  - Also, are there any http urls that aren't safe to rewrite to https?
  // static func normalizeUrlForId(_ url: String) -> String {
  //   return (url
  //     // Treat http:// and https:// urls the same
  //     //  - To avoid duplicate pins if the user saves a link before opening, and then again after opening and the link
  //     //    was an http:// link that redirects to an https:// link
  //     .replacingOccurrences(of: #"^https?://"#, with: "https?://", options: [.regularExpression])
  //   )
  // }

}
