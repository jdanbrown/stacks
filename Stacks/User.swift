import Firebase

class User: ObservableObject {

  let uid: String
  let displayName: String?
  let email: String?
  let photoURL: URL?

  init(
    uid: String,
    displayName: String?,
    email: String?,
    photoURL: URL?
  ) {
    self.uid = uid
    self.displayName = displayName
    self.email = email
    self.photoURL = photoURL
  }

  convenience init(_ user: Firebase.User) {
    // Docs:
    //  - https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/Classes/User
    //  - https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/Protocols/UserInfo.html
    self.init(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL
    )
  }

}
