//
//  UserDefaults.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 06/05/2024.
//

import Foundation

extension UserDefaults {
    
    enum Key: String {
        case user = "user"
        
        func value<T: Codable>() -> T? {
            guard let data = standard.object(forKey: rawValue) as? Data else { return nil }
            
            guard let model = try? JSONDecoder().decode(T.self, from: data) else { return nil }
            
            return model
        }
        
        func setValue<T: Codable>(_ val: T) {
            if let data = try? JSONEncoder().encode(val) {
                standard.set(data, forKey: rawValue)
            }
        }
    }
    
}
