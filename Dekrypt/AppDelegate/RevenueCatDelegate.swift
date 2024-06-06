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
    private(set) var products: [StoreProduct] = []
    
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(with: .init(withAPIKey: RevenueCatManager.apiKey))
        Purchases.shared.delegate = self
        fetchProducts(for: nil)
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
    
    func fetchProducts(for productIds: [String]?, completion: (([StoreProduct]) -> Void)? = nil) {
        let ids = productIds ?? [RemoteConfigManager.shared.choosenMonthlyProduct, RemoteConfigManager.shared.choosenYearlyProduct].compactMap({ $0 })
        Purchases.shared.getProducts(ids) { [weak self] products in
            guard let self else { return }
            if let completion {
                completion(products)
            } else {
                self.products = products
            }
        }
    }
    
    public var monthlyProductToDisplay: StoreProduct? {
        guard let choosenMonthlyProduct = RemoteConfigManager.shared.choosenMonthlyProduct else { return  nil }
        return products.first(where: { $0.productIdentifier == choosenMonthlyProduct })
    }
    
    public var yearlyProductToDisplay: StoreProduct? {
        guard let choosenYearlyProduct = RemoteConfigManager.shared.choosenYearlyProduct else { return  nil }
        return products.first(where: { $0.productIdentifier == choosenYearlyProduct })
    }
    
    // MARK: - PurchaseDelegate
    
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        print(customerInfo.entitlements.active)
    }
    
}
