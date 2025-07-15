//
//  vaultView.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-15.
//

import SwiftUI


struct VaultView: View {
    var body: some View {
        ZStack {
            Color("dark").ignoresSafeArea()
            ScrollView(.vertical) {
                VStack {
                    Image("logo_zero_totp_light")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 100)
                        .padding(.top, 20)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    Text("Your TOTP vault").font(.largeTitle).bold().foregroundStyle(.white).padding(.trailing, 30).padding(.leading, 30).multilineTextAlignment(.center)
                    Text("You and only you can access to this data. All the magic is done on your iPhone.").font(.subheadline ).bold().foregroundStyle(.gray)
                        .padding(.trailing, 30).padding(.leading, 30).multilineTextAlignment(.center).padding(.bottom, 70)
                }
            }
        }
        
    }
}


struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView()
    }
}
