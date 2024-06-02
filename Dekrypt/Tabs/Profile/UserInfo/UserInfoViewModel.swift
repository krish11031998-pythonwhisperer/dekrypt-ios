//
//  UserInfoViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 02/06/2024.
//

import Foundation
import DekryptService
import DekryptUI
import KKit
import Combine
import UIKit

class UserInfoViewModel {
    
    private let userDeletePublisher: PassthroughSubject<Void, Never> = .init()
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
        let userDelete: VoidPublisher
    }
    
    func transform() -> Output {
        let userDelete = userDeletePublisher
            .withUnretained(self)
            .flatMap { (vm, _) in vm.deleteUser() }
            .eraseToAnyPublisher()
        
        let section: AnyPublisher<[DiffableCollectionSection], Never> = .just([userInfoSection()].compactMap({ $0 }))
            
        return .init(section: section, userDelete: userDelete)
            
    }
    
    private func userInfoSection() -> DiffableCollectionSection? {
        
        guard let user = AppStorage.shared.user else { return nil }
        
        let name = user.name
        let email = user.email
        let uid = user.uid
        
        // Name

        let nameItem = DiffableCollectionItem<UserInfoItemView>(.init(title: "Name", description: name, action: nil))
        
        // Email
        
        let emailItem = DiffableCollectionItem<UserInfoItemView>(.init(title: "Email", description: email))
        
        // UID
        
        let uidItem = DiffableCollectionItem<UserInfoItemView>(.init(title: "User Identifier", description: uid))
        
        // Delete User
        
        let deleteUserAction: Callback = { [weak self] in
            self?.userDeletePublisher.send(())
        }
        
        let deleteUser = DiffableCollectionItem<DekryptButton>(.init(text: "Delete".body1Medium(color: .appRed), addHorizontal: false, action: deleteUserAction))
        
        // Section
        
        let sectionLayout: NSCollectionLayoutSection = .singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(44.0), insets: .sectionInsets, spacing: .appVerticalPadding)
            .addHeader()
        
        let header = CollectionSectionHeader(.init(label: "User Info", addHorizontalInset: false))
        
        let section = DiffableCollectionSection(0, cells: [nameItem, emailItem, uidItem, deleteUser], header: header, sectionLayout: sectionLayout)
        
        return section
    }
    
    private func deleteUser() -> VoidPublisher {
        let uid = AppStorage.shared.user!.uid
        
        return FirebaseAuthService.shared.deleteUser()
            .catch({ error -> AnyPublisher<(), Never> in
                print("(ERROR) error: ", error.localizedDescription)
                return .just(())
            })
            .flatMap { _ in
                UserService.shared.deleteUser(uid: uid)
                    .catch({ error -> AnyPublisher<GenericResult<Bool>, Never> in
                        print("(ERROR) error: ", error.localizedDescription)
                        return .just(.init(data: false, success: false, err: nil))
                    })
                    .compactMap(\.data)
                    .filter { $0 }
                    .mapToVoid()
            }
            .eraseToAnyPublisher()
        
    }
}
