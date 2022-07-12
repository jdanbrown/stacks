import CoreData
import Foundation
import XCGLogger

class Backup {

  static func save(_ backupDir: URL, pins: [Pin]) throws {
    log.info("Saving to backupDir[\(backupDir)]")
    let fileManager = FileManager.default
    try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true, attributes: nil)

    let pinsJson = try toJson(pins, pretty: true)
    let pinsURL = backupDir.appendingPathComponent("pins.json")
    try pinsJson.write(to: pinsURL, atomically: true, encoding: .utf8)

    log.info("Saved to backupDir[\(backupDir)]")
  }

  static func load(_ backupDir: URL) throws -> [Pin] {
    log.info("Loading from backupDir[\(backupDir)]")

    let pinsURL = backupDir.appendingPathComponent("pins.json")
    let pinsJson = try String(contentsOf: pinsURL, encoding: .utf8)
    let pins: [Pin] = try fromJson(pinsJson)

    log.info("Loaded from backupDir[\(backupDir)]: pins[\(pins.count)]")
    return pins
  }

  static func backupsDir() throws -> URL {
    guard let iCloudDriveDir = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
      throw SimpleError("Failed to open iCloud Drive directory")
    }
    return iCloudDriveDir
      .appendingPathComponent("Documents") // The "Documents/" dir (somehow) maps to "iCloud Drive" -> "Stacks/" in Files.app
      .appendingPathComponent("Backups")
  }

}
