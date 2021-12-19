import Firebase
import SwiftUI
import XCGLogger

struct Pin: Codable, Identifiable {

  var id: String
  var url: String
  var title: String
  var tags: [String]
  var notes: String

  static func parseMap(
    ref: DocumentReference, // TODO Pin + PurePin
    map: [String: Any]
  ) -> Pin {
    log.info("map[\(map)]") // XXX Debug (noisy)
    return Pin(
      // id:    map["id"]    as! String,
      id:    map["url"]   as! String, // TODO
      url:   map["url"]   as! String,
      title: map["title"] as! String,
      // tags:  map["tags"]  as! [String],
      tags:  [],
      notes: map["notes"] as! String
    )
  }

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
