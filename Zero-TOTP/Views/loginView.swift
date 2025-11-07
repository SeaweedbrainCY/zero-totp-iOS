//
//  loginView.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 16/05/2024.
//

import Foundation
import SwiftUI
import UIKit




struct LoginView: View {
    @ObservedObject var vaultViewModel: VaultViewModel
    @State private var email: String = ""
    @State private var passphrase: String = ""
    @State private var toast: FancyToast? = nil
    @State private var showingCustomURLAlert = false
    @State private var zero_totp_url = URLComponents(string: UserDefaults.standard.string(forKey: TenantDefaultsKeys.base_url) ?? "https://zero-totp.com") ?? URLComponents(string: "https://zero-totp.com")!
    @State private var customURL = ""
    @State private var isLoading = false
    
    
    func onLoginAppear(){
        let saved_email = UserDefaults.standard.value(forKey: UserDefaultsKeys.email)
        if(saved_email != nil){
            email = saved_email as! String;
        }
    }

    
    func loginflow(email:String, passphrase:String){
        isLoading = true
        if(!isEmailFormatCorrect(email: email) || !isPassphraseFormatCorrect(passphrase: passphrase)){
            return
        }
        let user_api = UserAPI()
        let vault_api = VaultAPI()
        DispatchQueue.global().async {
            Task {
                let specs = await user_api.getLoginSpec(username: email)
                if (specs.status == 200){
                    let salt = specs.message
                    let crypto_tool = CryptoTools()
                    let keychain = KeychainStorage()
                    let hashed_passphrase = await crypto_tool.hashPassphrase(passphrase: passphrase, salt: salt)
                    let login_flow = await user_api.authenticationFlow(username: email, passphrase: hashed_passphrase ?? "")
                    if (login_flow.status == 200){
                        if let derivedKey = await crypto_tool.derivePassphrase(passphrase: passphrase, derivationKeySalt: login_flow.derivedKeySalt) {
                            let get_zke_flow: VaultAPI.ZKEEncryptedKeyFlowResult = await vault_api.get_zke_encrypted_key()
                                if (get_zke_flow.status == 200){
                                    let decrypted_zke_key = crypto_tool.aes_decrypt(encrypted_cipher: get_zke_flow.zke_encrypted_key!, key_data: derivedKey)
                                    if (decrypted_zke_key != nil){
                                        let decrypted_zke_key_data = Data(base64Encoded: decrypted_zke_key!)
                                        if (decrypted_zke_key_data != nil){
                                            if (keychain.storeZKEKeyInKeychain(decrypted_zke_key_data!, user_id: login_flow.id)){
                                                await MainActor.run {
                                                    toast = FancyToast(type: .success , title: "Welcome back 🎉", message: "")
                                                    
                                                    UserDefaults.standard.set(email, forKey: UserDefaultsKeys.email)
                                                    isLoading = false
                                                    vaultViewModel.login_successful()
                                                }
                                            } else {
                                                await MainActor.run {
                                                    toast = FancyToast(type: .error, title: "Error occured while storing your keys", message: "Error code 0x3")
                                                    isLoading = false
                                                }
                                            }
                                        } else {
                                            await MainActor.run {
                                                toast = FancyToast(type: .error, title: "Error occured while decoded your keys", message: "Error code 0x2")
                                                isLoading = false
                                            }
                                        }
                                        
                                } else {
                                    await MainActor.run {
                                        toast = FancyToast(type: .error, title: "Error occured while decrypting your keys", message: "Error code 0x1")
                                        isLoading = false
                                    }
                                }
                            } else {
                                await MainActor.run {
                                    toast = FancyToast(type: .error, title: "Error \(get_zke_flow.status)", message: "\(get_zke_flow.message)")
                                    isLoading = false
                                }
                            }
                        }
                        
                    } else {
                        await MainActor.run {
                            toast = FancyToast(type: .error, title: "Error \(login_flow.status)", message: "\(login_flow.message)")
                            isLoading = false
                        }
                    }
                    
                    
                } else {
                    await MainActor.run {
                        toast = FancyToast(type: .error, title: "Error \(specs.status)", message: "Error while initiating the login flow. \(specs.message)")
                        isLoading = false
                    }
                }
            }
        }
    }
    
    func setCustomURL(url:String){
        if(url.range(of: "((([A-Za-z]{3,9}:(?:\\/\\/)?)(?:[-;:&=\\+\\$,\\w]+@)?[A-Za-z0-9.-]+(:[0-9]+)?|(?:www.|[-;:&=\\+\\$,\\w]+@)[A-Za-z0-9.-]+)((?:\\/[\\+~%\\/.\\w\\-_]*)?\\??(?:[-\\+=&;%@.\\w_]*)#?(?:[\\w]*))?)",  options: .regularExpression, range: nil, locale: nil)) == nil {
            toast = FancyToast(type: .error, title: "Invalid URL", message: "Please provide a valid URL for your custom Zero-TOTP instance")
            self.isLoading = false
        } else {
            guard let url_component = URLComponents(string: url) else {
                toast = FancyToast(type: .error, title: "Invalid URL", message: "Please provide a valid URL for your custom Zero-TOTP instance")
                self.isLoading = false
                return
            }
            self.zero_totp_url = url_component
            let defaults = UserDefaults.standard
            defaults.set(url, forKey: TenantDefaultsKeys.base_url)
        }
        
    }
    
    func isEmailFormatCorrect(email:String)->Bool{
        if(email == "" || email.range(of: "\\S+@\\S+\\.\\S+", options: .regularExpression, range: nil, locale: nil) == nil){
            toast = FancyToast(type: .error, title: "Invalid email address", message: "Please provide a valid email address ")
            self.isLoading = false
            return false
        } else {
            return true
        }
    }
    
    func isPassphraseFormatCorrect(passphrase:String)->Bool{
        if(passphrase == ""){
            toast = FancyToast(type: .error, title: "Empty passphrase", message: "Your passphrase cannot be empty")
            self.isLoading = false
            return false
        } else {
            return true
        }
    }
    
    
    var body: some View {
        
        ZStack {
            Color("dark").ignoresSafeArea()
            
            VStack {
                /*Spacer()*/
                Image("logo_zero_totp_light")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    .padding(.top, 30)
                    .padding(.horizontal, 40).padding(.bottom, 70)
                
                Text("Login to your account").font(.largeTitle).bold().foregroundStyle(.white)
                    .padding(.bottom, 70)
                HStack{
                    Text(Image(systemName: "envelope")).foregroundStyle(.white)
                    TextField("Your Email", text:$email)
                        .keyboardType(.emailAddress)
                          .textContentType(.emailAddress)
                          .disableAutocorrection(true)
                          .autocapitalization(.none)
                        .preferredColorScheme(.dark)
                        .foregroundColor(.white)
                        .bold()
                    
                }.padding(.horizontal, 40).padding(.bottom, 30)
                HStack{
                    Text(Image(systemName: "key.horizontal")).foregroundStyle(.white)
                    SecureField("Your passphrase", text:$passphrase)
                        .preferredColorScheme(.dark)
                        .foregroundColor(.white)
                        .bold()
                    
                }.padding(.horizontal, 40).padding(.bottom, 50)
                
                Button(action: {
                    
                    self.loginflow(email: self.email, passphrase: self.passphrase)
                }) {
                    if(!isLoading){
                        Text("\(Image(systemName:"lock.circle.dotted")) Decrypt")
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                            .fontWeight(.bold)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10).stroke( Color.white, lineWidth: 1)
                                
                            )
                    } else {
                        ProgressView().padding(.vertical, 10)
                    }
                }.disabled(isLoading)
                .padding(.horizontal, 70)
                HStack {
                    
                    Text("Zero-TOTP instance : ")
                    Button("\(zero_totp_url.host ?? "Invalid domain") \(Image(systemName:"pencil"))"){
                        showingCustomURLAlert.toggle()
                    }.foregroundColor(.info).alert("Enter your custom server URL", isPresented: $showingCustomURLAlert) {
                        TextField("https://zero-totp.com", text: $customURL, prompt: Text(verbatim:"https://zero-totp.com").foregroundStyle(.gray)).autocapitalization(.none)
                        Button("Cancel", action: {
                            showingCustomURLAlert.toggle()
                        })
                        Button("OK", action: {
                            showingCustomURLAlert.toggle()
                            setCustomURL(url:customURL)
                        })
                    } message: {
                        Text("If you're using a self-hosted version of Zero-TOTP, enter the URL of your server here.")
                    }
                        
                }.padding(.horizontal, 20).padding(.top, 10)
                
                Spacer()
                HStack {
                    Text("Don't have a account yet ?")
                        .foregroundColor(.white)
                    
                    Link("Signup", destination: URL(string: "https://zero-totp.com/signup")!)
                        .foregroundColor(.info)
                }.padding(.horizontal, 20)
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea(.keyboard)
        }
        .toastView(toast: $toast)
        .gesture(DragGesture().onChanged{_ in UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)}).onAppear(perform: onLoginAppear)
    }
    
    
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(vaultViewModel: VaultViewModel())
    }
}
