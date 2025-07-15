//
//  generalTabView.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-15.
//


import SwiftUI


struct GeneralTabView: View {
    var body: some View {
        TabView {
                    Tab("Vault", systemImage: "lock.rectangle.stack") {
                        VaultView()
                    }
                    Tab("Settings", systemImage: "gear") {
                        HomeView()
                    }
                }.tabViewStyle(.sidebarAdaptable)
    }
}


