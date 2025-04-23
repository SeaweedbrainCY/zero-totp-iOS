//
//  Crypto.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 16/05/2024.
//

import Foundation
import CryptoKit
import CommonCrypto

class CryptoTools {
    
    var pbkdf2_iterations = 700000;
    
    enum CryptoError: Error {
        case SaltImportError;
    }
    
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
    
    func derivePassphrase(passphrase:String, derivationKeySalt:String) async -> String? {
        do {
            
            guard let passphraseData = passphrase.data(using: .utf8) else { return nil }
            let derivationKeySaltData = Data(base64Encoded: derivationKeySalt)
            if(derivationKeySaltData == nil) {throw CryptoError.SaltImportError}
            var derivedKeyData = Data(repeating: 0, count: passphraseData.count)
            let derivedCount = derivedKeyData.count
            let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
                derivationKeySaltData!.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passphrase,
                        passphraseData.count,
                        saltBytes,
                        derivationKeySaltData!.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(self.pbkdf2_iterations),
                        derivedKeyBytes,
                        derivedCount)
                }
            }
            return derivationStatus == kCCSuccess ? derivedKeyData : nil
        } catch CryptoError.SaltImportError {
            
        } catch {
            
            
        }
    }
}
