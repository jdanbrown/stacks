import Firebase
import FirebaseFirestoreSwift
import SwiftUI
import XCGLogger

// TODO Don't do Pin vs. PurePin! -- DocumentReference doesn't need to be stored!
//  - A DocumentReference is 1-1 with the document path, and can be recreated from it
//  - https://firebase.google.com/docs/firestore/data-model#references

// Codable enabled by `import FirebaseFirestoreSwift`
//  - https://peterfriese.dev/firestore-codable-the-comprehensive-guide/
struct Pin: Codable, Identifiable {

  // id is determined by url
  var id: String {
    get { return Pin.idFromUrl(url) }
  }

  var schemaVersion: String?
  var url: String // NOTE When we need it: URL.absoluteString -> String
  var title: String
  var tags: [String]
  var notes: String
  var createdAt: Date
  var modifiedAt: Date
  var accessedAt: Date
  var isRead: Bool

  // Progress data
  //  - Track a separate notion of progress for each different content type
  //  - Web pages scroll, pdfs flip pages, etc.
  //  - (Conflating all of these into one shared, unitless "number" would probably be more confusing than simplifying)
  var progressPageScroll: Int?
  var progressPageScrollMax: Int?
  var progressPdfPage: Int?
  var progressPdfPageMax: Int?
  // var progressVideoTime: Int?
  // var progressVideoTimeMax: Int?
  // var progressAudioTime: Int?
  // var progressAudioTimeMax: Int?

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

  // Returns nil if document does not exist, throws if decoding fails
  //  - https://github.com/firebase/firebase-ios-sdk/blob/v8.10.0/Firestore/Swift/Source/Codable/DocumentSnapshot+ReadDecodable.swift
  static func fromDoc(_ doc: DocumentSnapshot) throws -> Pin? {
    return try doc.data(as: Pin.self)
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

  static let ex0 = Pin(
    url: "url_0",
    title: "title_0",
    tags: ["tag-0a", "tag-0b"],
    notes: "notes_0",
    createdAt:  try! parseDate("2020-01-02T03:04:05:678Z"),
    modifiedAt: try! parseDate("2020-01-02T03:04:05:678Z"),
    accessedAt: try! parseDate("2020-01-02T03:04:05:678Z"),
    isRead: false
  )

  static let ex1 = Pin(
    url: "url_1",
    title: "title_1",
    tags: ["tag-1a", "tag-1b"],
    notes: "notes_1",
    createdAt:  try! parseDate("2020-01-02T03:04:05:678Z"),
    modifiedAt: try! parseDate("2020-01-02T03:04:05:678Z"),
    accessedAt: try! parseDate("2020-01-02T03:04:05:678Z"),
    isRead: true
  )

}