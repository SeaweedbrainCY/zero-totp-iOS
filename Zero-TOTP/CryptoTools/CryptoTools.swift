//
//  Crypto.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 16/05/2024.
//

import Foundation
import CryptoKit

class CryptoTools {
    
    func hashPassphrase(passphrase:String, salt:String) async -> String? {
            var passphrase_encoded:Data? =  passphrase.data(using: .utf8)
            let salt_data: Data? =  Data(base64Encoded: salt)
            if(passphrase_encoded == nil || salt_data == nil){
                return nil
            }
            passphrase_encoded!.append(salt_data!)
            let hash_data = SHA256.hash(data: passphrase_encoded!)
            return Data(hash_data).base64EncodedString()
    }
}
