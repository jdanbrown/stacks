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

  var id: String
  var url: String
  var title: String
  var tags: [String]
  var notes: String

  // Returns nil if document does not exist, throws if decoding fails
  static func fromDoc(doc: DocumentSnapshot) throws -> Pin? {
    // https://github.com/firebase/firebase-ios-sdk/blob/v8.10.0/Firestore/Swift/Source/Codable/DocumentSnapshot+ReadDecodable.swift
    return try doc.data(as: Pin.self)
  }

  static let ex0 = Pin(
    id: "pin_0",
    url: "url_0",
    title: "title_0",
    tags: ["tag-0a", "tag-0b"],
    notes: "notes_0"
  )

  static let ex1 = Pin(
    id: "pin_1",
    url: "url_1",
    title: "title_1",
    tags: ["tag-1a", "tag-1b"],
    notes: "notes_1"
  )

}

// XXX Example
// map[[
//   "progress_page_scroll_max": <null>,
//   "notes": ,
//   "progress_pdf_page": <null>,
//   "tags": <__NSArrayM 0x60000381abe0>( nn, overfitting, generalization, explained, good),
//   "title": Are Deep Neural Networks Dramatically Overfitted?,
//   "is_read": 0,
//   "progress_pdf_page_max": <null>,
//   "url": https://lilianweng.github.io/lil-log/2019/03/14/are-deep-neural-networks-dramatically-overfitted.html,
//   "modified_at": <FIRTimestamp: seconds=1626103229 nanoseconds=0>,
//   "accessed_at": <FIRTimestamp: seconds=1626103229 nanoseconds=0>,
//   "created_at": <FIRTimestamp: seconds=1626103229 nanoseconds=0>,
//   "progress_page_scroll": <null>,
//   "schema_version": v0
// ]]
