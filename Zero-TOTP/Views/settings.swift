//
//  settings.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-11-02.
//

import Foundation
import SwiftUI
import UIKit


struct SettingsView: View {
    @State private var userNotifications = true
    @State private var darkMode = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Account Section
                Section("Account") {
                    NavigationLink("Edit Profile") {
                        
                    }
                    Button(role: .destructive) {
                        logout()
                    } label: {
                        Text("Log Out")
                    }
                }

                // MARK: - Preferences Section
                Section("Preferences") {
                    Toggle("Enable Notifications", isOn: $userNotifications)
                    Toggle("Dark Mode", isOn: $darkMode)
                    NavigationLink("Language") {
                        
                    }
                }

                // MARK: - Security Section
                Section("Security") {
                    NavigationLink("Change Password") {
                        
                    }
                    NavigationLink("Two-Factor Authentication") {
                        
                    }
                }

                // MARK: - About Section
                Section("About") {
                    NavigationLink("App Info") {
                        
                    }
                    Text("Version 1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
        }
    }

    func logout() {
        print("User logged out")
        // implement your logout logic here
    }
}
