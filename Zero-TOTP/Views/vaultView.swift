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

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    var lineWidth: CGFloat {
            size * 0.15 // Proportional line width
        }
        
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.5),
                    lineWidth: lineWidth
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color ,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                // 1
                .animation(.easeOut, value: progress)

        }.frame(width: size, height: size)
    }
}

struct TOTPBoxView: View {
    let website: String
    let code: String
    let color: TOTPBoxColor
    let icon_url: String
    let onEdit: () -> Void
    @State private var animate = false
    @ObservedObject var viewModel: VaultViewModel
    

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                AsyncImage(url: URL(string: icon_url)) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                    @unknown default:
                        EmptyView()
                    }
                    
                }
                Text(website)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.title3 )
                        .foregroundColor(.white)
                }.padding(.trailing, 10)

                Button(action:{viewModel.copy_totp_code(code)} ) {
                    Image(systemName: "document.on.clipboard")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            Divider()

            
            HStack(spacing: 8){
                Spacer()
                CircularProgressView(progress: viewModel.progress, color: .white, size: 20)
                Text(code)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .scaleEffect(animate ? 1.05 : 1.0)
                    .opacity(animate ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 0.25), value: animate)
                Spacer()
            }.frame(maxWidth: .infinity, alignment: .center)
        
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
                    icon_url: entry.favicon_url ,
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
                        if(viewModel.vault_state == .locally_encrypted){
                        
                                VStack{
                                    Spacer()
                                    Image(systemName:"exclamationmark.lock")
                                        .font(.largeTitle)
                                    Text("Your vault is encrypted.").font(.title)
                                    Button(action: {
                                        viewModel.vault_state = .loading
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            // We let the UI update.
                                            viewModel.decryptLocalVault()
                                        }
                                        
                                    }) {
                                        Label("Decrypt my vault", systemImage: "lock.app.dashed")
                                    }.buttonStyle(.borderedProminent)
                                        .padding(.top, 20)
                                        .font(.subheadline)
                                    Spacer()
                                    Button(action: {
                                        viewModel.logout()
                                    }) {
                                        Label("Logout", systemImage: "person.crop.circle.fill.badge.minus")
                                            
                                    }.buttonStyle(.bordered)
                                        .foregroundStyle(.gray)
                                        .padding(.bottom, 50)
                                }
                            }
                        
                        if(viewModel.vault_state == .needToBeFetchedAgain){
                        
                                VStack{
                                    Spacer()
                                    Image(systemName:"externaldrive.fill.badge.questionmark")
                                        .font(.largeTitle)
                                    Text("You need to login again to decrypt your vault").font(.title)
                                    Button(action: {
                                        viewModel.show_login_page = true
                                    }) {
                                        Label("Login", systemImage: "person.crop.circle.badge")
                                    }.buttonStyle(.borderedProminent)
                                        .padding(.top, 20)
                                        .font(.subheadline)
                                    Spacer()
                                }
                            }
                        
                            if(viewModel.vault_state != .locally_encrypted && viewModel.vault_state != .loaded && viewModel.vault_state != .needToBeFetchedAgain){
                            VStack{
                                Spacer()
                                ProgressView()
                                Text("Decrypting your vault ...").font(.subheadline).foregroundStyle(.gray)
                                
                                Spacer()
                                Button(action: {
                                    viewModel.logout()
                                }) {
                                    Label("Logout", systemImage: "person.crop.circle.fill.badge.minus")
                                        
                                }.buttonStyle(.bordered)
                                    .foregroundStyle(.gray)
                                    .padding(.bottom, 50)
                            }
                        }
                        
                            
                        if(viewModel.vault_state == .loaded){
                            ScrollView(.vertical) {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.vault){  entry in
                                        if (searchText == "" || (entry.name.lowercased().contains(searchText.lowercased()) || (entry.domain?.lowercased().contains(searchText.lowercased()) ?? false))) {
                                            TOTPBoxWrapper(entry: entry, viewModel: viewModel)
                                        }
                                    }
                                }
                            }
                            
                            
                        }
                    }.sheet(isPresented: $viewModel.show_login_page ) {
                        viewModel.onVaultAppear()
                        print("login view dismissed")
                    } content: {
                        LoginView(vaultViewModel: viewModel)
                    }
            }.onAppear(perform: viewModel.onVaultAppear)
                .toastView(toast: $viewModel.toast)
                .navigationTitle("Your TOTP vault")
                .navigationBarTitleDisplayMode(.automatic)
            
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        }
        
    }
}



struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView()
    }
}
