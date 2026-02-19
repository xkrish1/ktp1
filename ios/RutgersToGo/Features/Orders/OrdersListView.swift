import SwiftUI

struct OrdersListView: View {
    @StateObject private var vm = OrdersViewModel()

    var body: some View {
        List {
            ForEach(vm.recentOrders, id: \ .self) { order in
                NavigationLink(destination: {
                    if let id = order["id"] as? String { TicketView(orderId: id) }
                    else { Text("Invalid order") }
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Order: \(order["id"] as? String ?? "")")
                                .font(.subheadline)
                            Text("Status: \(order["status"] as? String ?? "")")
                                .font(.caption)
                        }
                        Spacer()
                        Text(order["hall"] as? String ?? "")
                    }
                }
            }
        }
        .navigationTitle("My Orders")
        .onAppear { Task { await vm.loadRecent() } }
    }
}
