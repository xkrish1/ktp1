import SwiftUI

struct MenuView: View {
    @StateObject private var vm = MenuViewModel()

    var body: some View {
        VStack {
            Picker("Hall", selection: $vm.hall) {
                Text("Atrium").tag("Atrium")
                Text("Busch").tag("Busch")
            }
            .pickerStyle(.segmented)
            .padding()

            HStack {
                DatePicker("", selection: $vm.date, displayedComponents: .date)
                Picker("Meal", selection: $vm.meal) {
                    Text("Breakfast").tag("Breakfast")
                    Text("Lunch").tag("Lunch")
                    Text("Dinner").tag("Dinner")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            List(vm.items, id: \ .self) { item in
                NavigationLink(destination: MenuItemDetailView(item: item)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item["name"] as? String ?? "Unnamed")
                                .font(.headline)
                            Text(item["station"] as? String ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusPill(status: Classifier.classifyRow(item: item).status)
                    }
                }
            }
        }
        .navigationTitle("Menu")
        .onAppear { Task { await vm.load() } }
    }
}

struct StatusPill: View {
    let status: ClassificationStatus
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(6)
            .background(color)
            .cornerRadius(8)
    }

    var color: Color {
        switch status {
        case .safe: return Color.green.opacity(0.2)
        case .avoid: return Color.red.opacity(0.2)
        case .uncertain: return Color.yellow.opacity(0.2)
        }
    }
}
