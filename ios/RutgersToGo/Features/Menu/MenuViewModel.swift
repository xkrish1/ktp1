import Foundation
import Combine

@MainActor
final class MenuViewModel: ObservableObject {
    @Published var hall: String = "Atrium"
    @Published var date: Date = Date()
    @Published var meal: String = "Lunch"
    @Published var items: [[String: Any]] = []

    private let repo = MenuRepo()

    func load() async {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateStr = DateFormatter()
        dateStr.dateFormat = "yyyy-MM-dd"
        do {
            let fetched = try await repo.fetchMenu(hall: hall, date: dateStr.string(from: date), meal: meal)
            items = fetched
        } catch {
            print("menu fetch error: \(error)")
            items = []
        }
    }
}
