//
//  AuthService.swift
//  SignalMVP
//
//  Created by Krishna Venkatramani on 28/12/2022.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import Combine
import DekryptService

enum UserState: String, Error {
    case userSignOutFailure = "User not able to sign out"
    case userGoogleSignInFailed = "User was not able to sign in using Google"
}

class FirebaseAuthService: AuthInterface {

    static var shared: FirebaseAuthService = .init()
    
    init() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    func registerUser(email: String, password: String) -> AnyPublisher<AuthDataResult?, Error> {
        Future { promise in
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] authRes, err in
                guard let self, let validAuthRes = authRes else {
                    if let err = err {
                        print("(ERROR) err: ", err.localizedDescription)
                        promise(.failure(err))
                    }
                    return
                }
                print("(DEBUG) auth: ", validAuthRes)
                promise(.success(authRes))
            }
        }.eraseToAnyPublisher()
       
    }
    
    func loginUser(email: String, password: String) -> AnyPublisher<AuthDataResult?, Error>  {
        Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authRes, err in
                guard let self, let validAuthRes = authRes else {
                    if let err = err {
                        print("(ERROR) err: ", err.localizedDescription)
                        promise(.failure(err))
                    }
                    return
                }
                print("(DEBUG) auth: ", validAuthRes)
                promise(.success(authRes))
            }
        }.eraseToAnyPublisher()
    }
    
    func signOutUserPublisher() -> AnyPublisher<(), Error> {
        Future { promise in
            guard let _ = try? Auth.auth().signOut() else {
                promise(.failure(UserState.userSignOutFailure))
                return
            }
            promise(.success(()))
        }.eraseToAnyPublisher()
    }
    
    func signOutUser() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("(ERROR) Sign Out: ", error.localizedDescription)
        }
    }
    
    func sendVerificationLink(email: String) -> AnyPublisher<(), Error> {
        Future { promise in
            Auth.auth().currentUser?.sendEmailVerification { err in
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func sendResetPasswordLink(email: String) -> AnyPublisher<Void, Error> {
        Future { promise in
            Auth.auth().sendPasswordReset(withEmail: email) {
                guard let err = $0 else {
                    promise(.success(()))
                    return
                }
                promise(.failure(err))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteUser() -> AnyPublisher<(), Error> {
        Future { promise in
            Auth.auth().currentUser?.delete { err in
                if let err {
                    promise(.failure(err))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

}


//MARK: - Sign In With Google
extension FirebaseAuthService {
    
    func signInWithGoogle(_ vc: UIViewController) -> AnyPublisher<FirebaseUserAuthModel, Error> {
        Future { promise in
            GIDSignIn.sharedInstance.signIn(withPresenting: vc) { result, error in
                if let error {
                    promise(.failure(error))
                    return
                }
                
                
                guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
                else {
                    promise(.failure(UserState.userGoogleSignInFailed))
                    return
                }
        
                var profileImage: URL?
                if user.profile?.hasImage ?? false {
                    profileImage = user.profile?.imageURL(withDimension: 100)
                }
                
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: user.accessToken.tokenString)
                
                let userAuthModel = FirebaseUserAuthModel(credential: credential,
                                                          displayName: user.profile?.name,
                                                          profileImage: profileImage)
                
                promise(.success(userAuthModel))
            }
        }.eraseToAnyPublisher()
    }
    
    func signInWithUserAuthCredentials(with model: FirebaseUserAuthModel) -> AnyPublisher<User, Error> {
        let credential = model.credential
        return Future { promise in
            Auth.auth().signIn(with: credential) { result, err in
                if let err {
                    promise(.failure(err))
                    return
                }
                
                
                guard let user = result?.user else {
                    promise(.failure(UserState.userGoogleSignInFailed))
                    return
                }
                let request = user.createProfileChangeRequest()
                request.displayName = model.displayName
                request.photoURL = model.profileImage
                request.commitChanges { err in
                    if let err {
                        print("(DEBUG) issue while updating the user's profile details: ", err.localizedDescription)
                    }
                    promise(.success(user))
                }

            }
        }.eraseToAnyPublisher()
    }
    
}
