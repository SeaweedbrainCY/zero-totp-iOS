//
//  VaultViewModel.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-17.
//

import Foundation
import CryptoKit
import SwiftOTP
import Combine
import SwiftUI


enum VaultState {
    case not_initialized;
    case loading;
    case locally_encrypted;
    case loaded;
    case needToBeFetchedAgain;
}

class TOTPEntry: ObservableObject, Identifiable, Codable {
    let id = UUID()
    let item_id: String
    let name: String
    let secret: String
    let color: TOTPBoxColor
    let favicon: Bool
    let uri: String
    let tags: [String]?
    let domain: String?
    var totp: TOTP? = nil

    @Published var totp_code: String?

    // Convenience initializer used elsewhere in the app
    init(name: String, color: TOTPBoxColor, item_id: String, secret: String, favicon: Bool, uri: String, tags: [String]?, domain: String?) {
        self.item_id = item_id
        self.secret = secret
        self.favicon = favicon
        self.uri = uri
        self.name = name
        self.color = color
        self.tags = tags
        self.domain = domain
        
        let secret_data = base32DecodeToData(self.secret)
        if let secret_data {
            self.totp = SwiftOTP.TOTP(secret: secret_data)
            self.totp_code = self.totp?.generate(time: Date())
            if self.totp == nil {
                print("Invalid TOTP secret")
            }
        } else {
            print("Secret is not a valid base32 encoded string.")
        }
    }

    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case item_id
        case name
        case secret
        case color
        case favicon
        case uri
        case tags
        case domain
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.item_id = try container.decode(String.self, forKey: .item_id)
        self.name = try container.decode(String.self, forKey: .name)
        self.secret = try container.decode(String.self, forKey: .secret)

        // Map color string to TOTPBoxColor, default to .blue if unknown
        let colorString = try container.decodeIfPresent(String.self, forKey: .color) ?? "info"
        switch colorString {
        case "success":
            self.color = .green
        case "warning":
            self.color = .yellow
        case "danger":
            self.color = .red
        case "info":
            fallthrough
        default:
            self.color = .blue
        }

        // favicon might be encoded as string "true"/"false" or a Bool; handle both
        if let boolValue = try? container.decode(Bool.self, forKey: .favicon) {
            self.favicon = boolValue
        } else if let stringValue = try? container.decode(String.self, forKey: .favicon) {
            self.favicon = (stringValue as NSString).boolValue
        } else {
            self.favicon = false
        }

        self.uri = try container.decode(String.self, forKey: .uri)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        self.domain = try container.decodeIfPresent(String.self, forKey: .domain)

        // Initialize runtime-only properties
        self.totp = nil
        self.totp_code = nil

        // Precompute TOTP if possible
        let secret_data = base32DecodeToData(self.secret)
        if let secret_data {
            self.totp = SwiftOTP.TOTP(secret: secret_data)
            self.totp_code = self.totp?.generate(time: Date())
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(item_id, forKey: .item_id)
        try container.encode(name, forKey: .name)
        try container.encode(secret, forKey: .secret)
        // Persist color back as the server string mapping
        let colorString: String
        switch color {
        case .green: colorString = "success"
        case .yellow: colorString = "warning"
        case .red: colorString = "danger"
        case .blue: colorString = "info"
        }
        try container.encode(colorString, forKey: .color)
        try container.encode(favicon, forKey: .favicon)
        try container.encode(uri, forKey: .uri)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(domain, forKey: .domain)
    }

    func regenerateCode() {
        DispatchQueue.main.async {
            self.totp_code = self.totp?.generate(time: Date())
        }
    }
}

struct DecryptedSecret:Codable {
    let name: String
    let secret: String
    let color: String
    let favicon: String
    let uri: String
    let tags: String?
    let domain: String?
}

struct DecryptionVaultResult {
    let success:Bool
    let decryptedVault: [TOTPEntry]
}



class VaultViewModel:ObservableObject {
    @Published var count = 0
    @Published var show_login_page = false;
    @Published var vault: [TOTPEntry]=[];
    @Published var toast: FancyToast?;
    @Published var totp_seconds_remaining:Double = 30.0;
    @Published var progress:Double = 1.0;
    @Published var vault_state:VaultState = .not_initialized;
    let totp_default_interval:Double = 30.0;
    private var backgroundQueue = DispatchQueue(label: "totp.timer", qos: .utility)
    var next_generate_datetime:Date? = nil;
    private var timer: Timer?
    public let refresh_interval_s = 0.1;

    
    func onVaultAppear(){
        print("Vault appeared. Vault state : \(self.vault_state)")
        /* Flow :
            If vault not init :
                Try to fetch it from keychain
                If fetched :
                    Display vault
                    Try to update current vault
                    If API auth fail
                        Display small error message
                Else:
                    Fetch the vault from API
                    If API auth fail
                        Prompt passphrase
            Else:
                nothing
        */
        if(self.vault_state == .needToBeFetchedAgain){
            print("Vault needed to be refetched. Refetching ...")
            self.vault_state = .loading
            self.fetch_new_vault_from_api()
        } else if(self.vault_state == .not_initialized){
            self.vault_state = .loading
            let keychain = KeychainStorage()
            let user_id = UserDefaults.standard.value(forKey: UserDefaultsKeys.user_id) as? Int
            if(UserDefaults.standard.bool(forKey: VaultDefaultsKeys.is_vault_stored_in_keychain) && user_id != nil){
                
                do {
                    let zke_key_data:Data? = try keychain.retrieveZKEKeyFromKeychain(user_id: user_id!)
                    if (zke_key_data != nil){
                        let stored_vault = try keychain.getEncryptedVaultFromKeychain(user_id:user_id!)
                        if(stored_vault != nil){
                            self.vault_state = .locally_encrypted
                            let decrypted_vault_result = self.decrypt_vault(stored_vault!.encrypted_vault , zke_key_data: zke_key_data!)
                            let storage_date = Date(timeIntervalSince1970: Double(stored_vault!.storage_timestamp) ?? 0)
                            
                            print("Vault was stored on \(storage_date.ISO8601Format())")
                            if(!decrypted_vault_result.success){
                                toast = FancyToast(type: .error, title: "Error while decrypting some of your secrets", message: "The vault content might not be complete. Error 0x4")
                            }
                                    
                            vault = decrypted_vault_result.decryptedVault
                        } else {
                            self.vault_state = .needToBeFetchedAgain
                            print("No vault found in keychain. Displaying login view.")
                            
                            show_login_page = true
                        }
                    } else {
                        self.vault_state = .needToBeFetchedAgain
                        print("No ZKE key found in keychain. Displaying login view.")
                        show_login_page = true
                    }
                } catch KeychainRetrievalError.authenticationFailed {
                    self.vault_state = .locally_encrypted
                } catch KeychainRetrievalError.itemNotFound {
                    print("Item not found in keychain. Displaying login view.")
                    self.vault_state = .needToBeFetchedAgain
                    self.show_login_page = true
                } catch KeychainRetrievalError.userCancel {
                    self.vault_state = .locally_encrypted
                } catch {
                    print("Generic error while retrieving ZKE key or vault in keychain. Displaying login vault.")
                    self.vault_state = .needToBeFetchedAgain
                    self.show_login_page = true
                }
                
                print("Vault view loaded. Vault state : \(self.vault_state)")
                
            } else { // vault not stored in keychain
                print("vault is not stored in keychain at all. Fetching the vault from the API.")
                self.vault_state = .loading
                self.fetch_new_vault_from_api()
            }
        }
    }
    
    func fetch_new_vault_from_api(){
       
        Task {
            let user_id:Int? = await self.who_am_i();
            let crypto_tools = CryptoTools()
            let keychain = KeychainStorage()
            
            if (user_id != nil){
                UserDefaults.standard.set(user_id, forKey: UserDefaultsKeys.user_id)
                do {
                    let zke_key_data:Data? = try keychain.retrieveZKEKeyFromKeychain(user_id: user_id!)
                    if (zke_key_data != nil){
                        let encryptedVault:VaultAPI.GetEncryptedVaultResult = await VaultAPI().get_encrypted_vault()
                        if (encryptedVault.status == 200){
                            let store_encrypted_vault_success = keychain.storeEncryptedVaultInKeychain(encryptedVault.encrypted_secrets!, user_id: user_id!)
                            if(store_encrypted_vault_success){
                                UserDefaults.standard.set(true, forKey: VaultDefaultsKeys.is_vault_stored_in_keychain)
                                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: VaultDefaultsKeys.last_storage_datetime)
                            }
                            let decryption_result = self.decrypt_vault(encryptedVault.encrypted_secrets!, zke_key_data: zke_key_data!)
                            await MainActor.run {
                                if(!decryption_result.success){
                                    
                                    toast = FancyToast(type: .error, title: "Error while decrypting one of your secret", message: "The vault content might not be complete. Error 0x4")
                                }
                                
                                vault = decryption_result.decryptedVault
                            }
                        } else {
                            await MainActor.run {
                                toast = FancyToast(type: .error, title: "Error \(encryptedVault.status)", message: "Error while getting your vault. \(encryptedVault.message). Please, try again later.")
                            }
                        }
                    } else {
                        await MainActor.run {
                            show_login_page = true
                        }
                    }
                } catch KeychainRetrievalError.authenticationFailed {
                    self.vault_state = .locally_encrypted
                } catch KeychainRetrievalError.itemNotFound {
                    await MainActor.run {
                        show_login_page = true
                    }
                } catch KeychainRetrievalError.userCancel {
                    self.vault_state = .locally_encrypted
                } catch {
                    await MainActor.run {
                        show_login_page = true
                    }
                }
            } else {
                await MainActor.run {
                    show_login_page = true
                }
            }
        }
        self.startTimer()
    }
    
    
    private func decrypt_vault(_ encryptedVault:[VaultAPI.EncryptedSecret], zke_key_data:Data) -> DecryptionVaultResult{
        var decryption_failed = false;
        var decrypted_vault=[TOTPEntry]()
        let crypto_tools = CryptoTools()
        for enc_secret in encryptedVault {
            let dec_secret = crypto_tools.aes_decrypt(encrypted_cipher: enc_secret.enc_secret, key_data: zke_key_data)
            if (dec_secret != nil){
                do {
                    let decoded_secret = try JSONDecoder().decode(DecryptedSecret.self, from: dec_secret!.data(using: .utf8)!)
                    var color: TOTPBoxColor = .blue;
                    switch decoded_secret.color {
                    case "success":
                        color = .green
                    case "warning":
                        color = .yellow
                    case "danger":
                        color = .red
                    case "info":
                        color = .blue
                    default:
                        color = .blue
                    }
                    
                    let display_favicon = decoded_secret.favicon == "true"
                    var tags:[String]? = nil
                    if decoded_secret.tags != nil {
                        tags = [decoded_secret.tags!]
                    }
                    
                    decrypted_vault.append(TOTPEntry(name: decoded_secret.name,  color: color, item_id: enc_secret.uuid , secret: decoded_secret.secret, favicon: display_favicon, uri: decoded_secret.uri, tags: tags, domain: decoded_secret.domain))
                    print("Secret for \(decoded_secret.name) added")
                } catch{
                   print("Failed to decode secret. \(error)");
                    decryption_failed = true;
                    continue;
                }
                
            } else {
                print("dec_secret is nil.")
                decryption_failed = true;
            }
            
        }
        return DecryptionVaultResult(success: decryption_failed, decryptedVault: decrypted_vault)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.backgroundQueue.async {
                self?.checkAndUpdateTOTP()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
     
     private func checkAndUpdateTOTP() {
         let now = Date().timeIntervalSince1970
         let totp_seconds_remaining = self.totp_default_interval - now.truncatingRemainder(dividingBy: self.totp_default_interval)
         DispatchQueue.main.async {
             self.totp_seconds_remaining = totp_seconds_remaining
             self.progress = self.totp_seconds_remaining/30
         }
         
         if(self.next_generate_datetime == nil){
             self.next_generate_datetime = Date(timeIntervalSince1970: (floor(now/self.totp_default_interval)+1)*self.totp_default_interval)
             print("init next_generate_datetime = \(next_generate_datetime)")
         }
         
         if(self.next_generate_datetime!.timeIntervalSince1970 < Date().timeIntervalSince1970){
             self.next_generate_datetime = Date(timeIntervalSince1970: (floor(now/self.totp_default_interval)+1)*self.totp_default_interval)
             print("new next_generate_datetime = \(next_generate_datetime)")
             self.regenerate_all_totp_codes()
         }
         
     }
    
    
    
    private func regenerate_all_totp_codes(){
        for entry in vault {
                    entry.regenerateCode() 
                }
        print("all totp code re generated")
    }
    
    func who_am_i() async ->Int?{
    // Retrieve account ID of the user and check the user is still auth
        let user_api = UserAPI()
        let api_response:UserAPI.WhoAmIResult = await user_api.getWhoAmI()
        print(api_response)
        if(api_response.status == 200){
             return api_response.id!
        } else {
             return nil
        }
        
    }
    
    func login_successful(){
        self.show_login_page = false
    }
}

