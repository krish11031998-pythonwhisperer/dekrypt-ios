//
//  AppStorage.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 07/01/2023.
//

import Foundation
import Combine
import FirebaseAuth
import DekryptService

class AppStorage {
    
    static var shared: AppStorage = .init()
    @Published var user: UserModel? = nil
    @Published var firstUserFetch: Bool = false
    private var auth: AuthPublisher
    private var bag: Set<AnyCancellable>
    
    init() {
        self.user = UserDefaults.Key.user.value()
        self.auth = .init()
        self.bag = .init()
        bind()
    }
    
    var userPublisher: AnyPublisher<UserModel?, Never> {
        $user
            .removeDuplicates()
            .handleEvents(receiveOutput: { print("(DEBUG) user: ", $0) })
            .share()
            .eraseToAnyPublisher()
    }
    
    var hasUserSession: AnyPublisher<Bool, Never> {
        auth
            .compactMap { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    private func bind() {
        auth
            .flatMap { auth -> AnyPublisher<UserModelResponse, Error> in
                guard let auth else {
                    return .just(UserModelResponse(data: nil, success: false, err: nil))
                }
                
                return UserService.shared.getOrCreateUser(uid: auth.uid)
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.firstUserFetch = true
            })
            .map(\.data)
            .withUnretained(self)
            .sinkReceive { 
                if UserDefaults.Key.user.value() != $1 {
                    UserDefaults.Key.user.setValue($1)
                }
                $0.user = $1
            }
            .store(in: &bag)
    }
 }
