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


class TOTPEntry: ObservableObject, Identifiable {
    let id = UUID()
    let item_id: String
    let name: String
    let secret: String
    let color: TOTPBoxColor
    let favicon: Bool
    let uri: String
    let tags: [String]
    let domain: String?
    var totp:TOTP? = nil

    @Published var totp_code: String?

    init(name: String, color: TOTPBoxColor,  item_id: String, secret: String, favicon: Bool, uri: String, tags: [String], domain: String?) {
        self.item_id = item_id
        self.secret = secret
        self.favicon = favicon
        self.uri = uri
        self.tags = tags
        self.domain = domain
        self.name = name
        self.color = color
        
        let secret_data = base32DecodeToData(self.secret)
        if (secret_data != nil){
            self.totp = SwiftOTP.TOTP(secret: secret_data!)
            self.totp_code = self.totp?.generate(time: Date())
            if (self.totp == nil){
                print("Invalid TOTP secret")
            }
        } else {
            print("Secret is not a valid base32 encoded string.");
        }
        
        
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
    let tags: String
    let domain: String?
}



class VaultViewModel:ObservableObject {
    @Published var count = 0
    @Published var show_login_page = false;
    @Published var vault: [TOTPEntry] = [];
    @Published var toast: FancyToast?;
    @Published var totp_seconds_remaining:Double = 30.0;
    @Published var progress:Double = 1.0;
    let totp_default_interval:Double = 30.0;
    private var backgroundQueue = DispatchQueue(label: "totp.timer", qos: .utility)
    var next_generate_datetime:Date? = nil;
    private var timer: Timer?
    public let refresh_interval_s = 0.1;

    
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
                                    
                                    decrypted_vault.append(TOTPEntry(name: decoded_secret.name,  color: color, item_id: enc_secret.uuid , secret: decoded_secret.secret, favicon: display_favicon, uri: decoded_secret.uri, tags: [decoded_secret.tags], domain: decoded_secret.domain))
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
        self.startTimer()
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
