//
//  AppleAuthService.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 30/09/2023.
//

import AuthenticationServices
import FirebaseAuth
import CryptoKit

class AppleAuthService: NSObject {
    
    private override init() {}
    
    fileprivate var currentNonce: String?
    fileprivate var window: UIWindow!
    static var shared: AppleAuthService = .init()
    
    //MARK: CreateNonce
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }

    
    //MARK: SHA256
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }

    //MARK: - Public Methods
    func signIn(_ window: UIWindow?) {
        let nonce = randomNonceString()
        currentNonce = nonce
        self.window = window
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
          authorizationController.delegate = self
          authorizationController.presentationContextProvider = self
          authorizationController.performRequests()
    }
}

//MARK: - AppleAuthService + ASAuthorizationControllerDelegate
extension AppleAuthService: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("(ERROR) Error while signing In with Apple: ", error.localizedDescription)
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
              guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
              }
              guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
              }
              guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
              }
              // Initialize a Firebase credential, including the user's full name.
              let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                                rawNonce: nonce,
                                                                fullName: appleIDCredential.fullName)
              // Sign in with Firebase.
              Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error {
                  // Error. If error.code == .MissingOrInvalidNonce, make sure
                  // you're sending the SHA256-hashed nonce as a hex string with
                  // your request to Apple.
                  print(error.localizedDescription)
                  return
                }
              }
            }
    }
}

//MARK: - AppleAuthService + ASAuthorizationControllerPresentationContextProviding
extension AppleAuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}
