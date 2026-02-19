import SwiftUI

struct CreateTicketView: View {
    @StateObject private var vm = OrdersViewModel()
    @Environment(\.presentationMode) var presentationMode

    var hall: String
    var items: [String] // item IDs

    @State private var selectedIndex = 0
    private var pickupOptions: [Date] {
        var arr: [Date] = []
        let now = Date()
        for i in 1...12 { // next 2 hours in 10-min increments (12 * 10 = 120)
            let mins = i * 10
            arr.append(Calendar.current.date(byAdding: .minute, value: mins, to: now)!)
        }
        return arr
    }
    @State private var note: String = ""

    var body: some View {
        Form {
            Section(header: Text("Pickup time")) {
                Picker("Pickup", selection: $selectedIndex) {
                    ForEach(0..<pickupOptions.count, id: \ .self) { idx in
                        Text(DateFormatter.localizedString(from: pickupOptions[idx], dateStyle: .none, timeStyle: .short)).tag(idx)
                    }
                }
            }

            Section(header: Text("Items")) {
                ForEach(items, id: \ .self) { id in
                    Text(id)
                }
            }

            Section(header: Text("Note")) {
                TextField("Optional note", text: $note)
            }

            Button("Create Ticket") {
                Task {
                    let dt = pickupOptions[selectedIndex]
                    await vm.createOrder(hall: hall, pickup: dt, itemIds: items, note: note)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle("Create Ticket")
    }
}
