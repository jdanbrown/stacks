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

    // FIXME This fails with "No such file or directory" if the file hasn't synced to local fs from icloud
    //  - See notes + fix in PinListView (the caller)
    let pinsURL = backupDir.appendingPathComponent("pins.json")
    let pinsJson = try String(contentsOf: pinsURL, encoding: .utf8)
    let pins: [Pin] = try fromJson(pinsJson)

    log.info("Loaded from backupDir[\(backupDir)]: pins[\(pins.count)]")
    return pins
  }

  static func backupName(pinsModel: PinsModel) -> String {
    // Use a deterministic name for the backup
    //  - Else autosave-before-restore will create a mess of extraneous backups when switching back and forth
    //  - e.g. "Backups/modified[2022-07-09T05-12-43]-pins[1093]/"
    let maxTimestamp = pinsModel.maxTimestamp
    return String(
      format: "%@ (%d pins)",
      maxTimestamp == Date.zero ? "Empty" : maxTimestamp.format("yyyyMMdd HHmmss.SSS"), // (Avoid ':', not allowed on hfs)
      pinsModel.numPins
    )
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
