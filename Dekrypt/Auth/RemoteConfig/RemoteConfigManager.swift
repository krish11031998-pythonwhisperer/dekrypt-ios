//
//  RemoteConfigManager.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 05/06/2024.
//

import Foundation
import FirebaseRemoteConfig

extension Notification.Name {
    static let FetchedRemoteConfig = Notification.Name("fetchedRemoteConfig")
}

class RemoteConfigManager {
    
    private let config: RemoteConfig!
    public static let shared: RemoteConfigManager = .init()
    
    private init() {
        self.config = RemoteConfig.remoteConfig()
    }
    
    public func setup() {
        setDefaultConfigValues()
        fetchRemoteConfig()
    }
    
    private func setDefaultConfigValues() {
        let defaultValues = ["betaPro": false]
        do {
            try config.setDefaults(from: defaultValues)
        } catch {
            print("(DEBUG) Error while setting defaults: ", error.localizedDescription)
        }
    }
    
    private func fetchRemoteConfig() {
        let expiration: TimeInterval
        
        #if DEBUG
        expiration = 0
        #else
        expiration = 3600
        #endif
        
        config.fetch(withExpirationDuration: expiration) { [weak self] status, error in
            
            guard error == nil else {
                if let error {
                    print("(DEBUG) RemoteConfig.Error: ", error.localizedDescription)
                }
                return
            }
            
            if status == .success {
                print("(DEBUG) Fetched Remote Config !")
                self?.config.activate()
                NotificationCenter.default.post(.init(name: .FetchedRemoteConfig))
            }
        }
    }
    
    public var betaPro: Bool {
        config["betaPro"].boolValue
    }
    
    public var includeSubscriptionManagementValue: Bool {
        config["includeSubscriptionManagement"].boolValue
    }
    
    
    // MARK: RevenueCat
    
    public var choosenMonthlyProduct: String? {
        config["choosenMonthlyProduct"].stringValue
    }
    
    public var choosenYearlyProduct: String? {
        config["choosenYearlyProduct"].stringValue
    }
}
