//
//  KeychainStorage.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-10-30.
//


import Foundation
import CryptoKit
import CommonCrypto
import LocalAuthentication
import Security




class KeychainTags {
    let user_id:Int;
    let zke_key:Data;
    let encrypted_vault:Data;
    
    init(_ user_id: Int){
        self.user_id = user_id
        self.zke_key = "com.zero-totp.zke_key.user.\(self.user_id)".data(using: .utf8)!
        self.encrypted_vault = "com.zero-totp.encrypted-vault.user.\(self.user_id)".data(using: .utf8)!
    }
}

enum KeychainRetrievalError:Error {
    case itemNotFound
    case userCancel
    case authenticationFailed
    case otherError(OSStatus)
}



class KeychainStorage {
    
    struct StoredEncryptedVault: Codable {
        var encrypted_vault: [VaultAPI.EncryptedSecret];
        var storage_timestamp: String;
    }
    
    func storeZKEKeyInKeychain(_ zke_key_data: Data, user_id:Int) -> Bool{
        guard let accessControl = SecAccessControlCreateWithFlags(nil,
                                                                      kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                                      .biometryCurrentSet,
                                                                      nil) else {
                print("Failed to create access control")
                return false
            }
        let query: [String:Any] = [kSecClass as String: kSecClassKey,
                                      kSecAttrApplicationTag as String: KeychainTags(user_id).zke_key,
                                      kSecValueData as String: zke_key_data,
                                      kSecAttrAccessControl as String: accessControl];
        

        SecItemDelete(query as CFDictionary);

        
        // Store the key
        
        let set_status = SecItemAdd(query as CFDictionary, nil);
        print(set_status)
        return set_status == errSecSuccess;
    }
    
    func retrieveZKEKeyFromKeychain(user_id:Int) throws -> Data?{
        let context = LAContext()
            context.localizedReason = "Your vault decryption key is protected by your biometrics."

        let query: [String:Any] = [kSecClass as String: kSecClassKey,
                                      kSecAttrApplicationTag as String: KeychainTags(user_id).zke_key,
                                   kSecReturnData as String: true,
                                   kSecUseAuthenticationContext as String: context,
                                   kSecMatchLimit as String: kSecMatchLimitOne];
        
        var result: AnyObject?;
        let status =  SecItemCopyMatching(query as CFDictionary, &result);
        if status == errSecSuccess, let data = result as? Data {
                return data
            } else {
                switch status {
                case errSecAuthFailed: throw KeychainRetrievalError.authenticationFailed
                case errSecItemNotFound: throw KeychainRetrievalError.itemNotFound
                case errSecUserCanceled: throw KeychainRetrievalError.userCancel
                default:
                    print("Keychain retrieval failed: \(status)")
                    throw KeychainRetrievalError.otherError(status)
                }
            }
    }
    
    
    func storeEncryptedVaultInKeychain(_ encryptedVault:[VaultAPI.EncryptedSecret] , user_id:Int) -> Bool{
        let currentTimestamp = Date()
        let vault_to_store: StoredEncryptedVault = StoredEncryptedVault(encrypted_vault: encryptedVault, storage_timestamp: String(currentTimestamp.timeIntervalSince1970))
        
        guard let accessControl = SecAccessControlCreateWithFlags(nil,
                                                                      kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                                      .biometryCurrentSet,
                                                                      nil) else {
                print("Failed to create access control")
                return false
            }
        print(encryptedVault)
        let encrypted_vault_data = try? JSONEncoder().encode(vault_to_store) //try? JSONSerialization.data(withJSONObject: encryptedVault, options: [])
        if(encrypted_vault_data != nil){
            
            
            let query: [String:Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: KeychainTags(user_id).encrypted_vault,
                                       kSecValueData as String: encrypted_vault_data!,
                                       kSecAttrAccessControl as String: accessControl];
            
            SecItemDelete(query as CFDictionary);
            
            
            let set_status = SecItemAdd(query as CFDictionary, nil);
            return set_status == errSecSuccess;
        } else {
            print("fail to convert vault as array")
            return false;
        }
    }
    
    func  getEncryptedVaultFromKeychain(user_id:Int) throws -> StoredEncryptedVault? {
        print("Attempt to get vault from keychain")
        let context = LAContext()
            context.localizedReason = "Your vault is protected by your biometrics."

        let query: [String:Any] = [kSecClass as String: kSecClassKey,
                                      kSecAttrApplicationTag as String: KeychainTags(user_id).encrypted_vault,
                                   kSecReturnData as String: true,
                                   kSecUseAuthenticationContext as String: context,
                                   kSecMatchLimit as String: kSecMatchLimitOne];
        
        var result: AnyObject?;
        let status =  SecItemCopyMatching(query as CFDictionary, &result);
        
        if status == errSecSuccess, let data = result as? Data {
            return try? JSONDecoder().decode(StoredEncryptedVault.self, from: data)
        } else {
            print("Vault retrieval failed with status: \(status)")
            switch status {
            case errSecAuthFailed: throw KeychainRetrievalError.authenticationFailed
            case errSecItemNotFound: throw KeychainRetrievalError.itemNotFound
            case errSecUserCanceled: throw KeychainRetrievalError.userCancel
            default:
                print("Keychain retrieval failed: \(status)")
                throw KeychainRetrievalError.otherError(status)
            }
        }
    }
    
}
