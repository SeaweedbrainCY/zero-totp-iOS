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
        case PassphraseImportError;
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
    
    func derivePassphrase(passphrase:String, derivationKeySalt:String) async -> Data? {
        do {
            
            guard let passphraseData = passphrase.data(using: .utf8) else { throw CryptoError.PassphraseImportError }
            let derivationKeySaltData = Data(base64Encoded: derivationKeySalt)
            if (derivationKeySaltData == nil) {throw CryptoError.PassphraseImportError}
            if(derivationKeySaltData == nil) {throw CryptoError.SaltImportError}
            
            let keyByteCount = 32; // 256 bits
            var derivedKeyData = Data( count: keyByteCount)
            
            
            let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
                    return derivationKeySaltData!.withUnsafeBytes { saltBytes in
                        let derivedKeyPointer = derivedKeyBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                        let saltPointer = saltBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)

                        return CCKeyDerivationPBKDF(
                            CCPBKDFAlgorithm(kCCPBKDF2),
                            passphrase, passphraseData.count,
                            saltPointer, derivationKeySaltData!.count,
                            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                            UInt32(pbkdf2_iterations),
                            derivedKeyPointer, keyByteCount
                        )
                    }
                }
            return derivationStatus == kCCSuccess ? derivedKeyData : nil
           
        } catch CryptoError.SaltImportError {
            print("Salt importError")
            return nil
        } catch CryptoError.PassphraseImportError {
            print("Passphrase importError")
            return nil
        } catch {
            print("Generic error happened")
            return nil
        }
        
    }
}
