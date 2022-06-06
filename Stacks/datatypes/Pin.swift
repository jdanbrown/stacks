import CoreData
import Firebase
import FirebaseFirestoreSwift
import SwiftUI
import XCGLogger

// TODO Don't do Pin vs. PurePin! -- DocumentReference doesn't need to be stored!
//  - A DocumentReference is 1-1 with the document path, and can be recreated from it
//  - https://firebase.google.com/docs/firestore/data-model#references

// TODO Do we want Withable here?
//  - Requires all let's be var's (ugh)
//  - How will PinEditView work? -- that's all that should matter

extension CorePin {

  var tagsList: [String] {
    // TODO Cache
    return Tags.decode(tags ?? "")
  }

  func toPin() -> Pin {
    return Pin(
      url: self.url ?? "[null-url]",
      tombstone: self.tombstone,
      title: self.title ?? "[null-title]",
      tags: Tags.decode(self.tags ?? "[null-tags]"),
      notes: self.notes ?? "[null-notes]",
      createdAt: self.createdAt ?? Date.zero,
      modifiedAt: self.modifiedAt ?? Date.zero,
      accessedAt: self.accessedAt ?? Date.zero,
      isRead: self.isRead,
      progressPageScroll: 0, // TODO
      progressPageScrollMax: 0, // TODO
      progressPdfPage: 0, // TODO
      progressPdfPageMax: 0 // TODO
    )
  }

}

// Codable enabled by `import FirebaseFirestoreSwift`
//  - https://peterfriese.dev/firestore-codable-the-comprehensive-guide/
struct Pin: Codable, Identifiable, Equatable {

  // TODO or XXX
  //  - Used in PinsModel.update
  var managedObjectID: NSManagedObjectID? = nil

  // id is determined by url
  var id: String {
    get { return Pin.idFromUrl(url) }
  }

  let schemaVersion: String = "v1"
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
    case schemaVersion = "schema_version"
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

  // Returns nil if document does not exist, throws if decoding fails
  static func fromDoc(_ doc: DocumentSnapshot) throws -> Pin? {
    // Reimplement `try doc.data(as: Pin.self)`, but add default values
    //  - https://github.com/firebase/firebase-ios-sdk/blob/v8.10.0/Firestore/Swift/Source/Codable/DocumentSnapshot+ReadDecodable.swift
    guard var data = doc.data() else {
      log.error("Null doc, returning nil")
      return nil
    }
    // Set defaults for keys that aren't present in firestore
    data.setDefault("tombstone", false)
    // HACK Be more aggressive than setDefault for these, since some firestore docs contain null for some of these keys
    for k in ["progress_page_scroll", "progress_page_scroll_max", "progress_pdf_page", "progress_pdf_page_max"] {
      if data[k] == nil || data[k] is NSNull {
        data[k] = 0
      }
    }
    return try Firestore.Decoder().decode(Pin.self, from: data, in: doc.reference)
  }

  static func idFromUrl(_ url: String) -> String {
    return sha1hex(normalizeUrlForId(url))
  }

  static func normalizeUrlForId(_ url: String) -> String {
    return (url
      // Treat http:// and https:// urls the same
      //  - To avoid duplicate pins if the user saves a link before opening, and then again after opening and the link
      //    was an http:// link that redirects to an https:// link
      .replacingOccurrences(of: #"^https?://"#, with: "https?://", options: [.regularExpression])
    )
  }

  // lazy because static [https://docs.swift.org/swift-book/LanguageGuide/Properties.html]
  static let previewPins: [Pin] = {
    let pins: [Pin] = loadPreviewJson("personal/preview-pins.json")
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

}

class Pins {

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
  // static func merge(_ xs: [Pin], _ ys: [Pin]) -> ([Pin], [PinDiff]) {
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
  //       let z = Pin.merge(x!, y!)
  //       zs.append(z)
  //       diffs.append(PinDiff(before: [x!, y!], after: z))
  //     }
  //   }
  //   log.info("xs.count[\(xs.count)], ys.count[\(ys.count)] -> zs.count[\(zs.count)], diffs.count[\(diffs.count)]")
  //   return (zs, diffs)
  // }

}
