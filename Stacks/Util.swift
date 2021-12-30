import Combine
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

// // Wrap types that aren't already ObservableObject
// //  - e.g. Optional/Array for .environmentObject
// class Obs<X>: ObservableObject {
//   @Published var value: X
//   init(_ value: X) {
//     self.value = value
//   }
// }

//
// Codable/json
//

func toJson(_ x: Any) throws -> String {
  let data: Data = try JSONSerialization.data(withJSONObject: x, options: [])
  return String(decoding: data, as: UTF8.self)
}

func toJson<X: Codable>(x: X) throws -> String {
  let data: Data = try JSONEncoder().encode(x)
  return String(decoding: data, as: UTF8.self)
}

func fromJson<X: Codable>(json: String) throws -> X {
  guard let jsonData = json.data(using: .utf8) else {
    preconditionFailure("Invalid json[\(json)]")
  }
  return try JSONDecoder().decode(X.self, from: jsonData)
}

//
// async + Future/Combine
//  - https://developer.apple.com/documentation/swift/asyncsequence
//  - https://developer.apple.com/documentation/combine/future
//  - https://benscheirman.com/2021/06/async-await-and-the-future-of-combine/
//  - https://wwdcbysundell.com/2021/the-future-of-combine/
//

func toAsync<X>(fut: Future<X, Never>) async -> X {
  for await x in fut.values {
    return x
  }
  fatalError("""
    A Future "eventually produces a single value and then finishes or fails"
    - https://developer.apple.com/documentation/combine/future
  """)
}

func toAsync<X>(fut: Future<X, Error>) async throws -> X {
  for try await x in fut.values {
    return x
  }
  fatalError("""
    A Future "eventually produces a single value and then finishes or fails"
    - https://developer.apple.com/documentation/combine/future
  """)
}
