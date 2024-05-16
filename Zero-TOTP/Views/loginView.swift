//
//  loginView.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 16/05/2024.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var passphrase: String = ""
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
                    // Action du deuxième bouton
                }) {
                    Text("Decrypt")
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
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
