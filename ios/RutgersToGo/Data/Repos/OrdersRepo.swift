import Foundation

final class OrdersRepo {
    private let client = SupabaseClient.shared

    /// Create an order. The function will fetch current user id and insert into orders table.
    func createOrder(hall: String, pickupTimeISO: String, itemIds: [String], note: String?) async throws -> String? {
        guard let user = try await client.currentUser(), let uid = user["id"] as? String else {
            throw NSError(domain: "OrdersRepo", code: 1, userInfo: ["message": "No authenticated user"]) }

        let obj: [String: Any] = [
            "user_id": uid,
            "hall": hall,
            "pickup_time": pickupTimeISO,
            "item_ids": itemIds,
            "note": note ?? "",
            // status defaults to 'submitted' in DB
        ]

        try await client.postToTable("orders", jsonObject: obj)
        // Supabase REST POST may not return the ID without Prefer header; simplest: return nil and caller can fetch recent orders
        return nil
    }

    func fetchOrder(id: String) async throws -> [String: Any]? {
        // GET /rest/v1/orders?id=eq.<id>&select=*
        let q = "id=eq.\(id)&select=*"
        let data = try await client.getFromTable("orders", query: q)
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return nil }
        return arr.first
    }

    func fetchRecentForUser(limit: Int = 20) async throws -> [[String: Any]] {
        // GET /rest/v1/orders?select=*&order=created_at.desc&limit=20
        let q = "select=*&order=created_at.desc&limit=\(limit)"
        let data = try await client.getFromTable("orders", query: q)
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return arr
    }

    func fetchLatest(limit: Int = 20) async throws -> [[String: Any]] {
        // For staff/demo: attempt to fetch latest orders (may be blocked by RLS for non-admins)
        let path = "rest/v1/orders?select=*&order=created_at.desc&limit=\(limit)"
        let (data, http) = try await client.authedRequest(path: path, method: "GET")
        guard (200...299).contains(http.statusCode) else { return [] }
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return arr
    }

    func updateOrderStatus(orderId: String, status: String) async throws {
        let path = "rest/v1/orders?id=eq.\(orderId)"
        let body = try JSONSerialization.data(withJSONObject: ["status": status])
        let (data, http) = try await client.authedRequest(path: path, method: "PATCH", body: body)
        guard (200...299).contains(http.statusCode) else { throw NSError(domain: "OrdersRepo", code: http.statusCode, userInfo: ["data": data]) }
    }
}
