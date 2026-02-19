import Foundation
import Security

/// Lightweight Supabase REST client using URLSession and Keychain for session storage.
/// Uses environment values from Info.plist keys: SUPABASE_URL and SUPABASE_ANON_KEY

public struct SupabaseSession: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
}

final class KeychainStore {
    static func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecValueData as String: data]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(key: String) -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecReturnData as String: kCFBooleanTrue!,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }

    static func delete(key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
    }
}

final class SupabaseClient {
    static let shared = SupabaseClient()
    private let sessionKey = "supabase_session_v1"

    private var supabaseUrl: URL
    private var anonKey: String

    private var urlSession = URLSession.shared

    private init() {
        let bundle = Bundle.main
        let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        let anon = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        guard let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL not configured in Info.plist or environment")
        }
        self.supabaseUrl = url
        self.anonKey = anon
    }

    // MARK: - Session storage
    func saveSession(_ s: SupabaseSession) {
        if let data = try? JSONEncoder().encode(s) {
            _ = KeychainStore.save(key: sessionKey, data: data)
        }
    }

    func loadSession() -> SupabaseSession? {
        guard let data = KeychainStore.load(key: sessionKey) else { return nil }
        return try? JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    func clearSession() {
        KeychainStore.delete(key: sessionKey)
    }

    // MARK: - Auth (OTP)
    /// Send OTP email (Supabase Auth: /auth/v1/otp)
    func signInWithOtp(email: String) async throws {
        let endpoint = supabaseUrl.appendingPathComponent("auth/v1/otp")
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["email": email]
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "SupabaseClient", code: 1, userInfo: ["data": data])
        }
        // Supabase returns 200 even if email sent. Nothing to store here.
    }

    /// Verify OTP with token. Uses token grant endpoint. Stores session on success.
    func verifyOtp(email: String, token: String) async throws {
        let endpoint = supabaseUrl.appendingPathComponent("auth/v1/token?grant_type=otp")
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["email": email, "token": token]
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "SupabaseClient", code: 2, userInfo: ["data": data])
        }
        // Parse response for access and refresh tokens; Supabase returns JSON with access_token, refresh_token, expires_in
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let access = json?["access_token"] as? String,
           let refresh = json?["refresh_token"] as? String,
           let expiresIn = json?["expires_in"] as? Double {
            let expiresAt = Date().addingTimeInterval(expiresIn)
            let s = SupabaseSession(accessToken: access, refreshToken: refresh, expiresAt: expiresAt)
            saveSession(s)
        } else {
            throw NSError(domain: "SupabaseClient", code: 3, userInfo: ["message": "Missing tokens in response"])
        }
    }

    // Refresh session when expired
    func refreshIfNeeded() async throws {
        guard let s = loadSession() else { return }
        if s.expiresAt > Date().addingTimeInterval(10) { return } // still valid
        // refresh
        let endpoint = supabaseUrl.appendingPathComponent("auth/v1/token?grant_type=refresh_token")
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["refresh_token": s.refreshToken]
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "SupabaseClient", code: 4, userInfo: ["data": data])
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let access = json?["access_token"] as? String,
           let refresh = json?["refresh_token"] as? String,
           let expiresIn = json?["expires_in"] as? Double {
            let expiresAt = Date().addingTimeInterval(expiresIn)
            let s2 = SupabaseSession(accessToken: access, refreshToken: refresh, expiresAt: expiresAt)
            saveSession(s2)
        }
    }

    // MARK: - Helpers for authed requests
    private func baseRequest(path: String, method: String = "GET") async throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: supabaseUrl) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        return req
    }

    func authedRequest(path: String, method: String = "GET", body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        try await refreshIfNeeded()
        guard let s = loadSession() else { throw NSError(domain: "SupabaseClient", code: 5, userInfo: ["message": "No session"]) }
        let full = supabaseUrl.appendingPathComponent(path)
        var req = URLRequest(url: full)
        req.httpMethod = method
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(s.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }

    /// Get current user info from Supabase Auth
    func currentUser() async throws -> [String: Any]? {
        try await refreshIfNeeded()
        guard let s = loadSession() else { return nil }
        let endpoint = supabaseUrl.appendingPathComponent("auth/v1/user")
        var req = URLRequest(url: endpoint)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(s.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json
    }

    // Convenience: GET from table with query params (Supabase REST endpoint: /rest/v1/<table>)
    func getFromTable(_ table: String, query: String? = nil) async throws -> Data {
        let path = "rest/v1/\(table)" + (query.map { "?\($0)" } ?? "")
        let (data, http) = try await authedRequest(path: path, method: "GET")
        guard (200...299).contains(http.statusCode) else { throw NSError(domain: "SupabaseClient", code: http.statusCode, userInfo: ["data": data]) }
        return data
    }

    func postToTable(_ table: String, jsonObject: Any) async throws {
        let path = "rest/v1/\(table)"
        let body = try JSONSerialization.data(withJSONObject: jsonObject)
        var req = URLRequest(url: supabaseUrl.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        // Prefer using service role for inserts, but for client-created rows we'll attach auth header
        if let s = loadSession() {
            req.setValue("Bearer \(s.accessToken)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "SupabaseClient", code: 6, userInfo: ["data": data])
        }
    }
}
