typealias Tag = String

class Tags {

  static func decode(_ string: String) -> [Tag] {
    return string.split(separator: ",").map { String($0) }
  }

  static func encode(_ tags: [Tag]) -> String {
    return tags.joined(separator: ",")
  }

}
