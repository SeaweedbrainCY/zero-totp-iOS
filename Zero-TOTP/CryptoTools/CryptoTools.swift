//
//  Crypto.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 16/05/2024.
//

import Foundation
import Crypto

class Crypto {
    
    func hashPassphrase(passphrase:String, salt:String) async -> String {
        let passphrase_encoded = passphrase.data(using: .utf8)
        let salt_data = Data(base64Encoded: salt)
        
    
    }
}
