//
//  vaultView.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-15.
//

import SwiftUI
import SwiftOTP



enum TOTPBoxColor {
    case red, blue, green, yellow

    var gradient: LinearGradient {
        switch self {
        case .red:
            return LinearGradient(
                
                colors: [Color("danger").opacity(0.9), Color("danger").opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blue:
            return LinearGradient(
                colors: [Color("info").opacity(0.9), Color("info").opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .green:
            return LinearGradient(
                colors: [Color("success").opacity(0.9), Color("success").opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow:
            return LinearGradient(
                colors: [Color("warning").opacity(0.9), Color("warning").opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct TOTPBoxView: View {
    let website: String
    let code: String
    let color: TOTPBoxColor
    let onEdit: () -> Void
    @State private var animate = false
    @ObservedObject var viewModel: VaultViewModel
    

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

                Button(action:{viewModel.copy_totp_code(code)} ) {
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
                .scaleEffect(animate ? 1.05 : 1.0)
                .opacity(animate ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.25), value: animate)

        }
        .padding()
        .background(color.gradient
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 6)
        .padding(.horizontal)
        .padding(.top, 20)
        .onChange(of: code) {
                    animate = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        animate = false
                    }
                }
        .onTapGesture {viewModel.copy_totp_code(code)}
    }
}



struct TOTPBoxWrapper: View {
    @ObservedObject var entry: TOTPEntry
    @ObservedObject var viewModel: VaultViewModel

        var body: some View {
            
            VStack(spacing: 20) {
                TOTPBoxView(
                    website: entry.name,
                    code: "\(entry.totp_code ?? "Error")" ,
                    color: entry.color,
                    onEdit: { print("edit tapped")},
                    viewModel: viewModel
                )
            }
    }
}

struct VaultView: View {
    @State private var searchText = "";
    @StateObject private var viewModel = VaultViewModel()
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                Color("dark")
                        .ignoresSafeArea()

                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .offset(x: -100, y: -200)
                        .blur(radius: 100)

                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 250, height: 250)
                        .offset(x: 150, y: 250)
                        .blur(radius: 100)

                VStack{
                VStack {
                    Image("logo_zero_totp_light")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 100)
                        .padding(.top, 20)
                        .padding(.horizontal, 40)
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
                    
                    ProgressView(value: viewModel.progress)
                        .padding(.horizontal)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                }.sheet(isPresented: $viewModel.show_login_page ) {
                    viewModel.onVaultAppear()
                    print("login view dismissed")
                } content: {
                    LoginView(vaultViewModel: viewModel)
                }
                    VStack{
                        
                        ScrollView(.vertical) {
                            ForEach(viewModel.vault){  entry in
                                TOTPBoxWrapper(entry: entry, viewModel: viewModel)
                            }
                        }
                    }
                }
            }.onAppear(perform: viewModel.onVaultAppear).toastView(toast: $viewModel.toast)
        }
        
    }
}



struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView()
    }
}
