import Firebase
import GoogleSignIn
import Logging

class AuthService: ObservableObject {

  let log = Logger(label: "Stacks.AuthService")

  @Published var loading: Bool
  @Published var user: User?

  init() {
    loading = true
    user = nil
    // https://firebase.google.com/docs/auth/ios/start
    // https://firebase.google.com/docs/auth/ios/manage-users
    Auth.auth().addStateDidChangeListener { auth, user in
      user = user
      loading = false
    }
    restoreLogin()
  }

  // TODO Switch loginWithGoogle + restoreLogin to async/await/combine/Future/Publisher
  //  - As is, loginWithGoogle + the non-async login/logout/withLoading code below won't do the right thing
  //  - And then we might as well migrate restoreLogin too

  // https://developers.google.com/identity/sign-in/ios/sign-in
  //  - "2. Attempt to restore the user's sign-in state"
  func restoreLogin() {
    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
      let isLoggedIn = error == nil && user != nil
      self.user = user
      loading = false
    }
  }

  // https://developers.google.com/identity/sign-in/ios/sign-in
  //  - https://github.com/firebase/quickstart-ios/blob/master/authentication/AuthenticationExample/ViewControllers/AuthViewController.swift
  //  - https://stackoverflow.com/questions/59737264/how-to-properly-use-google-signin-with-swiftui/65772658
  //  - https://developers.google.com/identity/sign-in/ios/reference/Classes/GIDSignIn
  func loginWithGoogle() {
    let clientId: String = (FirebaseApp.app()?.options.clientID)!
    let config = GIDConfiguration(clientID: clientId)
    let viewController: UIViewController = (UIApplication.shared.windows.first?.rootViewController)!
    GIDSignIn.sharedInstance.signIn(with: config, presenting: viewController) { user, error in

      // TODO
      if error != nil || user == nil {
        self.user = nil
        loading = false
      } else {
        self.user = user
        loading = false
        // https://developers.google.com/identity/sign-in/ios/people
        let emailAddress  = user.profile?.email
        let fullName      = user.profile?.name
        let givenName     = user.profile?.givenName
        let familyName    = user.profile?.familyName
        let profilePicUrl = user.profile?.imageURL(withDimension: 320)
      }

    }

  }

  // Called from AppMain.body
  //  - https://developers.google.com/identity/sign-in/ios/sign-in
  //    - "1.2. In your AppDelegate's application:openURL:options method, call GIDSignIn's handleURL: method"
  //  - SwiftUI View.onOpenURL replaces UIKit AppDelegate application:openURL:options
  //    - https://developer.apple.com/forums/thread/651234
  //    - https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:)
  //  - More details/examples
  //    - https://peterfriese.dev/ultimate-guide-to-swiftui2-application-lifecycle/
  //    - https://peterfriese.dev/swiftui-new-app-lifecycle-firebase/
  static func onOpenURL(_ url: URL) {
    GIDSignIn.sharedInstance.handle(url)
  }

  func login() {
    login(loginWith: loginWithGoogle)
  }

  func login(loginWith: () -> Bool) {
    if user != nil {
      log.info("AuthModel.login: Skipping, already logged in: user[\(user as Optional)]")
    } else {
      log.info("AuthModel.login: Logging in")
      withLoading {
        if !loginWith() {
          log.info("AuthModel.login: Login failed/canceled")
        } else {
          user = Auth.auth().currentUser
          log.info("")
          log.info("AuthModel.login: Logged in: user[\(user as Optional)]")
        }
      }
    }
  }

  func logout() {
    if user == nil {
      log.info("AuthModel.logout: Skipping, not logged in: user[\(user as Optional)]")
    } else {
      log.info("AuthModel.logout: Logging out user[\(user as Optional)]")
      withLoading {
        // https://firebase.google.com/docs/auth/ios/custom-auth
        do {
          try Auth.auth().signOut()
          log.info("AuthModel.logout: Logout successful")
        } catch {
          log.info("AuthModel.logout: Logout failed: \(error)")
        }
      }
      // Always set user to nil, whether logout succeeds or fails
      user = nil
    }
  }

  func withLoading<X>(f: () -> X) -> X {
    loading = true
    defer { loading = false }
    return f()
  }

}
