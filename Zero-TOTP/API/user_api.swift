//
//  user_api.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 29/04/2024.
//

import Foundation



class UserAPI {
    private var zero_totp_base_url: URLComponents = URLComponents(string: "https://zero-totp.com")!
    private var network_manager=NetworkManager()
    
    init(){
        let defaults = UserDefaults.standard
        if let baseUrlString = defaults.string(forKey: TenantDefaultsKeys.base_url) {
            zero_totp_base_url = URLComponents(string: baseUrlString) ?? URLComponents(string: "https://zero-totp.com")!
        }
    }
    
    enum NetworkError: Error {
        case badUrl
        case invalidRequest
        case badResponse
        case badStatus
        case failedToDecodeResponse
    }
    
    struct LoginSpecResponse: Codable {
        var message:String?;
        var passphrase_salt:String?;
    }
    
    struct LoginBody: Codable {
        var email:String;
        var password:String;
    }
    
    struct LoginResponse: Codable {
        var username:String;
        var id: Int;
        var derivedKeySalt: String;
        var role: String;
    }
    
    struct AuthenticationFlowResult: Codable {
        var status: Int;
        var message: String;
        var derivedKeySalt: String;
        var id:Int;
    }
    
    struct ErrorResponse: Codable {
        var message:String?;
        var error:String?;
    }
    
    struct HttpResponse {
        var status: Int;
        var message:String;
    }
    
    
    struct WhoAmIResult:Codable {
        var status:Int?;
        var message:String?;
        var id:Int?;
        var username:String?;
        var email:String?;
    }
    
    
    func authenticationFlow(username: String,passphrase: String) async -> AuthenticationFlowResult {
        var api_response = AuthenticationFlowResult(status: 0, message: "", derivedKeySalt: "", id:0);
        let generic_errors = ["generic_errors.invalid_creds": "Invalid credentials", "generic_errors.missing_params":"Information are missing. Make sure that Zero-TOTP is up to date", "generic_errors.bad_email":""]

        do {
            var base_url = self.zero_totp_base_url
            base_url.path = "/api/v1/login"
            var request = URLRequest(url: base_url.url!)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let encoder = JSONEncoder()
            let body_data_raw = LoginBody(email: username, password: passphrase)
            let body_data = try encoder.encode(body_data_raw)
            request.httpBody = body_data
            let (response_data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            if(response.statusCode != 200){
                guard let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response_data) else { api_response.status = response.statusCode; throw NetworkError.failedToDecodeResponse }
                api_response.status = response.statusCode
                api_response.message = decodedResponse.message ?? decodedResponse.error ?? "Unknown error"
                if( generic_errors[api_response.message] != nil ){
                    api_response.message = generic_errors[api_response.message]!
                }
                return api_response
            }
            guard let decodedResponse = try? JSONDecoder().decode(LoginResponse.self, from: response_data) else {api_response.status = response.statusCode;  throw NetworkError.failedToDecodeResponse }
                api_response.status = response.statusCode
                api_response.message = "OK"
                api_response.derivedKeySalt = decodedResponse.derivedKeySalt
                api_response.id = decodedResponse.id
                
                
            
                    
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
        return api_response
    }
    
    func getLoginSpec(username:String) async -> HttpResponse {
        var api_response:HttpResponse = HttpResponse(status: 0, message: "");

        do {
            let username_encoded = username.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            var base_url = self.zero_totp_base_url
            base_url.path = "/api/v1/login/specs"
            base_url.percentEncodedQuery = "username=\(username_encoded)"
            guard let final_url = base_url.url else { throw NetworkError.badUrl }
            let (data, response) = try await URLSession.shared.data(from: final_url)
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            if(response.statusCode != 200){
                guard let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) else { api_response.status = response.statusCode; throw NetworkError.failedToDecodeResponse }
                    api_response.status = response.statusCode
                    api_response.message = decodedResponse.message ?? decodedResponse.error ?? "Unknown error"
                    return api_response
            }
            guard let decodedResponse = try? JSONDecoder().decode(LoginSpecResponse.self, from: data) else {api_response.status = 0 ;  throw NetworkError.failedToDecodeResponse }
                api_response.status = response.statusCode
                api_response.message = decodedResponse.passphrase_salt ?? decodedResponse.message ?? ""
            
                    
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
                api_response.message = "An error occured while communicating with Zero-TOTP API"
                api_response.status = 0
            }
                
        return api_response;
    }
    
    func getWhoAmI() async -> WhoAmIResult {
        var api_response:WhoAmIResult = WhoAmIResult(status: 0, message: "")
        do {
            var base_url = self.zero_totp_base_url
            base_url.path = "/api/v1/whoami"
            guard let final_url = base_url.url else { throw NetworkError.badUrl }
            let (data, response) = try await network_manager.sendRequest(URLRequest(url:final_url))
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            if(response.statusCode != 200){
                guard let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) else { api_response.status = response.statusCode; throw NetworkError.failedToDecodeResponse }
                    api_response.status = response.statusCode
                    api_response.message = decodedResponse.message ?? decodedResponse.error ?? "Unknown error"
                    return api_response
            }
            guard let decodedResponse = try? JSONDecoder().decode(WhoAmIResult.self, from: data) else {api_response.status = 0;  throw NetworkError.failedToDecodeResponse }
            api_response.status = response.statusCode
            api_response.message = "OK"
            api_response.id = decodedResponse.id
            api_response.username = decodedResponse.username
            api_response.email = decodedResponse.email
            
                    
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
                api_response.message = "An error occured while communicating with Zero-TOTP API"
                api_response.status = 0
            }
                
        return api_response;
    }
    
    
}
