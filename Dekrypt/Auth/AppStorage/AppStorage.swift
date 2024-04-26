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
    private var auth: AuthPublisher
    private var bag: Set<AnyCancellable>
    
    init(user: UserModel? = nil) {
        self.user = user
        self.auth = .init()
        self.bag = .init()
        bind()
    }
    
    var userPublisher: AnyPublisher<UserModel?, Never> {
        $user
            .print("(DEBUG) userPublisher: ")
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
            .withUnretained(self)
            .flatMap { (appStorage, auth) -> AnyPublisher<UserModelResponse, Error> in
                guard let auth else {
                    return .just(UserModelResponse(data: nil, success: false, err: nil))
                }
                
                return UserService.shared.getOrCreateUser(uid: auth.uid)
            }
            .compactMap(\.data)
            .withUnretained(self)
            .sinkReceive { $0.user = $1 }
            .store(in: &bag)
    }
 }
