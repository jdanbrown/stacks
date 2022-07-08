import Combine
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFirestoreCombineSwift
import GoogleSignIn
import SwiftUI
import XCGLogger

// TODO Can we simplify anything with FirebaseFirestoreCombineSwift + FirebaseFirestoreSwift?
//  - https://github.com/firebase/firebase-ios-sdk/tree/master/Firestore/Swift
class PinsModelFirestore: ObservableObject {

  @Published var pins = [Pin]()

  var auth: AuthService
  var firestore: FirestoreService

  private var listeners: [ListenerRegistration] = []
  private var cancellables: [Cancellable] = [] // Must retain all .sink return values else they get deinit-ed and silently .cancel-ed!

  init(auth: AuthService, firestore: FirestoreService) {
    self.auth = auth
    self.firestore = firestore
    cancellables += [
      self.auth.userDidChange_.sink { (oldAuthState, newAuthState) in
        self.onUserChange(oldAuthState: oldAuthState, newAuthState: newAuthState)
      },
    ]
  }

  func onUserChange(oldAuthState: AuthState, newAuthState: AuthState) {
    log.info("oldAuthState[\(opt: oldAuthState)] -> newAuthState[\(opt: newAuthState)]")
    unlistenToAll()
    if let user = newAuthState.user {
      listenToPins(user: user)
    }
  }

  func unlistenToAll() {
    log.info("listeners[\(listeners.count)]")
    for listener in listeners {
      listener.remove()
    }
    listeners = []
  }

  func pinsCollection(user: User) -> CollectionReference {
    return firestore.db.collection("/users/\(user.uid)/pins")
  }

  // https://firebase.google.com/docs/firestore/query-data/listen
  // https://firebase.google.com/docs/firestore/query-data/listen#listen_to_multiple_documents_in_a_collection
  func listenToPins(user: User) {
    let c = pinsCollection(user: user)
    log.info("Listening to collection[\(c)]")
    listeners.append(
      c.addSnapshotListener { querySnapshot, error in
        guard let documents = querySnapshot?.documents else {
          log.error("Error in snapshot: \(opt: error)")
          return
        }
        log.info("Got snapshot: documents[\(documents.count)]")
        self.pins = documents.compactMap { queryDocumentSnapshot -> Pin? in
          switch (Result { try PinsModelFirestore.pinFromDoc(queryDocumentSnapshot) }) {
            case .failure(let e):
              log.error("Failed to parse document, skipping: queryDocumentSnapshot[\(queryDocumentSnapshot)], error[\(e)]")
              return nil
            case .success(nil):
              log.error("Document does not exist, skipping: queryDocumentSnapshot[\(queryDocumentSnapshot)]")
              return nil
            case .success(let pin):
              return pin
          }
        }

        // HACK Uncomment this to dump data to the Xcode console to copy/paste out for Previews
        // let pinsJson = try! toJson(self.pins, pretty: true)
        // log.info("Dumping all pins: count[\(self.pins.count)], pins[\(pinsJson)]")

      }
    )
  }

  // Returns nil if document does not exist, throws if decoding fails
  static func pinFromDoc(_ doc: DocumentSnapshot) throws -> Pin? {
    // Reimplement `try doc.data(as: Pin.self)`, but add default values
    //  - https://github.com/firebase/firebase-ios-sdk/blob/v8.10.0/Firestore/Swift/Source/Codable/DocumentSnapshot+ReadDecodable.swift
    guard var data = doc.data() else {
      log.error("Null doc, returning nil")
      return nil
    }
    // Set defaults for keys that aren't present in firestore
    data.setDefault("tombstone", false)
    // HACK Be more aggressive than setDefault for these, since some firestore docs contain null for some of these keys
    for k in ["progress_page_scroll", "progress_page_scroll_max", "progress_pdf_page", "progress_pdf_page_max"] {
      if data[k] == nil || data[k] is NSNull {
        data[k] = 0
      }
    }
    return try Firestore.Decoder().decode(Pin.self, from: data, in: doc.reference)
  }

  // TODO Add pins stuff from firestore.dart
  //  - pinFromUrl
  //  - pinFromId
  //  - pinFromDoc
  //  - insertPinsIfNotExists
  //  - upsertPins
  //  - deletePin
  //  - togglePinIsRead

}
