import Firebase
import GoogleSignIn
import Logging

class AuthService: ObservableObject {

  let log = Logger(label: "Stacks.AuthService")

  @Published var loading: Bool
  @Published var user: User?

  // NOTE This can't be async (for restoreLogin) because AppMain.init can't be async
  init() {
    loading = true
    user = nil
    // https://firebase.google.com/docs/auth/ios/start
    // https://firebase.google.com/docs/auth/ios/manage-users
    Auth.auth().addStateDidChangeListener { auth, user in
      self.user = user
      self.loading = false
    }
    Task {
      await restoreLogin()
    }
  }

  // TODO Howto get user properties, here whenever we want them
  //  - https://developers.google.com/identity/sign-in/ios/people
  //      emailAddress  = user.profile?.email
  //      fullName      = user.profile?.name
  //      givenName     = user.profile?.givenName
  //      familyName    = user.profile?.familyName
  //      profilePicUrl = user.profile?.imageURL(withDimension: 320)

  // https://developers.google.com/identity/sign-in/ios/sign-in
  //  - "2. Attempt to restore the user's sign-in state"
  func restoreLogin() async -> () {
    return await withLoading { () -> () in
      return await withCheckedContinuation { k in
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
          if let error = error {
            self.log.error("restoreLogin: error[\(error)], user[\(user as Optional)]")
          } else {
            self.log.info("restoreLogin: user[\(user as Optional)]")
          }
          k.resume()
          // self.user is updated by addStateDidChangeListener (above)
        }
      }
    }
  }

  // https://developers.google.com/identity/sign-in/ios/sign-in
  //  - https://github.com/firebase/quickstart-ios/blob/master/authentication/AuthenticationExample/ViewControllers/AuthViewController.swift
  //  - https://stackoverflow.com/questions/59737264/how-to-properly-use-google-signin-with-swiftui/65772658
  //  - https://developers.google.com/identity/sign-in/ios/reference/Classes/GIDSignIn
  func loginWithGoogle() async -> Bool {
    let clientId: String = (FirebaseApp.app()?.options.clientID)!
    let config = GIDConfiguration(clientID: clientId)
    // TODO Deprecation: 'windows' was deprecated in iOS 15.0: Use UIWindowScene.windows on a relevant window scene instead
    //  - https://developer.apple.com/forums/thread/682621
    //  - https://stackoverflow.com/questions/68387187/how-to-use-uiwindowscene-windows-on-ios-15
    let viewController: UIViewController = await (UIApplication.shared.windows.first?.rootViewController)!
    return await withLoading { () -> Bool in
      return await withCheckedContinuation { k in
        GIDSignIn.sharedInstance.signIn(with: config, presenting: viewController) { user, error in
          if let error = error {
            self.log.error("restoreLogin: error[\(error)], user[\(user as Optional)]")
          } else {
            self.log.info("restoreLogin: user[\(user as Optional)]")
          }
          let loggedIn = error == nil && user != nil
          k.resume(returning: loggedIn)
          // self.user is updated by addStateDidChangeListener (above)
        }
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

  func login() async {
    await login(loginWithGoogle)
  }

  func login(_ loginWith: () async -> Bool) async {
    if user != nil {
      log.info("login: Skipping, already logged in: user[\(user as Optional)]")
    } else {
      log.info("login: Logging in")
      await withLoading {
        if !(await loginWith()) {
          log.info("login: Login failed/canceled")
        } else {
          user = Auth.auth().currentUser
          log.info("")
          log.info("login: Logged in: user[\(user as Optional)]")
        }
      }
    }
  }

  func logout() async {
    if user == nil {
      log.info("logout: Skipping, not logged in: user[\(user as Optional)]")
    } else {
      log.info("logout: Logging out user[\(user as Optional)]")
      await withLoading {
        // https://firebase.google.com/docs/auth/ios/custom-auth
        do {
          try Auth.auth().signOut()
          log.info("logout: Logout successful")
        } catch {
          log.info("logout: Logout failed: \(error)")
        }
      }
      // Always set user to nil, whether logout succeeds or fails
      user = nil
    }
  }

  func withLoading<X>(f: () async -> X) async -> X {
    loading = true
    defer { loading = false }
    return await f()
  }

}
