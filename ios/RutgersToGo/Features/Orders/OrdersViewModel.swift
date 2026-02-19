import Foundation
import Combine

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published var recentOrders: [[String: Any]] = []
    @Published var selectedOrder: [String: Any]? = nil
    @Published var errorMessage: String? = nil

    private let repo = OrdersRepo()

    func createOrder(hall: String, pickup: Date, itemIds: [String], note: String?) async {
        let fmt = ISO8601DateFormatter()
        let iso = fmt.string(from: pickup)
        do {
            _ = try await repo.createOrder(hall: hall, pickupTimeISO: iso, itemIds: itemIds, note: note)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadRecent() async {
        do {
            let rows = try await repo.fetchRecentForUser()
            recentOrders = rows
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshOrder(id: String) async {
        do {
            if let row = try await repo.fetchOrder(id: id) { selectedOrder = row }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateStatus(orderId: String, status: String) async {
        do {
            try await repo.updateOrderStatus(orderId: orderId, status: status)
            await loadRecent()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
