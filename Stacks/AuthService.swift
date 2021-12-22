import Combine
import Firebase
import GoogleSignIn
import XCGLogger

enum AuthState {

  case Loading
  case LoggedOut
  case LoggedIn(User)

  var user: User? {
    get {
      switch self {
        case .Loading:            return nil
        case .LoggedOut:          return nil
        case .LoggedIn(let user): return user
      }
    }
  }

}

class AuthService: ObservableObject {

  // Must use DispatchQueue.main to set these
  //  - So that state publishes come from main thread (else runtime warning + no effect)
  @Published var authState: AuthState {
    didSet { userDidChange_.send((oldValue, authState)) }
  }

  // Trigger this manually via didSet because $user.sink fires with the new value _before_ auth.user is updated
  //  - didSet triggers _after_ auth.user is updated, and provides old and new values
  //  - $user.sink triggers _before_ auth.user is updated, and provides the new value (read auth.user for the old value)
  var userDidChange_ = PassthroughSubject<(AuthState, AuthState), Never>()

  // NOTE This can't be async (for restoreLogin) because AppMain.init can't be async
  init() {
    authState = AuthState.Loading
    // https://firebase.google.com/docs/auth/ios/start
    // https://firebase.google.com/docs/auth/ios/manage-users
    Auth.auth().addStateDidChangeListener { auth, user in
      self.userDidChange(user: user.map { User($0) })
    }
    Task {
      await restoreLogin()
    }
  }

  func userDidChange(user: User?) {
    log.info("user[\(opt: user)]")
    DispatchQueue.main.async {
      self.authState = user == nil ? .LoggedOut : .LoggedIn(user!)
    }
  }

  // https://developers.google.com/identity/sign-in/ios/sign-in
  //  - "2. Attempt to restore the user's sign-in state"
  func restoreLogin() async -> () {
    log.info("Start")
    authState = .Loading
    return await withCheckedContinuation { k in
      GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
        if let error = error {
          log.error("Failed: user[\(opt: user)], error[\(error)]")
          self.authState = .LoggedOut
        } else {
          log.info("Done: user[\(opt: user)]")
          // self.authState = .LoggedIn(...) // Handled by userDidChange
        }
        k.resume()
      }
    }
  }

  // https://developers.google.com/identity/sign-in/ios/sign-in
  //  - https://github.com/firebase/quickstart-ios/blob/master/authentication/AuthenticationExample/ViewControllers/AuthViewController.swift
  //  - https://stackoverflow.com/questions/59737264/how-to-properly-use-google-signin-with-swiftui/65772658
  //  - https://developers.google.com/identity/sign-in/ios/reference/Classes/GIDSignIn
  func loginWithGoogle() async -> AuthCredential? {
    log.info("Start")
    let clientId: String = (FirebaseApp.app()?.options.clientID)!
    let config = GIDConfiguration(clientID: clientId)
    // TODO Deprecation: 'windows' was deprecated in iOS 15.0: Use UIWindowScene.windows on a relevant window scene instead
    //  - https://developer.apple.com/forums/thread/682621
    //  - https://stackoverflow.com/questions/68387187/how-to-use-uiwindowscene-windows-on-ios-15
    let viewController: UIViewController = await (UIApplication.shared.windows.first?.rootViewController)!
    return await withCheckedContinuation { k in
      GIDSignIn.sharedInstance.signIn(with: config, presenting: viewController) { user, error in
        if error != nil || user == nil {
          log.error("Failed to signIn: config[\(config)] -> user[\(opt: user)], error[\(opt: error)]")
          k.resume(returning: nil)
        } else {
          let user = user!
          if user.authentication.idToken == nil {
            log.error("Null idToken for user[\(user)], user.authentication[\(user.authentication)]")
            k.resume(returning: nil)
          } else {
            let credential = GoogleAuthProvider.credential(
              withIDToken: user.authentication.idToken!,
              accessToken: user.authentication.accessToken
            )
            log.info("Done: user[\(user)] -> credential[\(credential)]")
            k.resume(returning: credential)
          }
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
  func onOpenURL(_ url: URL) {
    log.info("url[\(url)]")
    GIDSignIn.sharedInstance.handle(url)
  }

  func login() async {
    await login(loginWithGoogle)
  }

  func login(_ loginWith: () async -> AuthCredential?) async {
    log.info("Start")
    switch authState {
      case .Loading:
        log.info("Skipped, unexpected state: authState[\(authState)]")
      case .LoggedIn(let user):
        log.info("Skipping, already logged in: user[\(user)]")
      case .LoggedOut:
        log.info("Logging in...")
        authState = .Loading
        guard let credential = await loginWith() else {
          log.info("Login failed/canceled")
          authState = .LoggedOut
          return
        }
        return await withCheckedContinuation { k in
          // https://firebase.google.com/docs/auth/ios/google-signin
          //  - "3. Authenticate with Firebase"
          let _ = Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
              log.error("Failed to Auth.signIn: credential[\(credential)] -> authResult[\(opt: authResult)], error[\(error)]")
              self.authState = .LoggedOut
            } else {
              log.info("Logged in: user[\(opt: authResult?.user)]")
              // self.authState = .LoggedIn(...) // Handled by userDidChange
            }
            k.resume()
          }
        }
      }
  }

  func logout() async {
    log.info("Start")
    switch authState {
      case .Loading:
        log.info("Skipped, unexpected state: authState[\(authState)]")
      case .LoggedOut:
        log.info("Skipping, not logged in: authState[\(authState)]")
      case .LoggedIn(let user):
        log.info("Logging out user[\(user)]...")
        authState = .Loading
        // https://firebase.google.com/docs/auth/ios/custom-auth
        do {
          try Auth.auth().signOut()
          log.info("Logout successful")
        } catch {
          log.error("Logout failed: \(error)")
        }
        // Always reset to .LoggedOut, even if .signOut() failed
        authState = .LoggedOut
    }
  }

}
