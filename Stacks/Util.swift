import Combine
import CryptoKit
import Foundation
import SwiftUI
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

extension String {
  func trim() -> String {
    return trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension Array {
  func sorted<K: Comparable>(key: (Element) -> K, desc: Bool = false) -> Array<Element> {
    return sorted(by: { x, y in !desc ? key(x) < key(y) : key(y) < key(x) })
  }
}

extension Array where Element: Hashable {
  func unique() -> Array<Element> {
    return Array(Set(self))
  }
}

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

// Extend to add struct.with(\.field, value)
//  - NOTE This only works for var's, not let's
//  - Based on: https://stackoverflow.com/a/66623586/397334
protocol Withable {}
extension Withable {
  func with<X>(_ path: WritableKeyPath<Self, X>, _ value: X) -> Self {
    var copy = self // Struct assignment makes a copy
    copy[keyPath: path] = value
    return copy
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

func loadPreviewAsset(_ filename: String) -> Data {
  // Docs
  //  - https://developer.apple.com/documentation/foundation/bundle
  // Examples
  //  - https://www.hackingwithswift.com/books/ios-swiftui/loading-resources-from-your-app-bundle
  //  - https://medium.com/@keremkaratal/swiftui-exploiting-xcode-11-canvas-2fe46d66c3d8
  guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
    fatalError("Asset file not found: \(filename)")
  }
  do {
    return try Data(contentsOf: file)
  } catch {
    fatalError("Failed to read asset file[\(filename)] from main bundle: \(error)")
  }
}

func loadPreviewJson<X: Codable>(_ filename: String) -> X {
  do {
    return try fromJson(loadPreviewAsset(filename))
  } catch {
    fatalError("Failed to load preview json: filename[\(filename)]")
  }
}

//
// Codable/json
//

func toJsonNoCodable(_ x: Any) throws -> String {
  let data: Data = try JSONSerialization.data(withJSONObject: x, options: [])
  return String(decoding: data, as: UTF8.self)
}

func toJson<X: Codable>(_ x: X, pretty: Bool = false) throws -> String {
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .formatted(isoDateFormatter) // Instead of unixtime int
  if !pretty {
    encoder.outputFormatting = [.sortedKeys]
  } else {
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
  }
  let data: Data = try encoder.encode(x)
  return String(decoding: data, as: UTF8.self)
}

func fromJson<X: Codable>(_ json: String) throws -> X {
  guard let jsonData = json.data(using: .utf8) else {
    preconditionFailure("Invalid utf8 string[\(json)]")
  }
  return try fromJson(jsonData)
}

func fromJson<X: Codable>(_ jsonData: Data) throws -> X {
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .formatted(isoDateFormatter) // Instead of unixtime int
  return try decoder.decode(X.self, from: jsonData)
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

//
// Crypto
//

func sha1hex(_ string: String) -> String {
  let data: Data = string.data(using: .utf8)!
  let bytes: [UInt8] = Array(Insecure.SHA1.hash(data: data).makeIterator())
  let hex: String = bytes.map { String(format: "%02x", $0) }.joined()
  return hex
}

//
// Date
//

func parseDate(_ dateIso: String) throws -> Date {
  guard let date = isoDateFormatter.date(from: dateIso) else {
    preconditionFailure("Failed to parse iso8601 date[\(dateIso)]")
  }
  return date
}

extension Date {

  var era:               Int { get { return component(.era) } }
  var year:              Int { get { return component(.year) } }
  var yearForWeekOfYear: Int { get { return component(.yearForWeekOfYear) } }
  var quarter:           Int { get { return component(.quarter) } }
  var month:             Int { get { return component(.month) } }
  var weekOfYear:        Int { get { return component(.weekOfYear) } }
  var weekOfMonth:       Int { get { return component(.weekOfMonth) } }
  var weekday:           Int { get { return component(.weekday) } }
  var weekdayOrdinal:    Int { get { return component(.weekdayOrdinal) } }
  var day:               Int { get { return component(.day) } }
  var hour:              Int { get { return component(.hour) } }
  var minute:            Int { get { return component(.minute) } }
  var second:            Int { get { return component(.second) } }
  var nanosecond:        Int { get { return component(.nanosecond) } }
  var calendar:          Int { get { return component(.calendar) } }
  var timeZone:          Int { get { return component(.timeZone) } }

  func component(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
    return calendar.component(component, from: self)
  }

  // Docs
  //  - https://nsdateformatter.com/
  //  - https://nsdateformatter.com/#best-practices
  func format(_ format: String?) -> String {
    if let format = format {
      let x = DateFormatter()
      x.dateFormat = format
      return x.string(from: self)
    } else {
      return isoDateFormatter.string(from: self)
    }
  }

}

// HACK JSONDecoder/JSONEncoder accepts DateFormatter but not ISO8601DateFormatter
let isoDateFormatter: DateFormatter = {
  // let x = ISO8601DateFormatter()
  // x.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  let x = DateFormatter()
  x.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
  return x
}()

//
// http + url
//

// TODO Add PinboardService that calls this
func httpGetString(_ url: URL, queryParams: [String: String] = [:]) async throws -> String {
  let data = try await httpGet(url, queryParams: queryParams)
  return String(data: data, encoding: .utf8)!
}

// Docs
//  - https://developer.apple.com/documentation/foundation/url_loading_system
//  - https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
//  - https://developer.apple.com/documentation/foundation/urlsession
//  - https://developer.apple.com/documentation/foundation/urlsession/3767353-data
//  - https://developer.apple.com/documentation/foundation/url
func httpGet(_ url: URL, queryParams: [String: String] = [:]) async throws -> Data {
  let url = try urlWithQueryParams(url, queryParams: queryParams)
  // NOTE I think URLSession handles redirects by default?
  //  - https://stackoverflow.com/questions/49477437/swift-urlsession-prevent-redirect
  //  - https://stackoverflow.com/questions/29070420/preventing-urlsession-redirect-in-swift
  let (data, rep) = try await URLSession.shared.data(from: url)
  guard let rep = rep as? HTTPURLResponse else {
    preconditionFailure("Expected HTTPURLResponse, got rep[\(rep)]")
  }
  guard (200..<300).contains(rep.statusCode) else {
    preconditionFailure("Failed to http GET: status[\(rep.statusCode)], data[\(data)]")
  }
  return data
}

func urlWithQueryParams(_ url: URL, queryParams: [String: String] = [:]) throws -> URL {
  guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
    preconditionFailure("Invalid url[\(url)]")
  }
  components.queryItems = queryParams.map { k, v in URLQueryItem(name: k, value: v) }
  guard let url = components.url else {
    preconditionFailure("Invalid queryParams[\(queryParams)] for url[\(url)]")
  }
  return url
}

//
// swiftui
//

// HACK We wish we could add .pipe to Any/AnyObject, but you can't extend those
extension View {
  func pipe<X>(f: (Self) -> X) -> X {
    return f(self)
  }
}

// Motivated by NavigationLink, which eagerly loads its destination view
//  - https://gist.github.com/chriseidhof/d2fcafb53843df343fe07f3c0dac41d5
//  - https://betterprogramming.pub/swiftui-navigation-links-and-the-common-pitfalls-faced-505cbfd8029b
//  - Alternate approaches I didn't try
//    - https://swiftwithmajid.com/2021/01/27/lazy-navigation-in-swiftui/
struct LazyView<Content: View>: View {
  let build: () -> Content
  var body: Content {
    build()
  }
}
