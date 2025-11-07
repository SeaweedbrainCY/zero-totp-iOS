//
//  settings.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-11-02.
//

import Foundation
import SwiftUI
import UIKit

enum SettingsState {
    case loading;
    case logging_out;
    case loaded;
}

struct SettingsView: View {
    @State private var isFaviconPreviewEnabled = true
    @State private var darkMode = false
    @State private var showFaviconPreviewInfo = false
    @State private var showLogoutConfirmation = false
    @State private var settingsState: SettingsState = .loaded
    
    var body: some View {
        if (settingsState == .loading){
        }
        
        if(settingsState == .logging_out){
            VStack{
                Spacer()
                ProgressView()
                Text("Logging you out ...").font(.subheadline).foregroundStyle(.gray)
                
                Spacer()
            }
        }
        
        if(settingsState == .loaded){
            NavigationStack {
                List {
                    // MARK: - Account Section
                    Section("Account") {
                        NavigationLink {
                            
                        } label: {
                            Label("Edit profile", systemImage: "person.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }
                        Button(role: .destructive) {
                            showLogoutConfirmation = true
                        } label: {
                            Label("Log out", systemImage: "person.slash.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }
                        
                    }
                    .alert("Logout", isPresented: $showLogoutConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Logout", role: .destructive) {
                            logout()
                        }
                    } message: {
                        Text("""
Are you sure ? 
All the data on this device will be erased and you will have to login again to retrieve them.
""")
                    }
                    
                    // MARK: - Preferences Section
                    Section("Preferences") {
                        Toggle(isOn: $isFaviconPreviewEnabled){
                            HStack(spacing: 5) {
                                Label("Display websites' logo", systemImage: "photo.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.primary)
                                
                                Button {
                                    showFaviconPreviewInfo = true
                                } label: {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .alert("Display websites' logo", isPresented: $showFaviconPreviewInfo) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("""
When enabled, the app will try to fetch the favicon (logo) of each code's website and display it. If it fails, it will display a default icon.
                             
The favicon is fetched by the app using the DuckDuckGo API (a privacy friendly search engine). Zero-TOTP does not transmit any information to DuckDuckGo or the target website. The URI or domain name is never transmitted to zero-totp servers.

You can disable this feature globally, enable it globally, or use each secrets' setting.
""")
                        }
                        NavigationLink {
                            
                        } label:{
                            Label("Google Drive backups", systemImage: "externaldrive.badge.icloud")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    // MARK: - Security Section
                    Section("Security") {
                        NavigationLink {
                            
                        } label :{
                            Label("Update your passphrase", systemImage: "key.viewfinder")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
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
    }
    
    func logout() {
        settingsState = .logging_out
        Utils().eraseUserData()
        
    }
}
