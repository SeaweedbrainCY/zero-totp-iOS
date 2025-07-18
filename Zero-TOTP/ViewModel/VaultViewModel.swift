//
//  VaultViewModel.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-17.
//

import Foundation
import CryptoKit
import SwiftOTP

struct TOTPEntry: Identifiable {
    let id = UUID()
    let item_id: String
    let name: String
    let secret: String
    let color: TOTPBoxColor
    let favicon: Bool
    let uri: String
    let tags: [String]
    let domain: String?
    let totp_code: String?
}

struct DecryptedSecret:Codable {
    let name: String
    let secret: String
    let color: String
    let favicon: String
    let uri: String
    let tags: String
    let domain: String?
}



class VaultViewModel:ObservableObject {
    @Published var count = 0
    @Published var show_login_page = false;
    @Published var vault: [TOTPEntry] = [];
    @Published var toast: FancyToast?;
    func increment(){
        count += 1;
        show_login_page = true;
    }
    
    func onVaultAppear(){
       
        Task {
            let user_id:Int? = await self.who_am_i();
            let crypto_tools = CryptoTools()
            var decrypted_vault=[TOTPEntry]()
            
            if (user_id != nil){
                let zke_key_data:Data? = crypto_tools.retrieveZKEKeyFromKeychain(user_id: user_id!)
                if (zke_key_data != nil){
                    let encryptedVault:VaultAPI.GetEncryptedVaultResult = await VaultAPI().get_encrypted_vault()
                    var decryption_failed = false;
                    if (encryptedVault.status == 200){
                        for enc_secret in encryptedVault.encrypted_secrets! {
                            let dec_secret = crypto_tools.aes_decrypt(encrypted_cipher: enc_secret.enc_secret, key_data: zke_key_data!)
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
                                    let secret_data = base32DecodeToData(decoded_secret.secret)
                                    var totp:TOTP?;
                                    if (secret_data != nil){
                                        totp = SwiftOTP.TOTP(secret: secret_data!)
                                        if (totp == nil){
                                            print("Invalid TOTP secret")
                                            decryption_failed = true;
                                        }
                                    } else {
                                        print("Secret is not a valid base32 encoded string.");
                                        decryption_failed = true;
                                    }
                                    decrypted_vault.append(TOTPEntry(item_id: enc_secret.uuid , name: decoded_secret.name, secret: decoded_secret.secret, color: color, favicon: display_favicon, uri: decoded_secret.uri, tags: [decoded_secret.tags], domain: decoded_secret.domain, totp_code: totp?.generate(time: Date())))
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
                        let vault_to_publish = decrypted_vault
                        let final_decryption_failed = decryption_failed
                        await MainActor.run {
                            if(final_decryption_failed){
                                
                                    toast = FancyToast(type: .error, title: "Error while decrypting one of your secret", message: "The vault content might not be complete. Error 0x4")
                                }
                       
                            vault = vault_to_publish
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
            } else {
                await MainActor.run {
                    show_login_page = true
                }
            }
        }
        
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
