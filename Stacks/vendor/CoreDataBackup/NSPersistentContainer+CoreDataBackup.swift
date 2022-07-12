// XXX Removed in favor of Backup.swift
//  - Because I couldn't figure out how to properly use restorePersistentStores

// // Based on https://gist.github.com/atomicbird/25fed73657be4b9d3642981a4892fea4
// //  - Copied gist on 2022-07-08
// //  - Created by Tom Harrington on 5/12/20.
// //  - Copyright © 2020 Atomic Bird LLC. All rights reserved.
//
// import CoreData
// import Foundation
// import XCGLogger
//
// extension NSPersistentContainer {
//
//   // https://stackoverflow.com/questions/31443645/simplest-way-to-throw-an-error-exception-with-a-custom-message-in-swift
//   struct CoreDataBackupError: Error {
//     let message: String
//     init(_ message: String) { self.message = message }
//     public var localizedDescription: String { return message }
//   }
//
//   // Save all loaded persistent stores to a given dir
//   //  - Each currently loaded file-based persistent store will be copied into the destination dir
//   //    - Any in-memory stores are skipped
//   //    - Each store will save as a file with name/type determined by the store
//   //    - This will include journal files, external binary storage, etc.
//   //  - destDir must not exist (overwriting is not supported)
//   func savePersistentStores(to destDir: URL) throws {
//     let fileManager = FileManager.default
//     log.info("Saving to destDir[\(destDir)]")
//
//     // Validate destDir
//     guard destDir.isFileURL else {
//       throw CoreDataBackupError("Must be a file URL: destDir[\(destDir)]")
//     }
//     guard !fileManager.fileExists(atPath: destDir.path) else {
//       throw CoreDataBackupError("Already exists: destDir[\(destDir)]")
//     }
//
//     // Create the destination dir
//     do {
//       try fileManager.createDirectory(
//         at: destDir,
//         withIntermediateDirectories: true,
//         attributes: nil
//       )
//     } catch {
//       throw CoreDataBackupError("Failed to create destDir[\(destDir)]: \(error)")
//     }
//
//     // Save each store
//     let coordinator = self.persistentStoreCoordinator
//     let descriptions = self.persistentStoreDescriptions
//     let n = descriptions.count
//     log.info("Saving \(n) stores: descriptions[\(descriptions)]")
//     for (i, description) in descriptions.enumerated() {
//
//       // Validate
//       guard let storeURL = description.url else {
//         log.info("Skipping persistent store with no url (url[\(opt: description.url)]): description[\(description)]")
//         continue
//       }
//       guard description.type != NSInMemoryStoreType else {
//         log.info("Skipping in-memory persistent store (type[\(description.type)]): description[\(description)]")
//         continue
//       }
//       let destFile = destDir.appendingPathComponent(storeURL.lastPathComponent)
//       guard !fileManager.fileExists(atPath: destFile.path) else {
//         throw CoreDataBackupError("Already exists: destFile[\(destFile)]")
//       }
//
//       // Save this store
//       do {
//         let dupeCoordinator = NSPersistentStoreCoordinator(
//           managedObjectModel: coordinator.managedObjectModel
//         )
//         let dupeStore = try dupeCoordinator.addPersistentStore(
//           ofType:            description.type,
//           configurationName: description.configuration,
//           at:                description.url,
//           options:           description.options
//         )
//         let savedStore = try dupeCoordinator.migratePersistentStore(
//           dupeStore,
//           to:       destFile,
//           options:  description.options,
//           withType: description.type
//         )
//         log.info("Saved store \(i + 1)/\(n): \(savedStore)")
//       } catch {
//         throw CoreDataBackupError("Failed to save: \(error)")
//       }
//
//     }
//
//   }
//
//   // Restore persistent stores from sourceDir into this coordinator -- replacing existing stores
//   //  - WARNING This can crash your app if used improperly!
//   //    - You must stop referencing any existing managed objects or fetched results controllers
//   //    - Inner mechanics
//   //      - To restore a persistent store, the existing store must be removed from the container
//   //      - Removing a store invalidates all of its managed objects
//   //      - Using invalidated objects will crash the app
//   func restorePersistentStores(from sourceDir: URL) throws {
//     let fileManager = FileManager.default
//     log.info("Restoring from sourceDir[\(sourceDir)]")
//
//     // Validate sourceDir
//     guard sourceDir.isFileURL else {
//       throw CoreDataBackupError("Must be a file URL: sourceDir[\(sourceDir)]")
//     }
//     var _isDir: ObjCBool = false
//     if !fileManager.fileExists(atPath: sourceDir.path, isDirectory: &_isDir) {
//       throw CoreDataBackupError("Not found: sourceDir[\(sourceDir)]")
//     } else if !_isDir.boolValue {
//       throw CoreDataBackupError("Must be a directory: sourceDir[\(sourceDir)]")
//     }
//
//     // Restore each store
//     let coordinator = self.persistentStoreCoordinator
//     let persistentStores = coordinator.persistentStores
//     let n = persistentStores.count
//     log.info("Restoring \(n) stores: persistentStores[\(persistentStores)]")
//     for (i, persistentStore) in persistentStores.enumerated() {
//
//       // Validate
//       guard let existingStoreURL = persistentStore.url else {
//         log.info("Skipping persistent store with no url (url[\(opt: persistentStore.url)]): persistentStore[\(persistentStore)]")
//         continue
//       }
//       let sourceFile = sourceDir.appendingPathComponent(existingStoreURL.lastPathComponent)
//       guard fileManager.fileExists(atPath: sourceFile.path) else {
//         throw CoreDataBackupError("Not found: sourceFile[\(sourceFile)]")
//       }
//
//       // Restore this store
//       do {
//         // Remove the existing store from the coordinator
//         try coordinator.remove(persistentStore)
//         // Delete the files backing the existing store
//         try coordinator.destroyPersistentStore(
//           at:      existingStoreURL,
//           ofType:  persistentStore.type,
//           options: persistentStore.options
//         )
//         // Add the source store using its current file location
//         let sourceStore = try coordinator.addPersistentStore(
//           ofType:            persistentStore.type,
//           configurationName: persistentStore.configurationName,
//           at:                sourceFile,
//           options:           persistentStore.options
//         )
//         // Migrate the source store to the existing store's file location
//         //  - This leaves the source files as is, but sourceStore is now garbage and shouldn't be used
//         let restoredStore = try coordinator.migratePersistentStore(
//           sourceStore,
//           to:       existingStoreURL,
//           options:  persistentStore.options,
//           withType: persistentStore.type
//         )
//         log.info("Restored store \(i + 1)/\(n): \(restoredStore)")
//       } catch {
//         throw CoreDataBackupError("Failed to restore: \(error)")
//       }
//
//     }
//
//   }
//
// }
