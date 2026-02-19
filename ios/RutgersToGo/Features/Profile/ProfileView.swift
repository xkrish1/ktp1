import SwiftUI

struct Chip: View {
    let label: String
    let selected: Bool
    var body: some View {
        Text(label)
            .font(.caption)
            .padding(8)
            .background(selected ? Color.accentColor.opacity(0.2) : Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
    }
}

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    var userId: String

    var body: some View {
        Form {
            Section(header: Text("Allergens")) {
                WrapView(items: vm.allergenKeys, id: \ .self) { k in
                    Button(action: { toggleAllergen(k) }) { Chip(label: k, selected: vm.selectedAllergens.contains(k)) }
                }
            }

            Section(header: Text("Restrictions")) {
                WrapView(items: vm.restrictionKeys, id: \ .self) { k in
                    Button(action: { toggleRestriction(k) }) { Chip(label: k, selected: vm.selectedRestrictions.contains(k)) }
                }
            }

            Button("Save") { Task { await vm.save(userId: userId) } }
        }
        .onAppear { Task { await vm.load() } }
    }

    private func toggleAllergen(_ k: String) { if vm.selectedAllergens.contains(k) { vm.selectedAllergens.remove(k) } else { vm.selectedAllergens.insert(k) } }
    private func toggleRestriction(_ k: String) { if vm.selectedRestrictions.contains(k) { vm.selectedRestrictions.remove(k) } else { vm.selectedRestrictions.insert(k) } }
}

// Simple wrap view used to display chips in multiple lines
struct WrapView<Data: RandomAccessCollection, Content: View, ID: Hashable>: View where Data.Element: Hashable {
    var items: Data
    var id: KeyPath<Data.Element, Data.Element>
    var content: (Data.Element) -> Content

    init(items: Data, id: KeyPath<Data.Element, Data.Element>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.id = id
        self.content = content
    }

    var body: some View {
        // Very simple horizontal wrap using LazyVStack & flexible HStacks
        VStack(alignment: .leading) {
            var current: [Data.Element] = []
            // For brevity, show a simple VStack of HStacks dividing by 3 per row
            ForEach(Array(items.enumerated()), id: \ .offset) { idx, item in
                if idx % 3 == 0 { HStack { content(item) } }
                else { HStack { content(item) } }
            }
        }
    }
}
