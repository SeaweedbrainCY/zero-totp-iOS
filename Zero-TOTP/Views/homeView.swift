//
//  homeView.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 22/08/2023.
//

import SwiftUI


struct ContentView: View {
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
                    .padding(.horizontal, 40)
                
               Spacer()
            
                    Button(action: {
                        // Action du premier bouton
                    }) {
                        Text("Login")
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                            .fontWeight(.bold)
                            .padding()
                            .foregroundColor(Color("dark"))
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        // Action du deuxième bouton
                    }) {
                        Text("Signup")
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                            .fontWeight(.bold)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color("dark"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10).stroke( Color.white, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                Spacer()
                Button(action: {
                    // Action du premier bouton
                }) {
                    Text("Privacy Policy")
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        .padding()
                        .foregroundColor(Color.gray)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
