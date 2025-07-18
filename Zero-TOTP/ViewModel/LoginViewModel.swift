//
//  LoginViewModel.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-17.
//

import Foundation

class LoginViewModel: ObservableObject {
    private let defaults = UserDefaults.standard
    
    
    func onLoginAppear() {
        UserDefaults.standard.get("user_email")
    }
}
