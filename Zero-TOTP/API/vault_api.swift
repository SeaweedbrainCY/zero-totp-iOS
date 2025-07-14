//
//  vault_api.swift
//  Zero-TOTP
//
//  Created by Nathan Stchepinsky on 2025-07-14.
//

import Foundation

class VaultAPI {
    var zero_totp_base_url: URLComponents = URLComponents(string: "https://zero-totp.com")!
    
    enum NetworkError: Error {
        case badUrl
        case invalidRequest
        case badResponse
        case badStatus
        case failedToDecodeResponse
    }
    
    struct ErrorResponse: Codable {
        var message:String?;
        var error:String?;
    }
    
    
    struct ZKEEncryptedKeySpecResponse:Codable {
        var zke_encrypted_key: String?;
    }
    
    struct ZKEEncryptedKeyFlowResult {
        var zke_encrypted_key: String?;
        var status: Int;
        var message: String;
    }
    
    
    
    init(){
        let defaults = UserDefaults.standard
        if let baseUrlString = defaults.string(forKey: "zero_totp_base_url") {
            zero_totp_base_url = URLComponents(string: baseUrlString) ?? URLComponents(string: "https://zero-totp.com")!
        }
    }
    
    
    func get_zke_encrypted_key() async -> ZKEEncryptedKeyFlowResult {
        var api_response: ZKEEncryptedKeyFlowResult = ZKEEncryptedKeyFlowResult(zke_encrypted_key: nil, status: 0, message: "")
        
        do {
            var base_url = self.zero_totp_base_url
            base_url.path = "/api/v1/zke_encrypted_key"
            guard let final_url = base_url.url else { throw NetworkError.badUrl }
            let (data, response) = try await URLSession.shared.data(from: final_url)
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            if (response.statusCode == 200){
                guard let decoded_response = try? JSONDecoder().decode(ZKEEncryptedKeySpecResponse.self, from: data) else {
                    api_response.status = response.statusCode;
                    throw NetworkError.failedToDecodeResponse
                }
                api_response.status = response.statusCode;
                api_response.message = "OK";
                api_response.zke_encrypted_key = decoded_response.zke_encrypted_key;
            } else {
                guard let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) else { api_response.status = response.statusCode; throw NetworkError.failedToDecodeResponse }
                api_response.status = response.statusCode
                api_response.message = decodedResponse.message ?? decodedResponse.error ?? "Unknown error";
            }
        } catch NetworkError.badUrl {
            api_response.message = "There was an error forging the request";
            api_response.status = 0;
        } catch NetworkError.badResponse {
            api_response.message = "Impossible to chat with the server. Verify your connection and/or status.zero-totp.com";
            api_response.status = 0
        } catch NetworkError.badStatus {
            api_response.message = "Did not get a 2xx status code from the response"
            api_response.status = 0
        } catch NetworkError.failedToDecodeResponse {
            api_response.message = "Failed to read the response from API."
        } catch {
            api_response.message = "An error occured decoding the data"
            api_response.status = 0
        }
        return api_response;
        
    }
}
