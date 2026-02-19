import SwiftUI

struct StaffView: View {
    @State private var pin: String = ""
    @State private var unlocked = false
    @StateObject private var vm = OrdersViewModel()

    // Hardcoded PIN for hackathon demo
    private let demoPin = "1234"

    var body: some View {
        VStack {
            if !unlocked {
                SecureField("Enter staff PIN", text: $pin)
                    .padding()
                Button("Unlock") {
                    if pin == demoPin { unlocked = true; Task { await vm.loadRecent() } }
                }
                .buttonStyle(.borderedProminent)
            } else {
                List(vm.recentOrders, id: \ .self) { order in
                    VStack(alignment: .leading) {
                        Text(order["id"] as? String ?? "")
                        Text("Status: \(order["status"] as? String ?? "")")
                        HStack {
                            Button("Prepping") { Task { if let id = order["id"] as? String { await vm.updateStatus(orderId: id, status: "prepping") } } }
                            Button("Ready") { Task { if let id = order["id"] as? String { await vm.updateStatus(orderId: id, status: "ready") } } }
                            Button("Picked Up") { Task { if let id = order["id"] as? String { await vm.updateStatus(orderId: id, status: "picked_up") } } }
                        }
                    }
                }
            }
        }
        .navigationTitle("Staff")
    }
}
