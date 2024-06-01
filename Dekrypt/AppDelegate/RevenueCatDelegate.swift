//
//  RevenueCatDelegate.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 01/06/2024.
//

import RevenueCat
import ObjectiveC

class RevenueCatManager: NSObject, PurchasesDelegate {
    
    public static let shared: RevenueCatManager = .init()
    private static let apiKey: String = "appl_JaLdAaAOBCcZLHyoSKirbTxhYHh"
    private static let entitlementKey: String = "pro"
    
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(with: .init(withAPIKey: RevenueCatManager.apiKey))
        Purchases.shared.delegate = self
    }
 
    func fetchOfferings() {
        Purchases.shared.getOfferings { offerings, error in
            guard let offerings else {
                if let error {
                    print("(ERROR) while fetching: ", error.localizedDescription)
                }
                return
            }
            
            if let current = offerings.current?.availablePackages {
                print("(DEBUG) all Offerings: ", current.map(\.identifier).reduce("", { "\($0),\($1)"}))
            }
        }
    }
    
    
    // MARK: - PurchaseDelegate
    
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        print(customerInfo.entitlements.active)
    }
    
}
