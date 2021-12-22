import Firebase

struct User: Equatable {

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

  init(_ user: Firebase.User) {
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

  static let example0 = User(
    uid: "uid_0",
    displayName: "name_0",
    email: "email_0",
    photoURL: URL(string: "https://user-images.githubusercontent.com/627486/147042558-4adef573-f220-483b-9abe-d9b3a4f7bb70.png")
  )

}
