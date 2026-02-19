import Foundation

final class MenuRepo {
    private let client = SupabaseClient.shared

    /// Query menu_items by hall, date (ISO yyyy-mm-dd), meal
    func fetchMenu(hall: String, date: String, meal: String) async throws -> [[String: Any]] {
        // Supabase REST: GET /rest/v1/menu_items?hall=eq.<hall>&date=eq.<date>&meal=eq.<meal>
        let q = "hall=eq.\(hall)&date=eq.\(date)&meal=eq.\(meal)"
        let data = try await client.getFromTable("menu_items", query: q)
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return arr
    }
}
