import SwiftUI

struct Pin: Codable, Identifiable {

  var id: String
  var url: String
  var title: String
  var tags: [String]
  var notes: String

  static func parseMap(
    // ref: DocumentReference, // TODO
    map: [String: Any]
  ) -> Pin {
    return Pin(
      id:    map["id"]    as! String,
      url:   map["url"]   as! String,
      title: map["title"] as! String,
      // tags:  map["tags"]  as! [String],
      tags:  [],
      notes: map["notes"] as! String
    )
  }

}
