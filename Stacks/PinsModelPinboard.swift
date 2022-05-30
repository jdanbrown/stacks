import SwiftUI
import XCGLogger

class PinsModelPinboard: ObservableObject {

  let apiToken: String // TODO How to store?

  @Published var pins = [Pin]()

  init(apiToken: String) {
    self.apiToken = apiToken
  }

  func fetch() async throws {
    log.info()
    let url = URL(string: "https://api.pinboard.in/v1/posts/all")!
    let data = try await httpGet(url, queryParams: ["format": "json", "auth_token": apiToken])
    let posts: [[String: String]] = try fromJson(data) // TODO
    log.info("Got posts: count[\(posts.count)]")
    self.pins = try posts.map(pinboardPostToPin)
  }

}

func pinboardPostToPin(post: [String: String]) throws -> Pin {
  return Pin(
    // Map data that's present in pinboard
    tombstone:  false,
    url:        try post.getOrThrow("href"),
    title:      try post.getOrThrow("description"),
    tags:       (try post.getOrThrow("tags")).split(separator: " ").map { String($0) },
    notes:      try post.getOrThrow("extended"),
    createdAt:  try parseDate(post.getOrThrow("time"), dateFormat: pinboardDateFormat),
    modifiedAt: try parseDate(post.getOrThrow("time"), dateFormat: pinboardDateFormat),
    accessedAt: try parseDate(post.getOrThrow("time"), dateFormat: pinboardDateFormat),
    isRead:     (try post.getOrThrow("toread")) == "no",
    // Default remaining data that isn't present in pinboard
    progressPageScroll:    0,
    progressPageScrollMax: 0,
    progressPdfPage:       0,
    progressPdfPageMax:    0
  )
}

let pinboardDateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
