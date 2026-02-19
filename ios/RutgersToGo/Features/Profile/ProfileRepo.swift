import Foundation

final class ProfileRepo {
    private let client = SupabaseClient.shared

    func fetchProfile() async throws -> [String: Any]? {
        // fetch profile for current user
        let data = try await client.getFromTable("profiles", query: nil)
        // return first row if exists
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return nil }
        return arr.first
    }

    func upsertProfile(userId: String, allergens: [String], restrictions: [String], severity: [String: Int]) async throws {
        let obj: [String: Any] = [
            "user_id": userId,
            "allergens": allergens,
            "restrictions": restrictions,
            "severity": severity
        ]
        try await client.postToTable("profiles", jsonObject: obj)
    }
}
