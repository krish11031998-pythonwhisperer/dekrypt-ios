//
//  AuthInterface.swift
//  SignalMVP
//
//  Created by Krishna Venkatramani on 28/12/2022.
//

import Foundation
import FirebaseAuth
import Combine
import UIKit
import DekryptService

protocol AuthInterface {
    func registerUser(email: String, password: String) -> AnyPublisher<AuthDataResult?, Error>
    func loginUser(email: String, password: String) -> AnyPublisher<AuthDataResult?, Error>
    func signOutUserPublisher() -> AnyPublisher<(), Error>
    
    func sendVerificationLink(email: String) -> AnyPublisher<(), Error>
    func sendResetPasswordLink(email: String) -> AnyPublisher<(), Error>
    func deleteUser() -> AnyPublisher<(), Error>
    
    //MARK: - Sign In With Google
    func signInWithGoogle(_ vc: UIViewController) -> AnyPublisher<FirebaseUserAuthModel, Error>
}
