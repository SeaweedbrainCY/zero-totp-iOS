//
//  Crypto.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 16/05/2024.
//

import Foundation
import CryptoKit
import CommonCrypto
import LocalAuthentication
import Security




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
    
    func aes_decrypt(encrypted_cipher: String, key_data:Data)-> String? {
        let encrypted_parts = encrypted_cipher.split(separator: ",")
        if (encrypted_parts.count < 2) {
            print("Error. Invalidly formatted encrypted ZKE key")
            return nil;
        }
        
        let cipher_data: Data? = Data(base64Encoded: String(encrypted_parts[0]))
        let iv_data: Data? = Data(base64Encoded: String(encrypted_parts[1]))
        if(cipher_data == nil){
            print("Error. Was AES decrypting, but an error occured while decoding the cipher from b64.");
            return nil;
        } else if (iv_data == nil){
            print("Error. Was AES decrypting, but an error occured while decoding the iv from b64.");
            return nil;
        }
        do {
            let derivedPassphrase = SymmetricKey(data: key_data)
            let sealedBox = try AES.GCM.SealedBox(combined: iv_data! + cipher_data!) // tag is already included at the end of the cipher
            //let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: iv_data!), ciphertext: cipher_data!, tag: Data())
            let decryptedData = try AES.GCM.open(sealedBox, using: derivedPassphrase)
            return String(data: decryptedData, encoding: .utf8)
        } catch  {
            print("Error. ZKE decryption failed. Invalid key. \(error)")
            return nil;
        }
    }
   
}
