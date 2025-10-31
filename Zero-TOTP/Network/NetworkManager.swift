//
//  NetworkManager.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-17.
//

import Foundation

struct ExpiredAPIKeyResponse:Codable {
    var status:Int;
    var detail:String?;
}

class NetworkManager {
    static let shared = NetworkManager()
    private var zero_totp_base_url: URLComponents = URLComponents(string: "https://zero-totp.com")!
    
    init(){
        let defaults = UserDefaults.standard
        if let baseUrlString = defaults.string(forKey: TenantDefaultsKeys.base_url) {
            zero_totp_base_url = URLComponents(string: baseUrlString) ?? URLComponents(string: "https://zero-totp.com")!
        }
    }
    
    func sendRequest(_ request: URLRequest) async throws -> (Data, URLResponse){
        var request = request
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403 {
            let decodedResponse = try? JSONDecoder().decode(ExpiredAPIKeyResponse.self, from: data)
            if (decodedResponse != nil){
                if(decodedResponse?.detail != nil){
                    if(decodedResponse?.detail! == "API key expired"){
                        print("Token expired, trying to refresh...")
                        try await refreshToken()
                        var retryRequest = request
                        return try await URLSession.shared.data(for: retryRequest)
                    }
                }
            }
        }
        return (data, response)
    }
    
    private func refreshToken() async throws {
        var base_url = self.zero_totp_base_url
        base_url.path = "/api/v1/auth/refresh"
        var request = URLRequest(url: base_url.url!)
        request.httpMethod = "PUT"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.userAuthenticationRequired)
                }
    }
}
