import SwiftUI

struct TicketView: View {
    @StateObject private var vm = OrdersViewModel()
    let orderId: String

    var body: some View {
        VStack(spacing: 16) {
            if let order = vm.selectedOrder {
                let payload = buildPayload(order: order)
                QRCodeView(payload: payload)

                Text("Status: \(order["status"] as? String ?? "unknown")")
                    .font(.headline)

                VStack(alignment: .leading) {
                    if let itemIds = order["item_ids"] as? [String] {
                        ForEach(itemIds, id: \ .self) { id in Text("• \(id)") }
                    }
                }

                Button("Refresh") { Task { await vm.refreshOrder(id: orderId) } }
            } else {
                Text("Loading...")
                    .onAppear { Task { await vm.refreshOrder(id: orderId) } }
            }
        }
        .padding()
    }

    func buildPayload(order: [String: Any]) -> String {
        var dict: [String: Any] = [:]
        dict["order_id"] = order["id"] as? String ?? orderId
        dict["hall"] = order["hall"] as? String ?? ""
        dict["pickup_time"] = order["pickup_time"] as? String ?? ""
        if let d = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            return String(data: d, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }
}
