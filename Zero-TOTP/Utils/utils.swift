//
//  utils.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 16/05/2024.
//

import Foundation


class Utils{
    public func eraseUserData(){
        // Delete user specific default data
        let userDefaultKeys = [UserDefaultsKeys.email, UserDefaultsKeys.user_id, VaultDefaultsKeys.is_vault_stored_in_keychain, VaultDefaultsKeys.last_storage_datetime]
        for defaultKey in userDefaultKeys {
            UserDefaults.standard.removeObject(forKey: defaultKey)
        }
        
        // Delete keychain data
        let secItemClasses = [
            kSecClassKey
        ]
        
        for itemClass in secItemClasses {
            let spec: [String: Any] = [kSecClass as String: itemClass]
            SecItemDelete(spec as CFDictionary)
        }
        
        // Delete cookies
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
    }
}
