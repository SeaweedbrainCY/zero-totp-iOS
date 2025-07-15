//
//  homeView.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 22/08/2023.
//

import SwiftUI


struct HomeView: View {
    var body: some View {
        NavigationStack {
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
                    
                    
                    NavigationLink{
                        LoginView()
                    } label:{
                        Text("Login")
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                            .fontWeight(.bold)
                            .padding()
                            .foregroundColor(Color("dark"))
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                    
                    Link(destination: URL(string: "https://zero-totp.com/signup")!){
                        Text("Signup")
                    
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                            .fontWeight(.bold)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color("dark"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10).stroke( Color.white, lineWidth: 1)
                            )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    }
                    
                    Spacer()
                    Link("Privacy Policy", destination: URL(string: "https://zero-totp.com/privacy")!)
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                            .padding()
                            .foregroundColor(Color.gray)
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
