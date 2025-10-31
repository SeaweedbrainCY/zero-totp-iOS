//
//  StorageKeys.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-20.
//
// Manager User settings and information storage


import Foundation


struct UserDefaultsKeys {
    static let user_id = "user_id"
    static let email = "user_email"
}

struct TenantDefaultsKeys {
    static let base_url = "zero_totp_base_url"
}

struct VaultDefaultsKeys {
    static let is_vault_stored_in_keychain = "is_vault_stored_in_keychain"
    static let last_storage_datetime = "vault_last_storage_datetime"
}
