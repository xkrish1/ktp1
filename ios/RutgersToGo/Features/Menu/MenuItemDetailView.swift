import SwiftUI
import SafariServices

struct DisclaimerBanner: View {
    var body: some View {
        Text("Disclaimer: This classification is automated and may be incorrect — verify with the station.")
            .font(.footnote)
            .padding(8)
            .background(Color(UIColor.systemGray6))
    }
}

struct MenuItemDetailView: View {
    let item: [String: Any]
    @State private var showSafari = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DisclaimerBanner()

                Text(item["name"] as? String ?? "Unnamed")
                    .font(.title2).bold()

                HStack {
                    Text(item["station"] as? String ?? "")
                    Spacer()
                    Text(item["hall"] as? String ?? "")
                }

                let result = Classifier.classifyRow(item: item)
                HStack {
                    Text(result.status.rawValue.capitalized)
                        .padding(8)
                        .background(statusColor(result.status))
                        .cornerRadius(8)
                    Spacer()
                }

                if !result.reasons.isEmpty {
                    VStack(alignment: .leading) {
                        ForEach(result.reasons, id: \ .self) { r in Text("• \(r)") }
                    }
                }

                if let ing = item["ingredients"] as? String {
                    Text("Ingredients") .font(.headline)
                    Text(ing)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }

                if let src = item["source_url"] as? String, let _ = URL(string: src) {
                    Button("Open Source") { showSafari = true }
                        .sheet(isPresented: $showSafari) {
                            if let url = URL(string: src) { SafariView(url: url) }
                        }
                }
            }
            .padding()
        }
    }

    func statusColor(_ s: ClassificationStatus) -> Color {
        switch s { case .safe: return Color.green.opacity(0.2); case .avoid: return Color.red.opacity(0.2); case .uncertain: return Color.yellow.opacity(0.2) }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
