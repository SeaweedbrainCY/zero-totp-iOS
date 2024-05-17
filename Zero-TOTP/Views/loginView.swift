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
    @State private var email: String = ""
    @State private var passphrase: String = ""
    @State private var toast: FancyToast? = nil

    
    func loginflow(email:String, passphrase:String){
        let api = API()
        DispatchQueue.global().async {
            Task {
                let specs = await api.getLoginSpec(username: email)
                if (specs.status == 200){
                    let salt = specs.message
                    let crypto_tool = CryptoTools()
                    let hashed_passphrase = await crypto_tool.hashPassphrase(passphrase: passphrase, salt: salt)
                    print(hashed_passphrase)
                } else {
                    if(specs.status == 400){
                        toast = FancyToast(type: .error, title: "Bad email", message: "Are your sure about your mail ?")
                    } else {
                        toast = FancyToast(type: .error, title: "Error \(specs.status)", message: "\(specs.message)")
                    }
                }
            }
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
                
                Text("Decrypt your vault").font(.largeTitle).bold().foregroundStyle(.white)
                    .padding(.bottom, 70)
                HStack{
                    Text(Image(systemName: "envelope"))
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
                    Text(Image(systemName: "key.horizontal"))
                    SecureField("Your passphrase", text:$passphrase)
                        .preferredColorScheme(.dark)
                        .foregroundColor(.white)
                        .bold()
                    
                }.padding(.horizontal, 40).padding(.bottom, 50)
                
                Button(action: {
                    
                    self.loginflow(email: self.email, passphrase: self.passphrase)
                }) {
                    Text("\(Image(systemName:"lock.circle.dotted")) Decrypt")
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        .fontWeight(.bold)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke( Color.white, lineWidth: 1)
                            
                        )
                }
                .padding(.horizontal, 70)
                
                Spacer()
                HStack {
                    Text("Don't have a account yet ?")
                        .foregroundColor(.white)
                    
                    Link("Signup", destination: URL(string: "https://zero-totp.com/signup")!)
                            .foregroundColor(.info)
                }.padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toastView(toast: $toast)
        .gesture(DragGesture().onChanged{_ in UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)})
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
