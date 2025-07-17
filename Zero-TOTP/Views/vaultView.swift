//
//  vaultView.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-15.
//

import SwiftUI
import ComponentsKit



enum TOTPBoxColor {
    case red, blue, green, yellow

    var gradient: LinearGradient {
        switch self {
        case .red:
            return LinearGradient(
                colors: [Color.red.opacity(0.7), Color.red.opacity(0.9)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blue:
            return LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .green:
            return LinearGradient(
                colors: [Color.green.opacity(0.6), Color.green.opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow:
            return LinearGradient(
                colors: [Color.yellow.opacity(0.6), Color.orange.opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct TOTPBoxView: View {
    let website: String
    let code: String
    let color: TOTPBoxColor
    let onEdit: () -> Void
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(website)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.white)
                }.padding(.trailing, 10)

                Button(action: onCopy) {
                    Image(systemName: "document.on.clipboard.fill")
                        .foregroundColor(.white)
                }
            }
            Divider()

            // TOTP Code
            Text(code)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)

        }
        .padding()
        .background(color.gradient)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

struct VaultView: View {
    @State private var searchText = "";
    var body: some View {
        
        
        NavigationStack {
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
                            .padding(.trailing, 30).padding(.leading, 30).multilineTextAlignment(.center).padding(.bottom, 30)
                    
                        HStack{
                            Text(Image(systemName: "magnifyingglass")).foregroundStyle(.white)
                            TextField("Search", text:$searchText )
                                  .autocapitalization(.none)
                                .preferredColorScheme(.dark)
                                .foregroundColor(.white)
                                .bold().onAppear { UITextField.appearance().clearButtonMode = .whileEditing }
                        }.padding(.horizontal, 30).padding(.bottom, 20)
                        
                        VStack(spacing: 20) {
                                    TOTPBoxView(
                                        website: "github.com",
                                        code: "123 456",
                                        color: .blue,
                                        onEdit: { print("Edit tapped") },
                                        onCopy: { print("Copy tapped") }
                                    )
                                }
                        VStack(spacing: 20) {
                                    TOTPBoxView(
                                        website: "amazon.com",
                                        code: "123 456",
                                        color: .green,
                                        onEdit: { print("Edit tapped") },
                                        onCopy: { print("Copy tapped") }
                                    )
                                }
                        VStack(spacing: 20) {
                                    TOTPBoxView(
                                        website: "apple.com",
                                        code: "123 456",
                                        color: .red,
                                        onEdit: { print("Edit tapped") },
                                        onCopy: { print("Copy tapped") }
                                    )
                                }
                        VStack(spacing: 20) {
                                    TOTPBoxView(
                                        website: "microsoft.com",
                                        code: "123 456",
                                        color: .yellow,
                                        onEdit: { print("Edit tapped") },
                                        onCopy: { print("Copy tapped") }
                                    )
                                }
                        
                    }
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
