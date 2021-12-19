import Foundation
import XCGLogger

//
// Logging
//

let log = XCGLogger.default

class CustomLogFormatter: LogFormatterProtocol, CustomDebugStringConvertible {
  @discardableResult func format(logDetails: inout LogDetails, message: inout String) -> String {
    // Regex instead of String(format:) because not all info is included in LogDetails (e.g. thread name)
    //  - https://github.com/DaveWoodCom/XCGLogger/blob/master/Sources/XCGLogger/Destinations/BaseDestination.swift
    for (of, with) in [
      // Rewrite "... function() > message" -> "... function() — message"
      (#"^([^>]+) > "#, "$1 — "),
      // Rewrite "[Level]" -> "LEVEL"
      //  - https://github.com/DaveWoodCom/XCGLogger/blob/master/Sources/XCGLogger/XCGLogger.swift
      (#"\[Verbose\]"#,   "VERBOSE"),
      (#"\[Debug\]"#,     "DEBUG  "),
      (#"\[Info\]"#,      "INFO   "),
      (#"\[Notice\]"#,    "NOTICE "),
      (#"\[Warning\]"#,   "WARNING"),
      (#"\[Error\]"#,     "ERROR  "),
      (#"\[Severe\]"#,    "SEVERE "),
      (#"\[Alert\]"#,     "ALERT  "),
      (#"\[Emergency\]"#, "EMERGENCY"),
      (#"\[None\]"#,      "NONE   "),
    ] {
      message = message.replacingOccurrences(of: of, with: with, options: [.regularExpression])
    }
    return message
  }
  var debugDescription: String {
    return "\(self)"
  }
}

//
// swift
//

extension Thread {
  var number: Any {
    get {
      return Thread.current.value(forKeyPath: "private.seqNum") ?? -1
    }
  }
}

extension DefaultStringInterpolation {
  // https://stackoverflow.com/a/42543251/397334
  mutating func appendInterpolation<X>(opt: X?) {
    appendInterpolation(String(describing: opt))
  }
}

func toJson(_ x: Any) throws -> String {
  let data: Data = try JSONSerialization.data(withJSONObject: x, options: [])
  return String(decoding: data, as: UTF8.self)
}

// Is this one useful? Newer style, but requires static/swift construction of the input data
func toJson<X: Codable>(x: X) throws -> String {
  let data: Data = try JSONEncoder().encode(x)
  return String(decoding: data, as: UTF8.self)
}
