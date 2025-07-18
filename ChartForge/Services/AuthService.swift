import Foundation

class AuthService {
    static let shared = AuthService()
    private var token: String?
    
    private init() {}
    
    // Set authentication token
    func setToken(_ token: String) {
        self.token = token
    }
    
    // Get authentication token
    func getToken() -> String? {
        return token
    }
    
    // Secure API request (to be implemented)
    func authorizedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
