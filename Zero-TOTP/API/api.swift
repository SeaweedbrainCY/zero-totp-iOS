//
//  api.swift
//  Zero-TOTP
//
//  Created by Stchepinsky Nathan on 29/04/2024.
//

import Foundation



class API {
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
    
    struct HttpResponse {
        var status: Int;
        var message:String;
    }
    
    func authenticationFlow(username: String,passphrase: String) async -> HttpResponse {
        let login_specs_response = await getLoginSpec(username: username)
        if login_specs_response.status == 200{
            
        } else {
            return login_specs_response;
        }
        return HttpResponse(status: 0, message: "Unknown error")
    }
    
    func getLoginSpec(username:String) async -> HttpResponse {
        var api_response:HttpResponse = HttpResponse(status: 0, message: "");

        do {
            let username_encoded = username.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            guard let url = URL(string: "https://api.zero-totp.com/login/specs?username=" + username_encoded) else { throw NetworkError.badUrl }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            guard let decodedResponse = try? JSONDecoder().decode(LoginSpecResponse.self, from: data) else { throw NetworkError.failedToDecodeResponse }
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
                api_response.message = "Failed to decode response into the given type"
                api_response.status = 0
            } catch {
                api_response.message = "An error occured decoding the data"
                api_response.status = 0
            }
                
        return api_response;
    }
    
    
}
